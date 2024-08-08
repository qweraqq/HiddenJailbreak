#import <Foundation/Foundation.h>
#import "Core/hidden_path.h"
#import "Core/manual_hook.h"
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

static NSError *_error_file_not_found = nil;

%group hook_NSFileManager
%hook NSFileManager
- (BOOL)fileExistsAtPath:(NSString *)path {
    if(isHiddenPath(path)) {
        return NO;
    }

    return %orig;
}

- (BOOL)fileExistsAtPath:(NSString *)path isDirectory:(BOOL *)isDirectory {
    if(isHiddenPath(path)) {
        return NO;
    }

    return %orig;
}

- (BOOL)isReadableFileAtPath:(NSString *)path {
    if(isHiddenPath(path)) {
        return NO;
    }

    return %orig;
}

- (BOOL)isWritableFileAtPath:(NSString *)path {
    if(isHiddenPath(path)) {
        return NO;
    }

    return %orig;
}

- (BOOL)isDeletableFileAtPath:(NSString *)path {
    if(isHiddenPath(path)) {
        return NO;
    }

    return %orig;
}

- (BOOL)isExecutableFileAtPath:(NSString *)path {
    if(isHiddenPath(path)) {
        return NO;
    }

    return %orig;
}

- (NSURL *)URLForDirectory:(NSSearchPathDirectory)directory inDomain:(NSSearchPathDomainMask)domain appropriateForURL:(NSURL *)url create:(BOOL)shouldCreate error:(NSError * _Nullable *)error {
    if(isHiddenUrl(url)) {
        if(error) {
            *error = _error_file_not_found;
        }

        return nil;
    }

    return %orig;
}

- (NSArray<NSURL *> *)URLsForDirectory:(NSSearchPathDirectory)directory inDomains:(NSSearchPathDomainMask)domainMask {
    NSArray *ret = %orig;

    if(ret) {
        NSMutableArray *toRemove = [NSMutableArray new];
        NSMutableArray *filtered = [ret mutableCopy];

        for(NSURL *url in filtered) {
            if(isHiddenUrl(url)) {
                [toRemove addObject:url];
            }
        }

        [filtered removeObjectsInArray:toRemove];
        ret = [filtered copy];
    }

    return ret;
}

- (BOOL)isUbiquitousItemAtURL:(NSURL *)url {
    if(isHiddenUrl(url)) {
        return NO;
    }

    return %orig;
}

- (BOOL)setUbiquitous:(BOOL)flag itemAtURL:(NSURL *)url destinationURL:(NSURL *)destinationURL error:(NSError * _Nullable *)error {
    if(isHiddenUrl(url)) {
        if(error) {
            *error = _error_file_not_found;
        }

        return NO;
    }

    return %orig;
}

- (BOOL)replaceItemAtURL:(NSURL *)originalItemURL withItemAtURL:(NSURL *)newItemURL backupItemName:(NSString *)backupItemName options:(NSFileManagerItemReplacementOptions)options resultingItemURL:(NSURL * _Nullable *)resultingURL error:(NSError * _Nullable *)error {
    if(isHiddenUrl(originalItemURL) || isHiddenUrl(newItemURL)) {
        if(error) {
            *error = _error_file_not_found;
        }

        return NO;
    }

    return %orig;
}

- (NSArray<NSURL *> *)contentsOfDirectoryAtURL:(NSURL *)url includingPropertiesForKeys:(NSArray<NSURLResourceKey> *)keys options:(NSDirectoryEnumerationOptions)mask error:(NSError * _Nullable *)error {
    if(isHiddenUrl(url)) {
        if(error) {
            *error = _error_file_not_found;
        }

        return nil;
    }

    // Filter array.
    NSMutableArray *filtered_ret = nil;
    NSArray *ret = %orig;

    if(ret) {
        filtered_ret = [NSMutableArray new];

        for(NSURL *ret_url in ret) {
            if(!isHiddenUrl(ret_url)) {
                [filtered_ret addObject:ret_url];
            }
        }
    }

    return ret ? [filtered_ret copy] : ret;
}

