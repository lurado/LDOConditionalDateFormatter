# SLConditionalDateFormatter
"today 2 hours ago" and "yesterday at 4 PM" in one formatter

[![Version](https://img.shields.io/cocoapods/v/SLConditionalDateFormatter.svg?style=flat)](http://cocoapods.org/pods/SLConditionalDateFormatter)
[![License](https://img.shields.io/cocoapods/l/SLConditionalDateFormatter.svg?style=flat)](http://cocoapods.org/pods/SLConditionalDateFormatter)
[![Platform](https://img.shields.io/cocoapods/p/SLConditionalDateFormatter.svg?style=flat)](http://cocoapods.org/pods/SLConditionalDateFormatter)

## Quick Start

```objc
[formatter addFormat:@"R" forTimeInterval:-3600];
[formatter addFormat:@"{HH:mm}" for:SLTimeUnitToday];
[formatter addFormat:@"I" for:SLTimeUnitYesterday];
[formatter addFormat:@"R" forLast:7 unit:SLTimeUnitDays];
formatter.defaultFormat = @"{yMd}";

result = [self.formatter stringForTimeIntervalFromDate:minutesAgo toReferenceDate:now];     // 42 minutes ago
result = [self.formatter stringForTimeIntervalFromDate:earlierToday toReferenceDate:now];   // 13:37
result = [self.formatter stringForTimeIntervalFromDate:yesterday toReferenceDate:now];      // yesterday
result = [self.formatter stringForTimeIntervalFromDate:threeDaysAgo toReferenceDate:now];   // 3 days ago
result = [self.formatter stringForTimeIntervalFromDate:longAgo toReferenceDate:now];        // 2/11/2015
```

## String generation

- `(NSString *)stringForTimeIntervalFromDate:(NSDate *)date toReferenceDate:(NSDate *)referenceDate`
	
	Formats the given date. For relative and idiomatic formats, the time difference between the given date and the reference date is used.

- `(NSString *)stringForTimeIntervalFromDate:(NSDate *)date`

	Also formats the given date. The current date is used as reference date.
	
- `(NSString *)stringForTimeInterval:(NSTimeInterval)seconds`

	The given time interval is interpreted as offset from now. The calculated date is formatted. The current date is used as reference date.

## Supported Formats

- `I` for idiomatic expressions like "yesterday" or "next month"
- `R` for relative expressions like "2 weeks ago" or "1 day from now"
- `RRRR` repeat up to 7 `R` to specify the number of significant units. `RR` yields expressions like "2 days 13 hours ago"
- `~R` prepend `~` to any `R` format to add an approximate qualifier as in "about 4 hours ago", if the time difference isn't exact
- `{HH:mm}` for usual date formatting. You can use anything you'd normally set on `[NSDateFormatter -setDateFormat:]`. Unlike `I` and `R`, these patterns need to be wrapped in curly braces.
- `{hm}` for date formatting templates. Date formatting patterns that only consists of placeholders (no colons, spaces etc) will be used as template. Templates are converted to date formats using `[NSDateFormatter
+dateFormatFromTemplate:options:locale:]` with regard to the set locale.

## Format management

Formats can be added using one of four flavours.

1. `addFormat:(NSString *)format forTimeInterval:(NSTimeInterval)timeInterval`
	
	Adds a format to be used if the difference between a date and the reference date lies in the given time interval.

2. `addFormat:(NSString *)format for:(SLTimeUnit)unit`

	 Adds a format to be used for a specific time unit. The time unit needs to be a relative time unit like `SLTimeUnitToday`, `SLTimeUnitSameWeek` or `SLTimeNextYear`. Check out the header for a complete list.

3. `addFormat:(NSString *)format forLast:(NSUInteger)count unit:(SLTimeUnit)unit`

	Adds a format for a relative time span in the past. The time unit should be `SLTimeUnitDays`, `SLTimeUnitWeeks`, `SLTimeUnitMonths` or `SLTimeUnitYears`.

4. `addFormat:(NSString *)format forNext:(NSUInteger)count unit:(SLTimeUnit)unit`

	Same as 3., but for a time span in the future.


The formats are checked in the same order they are added. If two formats satisfy the condition for a date, the date will be formatted with the one added first. Only one format will be applied.

If no format matches the condition for a given date, a default format will be used (if specified).


## Examples

The pod contains a bunch of unit tests trying to prove things work as they should. They are also good to illustrate the usage. To run them, clone the repo, and run `pod install` from the Example directory first.

## Installation

SLConditionalDateFormatter is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "SLConditionalDateFormatter"
```

## Alternatives

Based on @mattt's work on [FormatterKit](https://github.com/mattt/FormatterKit) and everybody who contributed there. Go check it out, maybe it better suits your needs.

## Author

Sebastian Ludwig, sebastian@lurado.de

## License

SLConditionalDateFormatter is available under the MIT license. See the LICENSE file for more info.
