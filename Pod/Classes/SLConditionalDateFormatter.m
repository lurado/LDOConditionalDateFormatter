//
//  SLConditionalDateFormatter.m
//  Pods
//
//  Created by Sebastian Ludwig on 31.07.15.
//
//

#import "SLConditionalDateFormatter.h"


#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000) || (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 1090)
#define SLCalendarUnitYear NSCalendarUnitYear
#define SLCalendarUnitMonth NSCalendarUnitMonth
#define SLCalendarUnitWeek NSCalendarUnitWeekOfYear
#define SLCalendarUnitDay NSCalendarUnitDay
#define SLCalendarUnitHour NSCalendarUnitHour
#define SLCalendarUnitMinute NSCalendarUnitMinute
#define SLCalendarUnitSecond NSCalendarUnitSecond
#define SLCalendarUnitWeekday NSCalendarUnitWeekday
#define SLDateComponentUndefined NSDateComponentUndefined
#else
#define SLCalendarUnitYear NSYearCalendarUnit
#define SLCalendarUnitMonth NSMonthCalendarUnit
#define SLCalendarUnitWeek NSWeekOfYearCalendarUnit
#define SLCalendarUnitDay NSDayCalendarUnit
#define SLCalendarUnitHour NSHourCalendarUnit
#define SLCalendarUnitMinute NSMinuteCalendarUnit
#define SLCalendarUnitSecond NSSecondCalendarUnit
#define SLCalendarUnitWeekday NSWeekdayCalendarUnit
#define SLDateComponentUndefined NSUndefinedDateComponent
#endif

@interface SLDateRelationship : NSObject

@property (readonly, copy) NSDate *date;
@property (readonly, copy) NSDate *referenceDate;

@property (readonly) NSTimeInterval timeIntervalSinceReferenceDate;
@property (readonly) BOOL isInPast;
@property (readonly) BOOL isInFuture;

@property (readonly) NSInteger daysDifference;
@property (readonly) NSInteger weeksDifference;
@property (readonly) NSInteger monthsDifference;
@property (readonly) NSInteger yearsDifference;

@property (readonly) BOOL sameDay;
@property (readonly) BOOL perviousDay;
@property (readonly) BOOL nextDay;

@property (readonly) BOOL sameYear;
@property (readonly) BOOL previousYear;
@property (readonly) BOOL nextYear;

@property (readonly) BOOL sameMonth;
@property (readonly) BOOL previousMonth;
@property (readonly) BOOL nextMonth;

@property (readonly) BOOL sameWeek;
@property (readonly) BOOL previousWeek;
@property (readonly) BOOL nextWeek;

- (instancetype)initWithDate:(NSDate *)date referenceDate:(NSDate *)referenceDate calendar:(NSCalendar *)calendar;

@end

@implementation SLDateRelationship

+ (NSDateComponents *)componentsWithoutTime:(NSDate *)date calendar:(NSCalendar *)calendar
{
    NSCalendarUnit units = SLCalendarUnitYear | SLCalendarUnitMonth | SLCalendarUnitWeek | SLCalendarUnitDay | SLCalendarUnitWeekday;
    return [calendar components:units fromDate:date];
}

