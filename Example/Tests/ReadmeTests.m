//
//  ReadmeTests.m
//  LDOConditionalDateFormatter
//
//  Created by Sebastian Ludwig on 20.08.15.
//  Copyright (c) 2015 Sebastian Ludwig. All rights reserved.
//

#import "TestCase.h"

@interface ReadmeTests : TestCase

@end

@implementation ReadmeTests

- (void)testShortDescription
{
    [self.formatter addFormat:@"I R" for:LDOTimeUnitToday];
    [self.formatter addFormat:@"I at {h}" for:LDOTimeUnitYesterday];

    NSDate *now = [self parseDate:@"2015-02-24 10:10:39 +0000"];
    NSDate *twoHoursAgo = [self parseDate:@"2015-02-24 08:00:00 +0000"];
    NSDate *yesterdayAt4pm = [self parseDate:@"2015-02-23 16:20:00 +0000"];
    
    NSString *result = [self.formatter stringForTimeIntervalFromDate:twoHoursAgo toReferenceDate:now];
    XCTAssertEqualObjects(result, @"today 2 hours ago");
    result = [self.formatter stringForTimeIntervalFromDate:yesterdayAt4pm toReferenceDate:now];
    XCTAssertEqualObjects(result, @"yesterday at 4 PM");
}

- (void)testQuickStart
{
    NSDate *now = [self parseDate:@"2015-02-24 16:52:39 +0000"];
    NSDate *minutesAgo = [self parseDate:@"2015-02-24 16:10:39 +0000"];
    NSDate *earlierToday = [self parseDate:@"2015-02-24 13:37:00 +0000"];
    NSDate *yesterday = [self parseDate:@"2015-02-23 10:37:00 +0000"];
    NSDate *threeDaysAgo = [self parseDate:@"2015-02-21 15:55:00 +0000"];
    NSDate *longAgo = [self parseDate:@"2015-02-11 15:55:00 +0000"];
    
    LDOConditionalDateFormatter *formatter = self.formatter;
    NSString *result;
    
    [formatter addFormat:@"R" forTimeInterval:-3600];
    [formatter addFormat:@"{HH:mm}" for:LDOTimeUnitToday];
    [formatter addFormat:@"I" for:LDOTimeUnitYesterday];
    [formatter addFormat:@"R" forLast:7 unit:LDOTimeUnitDays];
    formatter.defaultFormat = @"{yMd}";
    
    result = [self.formatter stringForTimeIntervalFromDate:minutesAgo toReferenceDate:now];     // 42 minutes ago
    XCTAssertEqualObjects(result, @"42 minutes ago");
    result = [self.formatter stringForTimeIntervalFromDate:earlierToday toReferenceDate:now];   // 13:37
    XCTAssertEqualObjects(result, @"13:37");
    result = [self.formatter stringForTimeIntervalFromDate:yesterday toReferenceDate:now];      // yesterday
    XCTAssertEqualObjects(result, @"yesterday");
    result = [self.formatter stringForTimeIntervalFromDate:threeDaysAgo toReferenceDate:now];   // 3 days ago
    XCTAssertEqualObjects(result, @"3 days ago");
    result = [self.formatter stringForTimeIntervalFromDate:longAgo toReferenceDate:now];        // 2/11/2015
    XCTAssertEqualObjects(result, @"2/11/2015");
}

@end
