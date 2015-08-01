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

- (NSString *)expressionFromDate:(NSString *)from toDate:(NSString *)to
{
    NSDateFormatter *parser = [[NSDateFormatter alloc] init];
    parser.dateFormat = @"yyyy-MM-dd HH:mm:ss Z";
    
    NSDate *fromDate = [parser dateFromString:from];
    NSDate *toDate = [parser dateFromString:to];
    
    return [self.formatter stringForTimeIntervalFromDate:fromDate toDate:toDate];
}

@end