- (instancetype)initWithDate:(NSDate *)date referenceDate:(NSDate *)referenceDate calendar:(NSCalendar *)calendar
{
    if (self = [super init]) {
        _referenceDate = [referenceDate copy];
        _date = [date copy];
        
        NSDateComponents *referenceComponents = [self.class componentsWithoutTime:referenceDate calendar:calendar];
        NSDateComponents *dateComponents = [self.class componentsWithoutTime:date calendar:calendar];
        
        // same dates without time
        referenceDate = [calendar dateFromComponents:referenceComponents];
        date = [calendar dateFromComponents:dateComponents];
        _daysDifference = [calendar components:SLCalendarUnitDay fromDate:referenceDate toDate:date options:0].day;
        _weeksDifference = [calendar components:SLCalendarUnitWeek fromDate:referenceDate toDate:date options:0].weekOfYear;
        _monthsDifference = [calendar components:SLCalendarUnitMonth fromDate:referenceDate toDate:date options:0].month;
        _yearsDifference = [calendar components:SLCalendarUnitYear fromDate:referenceDate toDate:date options:0].year;
        
        _sameYear = referenceComponents.year == dateComponents.year;
        _previousYear = referenceComponents.year - 1 == dateComponents.year;
        _nextYear = referenceComponents.year + 1 == dateComponents.year;
        
        _sameMonth = _sameYear && referenceComponents.month == dateComponents.month;
        _previousMonth = (_sameYear && referenceComponents.month - 1 == dateComponents.month) || (_previousYear && referenceComponents.month == 1 && dateComponents.month == 12);
        _nextMonth = (_sameYear && referenceComponents.month + 1 == dateComponents.month) || (_nextYear && referenceComponents.month == 12 && dateComponents.month == 1);
        
        long numberOfWeeks = MAX(MAX(referenceComponents.weekOfYear, dateComponents.weekOfYear), 52);
        BOOL sameWeekNumber = referenceComponents.weekOfYear == dateComponents.weekOfYear;
        BOOL precedingWeekNumber = (dateComponents.weekOfYear % numberOfWeeks) + 1 == referenceComponents.weekOfYear;
        BOOL succeedingWeekNumber = (referenceComponents.weekOfYear % numberOfWeeks) + 1 == dateComponents.weekOfYear;
        _sameWeek = sameWeekNumber && _sameMonth;
        _previousWeek = precedingWeekNumber && (_sameMonth || _previousMonth);
        _nextWeek = succeedingWeekNumber && (_sameMonth || _nextMonth);
    }
    return self;
}

- (BOOL)sameDay
{
    return _daysDifference == 0;
}

- (BOOL)previousDay
{
    return _daysDifference == -1;
}

- (BOOL)nextDay
{
    return _daysDifference == 1;
}

- (NSTimeInterval)timeIntervalSinceReferenceDate {
    return [self.date timeIntervalSinceDate:self.referenceDate];
}

- (BOOL)isInPast
{
    return self.timeIntervalSinceReferenceDate < 0;
}

- (BOOL)isInFuture
{
    return self.timeIntervalSinceReferenceDate > 0;
}

@end


static inline NSComparisonResult NSCalendarUnitCompareSignificance(NSCalendarUnit a, NSCalendarUnit b)
{
    if ((a == SLCalendarUnitWeek) ^ (b == SLCalendarUnitWeek)) {
        if (b == SLCalendarUnitWeek) {     // TODO: check https://github.com/mattt/FormatterKit/pull/186
            switch (a) {
                case SLCalendarUnitYear:
                case SLCalendarUnitMonth:
                    return NSOrderedDescending;
                default:
                    return NSOrderedAscending;
            }
        } else {
            switch (b) {
                case SLCalendarUnitYear:
                case SLCalendarUnitMonth:
                    return NSOrderedAscending;
                default:
                    return NSOrderedDescending;
            }
        }
    } else {
        if (a > b) {
            return NSOrderedAscending;
        } else if (a < b) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }
}

typedef BOOL (^FormatCondition)(SLDateRelationship *relationship);

@implementation SLConditionalDateFormatter
{
    NSDateFormatter *dateFormatter;
    NSMutableArray *rules;
    NSDictionary *defaultFormat;
}

- (id)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    rules = [NSMutableArray array];
    _locale = [NSLocale currentLocale];
    _timeZone = [NSTimeZone localTimeZone];
    _calendar = [NSCalendar currentCalendar];
    _calendar.locale = _locale;
    _calendar.timeZone = _timeZone;
    dateFormatter = [NSDateFormatter new];
    dateFormatter.calendar = _calendar;
    dateFormatter.locale = _locale;
    dateFormatter.timeZone = _timeZone;
    
    _pastDeicticExpression = NSLocalizedStringFromTable(@"ago", @"FormatterKit", @"Past Deictic Expression");
    _presentDeicticExpression = NSLocalizedStringFromTable(@"just now", @"FormatterKit", @"Present Deictic Expression");
    _futureDeicticExpression = NSLocalizedStringFromTable(@"from now", @"FormatterKit", @"Future Deictic Expression");
    
    _deicticExpressionFormat = NSLocalizedStringWithDefaultValue(@"Deictic Expression Format String", @"FormatterKit", [NSBundle mainBundle], @"%@ %@", @"Deictic Expression Format (#{Time} #{Ago/From Now}");
    _approximateQualifierFormat = NSLocalizedStringFromTable(@"about %@", @"FormatterKit", @"Approximate Qualifier Format");
    _suffixExpressionFormat = NSLocalizedStringWithDefaultValue(@"Suffix Expression Format String", @"FormatterKit", [NSBundle mainBundle], @"%@ %@", @"Suffix Expression Format (#{Time} #{Unit})");
    
    _presentTimeIntervalMargin = 1;
    
    _significantUnits = SLCalendarUnitYear | SLCalendarUnitMonth | SLCalendarUnitWeek | SLCalendarUnitDay | SLCalendarUnitHour | SLCalendarUnitMinute | SLCalendarUnitSecond;
    _leastSignificantUnit = SLCalendarUnitSecond;
    
    return self;
}

