//
//  TestCase.m
//  SLConditionalDateFormatter
//
//  Created by Sebastian Ludwig on 31.07.15.
//  Copyright (c) 2015 Sebastian Ludwig. All rights reserved.
//

#import "TestCase.h"

@implementation TestCase
{
    NSDateFormatter *parser;
}

- (void)setUp
{
    [super setUp];
    parser = [[NSDateFormatter alloc] init];
    parser.dateFormat = @"yyyy-MM-dd HH:mm:ss Z";
    
    self.formatter = [SLConditionalDateFormatter new];
    self.formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    self.formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
}

- (NSDate *)parseDate:(NSString *)string
{
    return [parser dateFromString:string];
}

- (NSString *)expressionFromDate:(NSString *)from toReferenceDate:(NSString *)reference
{
    NSDate *referenceDate = [self parseDate:reference];
    NSDate *date = [self parseDate:from];
    
    return [self.formatter stringForTimeIntervalFromDate:date toReferenceDate:referenceDate];
}

@end
