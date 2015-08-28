//
//  SLViewController.m
//  SLConditionalDateFormatter
//
//  Created by Sebastian Ludwig on 07/31/2015.
//  Copyright (c) 2015 Sebastian Ludwig. All rights reserved.
//

#import "SLViewController.h"

@implementation SLViewController
{
    IBOutletCollection(UILabel) NSArray *labels;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSDateFormatter *parser = [[NSDateFormatter alloc] init];
    parser.dateFormat = @"yyyy-MM-dd HH:mm:ss Z";
    
    SLConditionalDateFormatter *formatter = [SLConditionalDateFormatter new];
    NSCalendar *calendar = formatter.calendar;
    calendar.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    calendar.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    formatter.calendar = calendar;
    
    NSDate *now = [parser dateFromString:@"2015-02-24 16:52:39 +0000"];
    NSDate *minutesAgo = [parser dateFromString:@"2015-02-24 16:10:39 +0000"];
    NSDate *earlierToday = [parser dateFromString:@"2015-02-24 13:37:00 +0000"];
    NSDate *yesterday = [parser dateFromString:@"2015-02-23 10:37:00 +0000"];
    NSDate *threeDaysAgo = [parser dateFromString:@"2015-02-21 15:55:00 +0000"];
    NSDate *longAgo = [parser dateFromString:@"2015-02-11 15:55:00 +0000"];
    
    [formatter addFormat:@"R" forTimeInterval:-3600];
    [formatter addFormat:@"{HH:mm}" for:SLTimeUnitToday];
    [formatter addFormat:@"I" for:SLTimeUnitYesterday];
    [formatter addFormat:@"R" forLast:7 unit:SLTimeUnitDays];
    formatter.defaultFormat = @"{yMd}";
    
    // 42 minutes ago
    [labels[0] setText:[formatter stringForTimeIntervalFromDate:minutesAgo toReferenceDate:now]];
    
    // 13:37
    [labels[1] setText:[formatter stringForTimeIntervalFromDate:earlierToday toReferenceDate:now]];
    
    // yesterday - it's localized to "the day before today" in German (see Localizable.strings). Set your simulator to German to check it out
    [labels[2] setText:[formatter stringForTimeIntervalFromDate:yesterday toReferenceDate:now]];
    
    // 3 days ago
    [labels[3] setText:[formatter stringForTimeIntervalFromDate:threeDaysAgo toReferenceDate:now]];
    
    // 2/11/2015
    [labels[4] setText:[formatter stringForTimeIntervalFromDate:longAgo toReferenceDate:now]];
}

@end
