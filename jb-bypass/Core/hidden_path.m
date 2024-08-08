#import "hidden_path.h"
// #import <rootless.h>

NSArray * hidePathList;
void initHiddenPath() {
  hidePathList = [[NSArray alloc]
      initWithObjects:@"/usr/lib/sandbox.plist", @"/usr/lib/systemhook.dylib",
                      @"/var/jb/basebin/.fakelib/sandbox.plist",
                      @"/var/jb/basebin/.fakelib/systemhook.dylib",
                      @"/var/jb/basebin/.fakelib", @"/var/jb/basebin",
                      @"/var/jb/bin/",
                      @"/var/jb/bin/bash", @"/var/jb/bin", @"/var/jb",
                      @"/var/lib/filza/sconf.plist", @"/var/lib/filza",
                      @"/var/lib", @"/Applications/Cydia.app",
                      @"/var/mobile/Library/Caches/org.coolstar.SileoStore",
                      @"/var/mobile/Library/Caches/ws.hbang.Terminal",
                      @"/var/mobile/Library/Caches/xyz.willy.Zebra",
                      @"/var/mobile/Library/Filza",
                      @"/var/mobile/Library/Sileo/sileo.sqlite3",
                      @"/var/mobile/Library/Sileo",
                      @"/var/mobile/Library/WebKit/org.coolstar.SileoStore",
                      @"/var/mobile/Library/WebKit/xyz.willy.Zebra", nil];
  // TODO: read from plist
}


bool isHiddenPath(NSString* p){
  if ([hidePathList containsObject:p]){
    NSLog(@"[jb-bypass] path: %@", p);
    return true;
  }

  for(NSString* pp in hidePathList) {
    if([p hasPrefix:pp]){
      NSLog(@"[jb-bypass] path: %@", p);
      return true;
    }
  }

  return false;
}


bool isHiddenUrl(NSURL *url){
    if(!url) {
        return false;
    }

    // Package manager URL scheme checks
    if([[url scheme] isEqualToString:@"cydia"]
    || [[url scheme] isEqualToString:@"sileo"]
    || [[url scheme] isEqualToString:@"zbra"]) {
      NSLog(@"[jb-bypass] url: %@", url);
      return true;
    }

        // File URL checks
    if([url isFileURL]) {
        NSString *path = [url path];

        // Handle File Reference URLs
        if([url isFileReferenceURL]) {
            NSURL *surl = [url standardizedURL];

            if(surl) {
                path = [surl path];
            }
        }
        if (isHiddenPath(path)){
            NSLog(@"[jb-bypass] url: %@", url);
            return true;
        } 
    }

    // URL set checks
    // if([url_set containsObject:[url scheme]]) {
    //     return YES;
    // }

    return false;
}


NSError * generateFileNotFoundError() {
    NSDictionary *userInfo = @{
        NSLocalizedDescriptionKey: NSLocalizedString(@"Operation was unsuccessful.", nil),
        NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Object does not exist.", nil),
        NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Don't access this again :)", nil)
    };

    NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:userInfo];
    return error;
}