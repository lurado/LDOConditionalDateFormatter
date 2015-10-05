//
//  FormatTests.m
//  LDOConditionalDateFormatterTests
//
//  Created by Sebastian Ludwig on 31.07.15.
//  Copyright (c) 2015 Julian Raschke und Sebastian Ludwig GbR. All rights reserved.
//

#import "TestCase.h"

static inline NSComparisonResult NSCalendarUnitCompareSignificance(NSCalendarUnit a, NSCalendarUnit b)
{
    if ((a == NSCalendarUnitWeekOfYear) ^ (b == NSCalendarUnitWeekOfYear)) {
        if (b == NSCalendarUnitWeekOfYear) {
            switch (a) {
                case NSCalendarUnitYear:
                case NSCalendarUnitMonth:
                    return NSOrderedDescending;
                default:
                    return NSOrderedAscending;
            }
        } else {
            switch (b) {
                case NSCalendarUnitYear:
                case NSCalendarUnitMonth:
                    return NSOrderedAscending;
                default:
                    return NSOrderedDescending;
            }
        }
    } else {
        if (a > b) {
            return NSOrderedAscending;
        } else if (a < b) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }
}

@interface FormatTests : TestCase

@end

@implementation FormatTests

- (void)testNSCalendarUnitCompareSignificance {
    NSCalendarUnit units[] = {NSCalendarUnitSecond, NSCalendarUnitMinute, NSCalendarUnitHour, NSCalendarUnitDay, NSCalendarUnitWeekOfYear, NSCalendarUnitMonth, NSCalendarUnitYear};
    
    for (int o = 0; o < 7; ++o) {
        NSCalendarUnit baseUnit = units[o];
        NSComparisonResult expected = NSOrderedDescending;
        for (int i = 0; i < 7; ++i) {
            if (units[i] == baseUnit) {
                XCTAssertEqual(NSCalendarUnitCompareSignificance(baseUnit, units[i]), NSOrderedSame);
                expected = NSOrderedAscending;
            } else if (NSCalendarUnitCompareSignificance(baseUnit, units[i]) != expected) {
                XCTFail(@"mismatch");
            }
        }
    }
}

- (void)testHandlesNilDefault {
    self.formatter.defaultFormat = nil;
    
    NSString *result = [self expressionFromDate:@"2015-02-23 20:33:50 +0000"
                                toReferenceDate:@"2015-02-24 10:13:39 +0000"];
    XCTAssertEqual(result, nil);
}

#pragma mark Formats I and R

- (void)testUsesDefaultFormat
{
    self.formatter.defaultFormat = @"R";
    NSString *result = [self expressionFromDate:@"2015-02-23 20:33:50 +0000"
                                toReferenceDate:@"2015-02-24 10:13:39 +0000"];
    XCTAssertEqualObjects(result, @"1 day ago");
}

- (void)testIdiomaticExpressionsFormat
{
    self.formatter.defaultFormat = @"I";
    NSString *result = [self expressionFromDate:@"2015-02-23 20:33:50 +0000"
                                toReferenceDate:@"2015-02-24 10:13:39 +0000"];
    XCTAssertEqualObjects(result, @"yesterday");
}

- (void)testSignificantUnitsForRelativeFormat
{
    self.formatter.defaultFormat = @"RR";
    
    NSString *result = [self expressionFromDate:@"2015-02-22 6:33:50 +0000" toReferenceDate:@"2015-02-24 10:13:39 +0000"];
    XCTAssertEqualObjects(result, @"2 days 3 hours ago");
}

- (void)testApproximateQualifier {
    self.formatter.defaultFormat = @"~R";
    
    NSString *result = [self expressionFromDate:@"2015-02-24 6:33:50 +0000" toReferenceDate:@"2015-02-24 10:13:39 +0000"];
    XCTAssertEqualObjects(result, @"about 3 hours ago");
}

- (void)testOmitsApproximateQualifier {
    self.formatter.defaultFormat = @"~R";
    
    NSString *result = [self expressionFromDate:@"2015-02-24 6:33:50 +0000" toReferenceDate:@"2015-02-24 9:33:50 +0000"];
    XCTAssertEqualObjects(result, @"3 hours ago");
}

- (void)testOnlyChangesTemplateCharacters
{
    self.formatter.defaultFormat = @"I, yo";
    NSString *result = [self expressionFromDate:@"2015-02-23 20:33:50 +0000"
                                toReferenceDate:@"2015-02-24 10:13:39 +0000"];
    XCTAssertEqualObjects(result, @"yesterday, yo");
}

- (void)testReplacesMultipleTemplates
{
    self.formatter.defaultFormat = @"I / R";
    NSString *result = [self expressionFromDate:@"2015-02-23 20:33:50 +0000"
                                toReferenceDate:@"2015-02-24 10:13:39 +0000"];
    XCTAssertEqualObjects(result, @"yesterday / 1 day ago");
}

