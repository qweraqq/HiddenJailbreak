#import <Foundation/Foundation.h>

extern NSArray *hidePathList;

void initHiddenPath();

bool isHiddenPath(NSString* p);

bool isHiddenUrl(NSURL *url);

NSError * generateFileNotFoundError() ;