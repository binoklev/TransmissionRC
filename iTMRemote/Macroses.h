//
//  Macroses.h
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 16.07.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#ifndef iTMRemote_Macroses_h
#define iTMRemote_Macroses_h

#define SINGLETON(classname)							\
\
+ (id)shared##classname									\
{														\
static dispatch_once_t predicate = 0;				\
__strong static id _shared##classname = nil;		\
dispatch_once(&predicate, ^{						\
_shared##classname = [[self alloc] init];		\
});													\
return _shared##classname;							\
}

#ifdef DEBUG
#define DLog( s, ... ) NSLog( @"<%p %@:(%d)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define DLog( s, ... )
#endif

#define USER_DEFAULTS   [NSUserDefaults standardUserDefaults]
#define IDIOM           [[UIDevice currentDevice] userInterfaceIdiom]
#define IPAD            UIUserInterfaceIdiomPad
#define IPHONE          UIUserInterfaceIdiomPhone

#define ROOT_VC_VIEW    [[[[UIApplication sharedApplication] keyWindow] rootViewController] view]
#endif
