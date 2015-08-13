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
 Specifies the locale used to format strings. Defaults to the current system locale.
 */
@property NSLocale *locale;

/**
 Specifies the calendar used in date calculation. Defaults to the current system calendar.
 */
@property NSCalendar *calendar;

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
 Specifies the localized string used to format the time interval string and deictic expression. Defaults to a format with the deictic expression following the time interval
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

/**
 Specifies whether to use an approximate qualifier when the described interval is not exact. `NO` by default.
 */
@property BOOL usesApproximateQualifier;

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


- (NSString *)defaultForamt;
- (void)setDefaultFormat:(NSString *)defaultForamt;
- (void)addFormat:(NSString *)format forTimeInterval:(NSTimeInterval)timeInterval;
- (void)addFormat:(NSString *)format for:(SLTimeUnit)unit;
- (void)addFormat:(NSString *)format forLast:(NSUInteger)count unit:(SLTimeUnit)unit;
- (void)addFormat:(NSString *)format forNext:(NSUInteger)count unit:(SLTimeUnit)unit;


///-------------------------
/// @name Converting Objects
///-------------------------

/**
 Returns a string representation of a time interval formatted using the receiver’s current settings.
 
 @param seconds The number of seconds to add to the receiver. Use a negative value for seconds to have the returned object specify a date before the receiver.
 */
- (NSString *)stringForTimeInterval:(NSTimeInterval)seconds;

/**
 Returns a string representation of the time interval between two specified dates formatted using the receiver’s current settings.
 
 @param date The date
 @param referenceDate The reference date
 */
- (NSString *)stringForTimeIntervalFromDate:(NSDate *)date toReferenceDate:(NSDate *)referenceDate;

@end