- (void)setTimeZone:(NSTimeZone *)timeZone
{
    _timeZone = [timeZone copy];
    dateFormatter.timeZone = _timeZone;
    self.calendar.timeZone = _timeZone;
}

- (void)setLocale:(NSLocale *)locale
{
    _locale = [locale copy];
    dateFormatter.locale = locale;
    self.calendar.locale = locale;
}

- (void)setCalendar:(NSCalendar *)calendar
{
    _calendar = [calendar copy];
    _calendar.timeZone = self.timeZone;
    _calendar.locale = self.locale;
    dateFormatter.calendar = _calendar;
}

- (NSInteger)extractComponent:(NSCalendarUnit)unit from:(NSDateComponents *)components
{
    switch (unit) {
        case SLCalendarUnitYear:
            return components.year;
        case SLCalendarUnitMonth:
            return components.month;
        case SLCalendarUnitWeek:
            return components.weekOfYear;
        case SLCalendarUnitDay:
            return components.day;
        case SLCalendarUnitHour:
            return components.hour;
        case SLCalendarUnitMinute:
            return components.minute;
        case SLCalendarUnitSecond:
            return components.second;
        default:
            return 0;
    }
}

- (BOOL)shouldUseUnit:(NSCalendarUnit)unit
{
    return (self.significantUnits & unit) && NSCalendarUnitCompareSignificance(self.leastSignificantUnit, unit) != NSOrderedDescending;
}

#pragma mark - Formats

- (NSString *)defaultForamt
{
    return defaultFormat[@"foramt"];
}

- (void)setDefaultFormat:(NSString *)format
{
    FormatCondition check = ^BOOL(SLDateRelationship *relationship) {
        return YES;
    };
    defaultFormat = format == nil ? nil : @{@"format": [format copy], @"condtion": check};
}

- (void)addFormat:(NSString *)format condition:(FormatCondition)condition
{
    [rules addObject:@{@"format": format, @"condtion": condition}];
}

- (void)addFormat:(NSString *)format forTimeInterval:(NSTimeInterval)timeInterval
{
    FormatCondition check = ^BOOL(SLDateRelationship *relationship) {
        NSTimeInterval difference = relationship.timeIntervalSinceReferenceDate;
        BOOL sameSign = (difference <= 0 && timeInterval <= 0) || (difference > 0 && timeInterval >= 0);
        return sameSign && ABS(difference) <= ABS(timeInterval);
    };
    [self addFormat:format condition:check];
}

- (void)addFormat:(NSString *)format for:(SLTimeUnit)unit
{
    FormatCondition check = ^BOOL(SLDateRelationship *relationship) {
        switch (unit) {
            case SLTimeUnitToday:
            case SLTimeUnitSameDay:
                return relationship.sameDay;
            case SLTimeUnitYesterday:
            case SLTimeUnitPreviousDay:
                return relationship.previousDay;
            case SLTimeUnitTomorrow:
            case SLTimeUnitNextDay:
                return relationship.nextDay;
            
            case SLTimeUnitThisWeek:
            case SLTimeUnitSameWeek:
                return relationship.sameWeek;
            case SLTimeUnitLastWeek:
            case SLTimeUnitPreviousWeek:
                return relationship.previousWeek;
            case SLTimeUnitNextWeek: return relationship.nextWeek;
            
            case SLTimeUnitThisMonth: return relationship.sameMonth;
            case SLTimeUnitLastMonth: return relationship.previousMonth;
            case SLTimeUnitNextMonth: return relationship.nextMonth;
            
            case SLTimeUnitThisYear: return relationship.sameYear;
            case SLTimeUnitLastYear: return relationship.previousYear;
            case SLTimeUnitNextYear: return relationship.nextYear;
            default:
                break;
        }
        return NO;
    };
    
    [self addFormat:format condition:check];
}

