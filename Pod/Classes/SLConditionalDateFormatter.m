//
//  SLConditionalDateFormatter.m
//  Pods
//
//  Created by Sebastian Ludwig on 31.07.15.
//
//

#import "SLConditionalDateFormatter.h"


#if (defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000) || (defined(__MAC_OS_X_VERSION_MAX_ALLOWED) && __MAC_OS_X_VERSION_MAX_ALLOWED >= 1090)
#define TTTCalendarUnitYear NSCalendarUnitYear
#define TTTCalendarUnitMonth NSCalendarUnitMonth
#define TTTCalendarUnitWeek NSCalendarUnitWeekOfYear
#define TTTCalendarUnitDay NSCalendarUnitDay
#define TTTCalendarUnitHour NSCalendarUnitHour
#define TTTCalendarUnitMinute NSCalendarUnitMinute
#define TTTCalendarUnitSecond NSCalendarUnitSecond
#define TTTCalendarUnitWeekday NSCalendarUnitWeekday
#define TTTDateComponentUndefined NSDateComponentUndefined
#else
#define TTTCalendarUnitYear NSYearCalendarUnit
#define TTTCalendarUnitMonth NSMonthCalendarUnit
#define TTTCalendarUnitWeek NSWeekOfYearCalendarUnit
#define TTTCalendarUnitDay NSDayCalendarUnit
#define TTTCalendarUnitHour NSHourCalendarUnit
#define TTTCalendarUnitMinute NSMinuteCalendarUnit
#define TTTCalendarUnitSecond NSSecondCalendarUnit
#define TTTCalendarUnitWeekday NSWeekdayCalendarUnit
#define TTTDateComponentUndefined NSUndefinedDateComponent
#endif

@interface SLDateRelationship : NSObject

@property (readonly, copy) NSDate *date;
@property (readonly, copy) NSDate *referenceDate;

@property (readonly) NSTimeInterval timeIntervalSinceReferenceDate;
@property (readonly) BOOL isInPast;
@property (readonly) BOOL isInFuture;

@property (readonly) NSInteger daysDifference;

@property (readonly) BOOL sameDay;
@property (readonly) BOOL perviousDay;
@property (readonly) BOOL nextDay;

@property (readonly) BOOL sameYear;
@property (readonly) BOOL previousYear;
@property (readonly) BOOL nextYear;

@property (readonly) BOOL sameMonth;
@property (readonly) BOOL previousMonth;
@property (readonly) BOOL nextMonth;

@property (readonly) BOOL previousWeek;
@property (readonly) BOOL nextWeek;

- (instancetype)initWithDate:(NSDate *)date referenceDate:(NSDate *)referenceDate calendar:(NSCalendar *)calendar;

@end

@implementation SLDateRelationship

+ (NSDateComponents *)componentsWithoutTime:(NSDate *)date calendar:(NSCalendar *)calendar
{
    NSCalendarUnit units = TTTCalendarUnitYear | TTTCalendarUnitMonth | TTTCalendarUnitWeek | TTTCalendarUnitDay | TTTCalendarUnitWeekday;
    return [calendar components:units fromDate:date];
}

+ (NSInteger)numberOfDaysFrom:(NSDate *)fromDate to:(NSDate *)toDate calendar:(NSCalendar *)calendar
{
    NSDateComponents *fromComponents = [self componentsWithoutTime:fromDate calendar:calendar];
    NSDateComponents *toComponents = [self componentsWithoutTime:toDate calendar:calendar];
    fromDate = [calendar dateFromComponents:fromComponents];
    toDate = [calendar dateFromComponents:toComponents];
    
    return [calendar components:TTTCalendarUnitDay fromDate:fromDate toDate:toDate options:0].day;
}

