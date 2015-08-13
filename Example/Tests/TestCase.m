//
//  TestCase.m
//  SLConditionalDateFormatter
//
//  Created by Sebastian Ludwig on 31.07.15.
//  Copyright (c) 2015 Sebastian Ludwig. All rights reserved.
//

#import "TestCase.h"

@implementation TestCase

- (void)setUp
{
    [super setUp];
    self.formatter = [SLConditionalDateFormatter new];
    self.formatter.calendar.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
}

- (NSString *)expressionFromDate:(NSString *)from toReferenceDate:(NSString *)reference
{
    NSDateFormatter *parser = [[NSDateFormatter alloc] init];
    parser.dateFormat = @"yyyy-MM-dd HH:mm:ss Z";
    
    NSDate *referenceDate = [parser dateFromString:reference];
    NSDate *date = [parser dateFromString:from];
    
    return [self.formatter stringForTimeIntervalFromDate:date toReferenceDate:referenceDate];
}

@end