- (void)addFormat:(NSString *)format forLast:(NSUInteger)count unit:(SLTimeUnit)unit
{
    FormatCondition check = ^BOOL(SLDateRelationship *relationship) {
        switch (unit) {
            case SLTimeUnitDays: return relationship.daysDifference <= 0 && relationship.daysDifference <= -count;
            case SLTimeUnitWeeks: return relationship.weeksDifference <= 0 && relationship.weeksDifference <= -count;
            case SLTimeUnitMonths: return relationship.monthsDifference <= 0 && relationship.monthsDifference <= -count;
            case SLTimeUnitYears: return relationship.yearsDifference <= 0 && relationship.yearsDifference <= -count;
            default:
                break;
        }
        return NO;
    };
    
    [self addFormat:format condition:check];
}

- (void)addFormat:(NSString *)format forNext:(NSUInteger)count unit:(SLTimeUnit)unit
{
    FormatCondition check = ^BOOL(SLDateRelationship *relationship) {
        switch (unit) {
            case SLTimeUnitDays: return relationship.daysDifference >= 0 && relationship.daysDifference <= count;
            case SLTimeUnitWeeks: return relationship.weeksDifference >= 0 && relationship.weeksDifference <= count;
            case SLTimeUnitMonths: return relationship.monthsDifference >= 0 && relationship.monthsDifference <= count;
            case SLTimeUnitYears: return relationship.yearsDifference >= 0 && relationship.yearsDifference <= count;
            default:
                break;
        }
        return NO;
    };
    
    [self addFormat:format condition:check];
}

#pragma mark - Transformations

- (NSString *)stringForTimeInterval:(NSTimeInterval)seconds
{
    NSDate *now = [NSDate date];    // use for offset calculation _and_ reference to ensure no second wrap occurs between two [NSDate date] calls
    return [self stringForTimeIntervalFromDate:[now dateByAddingTimeInterval:seconds] toReferenceDate:now];
}

- (NSString *)stringForTimeIntervalSinceDate:(NSDate *)date
{
    return [self stringForTimeIntervalFromDate:date toReferenceDate:[NSDate date]];
}

- (NSString *)stringForTimeIntervalFromDate:(NSDate *)date toReferenceDate:(NSDate *)referenceDate
{
    SLDateRelationship *dateRelationship = [[SLDateRelationship alloc] initWithDate:date referenceDate:referenceDate calendar:self.calendar];
    
    NSArray *applicableRules = defaultFormat ? [rules arrayByAddingObject:defaultFormat] : rules;
    for (NSDictionary *rule in applicableRules ) {
        FormatCondition check = rule[@"condtion"];
        if (!check(dateRelationship)) {
            continue;
        }
        NSString *result = [self applyFormat:rule[@"format"] toDateRelationship:dateRelationship];
        if (result) {
            return result;
        }
    }
    
    return nil;
}

#pragma mark Helper

- (NSString *)boundaryCharacterWrappedPattern:(NSString *)pattern
{
    NSString *boundaryCharacters = @"\\s,\\.";
    return [NSString stringWithFormat:@"(?:^|[%@])(%@)(?:$|[%@])", boundaryCharacters, pattern, boundaryCharacters];
}

