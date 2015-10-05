//
//  LDOConditionalDateFormatter.m
//  Pods
//
//  Created by Sebastian Ludwig on 31.07.15.
//
//

#import "LDOConditionalDateFormatter.h"


@interface LDODateRelationship : NSObject

@property (readonly, copy) NSDate *date;
@property (readonly, copy) NSDate *referenceDate;

@property (readonly) NSTimeInterval timeIntervalSinceReferenceDate;
@property (readonly, getter=isInPast) BOOL inPast;
@property (readonly, getter=isInFuture) BOOL inFuture;

@property (readonly) NSInteger daysDifference;
@property (readonly) NSInteger weeksDifference;
@property (readonly) NSInteger monthsDifference;
@property (readonly) NSInteger yearsDifference;

@property (readonly, getter=isSameDay) BOOL sameDay;
@property (readonly, getter=isPreviousDay) BOOL previousDay;
@property (readonly, getter=isNextDay) BOOL nextDay;

@property (readonly, getter=isSameYear) BOOL sameYear;
@property (readonly, getter=isPreviousYear) BOOL previousYear;
@property (readonly, getter=isNextYear) BOOL nextYear;

@property (readonly, getter=isSameMonth) BOOL sameMonth;
@property (readonly, getter=isPreviousMonth) BOOL previousMonth;
@property (readonly, getter=isNextMonth) BOOL nextMonth;

@property (readonly, getter=isSameWeek) BOOL sameWeek;
@property (readonly, getter=isPreviousWeek) BOOL previousWeek;
@property (readonly, getter=isNextWeek) BOOL nextWeek;

- (instancetype)initWithDate:(NSDate *)date referenceDate:(NSDate *)referenceDate calendar:(NSCalendar *)calendar;

@end

@implementation LDODateRelationship