- (NSArray<NSString *> *)contentsOfDirectoryAtPath:(NSString *)path error:(NSError * _Nullable *)error {
    if(isHiddenPath(path)) {
        if(error) {
            *error = _error_file_not_found;
        }

        return nil;
    }

    // Filter array.
    NSMutableArray *filtered_ret = nil;
    NSArray *ret = %orig;

    if(ret) {
        filtered_ret = [NSMutableArray new];

        for(NSString *ret_path in ret) {
            // Ensure absolute path for path.
            if(!isHiddenPath([path stringByAppendingPathComponent:ret_path])) {
                [filtered_ret addObject:ret_path];
            }
        }
    }

    return ret ? [filtered_ret copy] : ret;
}

- (NSDirectoryEnumerator<NSURL *> *)enumeratorAtURL:(NSURL *)url includingPropertiesForKeys:(NSArray<NSURLResourceKey> *)keys options:(NSDirectoryEnumerationOptions)mask errorHandler:(BOOL (^)(NSURL *url, NSError *error))handler {
    if(isHiddenUrl(url)) {
        return %orig([NSURL fileURLWithPath:@"/.file"], keys, mask, handler);
    }

    return %orig;
}

- (NSDirectoryEnumerator<NSString *> *)enumeratorAtPath:(NSString *)path {
    if(isHiddenPath(path)) {
        return %orig(@"/.file");
    }

    NSDirectoryEnumerator *ret = %orig;

    // if(ret && enum_path) {
    //     // Store this path.
    //     [enum_path setObject:path forKey:[NSValue valueWithNonretainedObject:ret]];
    // }

    return ret;
}

- (NSArray<NSString *> *)subpathsOfDirectoryAtPath:(NSString *)path error:(NSError * _Nullable *)error {
    if(isHiddenPath(path)) {
        if(error) {
            *error = _error_file_not_found;
        }

        return nil;
    }

    // Filter array.
    NSMutableArray *filtered_ret = nil;
    NSArray *ret = %orig;

    if(ret) {
        filtered_ret = [NSMutableArray new];

        for(NSString *ret_path in ret) {
            // Ensure absolute path for path.
            if(!isHiddenPath([path stringByAppendingPathComponent:ret_path])) {
                [filtered_ret addObject:ret_path];
            }
        }
    }

    return ret ? [filtered_ret copy] : ret;
}

- (NSArray<NSString *> *)subpathsAtPath:(NSString *)path {
    if(isHiddenPath(path)) {
        return nil;
    }

    // Filter array.
    NSMutableArray *filtered_ret = nil;
    NSArray *ret = %orig;

    if(ret) {
        filtered_ret = [NSMutableArray new];

        for(NSString *ret_path in ret) {
            // Ensure absolute path for path.
            if(!isHiddenPath([path stringByAppendingPathComponent:ret_path])) {
                [filtered_ret addObject:ret_path];
            }
        }
    }

    return ret ? [filtered_ret copy] : ret;
}

- (BOOL)copyItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL error:(NSError * _Nullable *)error {
    if(isHiddenUrl(srcURL) || isHiddenUrl(dstURL)) {
        if(error) {
            *error = _error_file_not_found;
        }

        return NO;
    }

    return %orig;
}

- (BOOL)copyItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath error:(NSError * _Nullable *)error {
    if(isHiddenPath(srcPath) || isHiddenPath(dstPath)) {
        if(error) {
            *error = _error_file_not_found;
        }

        return NO;
    }

    return %orig;
}

- (BOOL)moveItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL error:(NSError * _Nullable *)error {
    if(isHiddenUrl(srcURL) || isHiddenUrl(dstURL)) {
        if(error) {
            *error = _error_file_not_found;
        }

        return NO;
    }

    return %orig;
}