- (NSString *)applyFormat:(NSString *)format toDateRelationship:(SLDateRelationship *)relationship
{
    if (!format) {
        return nil;
    }
    
    NSString *result = [format copy];
    
    result = [self replaceMatchesOfRegex:[self boundaryCharacterWrappedPattern:@"(~?)(R{1,7})"] inString:result usingBlock:^NSString *(NSString *input, NSTextCheckingResult *match) {
        BOOL approximate = [match rangeAtIndex:2].length == 1;
        NSString *replacement = [self relativeExpressionForDateRelationship:relationship numberOfSignificantUnits:[match rangeAtIndex:3].length approximate:approximate];
        if (replacement) {
            input = [input stringByReplacingCharactersInRange:[match rangeAtIndex:1] withString:replacement];
        }
        return input;
    }];
    
    result = [self replaceMatchesOfRegex:[self boundaryCharacterWrappedPattern:@"I"] inString:result usingBlock:^NSString *(NSString *input, NSTextCheckingResult *match) {
        NSString *replacement = [self idiomaticDeicticExpressionForDateRelationship:relationship];
        if (replacement) {
            input = [input stringByReplacingCharactersInRange:[match rangeAtIndex:1] withString:replacement];
        }
        return input;
    }];
    
    result = [self replaceMatchesOfRegex:@"\\{([cdeghjklmqrsuvwxyzADEFGHJKLMOQSUVWXYZ]*?)\\}" inString:result usingBlock:^NSString *(NSString *input, NSTextCheckingResult *match) {
        NSRange templateRange = [match rangeAtIndex:1];
        NSString *template = [input substringWithRange:templateRange];
        NSString *replacement = [NSDateFormatter dateFormatFromTemplate:template options:0 locale:self.locale];
        if (replacement) {
            input = [input stringByReplacingCharactersInRange:templateRange withString:replacement];
        }
        return input;
    }];
    
    result = [self replaceMatchesOfRegex:@"\\{(.*?)\\}" inString:result usingBlock:^NSString *(NSString *input, NSTextCheckingResult *match) {
        dateFormatter.dateFormat = [input substringWithRange:[match rangeAtIndex:1]];
        NSString *replacement = [dateFormatter stringFromDate:relationship.date];
        if (replacement) {
            input = [input stringByReplacingCharactersInRange:match.range withString:replacement];
        }
        return input;
    }];
    
    return [result isEqualToString:format] ? nil : result;
}

- (NSString *)replaceMatchesOfRegex:(NSString *)pattern inString:(NSString *)string usingBlock:(NSString* (^)(NSString *input, NSTextCheckingResult* match))block {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    NSArray *matches = [regex matchesInString:string options:0 range:NSMakeRange(0, string.length)];
    for (NSTextCheckingResult *match in [matches reverseObjectEnumerator]) {
        string = block(string, match);
    }
    return string;
}

#pragma mark - Relative and idiomatic

- (NSString *)relativeExpressionForDateRelationship:(SLDateRelationship *)relationship numberOfSignificantUnits:(NSUInteger)numberOfSignificantUnits approximate:(BOOL)approximate
{
    NSDateComponents *components = [self.calendar components:self.significantUnits fromDate:relationship.referenceDate toDate:relationship.date options:0];
    NSString *string = nil;
    BOOL isApproximate = NO;
    NSUInteger numberOfUnits = 0;
    for (NSNumber *unitWrapper in @[@(SLCalendarUnitYear), @(SLCalendarUnitMonth), @(SLCalendarUnitWeek), @(SLCalendarUnitDay), @(SLCalendarUnitHour), @(SLCalendarUnitMinute), @(SLCalendarUnitSecond)]) {
        NSCalendarUnit unit = [unitWrapper unsignedLongValue];
        if ([self shouldUseUnit:unit]) {
            BOOL reportOnlyDays = unit == SLCalendarUnitDay && numberOfSignificantUnits == 1;
            NSInteger value = reportOnlyDays ? relationship.daysDifference : [self extractComponent:unit from:components];
            if (value) {
                NSNumber *number = @(abs((int)value));
                NSString *suffix = [NSString stringWithFormat:self.suffixExpressionFormat, number, [self localizedStringForNumber:[number unsignedIntegerValue] ofCalendarUnit:unit]];
                if (!string) {
                    string = suffix;
                } else if (numberOfSignificantUnits == 0 || numberOfUnits < numberOfSignificantUnits) {
                    string = [string stringByAppendingFormat:@" %@", suffix];
                } else {
                    isApproximate = YES;
                    break;
                }
                
                numberOfUnits++;
            }
        }
    }
    
    if (string) {
        if (relationship.isInPast) {
            if ([self.pastDeicticExpression length]) {
                string = [NSString stringWithFormat:self.deicticExpressionFormat, string, self.pastDeicticExpression];
            }
        } else {
            if ([self.futureDeicticExpression length]) {
                string = [NSString stringWithFormat:self.deicticExpressionFormat, string, self.futureDeicticExpression];
            }
        }
        
        if (isApproximate && approximate) {
            string = [NSString stringWithFormat:self.approximateQualifierFormat, string];
        }
    }
    
    return string;
}

