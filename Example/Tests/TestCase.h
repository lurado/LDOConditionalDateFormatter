//
//  TestCase.h
//  SLConditionalDateFormatter
//
//  Created by Sebastian Ludwig on 31.07.15.
//  Copyright (c) 2015 Sebastian Ludwig. All rights reserved.
//

@import XCTest;
@import SLConditionalDateFormatter;

@interface TestCase : XCTestCase

@property SLConditionalDateFormatter *formatter;

- (NSString *)expressionFromDate:(NSString *)from toReferenceDate:(NSString *)to;

@end
