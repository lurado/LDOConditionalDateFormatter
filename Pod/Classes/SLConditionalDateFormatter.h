//
//  SLConditionalDateFormatter.h
//  Pods
//
//  Created by Sebastian Ludwig on 31.07.15.
//
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    SLTimeUnitDays,
    SLTimeUnitWeeks,
    SLTimeUnitMonths,
    SLTimeUnitYears,
    
    SLTimeUnitToday,
    SLTimeUnitSameDay,
    SLTimeUnitYesterday,
    SLTimeUnitPreviousDay,
    SLTimeUnitTomorrow,
    SLTimeUnitNextDay,
    
    SLTimeUnitThisWeek,
    SLTimeUnitSameWeek,
    SLTimeUnitLastWeek,
    SLTimeUnitPreviousWeek,
    SLTimeUnitNextWeek,
    
    SLTimeUnitThisMonth,
    SLTimeUnitLastMonth,
    SLTimeUnitNextMonth,
    
    SLTimeUnitThisYear,
    SLTimeUnitLastYear,
    SLTimeUnitNextYear,
} SLTimeUnit;

@interface SLConditionalDateFormatter : NSFormatter

/**
 Specifies the calendar used in date calculation. Defaults to the current system calendar.
 The calendar also specifies the time zone and locale that will be used to format strings.
 */
@property (copy, nonatomic) NSCalendar *calendar;

///--------------------------------------
/// @name Configuring Deictic Expressions
///--------------------------------------

/**
 Specifies the localized string used to express the past deictic expression. "ago" by default.
 */
@property (copy) NSString *pastDeicticExpression;

/**
 Specifies the localized string used to express the present deictic expression. "just now" by default.
 */
@property (copy) NSString *presentDeicticExpression;

/**
 Specifies the localized string used to express the future deictic expression. "from now" by default.
 */
@property (copy) NSString *futureDeicticExpression;

/**
 Specifies the localized string used to format the time interval string and deictic expression. #{Time} #{Ago/From Now} by default.
 */
@property (copy) NSString *deicticExpressionFormat;

/**
 Specifies the localized string used to format the time with its suffix. "#{Time} #{Unit}" by default.
 */
@property (copy) NSString *suffixExpressionFormat;

/**
 Specifies the time interval before and after the present moment that is described as still being in the present, rather than the past or future. Defaults to 1 second.
 */
@property NSTimeInterval presentTimeIntervalMargin;

///-----------------------------------------
/// @name Configuring Approximate Qualifiers
///-----------------------------------------

/**
 Specifies the localized string used to qualify a time interval as being an approximate time. "about" by default.
 */
@property (copy) NSString *approximateQualifierFormat;

///------------------------------------
/// @name Configuring Significant Units
///------------------------------------

/**
 A bitmask specifying the significant units. Defaults to a bitmask of year, month, week, day, hour, minute, and second.
 */
@property NSCalendarUnit significantUnits;

/**
 Specifies the least significant unit that should be displayed when not approximating. Defaults to `NSCalendarUnitSeconds`.
 */
@property NSCalendarUnit leastSignificantUnit;

///----------------------------------------------
/// @name Configuring Calendar Unit Abbreviations
///----------------------------------------------

/**
 Specifies whether to use abbreviated calendar units to describe time intervals, for instance "wks" instead of "weeks" in English. Defaults to `NO`.
 */
@property BOOL usesAbbreviatedCalendarUnits;

///----------------------------------------------
/// @name Formats
///----------------------------------------------

/**
 Specifies the default format to be used if no other format applies. Defaults to `nil`.
 */
@property (nonatomic, copy) NSString *defaultFormat;

/**
 Adds a format to be used if the difference between the date to be formatted and the reference date falls into the given format.
 
 @param format Format string. See README for a detailed description.
 @param timeInterval The time interval for which the format should be used.
 */
- (void)addFormat:(NSString *)format forTimeInterval:(NSTimeInterval)timeInterval;

/**
 Adds a fromat to be used for a specific time unit.
 
 The time unit needs to be a relative time unit like `SLTimeUnitToday`, `SLTimeUnitSameWeek` or `SLTimeNextYear`.
 
 @param format Format string. See README for a detailed description.
 @param unit Time unit at which the format will be active.
 */
- (void)addFormat:(NSString *)format for:(SLTimeUnit)unit;

/**
 Adds a format for a relative time span in the past.
 
 The time unit should be one of the following: `SLTimeUnitDays`, `SLTimeUnitWeeks`, `SLTimeUnitMonths`, `SLTimeUnitYears`.
 
 @param format Format string. See README for a detailed description.
 @param count Multiplier for the given unit.
 @param unit Time unit.
 */
- (void)addFormat:(NSString *)format forLast:(NSUInteger)count unit:(SLTimeUnit)unit;

/**
 Adds a format for a relative time span in the future.
 
 The time unit should be one of the following: `SLTimeUnitDays`, `SLTimeUnitWeeks`, `SLTimeUnitMonths`, `SLTimeUnitYears`.
 
 @param format Format string. See README for a detailed description.
 @param count Multiplier for the given unit.
 @param unit Time unit.
 */
- (void)addFormat:(NSString *)format forNext:(NSUInteger)count unit:(SLTimeUnit)unit;


///-------------------------
/// @name Converting Objects
///-------------------------

/**
 Returns a string representation of a time interval formatted using the receiver's current settings.
 
 @param seconds The number of seconds offset from now.
 */
- (NSString *)stringForTimeInterval:(NSTimeInterval)seconds;

/**
 Returns a string representation of the time interval between two specified dates formatted using the receiver’s current settings.
 
 @param date The date to be formatted.
 @param referenceDate The reference date
 */
- (NSString *)stringForTimeIntervalFromDate:(NSDate *)date toReferenceDate:(NSDate *)referenceDate;

/**
 Returns a string representation of the specified date formatted using the receiver's current settings.
 
 The current time is used as referece date for relative formats.
 
 @param The date to be formatted.
 */
- (NSString *)stringForTimeIntervalFromDate:(NSDate *)date;

@end