- (BOOL)moveItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath error:(NSError * _Nullable *)error {
    if(isHiddenPath(srcPath) || isHiddenPath(dstPath)) {
        if(error) {
            *error = _error_file_not_found;
        }

        return NO;
    }

    return %orig;
}

- (NSArray<NSString *> *)componentsToDisplayForPath:(NSString *)path {
    if(isHiddenPath(path)) {
        return nil;
    }

    return %orig;
}

- (NSString *)displayNameAtPath:(NSString *)path {
    if(isHiddenPath(path)) {
        return path;
    }

    return %orig;
}

- (NSDictionary<NSFileAttributeKey, id> *)attributesOfItemAtPath:(NSString *)path error:(NSError * _Nullable *)error {
    if(isHiddenPath(path)) {
        if(error) {
            *error = _error_file_not_found;
        }

        return nil;
    }

    return %orig;
}

- (NSDictionary<NSFileAttributeKey, id> *)attributesOfFileSystemForPath:(NSString *)path error:(NSError * _Nullable *)error {
    if(isHiddenPath(path)) {
        if(error) {
            *error = _error_file_not_found;
        }

        return nil;
    }

    return %orig;
}

- (BOOL)setAttributes:(NSDictionary<NSFileAttributeKey, id> *)attributes ofItemAtPath:(NSString *)path error:(NSError * _Nullable *)error {
    if(isHiddenPath(path)) {
        if(error) {
            *error = _error_file_not_found;
        }

        return NO;
    }

    return %orig;
}

- (NSData *)contentsAtPath:(NSString *)path {
    if(isHiddenPath(path)) {
        return nil;
    }

    return %orig;
}

- (BOOL)contentsEqualAtPath:(NSString *)path1 andPath:(NSString *)path2 {
    if(isHiddenPath(path1) || isHiddenPath(path2)) {
        return NO;
    }

    return %orig;
}

- (BOOL)getRelationship:(NSURLRelationship *)outRelationship ofDirectoryAtURL:(NSURL *)directoryURL toItemAtURL:(NSURL *)otherURL error:(NSError * _Nullable *)error {
    if(isHiddenUrl(directoryURL) || isHiddenUrl(otherURL)) {
        if(error) {
            *error = _error_file_not_found;
        }

        return NO;
    }

    return %orig;
}

- (BOOL)getRelationship:(NSURLRelationship *)outRelationship ofDirectory:(NSSearchPathDirectory)directory inDomain:(NSSearchPathDomainMask)domainMask toItemAtURL:(NSURL *)otherURL error:(NSError * _Nullable *)error {
    if(isHiddenUrl(otherURL)) {
        if(error) {
            *error = _error_file_not_found;
        }

        return NO;
    }

    return %orig;
}

- (BOOL)changeCurrentDirectoryPath:(NSString *)path {
    if(isHiddenPath(path)) {
        return NO;
    }

    return %orig;
}

- (BOOL)createSymbolicLinkAtURL:(NSURL *)url withDestinationURL:(NSURL *)destURL error:(NSError * _Nullable *)error {
    if(isHiddenUrl(url) || isHiddenUrl(destURL)) {
        if(error) {
            *error = _error_file_not_found;
        }

        return NO;
    }

    BOOL ret = %orig;

    // TODO
    // if(ret) {
    //     // Track this symlink in HiddenJailbreak
    //     [_hiddenjailbreak addLinkFromPath:[url path] toPath:[destURL path]];
    // }

    return ret;
}

- (BOOL)createSymbolicLinkAtPath:(NSString *)path withDestinationPath:(NSString *)destPath error:(NSError * _Nullable *)error {
    if(isHiddenPath(path) || isHiddenPath(destPath)) {
        if(error) {
            *error = _error_file_not_found;
        }

        return NO;
    }

    BOOL ret = %orig;

    // if(ret) {
    //     // Track this symlink in HiddenJailbreak
    //     [_hiddenjailbreak addLinkFromPath:path toPath:destPath];
    // }

    return ret;
}

