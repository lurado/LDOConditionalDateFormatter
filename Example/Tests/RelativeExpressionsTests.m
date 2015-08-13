//
//  RelativeExpressionsTests.m
//  SLConditionalDateFormatter
//
//  Created by Sebastian Ludwig on 31.07.15.
//  Copyright (c) 2015 Sebastian Ludwig. All rights reserved.
//

#import "TestCase.h"

@interface RelativeExpressionsTests : TestCase

@end

@implementation RelativeExpressionsTests

#pragma mark - days ago

- (void)testTwoDaysAgo
{
    self.formatter.defaultFormat = @"R";
    NSString *result = [self expressionFromDate:@"2015-02-22 15:33:50 +0000"
                                toReferenceDate:@"2015-02-24 10:13:39 +0000"];
    XCTAssertEqualObjects(result, @"2 days ago");
}

- (void)testOneDay18HoursAgo
{
    self.formatter.defaultFormat = @"RR";
    
    NSString *result = [self expressionFromDate:@"2015-02-22 15:33:50 +0000"
                                toReferenceDate:@"2015-02-24 10:13:39 +0000"];
    XCTAssertEqualObjects(result, @"1 day 18 hours ago");
}

- (void)testTwoDays3HoursAgo
{
    self.formatter.defaultFormat = @"RR";
    
    NSString *result = [self expressionFromDate:@"2015-02-22 6:33:50 +0000"
                                toReferenceDate:@"2015-02-24 10:13:39 +0000"];
    XCTAssertEqualObjects(result, @"2 days 3 hours ago");
}

#pragma mark - days from now

- (void)testTwoDaysFromNow
{
    self.formatter.defaultFormat = @"R";
    
    NSString *result = [self expressionFromDate:@"2015-02-24 10:13:39 +0000"
                                toReferenceDate:@"2015-02-22 15:33:50 +0000"];
    XCTAssertEqualObjects(result, @"2 days from now");
}

- (void)testOneDay18HoursFromNow
{
    self.formatter.defaultFormat = @"RR";
    
    NSString *result = [self expressionFromDate:@"2015-02-24 10:13:39 +0000"
                                toReferenceDate:@"2015-02-22 15:33:50 +0000"];
    XCTAssertEqualObjects(result, @"1 day 18 hours from now");
}

- (void)testTwoDays3HoursFromNow
{
    self.formatter.defaultFormat = @"RR";
    
    NSString *result = [self expressionFromDate:@"2015-02-24 10:13:39 +0000"
                                toReferenceDate:@"2015-02-22 6:33:50 +0000"];
    XCTAssertEqualObjects(result, @"2 days 3 hours from now");
}

#pragma mark - hours ago

- (void)testNineHoursAgo
{
    self.formatter.defaultFormat = @"R";
    
    NSString *result = [self expressionFromDate:@"2015-02-24 00:33:50 +0000"
                                toReferenceDate:@"2015-02-24 10:13:39 +0000"];
    XCTAssertEqualObjects(result, @"9 hours ago");
}

@end
