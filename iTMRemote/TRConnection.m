//
//  TRConnection.m
//  iTMRemote
//
//  Created by Igor Dvoeglazov on 17.07.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#import "TRConnection.h"

@implementation TRConnection

- (void)dealloc {
    self.data = nil;
}

- (NSString*)description  {
    return [NSString stringWithFormat:@"TRConnection %@ with tag %d", [super description], self.tag];
}

@end