- (NSString *)localizedStringForNumber:(NSUInteger)number ofCalendarUnit:(NSCalendarUnit)unit
{
    BOOL singular = (number == 1);
    
    if (self.usesAbbreviatedCalendarUnits) {
        switch (unit) {
            case SLCalendarUnitYear:
                return singular ? NSLocalizedStringFromTable(@"yr", @"FormatterKit", @"Year Unit (Singular, Abbreviated)") : NSLocalizedStringFromTable(@"yrs", @"FormatterKit", @"Year Unit (Plural, Abbreviated)");
            case SLCalendarUnitMonth:
                return singular ? NSLocalizedStringFromTable(@"mo", @"FormatterKit", @"Month Unit (Singular, Abbreviated)") : NSLocalizedStringFromTable(@"mos", @"FormatterKit", @"Month Unit (Plural, Abbreviated)");
            case SLCalendarUnitWeek:
                return singular ? NSLocalizedStringFromTable(@"wk", @"FormatterKit", @"Week Unit (Singular, Abbreviated)") : NSLocalizedStringFromTable(@"wks", @"FormatterKit", @"Week Unit (Plural, Abbreviated)");
            case SLCalendarUnitDay:
                return singular ? NSLocalizedStringFromTable(@"d", @"FormatterKit", @"Day Unit (Singular, Abbreviated)") : NSLocalizedStringFromTable(@"ds", @"FormatterKit", @"Day Unit (Plural, Abbreviated)");
            case SLCalendarUnitHour:
                return singular ? NSLocalizedStringFromTable(@"hr", @"FormatterKit", @"Hour Unit (Singular, Abbreviated)") : NSLocalizedStringFromTable(@"hrs", @"FormatterKit", @"Hour Unit (Plural, Abbreviated)");
            case SLCalendarUnitMinute:
                return singular ? NSLocalizedStringFromTable(@"min", @"FormatterKit", @"Minute Unit (Singular, Abbreviated)") : NSLocalizedStringFromTable(@"mins", @"FormatterKit", @"Minute Unit (Plural, Abbreviated)");
            case SLCalendarUnitSecond:
                return singular ? NSLocalizedStringFromTable(@"s", @"FormatterKit", @"Second Unit (Singular, Abbreviated)") : NSLocalizedStringFromTable(@"s", @"FormatterKit", @"Second Unit (Plural, Abbreviated)");
            default:
                return nil;
        }
    } else {
        switch (unit) {
            case SLCalendarUnitYear:
                return singular ? NSLocalizedStringFromTable(@"year", @"FormatterKit", @"Year Unit (Singular)") : NSLocalizedStringFromTable(@"years", @"FormatterKit", @"Year Unit (Plural)");
            case SLCalendarUnitMonth:
                return singular ? NSLocalizedStringFromTable(@"month", @"FormatterKit", @"Month Unit (Singular)") : NSLocalizedStringFromTable(@"months", @"FormatterKit", @"Month Unit (Plural)");
            case SLCalendarUnitWeek:
                return singular ? NSLocalizedStringFromTable(@"week", @"FormatterKit", @"Week Unit (Singular)") : NSLocalizedStringFromTable(@"weeks", @"FormatterKit", @"Week Unit (Plural)");
            case SLCalendarUnitDay:
                return singular ? NSLocalizedStringFromTable(@"day", @"FormatterKit", @"Day Unit (Singular)") : NSLocalizedStringFromTable(@"days", @"FormatterKit", @"Day Unit (Plural)");
            case SLCalendarUnitHour:
                return singular ? NSLocalizedStringFromTable(@"hour", @"FormatterKit", @"Hour Unit (Singular)") : NSLocalizedStringFromTable(@"hours", @"FormatterKit", @"Hour Unit (Plural)");
            case SLCalendarUnitMinute:
                return singular ? NSLocalizedStringFromTable(@"minute", @"FormatterKit", @"Minute Unit (Singular)") : NSLocalizedStringFromTable(@"minutes", @"FormatterKit", @"Minute Unit (Plural)");
            case SLCalendarUnitSecond:
                return singular ? NSLocalizedStringFromTable(@"second", @"FormatterKit", @"Second Unit (Singular)") : NSLocalizedStringFromTable(@"seconds", @"FormatterKit", @"Second Unit (Plural)");
            default:
                return nil;
        }
    }
}

