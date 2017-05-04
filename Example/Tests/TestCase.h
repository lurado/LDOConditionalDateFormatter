//
//  TestCase.h
//  LDOConditionalDateFormatter
//
//  Created by Sebastian Ludwig on 31.07.15.
//  Copyright (c) 2015 Julian Raschke und Sebastian Ludwig GbR. All rights reserved.
//

#define HOURS * 60 * 60
#define DAY * 24 * 60 * 60
#define DAYS * 24 * 60 * 60
#define WEEKS * 7 * 24 * 60 * 60

@import XCTest;
@import LDOConditionalDateFormatter;

@interface TestCase : XCTestCase

@property LDOConditionalDateFormatter *formatter;

- (NSDate *)parseDate:(NSString *)string;
- (NSString *)expressionFromDate:(NSString *)from toReferenceDate:(NSString *)to;

@end
