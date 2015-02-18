//
//  iTMRemoteTests.m
//  iTMRemoteTests
//
//  Created by Igor Dvoeglazov on 16.07.14.
//  Copyright (c) 2014 Binoklev Studio. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TRTorrentParser.h"

@interface iTMRemoteTests : XCTestCase

@end

@implementation iTMRemoteTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

//- (void)testExample
//{
//    XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
//}

- (void)testTorrentParsing {
    // load file from resources
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"test" ofType:@"torrent"];
    XCTAssertNotNil(path, @"Path to file test.torrent doesn't exists!");
    XCTAssert( [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:NO], "File test.torrent not found!!!");

    NSData *data = [NSData dataWithContentsOfFile:path];
    XCTAssertNotNil(data, @"file %@ doesn't content torrent!", path);
    
    TRTorrentParser *parser = [[TRTorrentParser alloc] init];
    NSDictionary *dic = [parser parseBuffer:data];
    XCTAssertNotNil(dic, @"file %@ wasn't parsed!", path);
    XCTAssert([dic count] > 0, @"Parser returned empty dictionary!");
}

- (void)testTorrentWithNonUTF8Parsing {
    // load file from resources
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"test2" ofType:@"torrent"];
    XCTAssertNotNil(path, @"Path to file test.torrent doesn't exists!");
    XCTAssert( [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:NO], "File test.torrent not found!!!");
    
    NSData *data = [NSData dataWithContentsOfFile:path];
    XCTAssertNotNil(data, @"file %@ doesn't content torrent!", path);
    
    TRTorrentParser *parser = [[TRTorrentParser alloc] init];
    NSDictionary *dic = [parser parseBuffer:data];
    XCTAssertNotNil(dic, @"file %@ wasn't parsed!", path);
    XCTAssert([dic count] > 0, @"Parser returned empty dictionary!");
}

- (void)testWrongTorrent {
    // load file from resources
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"wrong" ofType:@"torrent"];
    XCTAssertNotNil(path, @"Path to file wrong.torrent doesn't exists!");
    XCTAssert( [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:NO], "File wrong.torrent not found!!!");
    
    NSData *data = [NSData dataWithContentsOfFile:path];
    XCTAssertNotNil(data, @"file %@ doesn't content torrent!", path);
    
    TRTorrentParser *parser = [[TRTorrentParser alloc] init];
    NSDictionary *dic = [parser parseBuffer:data];
    XCTAssertNil(dic, @"Wrong file %@ parsed and return dictionary!", path);
}

@end