- (BOOL)linkItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL error:(NSError * _Nullable *)error {
    if(isHiddenUrl(srcURL) || isHiddenUrl(dstURL) ) {
        if(error) {
            *error = _error_file_not_found;
        }

        return NO;
    }

    BOOL ret = %orig;

    // if(ret) {
    //     // Track this symlink in HiddenJailbreak
    //     [_hiddenjailbreak addLinkFromPath:[srcURL path] toPath:[dstURL path]];
    // }

    return ret;
}

- (BOOL)linkItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath error:(NSError * _Nullable *)error {
    if(isHiddenPath(srcPath) || isHiddenPath(dstPath)) {
        if(error) {
            *error = _error_file_not_found;
        }

        return NO;
    }

    BOOL ret = %orig;

    // if(ret) {
    //     // Track this symlink in HiddenJailbreak
    //     [_hiddenjailbreak addLinkFromPath:srcPath toPath:dstPath];
    // }

    return ret;
}

- (NSString *)destinationOfSymbolicLinkAtPath:(NSString *)path error:(NSError * _Nullable *)error {
    if(isHiddenPath(path)) {
        if(error) {
            *error = _error_file_not_found;
        }

        return nil;
    }

    NSString *ret = %orig;

    // if(ret) {
    //     // Track this symlink in HiddenJailbreak
    //     [_hiddenjailbreak addLinkFromPath:path toPath:ret];
    // }

    return ret;
}
%end
%end




%group hook_NSFileHandle
// #include "Hooks/Stable/NSFileHandle.xm"
%hook NSFileHandle
+ (instancetype)fileHandleForReadingAtPath:(NSString *)path {
    if(isHiddenPath(path)) {
        return nil;
    }

    return %orig;
}

+ (instancetype)fileHandleForReadingFromURL:(NSURL *)url error:(NSError * _Nullable *)error {
    if(isHiddenUrl(url)) {
        if(error) {
            *error = _error_file_not_found;
        }

        return nil;
    }

    return %orig;
}

+ (instancetype)fileHandleForWritingAtPath:(NSString *)path {
    if(isHiddenPath(path)) {
        return nil;
    }

    return %orig;
}

+ (instancetype)fileHandleForWritingToURL:(NSURL *)url error:(NSError * _Nullable *)error {
    if(isHiddenUrl(url)) {
        if(error) {
            *error = _error_file_not_found;
        }

        return nil;
    }

    return %orig;
}

+ (instancetype)fileHandleForUpdatingAtPath:(NSString *)path {
    if(isHiddenPath(path)) {
        return nil;
    }

    return %orig;
}

+ (instancetype)fileHandleForUpdatingURL:(NSURL *)url error:(NSError * _Nullable *)error {
    if(isHiddenUrl(url)) {
        if(error) {
            *error = _error_file_not_found;
        }

        return nil;
    }

    return %orig;
}
%end
%end


// Stable Hooks
%group hook_libc
%hookf(int, access, const char *pathname, int mode) {
    if(pathname) {
        NSString *path = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:pathname length:strlen(pathname)];

        if(isHiddenPath(path)) {
            errno = ENOENT;
            return -1;
        }
    }

    return %orig;
}

%hookf(char *, getenv, const char *name) {
    if(name) {
        NSString *env = [NSString stringWithUTF8String:name];

        if([env isEqualToString:@"DYLD_INSERT_LIBRARIES"]
        || [env isEqualToString:@"_MSSafeMode"]
        || [env isEqualToString:@"_SafeMode"]) {
            return NULL;
        }
    }

    return %orig;
}

%hookf(FILE *, fopen, const char *pathname, const char *mode) {
    if(pathname) {
        NSString *path = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:pathname length:strlen(pathname)];
        
        if(isHiddenPath(path)) {
            errno = ENOENT;
            return NULL;
        }
    }

    return %orig;
}

