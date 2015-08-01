//
//  FormatTests.m
//  SLConditionalDateFormatterTests
//
//  Created by Sebastian Ludwig on 31.07.15.
//  Copyright (c) 2015 Sebastian Ludwig. All rights reserved.
//

#import "TestCase.h"

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

- (void)testUsesDefaultFormat
{
    self.formatter.defaultFormat = @"R";
    NSString *result = [self expressionFromDate:@"2015-02-24 10:13:39 +0000"
                                         toDate:@"2015-02-23 20:33:50 +0000"];
    XCTAssertEqualObjects(result, @"1 day ago");
}

- (void)testIdiomaticExpressionsFormat
{
    self.formatter.defaultFormat = @"I";
    NSString *result = [self expressionFromDate:@"2015-02-24 10:13:39 +0000"
                                         toDate:@"2015-02-23 20:33:50 +0000"];
    XCTAssertEqualObjects(result, @"yesterday");
}

- (void)testSignificantUnitsForRelativeFormat
{
    self.formatter.defaultFormat = @"RR";
    
    NSString *result = [self expressionFromDate:@"2015-02-24 10:13:39 +0000" toDate:@"2015-02-22 6:33:50 +0000"];
    XCTAssertEqualObjects(result, @"2 days 3 hours ago");
}

- (void)testOnlyChangesTemplateCharacters
{
    self.formatter.defaultFormat = @"I, yo";
    NSString *result = [self expressionFromDate:@"2015-02-24 10:13:39 +0000"
                                         toDate:@"2015-02-23 20:33:50 +0000"];
    XCTAssertEqualObjects(result, @"yesterday, yo");
}

- (void)testAppliesAddedFormatFirst
{
    self.formatter.defaultFormat = @"I";
    [self.formatter addFormat:@"R" forTimeInterval:(-4 * 24 * 60 * 60)];
    NSString *result = [self.formatter stringForTimeInterval:(-1 * 24 * 60 * 60)];
    XCTAssertEqualObjects(result, @"1 day ago");
}

- (void)testChecksTimeIntervalForFormat
{
    // expected fallback to defaultForamt
}

@end