#pragma mark -

- (NSString *)idiomaticDeicticExpressionForDateRelationship:(SLDateRelationship *)relationship
{
    if (fabs(relationship.timeIntervalSinceReferenceDate) <= self.presentTimeIntervalMargin) {
        return self.presentDeicticExpression;
    }
    
    if ([self shouldUseUnit:SLCalendarUnitDay] && relationship.previousDay) {
        return NSLocalizedStringFromTable(@"yesterday", @"FormatterKit", @"yesterday");
    }
    if ([self shouldUseUnit:SLCalendarUnitDay] && relationship.nextDay) {
        return NSLocalizedStringFromTable(@"tomorrow", @"FormatterKit", @"tomorrow");
    }
    
    if ([self shouldUseUnit:SLCalendarUnitWeek] && relationship.previousWeek) {
        return NSLocalizedStringFromTable(@"last week", @"FormatterKit", @"last week");
    }
    if ([self shouldUseUnit:SLCalendarUnitWeek] && relationship.nextWeek) {
        return NSLocalizedStringFromTable(@"next week", @"FormatterKit", @"next week");
    }
    
    if ([self shouldUseUnit:SLCalendarUnitMonth] && relationship.previousMonth) {
        return NSLocalizedStringFromTable(@"last month", @"FormatterKit", @"last month");
    }
    if ([self shouldUseUnit:SLCalendarUnitMonth] && relationship.nextMonth) {
        return NSLocalizedStringFromTable(@"next month", @"FormatterKit", @"next month");
    }
    
    if ([self shouldUseUnit:SLCalendarUnitYear] && relationship.previousYear) {
        return NSLocalizedStringFromTable(@"last year", @"FormatterKit", @"last year");
    }
    if ([self shouldUseUnit:SLCalendarUnitYear] && relationship.nextYear) {
        return NSLocalizedStringFromTable(@"next year", @"FormatterKit", @"next year");
    }
    
    return nil;
}

#pragma mark - Not used atm

- (NSString *)caRelativeDateStringForComponents:(NSDateComponents *)components
{
    if ([components day] == -2 && [components year] == 0 && [components month] == 0 && [components weekOfYear] == 0) {
        return @"abans d'ahir";
    }
    
    if ([components day] == 2 && [components year] == 0 && [components month] == 0 && [components weekOfYear] == 0) {
        return @"passat demà";
    }
    
    return nil;
}

- (NSString *)heRelativeDateStringForComponents:(NSDateComponents *)components
{
    if ([components year] == -2) {
        return @"לפני שנתיים";
    } else if ([components month] == -2 && [components year] == 0) {
        return @"לפני חודשיים";
    } else if ([components weekOfYear] == -2 && [components year] == 0 && [components month] == 0) {
        return @"לפני שבועיים";
    } else if ([components day] == -2 && [components year] == 0 && [components month] == 0 && [components weekOfYear] == 0) {
        return @"שלשום";
    }
    
    if ([components year] == 2) {
        return @"בעוד שנתיים";
    } else if ([components month] == 2 && [components year] == 0) {
        return @"בעוד חודשיים";
    } else if ([components weekOfYear] == 2 && [components year] == 0 && [components month] == 0) {
        return @"בעוד שבועיים";
    } else if ([components day] == 2 && [components year] == 0 && [components month] == 0 && [components weekOfYear] == 0) {
        return @"מחרתיים";
    }
    
    return nil;
}

- (NSString *)nlRelativeDateStringForComponents:(NSDateComponents *)components
{
    if ([components day] == -2 && [components year] == 0 && [components month] == 0 && [components weekOfYear] == 0) {
        return @"eergisteren";
    }
    
    if ([components day] == 2 && [components year] == 0 && [components month] == 0 && [components weekOfYear] == 0) {
        return @"overmorgen";
    }
    
    return nil;
}

