//
//  ReadmeTests.m
//  SLConditionalDateFormatter
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
    [self.formatter addFormat:@"I R" for:SLTimeUnitToday];
    [self.formatter addFormat:@"I at {h}" for:SLTimeUnitYesterday];

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
    
    [self.formatter addFormat:@"R" forTimeInterval:-3600];
    [self.formatter addFormat:@"{HH:mm}" for:SLTimeUnitToday];
    [self.formatter addFormat:@"I" for:SLTimeUnitYesterday];
    [self.formatter addFormat:@"R" forLast:7 unit:SLTimeUnitDays];
    self.formatter.defaultFormat = @"{yMd}";
    
    NSString *result = [self.formatter stringForTimeIntervalFromDate:minutesAgo toReferenceDate:now];
    XCTAssertEqualObjects(result, @"42 minutes ago");
    result = [self.formatter stringForTimeIntervalFromDate:earlierToday toReferenceDate:now];
    XCTAssertEqualObjects(result, @"13:37");
    result = [self.formatter stringForTimeIntervalFromDate:yesterday toReferenceDate:now];
    XCTAssertEqualObjects(result, @"yesterday");
    result = [self.formatter stringForTimeIntervalFromDate:threeDaysAgo toReferenceDate:now];
    XCTAssertEqualObjects(result, @"3 days ago");
    result = [self.formatter stringForTimeIntervalFromDate:longAgo toReferenceDate:now];
    XCTAssertEqualObjects(result, @"2/11/2015");
}

@end
