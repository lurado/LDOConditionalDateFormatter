//
//  FormatTests.m
//  SLConditionalDateFormatterTests
//
//  Created by Sebastian Ludwig on 31.07.15.
//  Copyright (c) 2015 Sebastian Ludwig. All rights reserved.
//

#import "TestCase.h"

#define HOURS * 60 * 60
#define DAY * 24 * 60 * 60
#define DAYS * 24 * 60 * 60
#define WEEKS * 7 * 24 * 60 * 60

@interface FormatTests : TestCase

@end

@implementation FormatTests

- (void)setUp {
    [super setUp];
}

- (void)testRules
{
    //    [formatter addFormat:@"R" forTimeInterval:(-2 * 60 * 60)];    // 1 hour ago
    //    [formatter addFormat:@"RR" forTimeInterval:(-2 * 60 * 60 * 24)];    // 1 day 2 hours ago
    //    [formatter addFormat:@"~R" forTimeInterval:(-2 * 60 * 60)];    // about 1 hour ago
    //    [formatter addFormat:@"HH:mm" for:Today];
    //    [formatter addFormat:@"R at {HH:mm}" for:Yesterday];
    //    [formatter addFormat:@"HH:mm" for:Today];
    //    [formatter addFormat:@"R at {HH:mm}" for:Yesterday];
    //    [formatter addFormat:@"I" forLast:2 unit:Weeks];
    //    [formatter addFormat:@"R" forNext:2 unit:Days];
    
    //    [formatter addFormat:@"HH:mm" for:SLRealtiveDateToday];
    //    [formatter addFormat:@"R at {HH:mm}" for:SLRealtiveDateYesterday];
    //    [formatter addFormat:@"R" forLast:2 unit:SLRealtiveDateWeeks];
    //    [formatter addFormat:@"R" forNext:2 unit:SLRealtiveDateDays];
    
    
    //    [formatter addFormat:@"HH:mm" for:SLTimeUnitToday];
    //    [formatter addFormat:@"R at {HH:mm}" for:SLTimeUnitYesterday];
    //    [formatter addFormat:@"R" forLast:2 unit:SLTimeUnitWeeks];
    //    [formatter addFormat:@"R" forNext:2 unit:SLTimeUnitDays];
    
    //    formatter.defaultFormat:@"{yyyy-MM-dd} at {HH:mm}";
    // {<anything with only template characters will be passed to dateFormatFromTemplate>}
    
    // Days
    // Weeks
    // Months
    // Years
    
    // Today        // TODO: allow "I" only for the following?
    // Yesterday
    // Tomorrow
    
    // ThisWeek
    // LastWeek
    // NextWeek
    
    // ThisMonth
    // LastMonth
    // NextMonth
    
    // ThisYear
    // LastYear
    // NextYear
    
    // TODO: should default "I" fall back to "R"?
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
    XCTAssertEqualObjects(result, @"yesterday / 13 hours 39 minutes ago");
}

- (void)testMultipleTemplateInvariance {
    self.formatter.defaultFormat = @"R / I";   // opposite order as previous test
    NSString *result = [self expressionFromDate:@"2015-02-23 20:33:50 +0000"
                                toReferenceDate:@"2015-02-24 10:13:39 +0000"];
    XCTAssertEqualObjects(result, @"13 hours 39 minutes ago / yesterday");
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
    [self.formatter addFormat:@"R" for:SLTimeUnitToday];
    NSString *result = [self.formatter stringForTimeInterval:(-3 HOURS)];
    XCTAssertEqualObjects(result, @"3 hours ago");
}

- (void)testFormatForYesterday
{
    [self.formatter addFormat:@"R" for:SLTimeUnitToday];
    [self.formatter addFormat:@"I" for:SLTimeUnitYesterday];
    NSString *result = [self.formatter stringForTimeInterval:(-1 DAY)];
    XCTAssertEqualObjects(result, @"yesterday");
}

- (void)testFormatForLastTwoWeeks {
    [self.formatter addFormat:@"R" forLast:2 unit:SLTimeUnitWeeks];
    NSString *result = [self.formatter stringForTimeInterval:(-2 WEEKS)];
    XCTAssertEqualObjects(result, @"2 weeks ago");
}

- (void)testFormatForNextTwoWeeks {
    [self.formatter addFormat:@"I" forLast:2 unit:SLTimeUnitWeeks];
    [self.formatter addFormat:@"R" forNext:2 unit:SLTimeUnitWeeks];
    NSString *result = [self.formatter stringForTimeInterval:(2 WEEKS)];
    XCTAssertEqualObjects(result, @"2 weeks from now");
}

#pragma mark - Regular formatting

- (void)testReplacesTimePattern {
    self.formatter.defaultFormat = @"{HH:mm}";
    NSString *result = [self expressionFromDate:@"2015-02-22 6:33:50 +0000" toReferenceDate:@"2015-02-22 10:13:39 +0000"];
    XCTAssertEqualObjects(result, @"06:33");
}

- (void)testSubstitutesTemplate {
//    [formatter addFormat:@"{Hm}" for:SLTimeUnitToday];
}

- (void)testDoesNotSubstituteTemplateWithNonPatternCharacter {
//    [formatter addFormat:@"{p}" for:SLTimeUnitToday];
}

//    [formatter addFormat:@"HH:mm" for:SLTimeUnitToday];
//    [formatter addFormat:@"R at {HH:mm}" for:SLTimeUnitYesterday];
//    [formatter addFormat:@"R" forLast:2 unit:SLTimeUnitWeeks];
//    [formatter addFormat:@"R" forNext:2 unit:SLTimeUnitDays];

@end
