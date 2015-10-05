//
//  ViewController.m
//  LDOConditionalDateFormatter
//
//  Created by Sebastian Ludwig on 07/31/2015.
//  Copyright (c) 2015 Sebastian Ludwig. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController
{
    IBOutletCollection(UILabel) NSArray *labels;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSDateFormatter *parser = [[NSDateFormatter alloc] init];
    parser.dateFormat = @"yyyy-MM-dd HH:mm:ss Z";
    
    LDOConditionalDateFormatter *formatter = [LDOConditionalDateFormatter new];
    NSCalendar *calendar = formatter.calendar;
    calendar.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    calendar.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    formatter.calendar = calendar;
    
    NSDate *now = [parser dateFromString:@"2015-02-24 16:52:39 +0000"];
    NSDate *minutesAgo = [parser dateFromString:@"2015-02-24 16:10:39 +0000"];
    NSDate *earlierToday = [parser dateFromString:@"2015-02-24 13:37:00 +0000"];
    NSDate *yesterday = [parser dateFromString:@"2015-02-23 10:37:00 +0000"];
    NSDate *twoDaysAgo = [parser dateFromString:@"2015-02-22 15:55:00 +0000"];
    NSDate *threeDaysAgo = [parser dateFromString:@"2015-02-21 15:55:00 +0000"];
    NSDate *longAgo = [parser dateFromString:@"2015-02-11 15:55:00 +0000"];
    
    [formatter addFormat:@"R" forTimeInterval:-3600];
    [formatter addFormat:@"{HH:mm}" for:LDOTimeUnitToday];
    [formatter addFormat:@"I" for:LDOTimeUnitYesterday];
    [formatter addFormat:@"I" forLast:2 unit:LDOTimeUnitDays];
    [formatter addFormat:@"R" forLast:7 unit:LDOTimeUnitDays];
    formatter.defaultFormat = @"{yMd}";
    
    // 42 minutes ago
    [labels[0] setText:[formatter stringForTimeIntervalFromDate:minutesAgo toReferenceDate:now]];
    
    // 13:37
    [labels[1] setText:[formatter stringForTimeIntervalFromDate:earlierToday toReferenceDate:now]];
    
    // yesterday - it's localized to "the day before today" in German (see Localizable.strings). Set your simulator to German to check it out
    [labels[2] setText:[formatter stringForTimeIntervalFromDate:yesterday toReferenceDate:now]];
    
    // 2 days ago / "vorgestern" (German for "day before yesterday"). Set your simulator to German to check it out
    [labels[3] setText:[formatter stringForTimeIntervalFromDate:twoDaysAgo toReferenceDate:now]];
    
    // 3 days ago
    [labels[4] setText:[formatter stringForTimeIntervalFromDate:threeDaysAgo toReferenceDate:now]];
    
    // 2/11/2015
    [labels[5] setText:[formatter stringForTimeIntervalFromDate:longAgo toReferenceDate:now]];
}

@end