- (NSString *)plRelativeDateStringForComponents:(NSDateComponents *)components
{
    if ([components day] == -2 && [components year] == 0 && [components month] == 0 && [components weekOfYear] == 0) {
        return @"przedwczoraj";
    }
    
    if ([components day] == 2 && [components year] == 0 && [components month] == 0 && [components weekOfYear] == 0) {
        return @"pojutrze";
    }
    
    return nil;
}

- (NSString *)csRelativeDateStringForComponents:(NSDateComponents *)components
{
    if ([components day] == -2 && [components weekOfYear] == 0 && [components month] == 0 && [components year] == 0) {
        return @"předevčírem";
    }
    
    if ([components day] == 2 && [components weekOfYear] == 0 && [components month] == 0 && [components year] == 0) {
        return @"pozítří";
    }
    
    return nil;
}

#pragma mark - NSFormatter

- (NSString *)stringForObjectValue:(id)anObject
{
    if (![anObject isKindOfClass:[NSNumber class]]) {
        return nil;
    }
    
    return [self stringForTimeInterval:[(NSNumber *)anObject doubleValue]];
}

- (BOOL)getObjectValue:(out __unused __autoreleasing id *)obj
             forString:(__unused NSString *)string
      errorDescription:(out NSString *__autoreleasing *)error
{
    *error = NSLocalizedStringFromTable(@"Method Not Implemented", @"FormatterKit", nil);
    
    return NO;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    SLConditionalDateFormatter *formatter = [[[self class] allocWithZone:zone] init];
    
    formatter.locale = [self.locale copyWithZone:zone];
    formatter.pastDeicticExpression = [self.pastDeicticExpression copyWithZone:zone];
    formatter.presentDeicticExpression = [self.presentDeicticExpression copyWithZone:zone];
    formatter.futureDeicticExpression = [self.futureDeicticExpression copyWithZone:zone];
    formatter.deicticExpressionFormat = [self.deicticExpressionFormat copyWithZone:zone];
    formatter.approximateQualifierFormat = [self.approximateQualifierFormat copyWithZone:zone];
    formatter.presentTimeIntervalMargin = self.presentTimeIntervalMargin;
    formatter.usesAbbreviatedCalendarUnits = self.usesAbbreviatedCalendarUnits;
    
    return formatter;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    self.locale = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(locale))];
    self.pastDeicticExpression = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(pastDeicticExpression))];
    self.presentDeicticExpression = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(presentDeicticExpression))];
    self.futureDeicticExpression = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(futureDeicticExpression))];
    self.deicticExpressionFormat = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(deicticExpressionFormat))];
    self.approximateQualifierFormat = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(approximateQualifierFormat))];
    self.presentTimeIntervalMargin = [aDecoder decodeDoubleForKey:NSStringFromSelector(@selector(presentTimeIntervalMargin))];
    self.usesAbbreviatedCalendarUnits = [aDecoder decodeBoolForKey:NSStringFromSelector(@selector(usesAbbreviatedCalendarUnits))];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:self.locale forKey:NSStringFromSelector(@selector(locale))];
    [aCoder encodeObject:self.pastDeicticExpression forKey:NSStringFromSelector(@selector(pastDeicticExpression))];
    [aCoder encodeObject:self.presentDeicticExpression forKey:NSStringFromSelector(@selector(presentDeicticExpression))];
    [aCoder encodeObject:self.futureDeicticExpression forKey:NSStringFromSelector(@selector(futureDeicticExpression))];
    [aCoder encodeObject:self.deicticExpressionFormat forKey:NSStringFromSelector(@selector(deicticExpressionFormat))];
    [aCoder encodeObject:self.approximateQualifierFormat forKey:NSStringFromSelector(@selector(approximateQualifierFormat))];
    [aCoder encodeDouble:self.presentTimeIntervalMargin forKey:NSStringFromSelector(@selector(presentTimeIntervalMargin))];
    [aCoder encodeBool:self.usesAbbreviatedCalendarUnits forKey:NSStringFromSelector(@selector(usesAbbreviatedCalendarUnits))];
}

@end