%hookf(FILE *, freopen, const char *pathname, const char *mode, FILE *stream) {
    if(pathname) {
        NSString *path = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:pathname length:strlen(pathname)];

        if(isHiddenPath(path)) {
            fclose(stream);
            errno = ENOENT;
            return NULL;
        }
    }

    return %orig;
}

%hookf(int, stat, const char *pathname, struct stat *statbuf) {
    if(pathname) {
        NSString *path = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:pathname length:strlen(pathname)];

        if(isHiddenPath(path)) {
            errno = ENOENT;
            return -1;
        }
    }

    return %orig;
}

%hookf(int, lstat, const char *pathname, struct stat *statbuf) {
    if(pathname) {
        NSString *path = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:pathname length:strlen(pathname)];

        if(isHiddenPath(path)) {
            errno = ENOENT;
            return -1;
        }

    }

    return %orig;
}

%hookf(int, fstatfs, int fd, struct statfs *buf) {
    int ret = %orig;

    if(ret == 0) {
        // Get path of dirfd.
        char path[PATH_MAX];

        if(fcntl(fd, F_GETPATH, path) != -1) {
            NSString *pathname = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:path length:strlen(path)];

            if(isHiddenPath(pathname)) {
                errno = ENOENT;
                return -1;
            }
        }
    }

    return ret;
}

%hookf(int, statfs, const char *path, struct statfs *buf) {
    int ret = %orig;

    if(ret == 0) {
        NSString *pathname = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:path length:strlen(path)];

        if(isHiddenPath(pathname)) {
            errno = ENOENT;
            return -1;
        }

    }

    return ret;
}


%hookf(int, fstatat, int dirfd, const char *pathname, struct stat *buf, int flags) {
    if(pathname) {
        NSString *path = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:pathname length:strlen(pathname)];

        if(![path isAbsolutePath]) {
            // Get path of dirfd.
            char dirfdpath[PATH_MAX];
        
            if(fcntl(dirfd, F_GETPATH, dirfdpath) != -1) {
                NSString *dirfd_path = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:dirfdpath length:strlen(dirfdpath)];
                path = [dirfd_path stringByAppendingPathComponent:path];
            }
        }
        
        if(isHiddenPath(path)) {
            errno = ENOENT;
            return -1;
        }
    }

    return %orig;
}

%hookf(int, faccessat, int dirfd, const char *pathname, int mode, int flags) {
    if(pathname) {
        NSString *path = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:pathname length:strlen(pathname)];

        if(![path isAbsolutePath]) {
            // Get path of dirfd.
            char dirfdpath[PATH_MAX];
        
            if(fcntl(dirfd, F_GETPATH, dirfdpath) != -1) {
                NSString *dirfd_path = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:dirfdpath length:strlen(dirfdpath)];
                path = [dirfd_path stringByAppendingPathComponent:path];
            }
        }
        
        if(isHiddenPath(path)) {
            errno = ENOENT;
            return -1;
        }
    }

    return %orig;
}

%end




%ctor {
    initHiddenPath();
    _error_file_not_found = generateFileNotFoundError();
    NSString *processName = [[NSProcessInfo processInfo] processName];
    if([processName isEqualToString:@"SpringBoard"]) {
        return;
    }
    NSBundle *bundle = [NSBundle mainBundle];
    if(bundle != nil) {
        NSString *executablePath = [bundle executablePath];
        NSString *bundleIdentifier = [bundle bundleIdentifier];
        
        // User (Sandboxed) Applications
        if([executablePath hasPrefix:@"/var/containers/Bundle/Application"]
        || [executablePath hasPrefix:@"/private/var/containers/Bundle/Application"]
        || [executablePath hasPrefix:@"/var/mobile/Containers/Bundle/Application"]
        || [executablePath hasPrefix:@"/private/var/mobile/Containers/Bundle/Application"]) {
            NSLog(@"[jb-bypass] bundleIdentifier: %@", bundleIdentifier);
            %init(hook_libc);
            %init(hook_NSFileHandle);
            %init(hook_NSFileManager);

            manualHooks();
        }
    }
}