- (void)testMultipleTemplateInvariance
{
    self.formatter.defaultFormat = @"R / I";   // opposite order as previous test
    NSString *result = [self expressionFromDate:@"2015-02-23 20:33:50 +0000"
                                toReferenceDate:@"2015-02-24 10:13:39 +0000"];
    XCTAssertEqualObjects(result, @"1 day ago / yesterday");
}

- (void)testRelativeRepetition
{
    self.formatter.defaultFormat = @"R - R";
    NSString *result = [self expressionFromDate:@"2015-02-23 20:33:50 +0000"
                                toReferenceDate:@"2015-02-24 10:13:39 +0000"];
    XCTAssertEqualObjects(result, @"1 day ago - 1 day ago");
}

- (void)testIdiomaticRepetition
{
    self.formatter.defaultFormat = @"I - I";
    NSString *result = [self expressionFromDate:@"2015-02-23 20:33:50 +0000"
                                toReferenceDate:@"2015-02-24 10:13:39 +0000"];
    XCTAssertEqualObjects(result, @"yesterday - yesterday");
}

#pragma mark Precedence

- (void)testAppliesAddedFormatFirst
{
    self.formatter.defaultFormat = @"I";
    [self.formatter addFormat:@"R" forTimeInterval:(-4 DAYS)];
    NSString *result = [self.formatter stringForTimeInterval:(-1 DAYS)];
    XCTAssertEqualObjects(result, @"1 day ago");
}

- (void)testChecksTimeIntervalForFormat
{
    self.formatter.defaultFormat = @"I";
    [self.formatter addFormat:@"R" forTimeInterval:(-3 HOURS)];
    NSString *result = [self.formatter stringForTimeInterval:(-1 DAYS)];
    XCTAssertEqualObjects(result, @"yesterday");
}

- (void)testAppliesFormatsInOrder
{
    [self.formatter addFormat:@"R" forTimeInterval:(-4 DAYS)];
    [self.formatter addFormat:@"RR" forTimeInterval:(-4 DAYS)];
    
    NSString *result = [self expressionFromDate:@"2015-02-22 6:33:50 +0000" toReferenceDate:@"2015-02-24 10:13:39 +0000"];
    XCTAssertEqualObjects(result, @"2 days ago");
}

#pragma mark Logical intervals

- (void)testFormatForToday
{
    [self.formatter addFormat:@"R" for:LDOTimeUnitToday];
    NSString *result = [self.formatter stringForTimeInterval:(-3 HOURS)];
    XCTAssertEqualObjects(result, @"3 hours ago");
}

- (void)testFormatForYesterday
{
    [self.formatter addFormat:@"R" for:LDOTimeUnitToday];
    [self.formatter addFormat:@"I" for:LDOTimeUnitYesterday];
    NSString *result = [self.formatter stringForTimeInterval:(-1 DAY)];
    XCTAssertEqualObjects(result, @"yesterday");
}

- (void)testFormatForLastTwoWeeks {
    [self.formatter addFormat:@"R" forLast:3 unit:LDOTimeUnitWeeks];
    NSString *result = [self.formatter stringForTimeInterval:(-2 WEEKS)];
    XCTAssertEqualObjects(result, @"2 weeks ago");
}

- (void)testFormatForNextTwoWeeks {
    [self.formatter addFormat:@"I" forLast:2 unit:LDOTimeUnitWeeks];
    [self.formatter addFormat:@"R" forNext:2 unit:LDOTimeUnitWeeks];
    NSString *result = [self.formatter stringForTimeInterval:(2 WEEKS)];
    XCTAssertEqualObjects(result, @"2 weeks from now");
}

#pragma mark - Regular formatting

- (void)testReplacesTimePattern {
    self.formatter.defaultFormat = @"{HH:mm}";
    NSString *result = [self.formatter stringForTimeIntervalFromDate:[self parseDate:@"2015-02-22 06:33:50 +0000"]];
    XCTAssertEqualObjects(result, @"06:33");
}

- (void)testSubstitutesTemplate {
    self.formatter.defaultFormat = @"{hm}";
    NSString *result = [self.formatter stringForTimeIntervalFromDate:[self parseDate:@"2015-02-22 16:33:50 +0000"]];
    XCTAssertEqualObjects(result, @"4:33 PM");
}

- (void)testMultipleTimeFormatOccurances {
    self.formatter.defaultFormat = @"{yyyy-MM-dd} at {HH:mm}";
    NSString *result = [self.formatter stringForTimeIntervalFromDate:[self parseDate:@"2015-02-22 16:33:50 +0000"]];
    XCTAssertEqualObjects(result, @"2015-02-22 at 16:33");
}

- (void)testMultipleTemplateOccurances {
    self.formatter.defaultFormat = @"{yMd} at {Hm}";
    NSString *result = [self.formatter stringForTimeIntervalFromDate:[self parseDate:@"2015-02-22 16:33:50 +0000"]];
    XCTAssertEqualObjects(result, @"2/22/2015 at 16:33");
}

@end
