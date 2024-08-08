#import "manual_hook.h"
#import "hidden_path.h"
#import "substrate.h"
#import "dobby.h"
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/mount.h>
#include <unistd.h>
#include <spawn.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
#include <dlfcn.h>
#include <mach-o/dyld.h>
#include <sys/sysctl.h>
#include <dirent.h>

static int (*orig_open)(const char *path, int oflag, ...);
static int hook_open(const char *path, int oflag, ...) {
    int result = 0;

    if(path) {
        NSString *pathname = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:path length:strlen(path)];

        if(isHiddenPath(pathname)) {
            errno = ((oflag & O_CREAT) == O_CREAT) ? EACCES : ENOENT;
            return -1;
        }
    }
    
    if((oflag & O_CREAT) == O_CREAT) {
        mode_t mode;
        va_list args;
        
        va_start(args, oflag);
        mode = (mode_t) va_arg(args, int);
        va_end(args);

        result = orig_open(path, oflag, mode);
    } else {
        result = orig_open(path, oflag);
    }

    return result;
}

static int (*orig_openat)(int fd, const char *path, int oflag, ...);
static int hook_openat(int fd, const char *path, int oflag, ...) {
    int result = 0;

    if(path) {
        NSString *nspath = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:path length:strlen(path)];

        if(![nspath isAbsolutePath]) {
            // Get path of dirfd.
            char dirfdpath[PATH_MAX];
        
            if(fcntl(fd, F_GETPATH, dirfdpath) != -1) {
                NSString *dirfd_path = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:dirfdpath length:strlen(dirfdpath)];
                nspath = [dirfd_path stringByAppendingPathComponent:nspath];
            }
        }
        
        if(isHiddenPath(nspath)) {
            errno = ((oflag & O_CREAT) == O_CREAT) ? EACCES : ENOENT;
            return -1;
        }
    }
    
    if((oflag & O_CREAT) == O_CREAT) {
        mode_t mode;
        va_list args;
        
        va_start(args, oflag);
        mode = (mode_t) va_arg(args, int);
        va_end(args);

        result = orig_openat(fd, path, oflag, mode);
    } else {
        result = orig_openat(fd, path, oflag);
    }

    return result;
}

// static DIR *(*orig_opendir)(const char *filename);
// static DIR *hook_opendir(const char *filename) {
//     if(filename) {
//         NSString *path = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:filename length:strlen(filename)];

//         if(isHiddenPath(path)) {
//             errno = ENOENT;
//             return NULL;
//         }
//     }

//     return orig_opendir(filename);
// }

static struct dirent *(*orig_readdir)(DIR *dirp);
static struct dirent *hook_readdir(DIR *dirp) {
    struct dirent *ret = NULL;
    NSString *path = nil;

    // Get path of dirfd.
    NSString *dirfd_path = nil;
    int fd = dirfd(dirp);
    char dirfdpath[PATH_MAX];

    if(fcntl(fd, F_GETPATH, dirfdpath) != -1) {
        dirfd_path = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:dirfdpath length:strlen(dirfdpath)];
    } else {
        return orig_readdir(dirp);
    }

    // Filter returned results, skipping over restricted paths.
    do {
        ret = orig_readdir(dirp);

        if(ret) {
            path = [dirfd_path stringByAppendingPathComponent:[NSString stringWithUTF8String:ret->d_name]];
        } else {
            break;
        }
    } while(isHiddenPath(path));

    return ret;
}

// static int (*orig_dladdr)(const void *addr, Dl_info *info);
// static int hook_dladdr(const void *addr, Dl_info *info) {
//     int ret = orig_dladdr(addr, info);

//     if(ret) {
//         NSString *path = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:info->dli_fname length:strlen(info->dli_fname)];

//         if(isHiddenPath(path)) {
//             return 0;
//         }
//     }

//     return ret;
// }

static ssize_t (*orig_readlink)(const char *path, char *buf, size_t bufsiz);
static ssize_t hook_readlink(const char *path, char *buf, size_t bufsiz) {
    if(!path || !buf) {
        return orig_readlink(path, buf, bufsiz);
    }

    NSString *nspath = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:path length:strlen(path)];

    if(isHiddenPath(nspath)) {
        errno = ENOENT;
        return -1;
    }

    ssize_t ret = orig_readlink(path, buf, bufsiz);

    if(ret != -1) {
        buf[ret] = '\0';

        // Track this symlink in HiddenJailbreak
        // [_hiddenjailbreak addLinkFromPath:nspath toPath:[[NSFileManager defaultManager] stringWithFileSystemRepresentation:buf length:strlen(buf)]];
    }

    return ret;
}

static ssize_t (*orig_readlinkat)(int fd, const char *path, char *buf, size_t bufsiz);
static ssize_t hook_readlinkat(int fd, const char *path, char *buf, size_t bufsiz) {
    if(!path || !buf) {
        return orig_readlinkat(fd, path, buf, bufsiz);
    }

    NSString *nspath = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:path length:strlen(path)];

    if(![nspath isAbsolutePath]) {
        // Get path of dirfd.
        char dirfdpath[PATH_MAX];
    
        if(fcntl(fd, F_GETPATH, dirfdpath) != -1) {
            NSString *dirfd_path = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:dirfdpath length:strlen(dirfdpath)];
            nspath = [dirfd_path stringByAppendingPathComponent:nspath];
        }
    }

    if(isHiddenPath(nspath)) {
        errno = ENOENT;
        return -1;
    }

    ssize_t ret = orig_readlinkat(fd, path, buf, bufsiz);

    if(ret != -1) {
        buf[ret] = '\0';

        // Track this symlink in HiddenJailbreak
        // [_hiddenjailbreak addLinkFromPath:nspath toPath:[[NSFileManager defaultManager] stringWithFileSystemRepresentation:buf length:strlen(buf)]];
    }

    return ret;
}

// #pragma unused(hook_dladdr)

// https://book.crifan.org/books/ios_re_jb_detection/website/anti_jb_detect/file/open/c_func/
static DIR *(*orig__opendir2)(const char *filename, int flags);
static DIR *hook_opendir2(const char *filename, int flags) {
    if(filename) {
        NSString *path = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:filename length:strlen(filename)];

        if(isHiddenPath(path)) {
            errno = ENOENT;
            return NULL;
        }
    }

    return orig__opendir2(filename, flags);
}


void manualHooks(){
    MSHookFunction((void *) open, (void *) hook_open, (void **) &orig_open);
    MSHookFunction((void *) openat, (void *) hook_openat, (void **) &orig_openat);
    MSHookFunction((void *) readlink, (void *) hook_readlink, (void **) &orig_readlink);
    MSHookFunction((void *) readlinkat, (void *) hook_readlinkat, (void **) &orig_readlinkat);

    MSHookFunction((void *) __opendir2, (void *) hook_opendir2, (void **) &orig__opendir2);
    // Hook会导致卡死
    // DobbyHook(DobbySymbolResolver(NULL, "opendir"), (void *) hook_opendir, (void **) &orig_opendir);
    MSHookFunction((void *) readdir, (void *) hook_readdir, (void **) &orig_readdir);
}