//
//  TestCase.h
//  SLConditionalDateFormatter
//
//  Created by Sebastian Ludwig on 31.07.15.
//  Copyright (c) 2015 Sebastian Ludwig. All rights reserved.
//

#define HOURS * 60 * 60
#define DAY * 24 * 60 * 60
#define DAYS * 24 * 60 * 60
#define WEEKS * 7 * 24 * 60 * 60

@import XCTest;
#include <SLConditionalDateFormatter.h>

@interface TestCase : XCTestCase

@property SLConditionalDateFormatter *formatter;

- (NSDate *)parseDate:(NSString *)string;
- (NSString *)expressionFromDate:(NSString *)from toReferenceDate:(NSString *)to;

@end