- (instancetype)initWithDate:(NSDate *)date referenceDate:(NSDate *)referenceDate calendar:(NSCalendar *)calendar
{
    if (self = [super init]) {
        _referenceDate = referenceDate;
        _date = date;
        
        NSDateComponents *startingComponents = [self.class componentsWithoutTime:referenceDate calendar:calendar];
        NSDateComponents *endingComponents = [self.class componentsWithoutTime:date calendar:calendar];
        
        _daysDifference = [self.class numberOfDaysFrom:referenceDate to:date calendar:calendar];
        
        _sameYear = startingComponents.year == endingComponents.year;
        _previousYear = startingComponents.year - 1 == endingComponents.year;
        _nextYear = startingComponents.year + 1 == endingComponents.year;
        
        _sameMonth = _sameYear && startingComponents.month == endingComponents.month;
        _previousMonth = (_sameYear && startingComponents.month - 1 == endingComponents.month) || (_previousYear && startingComponents.month == 1 && endingComponents.month == 12);
        _nextMonth = (_sameYear && startingComponents.month + 1 == endingComponents.month) || (_nextYear && startingComponents.month == 12 && endingComponents.month == 1);
        
        long numberOfWeeks = MAX(MAX(startingComponents.weekOfYear, endingComponents.weekOfYear), 52);
        BOOL precedingWeekNumber = (endingComponents.weekOfYear % numberOfWeeks) + 1 == startingComponents.weekOfYear;
        BOOL succeedingWeekNumber = (startingComponents.weekOfYear % numberOfWeeks) + 1 == endingComponents.weekOfYear;
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
    if ((a == TTTCalendarUnitWeek) ^ (b == TTTCalendarUnitWeek)) {
        if (b == TTTCalendarUnitWeek) {     // TODO: check https://github.com/mattt/FormatterKit/pull/186
            switch (a) {
                case TTTCalendarUnitYear:
                case TTTCalendarUnitMonth:
                    return NSOrderedDescending;
                default:
                    return NSOrderedAscending;
            }
        } else {
            switch (b) {
                case TTTCalendarUnitYear:
                case TTTCalendarUnitMonth:
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

typedef BOOL (^RuleCondition)(SLDateRelationship *relationship);

@implementation SLConditionalDateFormatter
{
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
    self.locale = [NSLocale currentLocale];
    self.calendar = [NSCalendar currentCalendar];
    
    self.pastDeicticExpression = NSLocalizedStringFromTable(@"ago", @"FormatterKit", @"Past Deictic Expression");
    self.presentDeicticExpression = NSLocalizedStringFromTable(@"just now", @"FormatterKit", @"Present Deictic Expression");
    self.futureDeicticExpression = NSLocalizedStringFromTable(@"from now", @"FormatterKit", @"Future Deictic Expression");
    
    self.deicticExpressionFormat = NSLocalizedStringWithDefaultValue(@"Deictic Expression Format String", @"FormatterKit", [NSBundle mainBundle], @"%@ %@", @"Deictic Expression Format (#{Time} #{Ago/From Now}");
    self.approximateQualifierFormat = NSLocalizedStringFromTable(@"about %@", @"FormatterKit", @"Approximate Qualifier Format");
    self.suffixExpressionFormat = NSLocalizedStringWithDefaultValue(@"Suffix Expression Format String", @"FormatterKit", [NSBundle mainBundle], @"%@ %@", @"Suffix Expression Format (#{Time} #{Unit})");
    
    self.presentTimeIntervalMargin = 1;
    
    self.significantUnits = TTTCalendarUnitYear | TTTCalendarUnitMonth | TTTCalendarUnitWeek | TTTCalendarUnitDay | TTTCalendarUnitHour | TTTCalendarUnitMinute | TTTCalendarUnitSecond;
    self.leastSignificantUnit = TTTCalendarUnitSecond;
    
    return self;
}

- (NSInteger)extractComponent:(NSCalendarUnit)unit from:(NSDateComponents *)components
{
    switch (unit) {
        case TTTCalendarUnitYear:
            return components.year;
        case TTTCalendarUnitMonth:
            return components.month;
        case TTTCalendarUnitWeek:
            return components.weekOfYear;
        case TTTCalendarUnitDay:
            return components.day;
        case TTTCalendarUnitHour:
            return components.hour;
        case TTTCalendarUnitMinute:
            return components.minute;
        case TTTCalendarUnitSecond:
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
    RuleCondition check = ^BOOL(SLDateRelationship *relationship) {
        return YES;
    };
    defaultFormat = format == nil ? nil : @{@"format": [format copy], @"condtion": check};
}

- (void)addFormat:(NSString *)format forTimeInterval:(NSTimeInterval)timeInterval
{
    RuleCondition check = ^BOOL(SLDateRelationship *relationship) {
        NSTimeInterval difference = relationship.timeIntervalSinceReferenceDate;
        BOOL sameSign = (difference <= 0 && timeInterval <= 0) || (difference > 0 && timeInterval >= 0);
        return sameSign && ABS(difference) <= ABS(timeInterval);
    };
    [rules addObject:@{@"format": format, @"condtion": check}];
}

- (void)addFormat:(NSString *)format for:(SLTimeUnit)unit
{
    
}

- (void)addFormat:(NSString *)format forLast:(NSUInteger)count unit:(SLTimeUnit)unit
{
    
}

- (void)addFormat:(NSString *)format forNext:(NSUInteger)count unit:(SLTimeUnit)unit
{
    
}

#pragma mark - interface methods

- (NSString *)stringForTimeInterval:(NSTimeInterval)seconds
{
    NSDate *now = [NSDate date];
    return [self stringForTimeIntervalFromDate:[now dateByAddingTimeInterval:seconds] toReferenceDate:now];
}

- (NSString *)stringForTimeIntervalFromDate:(NSDate *)date toReferenceDate:(NSDate *)referenceDate
{
    SLDateRelationship *dateRelationship = [[SLDateRelationship alloc] initWithDate:date referenceDate:referenceDate calendar:self.calendar];
    
    if (fabs(dateRelationship.timeIntervalSinceReferenceDate) < self.presentTimeIntervalMargin) {
        return self.presentDeicticExpression;       // move to idiomaticDeicticExpression
    }
    
    NSArray *applicableRules = defaultFormat ? [rules arrayByAddingObject:defaultFormat] : rules;
    for (NSDictionary *rule in applicableRules ) {
        RuleCondition check = rule[@"condtion"];
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

- (NSRegularExpression *)boundaryCharacterWrappedRegexp:(NSString *)regexp
{
    NSString *boundaryCharacters = @"\\s,\\.";
    NSString *pattern = [NSString stringWithFormat:@"(?:^|[%@])(%@)(?:$|[%@])", boundaryCharacters, regexp, boundaryCharacters];
    return [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
}

- (NSString *)applyFormat:(NSString *)format toDateRelationship:(SLDateRelationship *)relationship
{
    if (!format) {
        return nil;
    }
    
    NSRegularExpression *relativeRegex = [self boundaryCharacterWrappedRegexp:@"R{1,8}"];
    NSTextCheckingResult *relativeResult = [relativeRegex firstMatchInString:format options:0 range:NSMakeRange(0, format.length)];
    
    NSRegularExpression *idiomaticRegex = [self boundaryCharacterWrappedRegexp:@"I"];
    NSTextCheckingResult *idiomaticResult = [idiomaticRegex firstMatchInString:format options:0 range:NSMakeRange(0, format.length)];
    
    
    NSString *result = [format copy];
    if (relativeResult && relativeResult.range.location != NSNotFound) {
        NSString *replacement = [self relativeExpressionForDateRelationship:relationship numberOfSignificantUnits:relativeResult.range.length];
        if (replacement) {
            result = [result stringByReplacingCharactersInRange:[relativeResult rangeAtIndex:1] withString:replacement];
        }
    }
    if (idiomaticResult && idiomaticResult.range.location != NSNotFound) {
        NSString *replacement = [self idiomaticDeicticExpressionForDateRelationship:relationship];
        if (replacement) {
            result = [result stringByReplacingCharactersInRange:[idiomaticResult rangeAtIndex:1] withString:replacement];
        }
    }
    
    return [result isEqualToString:format] ? nil : result;
}

#pragma mark - Transformations

- (NSString *)relativeExpressionForDateRelationship:(SLDateRelationship *)relationship numberOfSignificantUnits:(NSUInteger)numberOfSignificantUnits
{
    NSDateComponents *components = [self.calendar components:self.significantUnits fromDate:relationship.referenceDate toDate:relationship.date options:0];
    NSString *string = nil;
    BOOL isApproximate = NO;
    NSUInteger numberOfUnits = 0;
    for (NSNumber *unitWrapper in @[@(TTTCalendarUnitYear), @(TTTCalendarUnitMonth), @(TTTCalendarUnitWeek), @(TTTCalendarUnitDay), @(TTTCalendarUnitHour), @(TTTCalendarUnitMinute), @(TTTCalendarUnitSecond)]) {
        NSCalendarUnit unit = [unitWrapper unsignedLongValue];
        if ([self shouldUseUnit:unit]) {
            BOOL reportOnlyDays = unit == TTTCalendarUnitDay && numberOfSignificantUnits == 1;
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
                }
                
                numberOfUnits++;    // TODO: break
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
        
        if (isApproximate && self.usesApproximateQualifier) {
            string = [NSString stringWithFormat:self.approximateQualifierFormat, string];
        }
    } else {
        string = self.presentDeicticExpression;     // this default is wrong - rather raise an error or return nil
    }
    
    return string;
}

- (NSString *)localizedStringForNumber:(NSUInteger)number ofCalendarUnit:(NSCalendarUnit)unit
{
    BOOL singular = (number == 1);
    
    if (self.usesAbbreviatedCalendarUnits) {
        switch (unit) {
            case TTTCalendarUnitYear:
                return singular ? NSLocalizedStringFromTable(@"yr", @"FormatterKit", @"Year Unit (Singular, Abbreviated)") : NSLocalizedStringFromTable(@"yrs", @"FormatterKit", @"Year Unit (Plural, Abbreviated)");
            case TTTCalendarUnitMonth:
                return singular ? NSLocalizedStringFromTable(@"mo", @"FormatterKit", @"Month Unit (Singular, Abbreviated)") : NSLocalizedStringFromTable(@"mos", @"FormatterKit", @"Month Unit (Plural, Abbreviated)");
            case TTTCalendarUnitWeek:
                return singular ? NSLocalizedStringFromTable(@"wk", @"FormatterKit", @"Week Unit (Singular, Abbreviated)") : NSLocalizedStringFromTable(@"wks", @"FormatterKit", @"Week Unit (Plural, Abbreviated)");
            case TTTCalendarUnitDay:
                return singular ? NSLocalizedStringFromTable(@"d", @"FormatterKit", @"Day Unit (Singular, Abbreviated)") : NSLocalizedStringFromTable(@"ds", @"FormatterKit", @"Day Unit (Plural, Abbreviated)");
            case TTTCalendarUnitHour:
                return singular ? NSLocalizedStringFromTable(@"hr", @"FormatterKit", @"Hour Unit (Singular, Abbreviated)") : NSLocalizedStringFromTable(@"hrs", @"FormatterKit", @"Hour Unit (Plural, Abbreviated)");
            case TTTCalendarUnitMinute:
                return singular ? NSLocalizedStringFromTable(@"min", @"FormatterKit", @"Minute Unit (Singular, Abbreviated)") : NSLocalizedStringFromTable(@"mins", @"FormatterKit", @"Minute Unit (Plural, Abbreviated)");
            case TTTCalendarUnitSecond:
                return singular ? NSLocalizedStringFromTable(@"s", @"FormatterKit", @"Second Unit (Singular, Abbreviated)") : NSLocalizedStringFromTable(@"s", @"FormatterKit", @"Second Unit (Plural, Abbreviated)");
            default:
                return nil;
        }
    } else {
        switch (unit) {
            case TTTCalendarUnitYear:
                return singular ? NSLocalizedStringFromTable(@"year", @"FormatterKit", @"Year Unit (Singular)") : NSLocalizedStringFromTable(@"years", @"FormatterKit", @"Year Unit (Plural)");
            case TTTCalendarUnitMonth:
                return singular ? NSLocalizedStringFromTable(@"month", @"FormatterKit", @"Month Unit (Singular)") : NSLocalizedStringFromTable(@"months", @"FormatterKit", @"Month Unit (Plural)");
            case TTTCalendarUnitWeek:
                return singular ? NSLocalizedStringFromTable(@"week", @"FormatterKit", @"Week Unit (Singular)") : NSLocalizedStringFromTable(@"weeks", @"FormatterKit", @"Week Unit (Plural)");
            case TTTCalendarUnitDay:
                return singular ? NSLocalizedStringFromTable(@"day", @"FormatterKit", @"Day Unit (Singular)") : NSLocalizedStringFromTable(@"days", @"FormatterKit", @"Day Unit (Plural)");
            case TTTCalendarUnitHour:
                return singular ? NSLocalizedStringFromTable(@"hour", @"FormatterKit", @"Hour Unit (Singular)") : NSLocalizedStringFromTable(@"hours", @"FormatterKit", @"Hour Unit (Plural)");
            case TTTCalendarUnitMinute:
                return singular ? NSLocalizedStringFromTable(@"minute", @"FormatterKit", @"Minute Unit (Singular)") : NSLocalizedStringFromTable(@"minutes", @"FormatterKit", @"Minute Unit (Plural)");
            case TTTCalendarUnitSecond:
                return singular ? NSLocalizedStringFromTable(@"second", @"FormatterKit", @"Second Unit (Singular)") : NSLocalizedStringFromTable(@"seconds", @"FormatterKit", @"Second Unit (Plural)");
            default:
                return nil;
        }
    }
}

#pragma mark -

- (NSString *)idiomaticDeicticExpressionForDateRelationship:(SLDateRelationship *)relationship
{
    if ([self shouldUseUnit:TTTCalendarUnitDay] && relationship.previousDay) {
        return NSLocalizedStringFromTable(@"yesterday", @"FormatterKit", @"yesterday");
    }
    if ([self shouldUseUnit:TTTCalendarUnitDay] && relationship.nextDay) {
        return NSLocalizedStringFromTable(@"tomorrow", @"FormatterKit", @"tomorrow");
    }
    
    if ([self shouldUseUnit:TTTCalendarUnitWeek] && relationship.previousWeek) {
        return NSLocalizedStringFromTable(@"last week", @"FormatterKit", @"last week");
    }
    if ([self shouldUseUnit:TTTCalendarUnitWeek] && relationship.nextWeek) {
        return NSLocalizedStringFromTable(@"next week", @"FormatterKit", @"next week");
    }
    
    if ([self shouldUseUnit:TTTCalendarUnitMonth] && relationship.previousMonth) {
        return NSLocalizedStringFromTable(@"last month", @"FormatterKit", @"last month");
    }
    if ([self shouldUseUnit:TTTCalendarUnitMonth] && relationship.nextMonth) {
        return NSLocalizedStringFromTable(@"next month", @"FormatterKit", @"next month");
    }
    
    if ([self shouldUseUnit:TTTCalendarUnitYear] && relationship.previousYear) {
        return NSLocalizedStringFromTable(@"last year", @"FormatterKit", @"last year");
    }
    if ([self shouldUseUnit:TTTCalendarUnitYear] && relationship.nextYear) {
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
    formatter.usesApproximateQualifier = self.usesApproximateQualifier;
    
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
    self.usesApproximateQualifier = [aDecoder decodeBoolForKey:NSStringFromSelector(@selector(usesApproximateQualifier))];
    
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
    [aCoder encodeBool:self.usesApproximateQualifier forKey:NSStringFromSelector(@selector(usesApproximateQualifier))];
}

@end