+ (NSDateComponents *)componentsWithoutTime:(NSDate *)date calendar:(NSCalendar *)calendar
{
    NSCalendarUnit units = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekOfYear | NSCalendarUnitDay | NSCalendarUnitWeekday;
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
        _daysDifference = [calendar components:NSCalendarUnitDay fromDate:referenceDate toDate:date options:0].day;
        _weeksDifference = [calendar components:NSCalendarUnitWeekOfYear fromDate:referenceDate toDate:date options:0].weekOfYear;
        _monthsDifference = [calendar components:NSCalendarUnitMonth fromDate:referenceDate toDate:date options:0].month;
        _yearsDifference = [calendar components:NSCalendarUnitYear fromDate:referenceDate toDate:date options:0].year;
        
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

- (BOOL)isSameDay
{
    return _daysDifference == 0;
}

- (BOOL)isPreviousDay
{
    return _daysDifference == -1;
}

- (BOOL)isNextDay
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


static NSComparisonResult NSCalendarUnitCompareSignificance(NSCalendarUnit a, NSCalendarUnit b)
{
    if ((a == NSCalendarUnitWeekOfYear && b != NSCalendarUnitWeekOfYear) ||
        (a != NSCalendarUnitWeekOfYear && b == NSCalendarUnitWeekOfYear)) {
        if (b == NSCalendarUnitWeekOfYear) {
            switch (a) {
                case NSCalendarUnitYear:
                case NSCalendarUnitMonth:
                    return NSOrderedDescending;
                default:
                    return NSOrderedAscending;
            }
        } else {
            switch (b) {
                case NSCalendarUnitYear:
                case NSCalendarUnitMonth:
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

typedef BOOL (^FormatCondition)(LDODateRelationship *relationship);

@implementation LDOConditionalDateFormatter
{
    NSDateFormatter *dateFormatter;
    NSMutableArray *rules;
    NSDictionary *defaultFormat;
}

+ (NSString *)localizedString:(NSString *)key
{
    static NSString *notFound = @"--localizationKeyNotFound--";
    static NSBundle *assetsBundle = nil;
    if (assetsBundle == nil) {
        NSURL *resourcesURL = [[NSBundle bundleForClass:self] URLForResource:@"LDOConditionalDateFormatter" withExtension:@"bundle"];
        assetsBundle = [NSBundle bundleWithURL:resourcesURL];
    }
    NSString *defaultString = [assetsBundle localizedStringForKey:key value:notFound table:@"LDOConditionalDateFormatter"];
    
    NSString *result = [[NSBundle mainBundle] localizedStringForKey:key value:defaultString table:nil];
    
    return [result isEqualToString:notFound] ? nil : result;
}

- (id)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    rules = [NSMutableArray array];
    _calendar = [NSCalendar currentCalendar];
    dateFormatter = [NSDateFormatter new];
    dateFormatter.calendar = _calendar;
    dateFormatter.locale = _calendar.locale;
    dateFormatter.timeZone = _calendar.timeZone;
    
    _pastDeicticExpression = [self.class localizedString:@"ago"];
    _presentDeicticExpression = [self.class localizedString:@"just now"];
    _futureDeicticExpression = [self.class localizedString:@"from now"];
    
    _deicticExpressionFormat = [self.class localizedString:@"Deictic Expression Format String"];
    _approximateQualifierFormat = [self.class localizedString:@"about %@"];
    _suffixExpressionFormat = [self.class localizedString:@"Suffix Expression Format String"];
    
    _presentTimeIntervalMargin = 1;
    
    _significantUnits = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekOfYear | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    _leastSignificantUnit = NSCalendarUnitSecond;
    
    return self;
}

- (NSLocale *)locale
{
    return _calendar.locale;
}

- (void)setLocale:(NSLocale *)locale
{
    _calendar.locale = locale;
    dateFormatter.locale = locale;
}

- (NSTimeZone *)timeZone
{
    return _calendar.timeZone;
}

- (void)setTimeZone:(NSTimeZone *)timeZone
{
    _calendar.timeZone = timeZone;
    dateFormatter.timeZone = timeZone;
}

- (void)setCalendar:(NSCalendar *)calendar
{
    _calendar = [calendar copy];
    dateFormatter.calendar = _calendar;
    dateFormatter.timeZone = _calendar.timeZone;
    dateFormatter.locale = _calendar.locale;
}

- (void)setRules:(NSArray *)newRules
{
    rules = [newRules copy];
}

- (NSInteger)extractComponent:(NSCalendarUnit)unit from:(NSDateComponents *)components
{
    switch (unit) {
        case NSCalendarUnitYear:
            return components.year;
        case NSCalendarUnitMonth:
            return components.month;
        case NSCalendarUnitWeekOfYear:
            return components.weekOfYear;
        case NSCalendarUnitDay:
            return components.day;
        case NSCalendarUnitHour:
            return components.hour;
        case NSCalendarUnitMinute:
            return components.minute;
        case NSCalendarUnitSecond:
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

- (NSString *)defaultFormat
{
    return [defaultFormat[@"format"] copy];
}

- (void)setDefaultFormat:(NSString *)format
{
    FormatCondition check = ^BOOL(LDODateRelationship *relationship) {
        return YES;
    };
    defaultFormat = format == nil ? nil : @{@"format": [format copy], @"condition": check};
}

- (void)addFormat:(NSString *)format condition:(FormatCondition)condition
{
    [rules addObject:@{@"format": format, @"condition": condition}];
}

- (void)addFormat:(NSString *)format forTimeInterval:(NSTimeInterval)timeInterval
{
    FormatCondition check = ^BOOL(LDODateRelationship *relationship) {
        NSTimeInterval difference = relationship.timeIntervalSinceReferenceDate;
        BOOL sameSign = (difference <= 0 && timeInterval <= 0) || (difference > 0 && timeInterval >= 0);
        return sameSign && ABS(difference) <= ABS(timeInterval);
    };
    [self addFormat:format condition:check];
}

- (void)addFormat:(NSString *)format for:(LDOTimeUnit)unit
{
    FormatCondition check = ^BOOL(LDODateRelationship *relationship) {
        switch (unit) {
            case LDOTimeUnitToday:
            case LDOTimeUnitSameDay:
                return relationship.sameDay;
            case LDOTimeUnitYesterday:
            case LDOTimeUnitPreviousDay:
                return relationship.previousDay;
            case LDOTimeUnitTomorrow:
            case LDOTimeUnitNextDay:
                return relationship.nextDay;
            
            case LDOTimeUnitThisWeek:
            case LDOTimeUnitSameWeek:
                return relationship.sameWeek;
            case LDOTimeUnitLastWeek:
            case LDOTimeUnitPreviousWeek:
                return relationship.previousWeek;
            case LDOTimeUnitNextWeek:
                return relationship.nextWeek;
            
            case LDOTimeUnitThisMonth:
                return relationship.sameMonth;
            case LDOTimeUnitLastMonth:
                return relationship.previousMonth;
            case LDOTimeUnitNextMonth:
                return relationship.nextMonth;
            
            case LDOTimeUnitThisYear:
                return relationship.sameYear;
            case LDOTimeUnitLastYear:
                return relationship.previousYear;
            case LDOTimeUnitNextYear:
                return relationship.nextYear;
            default:
                break;
        }
        return NO;
    };
    
    [self addFormat:format condition:check];
}

- (void)addFormat:(NSString *)format forLast:(NSUInteger)count unit:(LDOTimeUnit)unit
{
    FormatCondition check = ^BOOL(LDODateRelationship *relationship) {
        switch (unit) {
            case LDOTimeUnitDays: return relationship.daysDifference <= 0 && relationship.daysDifference >= -count;
            case LDOTimeUnitWeeks: return relationship.weeksDifference <= 0 && relationship.weeksDifference >= -count;
            case LDOTimeUnitMonths: return relationship.monthsDifference <= 0 && relationship.monthsDifference >= -count;
            case LDOTimeUnitYears: return relationship.yearsDifference <= 0 && relationship.yearsDifference >= -count;
            default:
                break;
        }
        return NO;
    };
    
    [self addFormat:format condition:check];
}

- (void)addFormat:(NSString *)format forNext:(NSUInteger)count unit:(LDOTimeUnit)unit
{
    FormatCondition check = ^BOOL(LDODateRelationship *relationship) {
        switch (unit) {
            case LDOTimeUnitDays:
                return relationship.daysDifference >= 0 && relationship.daysDifference <= count;
            case LDOTimeUnitWeeks:
                return relationship.weeksDifference >= 0 && relationship.weeksDifference <= count;
            case LDOTimeUnitMonths:
                return relationship.monthsDifference >= 0 && relationship.monthsDifference <= count;
            case LDOTimeUnitYears:
                return relationship.yearsDifference >= 0 && relationship.yearsDifference <= count;
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
    // use for offset calculation _and_ reference to ensure no second wrap occurs between two [NSDate date] calls
    NSDate *now = [NSDate date];
    return [self stringForTimeIntervalFromDate:[now dateByAddingTimeInterval:seconds] toReferenceDate:now];
}

- (NSString *)stringForTimeIntervalFromDate:(NSDate *)date
{
    return [self stringForTimeIntervalFromDate:date toReferenceDate:[NSDate date]];
}

- (NSString *)stringForTimeIntervalFromDate:(NSDate *)date toReferenceDate:(NSDate *)referenceDate
{
    LDODateRelationship *dateRelationship = [[LDODateRelationship alloc] initWithDate:date referenceDate:referenceDate calendar:self.calendar];
    
    NSArray *applicableRules = defaultFormat ? [rules arrayByAddingObject:defaultFormat] : rules;
    
    for (NSDictionary *rule in applicableRules ) {
        FormatCondition check = rule[@"condition"];
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

#pragma mark Helpers

+ (NSString *)boundaryCharacterWrappedPattern:(NSString *)pattern
{
    NSString *boundaryCharacters = @"\\s,\\.";
    return [NSString stringWithFormat:@"(?:^|[%@])(%@)(?:$|[%@])", boundaryCharacters, pattern, boundaryCharacters];
}

- (NSString *)applyFormat:(NSString *)format toDateRelationship:(LDODateRelationship *)relationship
{
    if (!format) {
        return nil;
    }
    
    NSString *result = [format copy];
    
    result = [self.class replaceMatchesOfRegex:[self.class boundaryCharacterWrappedPattern:@"(~?)(R{1,7})"] inString:result usingBlock:^NSString *(NSString *input, NSTextCheckingResult *match) {
        BOOL approximate = [match rangeAtIndex:2].length == 1;
        NSString *replacement = [self relativeExpressionForDateRelationship:relationship numberOfSignificantUnits:[match rangeAtIndex:3].length approximate:approximate];
        if (replacement) {
            input = [input stringByReplacingCharactersInRange:[match rangeAtIndex:1] withString:replacement];
        }
        return input;
    }];
    
    result = [self.class replaceMatchesOfRegex:[self.class boundaryCharacterWrappedPattern:@"I"] inString:result usingBlock:^NSString *(NSString *input, NSTextCheckingResult *match) {
        NSString *replacement = [self idiomaticDeicticExpressionForDateRelationship:relationship];
        if (replacement) {
            input = [input stringByReplacingCharactersInRange:[match rangeAtIndex:1] withString:replacement];
        }
        return input;
    }];
    
    result = [self.class replaceMatchesOfRegex:@"\\{([cdeghjklmqrsuvwxyzADEFGHJKLMOQSUVWXYZ]*?)\\}" inString:result usingBlock:^NSString *(NSString *input, NSTextCheckingResult *match) {
        NSRange templateRange = [match rangeAtIndex:1];
        NSString *template = [input substringWithRange:templateRange];
        NSString *replacement = [NSDateFormatter dateFormatFromTemplate:template options:0 locale:self.calendar.locale];
        if (replacement) {
            input = [input stringByReplacingCharactersInRange:templateRange withString:replacement];
        }
        return input;
    }];
    
    result = [self.class replaceMatchesOfRegex:@"\\{(.*?)\\}" inString:result usingBlock:^NSString *(NSString *input, NSTextCheckingResult *match) {
        dateFormatter.dateFormat = [input substringWithRange:[match rangeAtIndex:1]];
        NSString *replacement = [dateFormatter stringFromDate:relationship.date];
        if (replacement) {
            input = [input stringByReplacingCharactersInRange:match.range withString:replacement];
        }
        return input;
    }];
    
    return [result isEqualToString:format] ? nil : result;
}

+ (NSString *)replaceMatchesOfRegex:(NSString *)pattern inString:(NSString *)string usingBlock:(NSString* (^)(NSString *input, NSTextCheckingResult* match))block {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    NSArray *matches = [regex matchesInString:string options:0 range:NSMakeRange(0, string.length)];
    for (NSTextCheckingResult *match in [matches reverseObjectEnumerator]) {
        string = block(string, match);
    }
    return string;
}

#pragma mark - Relative and idiomatic

- (NSString *)relativeExpressionForDateRelationship:(LDODateRelationship *)relationship numberOfSignificantUnits:(NSUInteger)numberOfSignificantUnits approximate:(BOOL)approximate
{
    NSDateComponents *components = [self.calendar components:self.significantUnits fromDate:relationship.referenceDate toDate:relationship.date options:0];
    NSString *string = nil;
    BOOL isApproximate = NO;
    NSUInteger numberOfUnits = 0;
    for (NSNumber *unitWrapper in @[@(NSCalendarUnitYear), @(NSCalendarUnitMonth), @(NSCalendarUnitWeekOfYear), @(NSCalendarUnitDay), @(NSCalendarUnitHour), @(NSCalendarUnitMinute), @(NSCalendarUnitSecond)]) {
        NSCalendarUnit unit = [unitWrapper unsignedLongValue];
        if ([self shouldUseUnit:unit]) {
            BOOL reportOnlyDays = unit == NSCalendarUnitDay && numberOfSignificantUnits == 1;
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
        if (relationship.inPast) {
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
            case NSCalendarUnitYear:
                return singular ? [self.class localizedString:@"yr"] : [self.class localizedString:@"yrs"];
            case NSCalendarUnitMonth:
                return singular ? [self.class localizedString:@"mo"] : [self.class localizedString:@"mos"];
            case NSCalendarUnitWeekOfYear:
                return singular ? [self.class localizedString:@"wk"] : [self.class localizedString:@"wks"];
            case NSCalendarUnitDay:
                return singular ? [self.class localizedString:@"d"] : [self.class localizedString:@"ds"];
            case NSCalendarUnitHour:
                return singular ? [self.class localizedString:@"hr"] : [self.class localizedString:@"hrs"];
            case NSCalendarUnitMinute:
                return singular ? [self.class localizedString:@"min"] : [self.class localizedString:@"mins"];
            case NSCalendarUnitSecond:
                return singular ? [self.class localizedString:@"s"] : [self.class localizedString:@"s"];
            default:
                return nil;
        }
    } else {
        switch (unit) {
            case NSCalendarUnitYear:
                return singular ? [self.class localizedString:@"year"] : [self.class localizedString:@"years"];
            case NSCalendarUnitMonth:
                return singular ? [self.class localizedString:@"month"] : [self.class localizedString:@"months"];
            case NSCalendarUnitWeekOfYear:
                return singular ? [self.class localizedString:@"week"] : [self.class localizedString:@"weeks"];
            case NSCalendarUnitDay:
                return singular ? [self.class localizedString:@"day"] : [self.class localizedString:@"days"];
            case NSCalendarUnitHour:
                return singular ? [self.class localizedString:@"hour"] : [self.class localizedString:@"hours"];
            case NSCalendarUnitMinute:
                return singular ? [self.class localizedString:@"minute"] : [self.class localizedString:@"minutes"];
            case NSCalendarUnitSecond:
                return singular ? [self.class localizedString:@"second"] : [self.class localizedString:@"seconds"];
            default:
                return nil;
        }
    }
}

#pragma mark -

- (NSString *)idiomaticDeicticExpressionForDateRelationship:(LDODateRelationship *)relationship
{
    if (fabs(relationship.timeIntervalSinceReferenceDate) <= self.presentTimeIntervalMargin) {
        return self.presentDeicticExpression;
    }

    if ([self shouldUseUnit:NSCalendarUnitDay]) {
        if (relationship.sameDay) {
            return [self.class localizedString:@"today"];
        }
        if (relationship.previousDay) {
            return [self.class localizedString:@"yesterday"];
        }
        if (relationship.nextDay) {
            return [self.class localizedString:@"tomorrow"];
        }
        
        // optional
        if (relationship.daysDifference == -2) {
            NSString *result = [self.class localizedString:@"day before yesterday"];
            if (result) {
                return result;
            }
        }
        if (relationship.daysDifference == 2) {
            NSString *result = [self.class localizedString:@"day after tomorrow"];
            if (result) {
                return result;
            }
        }
    }
    
    if ([self shouldUseUnit:NSCalendarUnitWeekOfYear]) {
        if (relationship.sameWeek) {
            return [self.class localizedString:@"this week"];
        }
        if (relationship.previousWeek) {
            return [self.class localizedString:@"last week"];
        }
        if (relationship.nextWeek) {
            return [self.class localizedString:@"next week"];
        }
        
        // optional
        if (relationship.weeksDifference == -2) {
            NSString *result = [self.class localizedString:@"week before last week"];
            if (result) {
                return result;
            }
        }
        if (relationship.weeksDifference == 2) {
            NSString *result = [self.class localizedString:@"week after next week"];
            if (result) {
                return result;
            }
        }
    }

    if ([self shouldUseUnit:NSCalendarUnitMonth]) {
        if (relationship.sameMonth) {
            return [self.class localizedString:@"this month"];
        }
        if (relationship.previousMonth) {
            return [self.class localizedString:@"last month"];
        }
        if (relationship.nextMonth) {
            return [self.class localizedString:@"next month"];
        }
        
        // optional
        if (relationship.monthsDifference == -2) {
            NSString *result = [self.class localizedString:@"month before last month"];
            if (result) {
                return result;
            }
        }
        if (relationship.monthsDifference == 2) {
            NSString *result = [self.class localizedString:@"month after next month"];
            if (result) {
                return result;
            }
        }
    }
    
    if ([self shouldUseUnit:NSCalendarUnitYear]) {
        if (relationship.sameYear) {
            return [self.class localizedString:@"this year"];
        }
        if (relationship.previousYear) {
            return [self.class localizedString:@"last year"];
        }
        if (relationship.nextYear) {
            return [self.class localizedString:@"next year"];
        }
        
        // optional
        if (relationship.yearsDifference == -2) {
            NSString *result = [self.class localizedString:@"year before last year"];
            if (result) {
                return result;
            }
        }
        if (relationship.yearsDifference == 2) {
            NSString *result = [self.class localizedString:@"year after next year"];
            if (result) {
                return result;
            }
        }
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
    *error = [self.class localizedString:@"Method Not Implemented"];
    
    return NO;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    LDOConditionalDateFormatter *formatter = [[[self class] allocWithZone:zone] init];
    
    formatter.calendar = [self.calendar copyWithZone:zone];
    formatter.pastDeicticExpression = [self.pastDeicticExpression copyWithZone:zone];
    formatter.presentDeicticExpression = [self.presentDeicticExpression copyWithZone:zone];
    formatter.futureDeicticExpression = [self.futureDeicticExpression copyWithZone:zone];
    formatter.deicticExpressionFormat = [self.deicticExpressionFormat copyWithZone:zone];
    formatter.suffixExpressionFormat = [self.suffixExpressionFormat copyWithZone:zone];
    formatter.presentTimeIntervalMargin = self.presentTimeIntervalMargin;
    formatter.approximateQualifierFormat = [self.approximateQualifierFormat copyWithZone:zone];
    formatter.significantUnits = self.significantUnits;
    formatter.leastSignificantUnit = self.leastSignificantUnit;
    formatter.usesAbbreviatedCalendarUnits = self.usesAbbreviatedCalendarUnits;
    formatter.defaultFormat = [self.defaultFormat copyWithZone:zone];
    
    [formatter setRules:[rules copyWithZone:zone]];
    
    return formatter;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (!self) {
        return nil;
    }
    
    dateFormatter = [NSDateFormatter new];
    
    self.calendar = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(calendar))];
    self.pastDeicticExpression = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(pastDeicticExpression))];
    self.presentDeicticExpression = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(presentDeicticExpression))];
    self.futureDeicticExpression = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(futureDeicticExpression))];
    
    self.deicticExpressionFormat = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(deicticExpressionFormat))];
    self.suffixExpressionFormat = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(suffixExpressionFormat))];
    
    self.presentTimeIntervalMargin = [aDecoder decodeDoubleForKey:NSStringFromSelector(@selector(presentTimeIntervalMargin))];
    self.approximateQualifierFormat = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(approximateQualifierFormat))];
    
    self.significantUnits = [aDecoder decodeIntForKey:NSStringFromSelector(@selector(significantUnits))];
    self.leastSignificantUnit = [aDecoder decodeIntForKey:NSStringFromSelector(@selector(leastSignificantUnit))];
    
    self.usesAbbreviatedCalendarUnits = [aDecoder decodeBoolForKey:NSStringFromSelector(@selector(usesAbbreviatedCalendarUnits))];
    self.defaultFormat = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(defaultFormat))];
    
    rules = [aDecoder decodeObjectForKey:@"rules"];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:self.calendar forKey:NSStringFromSelector(@selector(calendar))];
    [aCoder encodeObject:self.pastDeicticExpression forKey:NSStringFromSelector(@selector(pastDeicticExpression))];
    [aCoder encodeObject:self.presentDeicticExpression forKey:NSStringFromSelector(@selector(presentDeicticExpression))];
    [aCoder encodeObject:self.futureDeicticExpression forKey:NSStringFromSelector(@selector(futureDeicticExpression))];
    [aCoder encodeObject:self.deicticExpressionFormat forKey:NSStringFromSelector(@selector(deicticExpressionFormat))];
    
    [aCoder encodeObject:self.suffixExpressionFormat forKey:NSStringFromSelector(@selector(suffixExpressionFormat))];
    [aCoder encodeDouble:self.presentTimeIntervalMargin forKey:NSStringFromSelector(@selector(suffixExpressionFormat))];
    [aCoder encodeObject:self.approximateQualifierFormat forKey:NSStringFromSelector(@selector(approximateQualifierFormat))];
    
    [aCoder encodeInt:self.significantUnits forKey:NSStringFromSelector(@selector(significantUnits))];
    [aCoder encodeInt:self.leastSignificantUnit forKey:NSStringFromSelector(@selector(leastSignificantUnit))];
    
    [aCoder encodeBool:self.usesAbbreviatedCalendarUnits forKey:NSStringFromSelector(@selector(usesAbbreviatedCalendarUnits))];
    [aCoder encodeObject:self.defaultFormat forKey:NSStringFromSelector(@selector(defaultFormat))];
    
    [aCoder encodeObject:rules forKey:@"rules"];
}

@end
