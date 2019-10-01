# LDOConditionalDateFormatter
"today 2 hours ago" and "yesterday at 4 PM" in one formatter

[![Version](https://img.shields.io/cocoapods/v/LDOConditionalDateFormatter.svg?style=flat)](http://cocoapods.org/pods/LDOConditionalDateFormatter)
[![License](https://img.shields.io/cocoapods/l/LDOConditionalDateFormatter.svg?style=flat)](http://cocoapods.org/pods/LDOConditionalDateFormatter)
[![Platform](https://img.shields.io/cocoapods/p/LDOConditionalDateFormatter.svg?style=flat)](http://cocoapods.org/pods/LDOConditionalDateFormatter)

## Quick Start

```objc
LDOConditionalDateFormatter *formatter = [LDOConditionalDateFormatter new];
[formatter addFormat:@"just now" forTimeInterval:-10];
[formatter addFormat:@"R" forTimeInterval:-3600];
[formatter addFormat:@"{HH:mm}" for:LDOTimeUnitToday];
[formatter addFormat:@"I" for:LDOTimeUnitYesterday];
[formatter addFormat:@"R" forLast:7 unit:LDOTimeUnitDays];
formatter.defaultFormat = @"{yMd}";

[formatter stringForTimeIntervalFromDate:secondsAgo toReferenceDate:now];
// = just now

[formatter stringForTimeIntervalFromDate:minutesAgo toReferenceDate:now];
// = 42 minutes ago

[formatter stringForTimeIntervalFromDate:earlierToday toReferenceDate:now];
// = 13:37

[formatter stringForTimeIntervalFromDate:yesterday toReferenceDate:now];
// = yesterday

[formatter stringForTimeIntervalFromDate:threeDaysAgo toReferenceDate:now];
// = 3 days ago

[formatter stringForTimeIntervalFromDate:longAgo toReferenceDate:now];
// = 2/11/2015
```

or

```objc
LDOConditionalDateFormatter *formatter = [LDOConditionalDateFormatter new];
[formatter addFormat:@"I R" for:LDOTimeUnitToday];
[formatter addFormat:@"I at {h}" for:LDOTimeUnitYesterday];

[formatter stringForTimeIntervalFromDate:twoHoursAgo toReferenceDate:now];
// = today 2 hours ago

[formatter stringForTimeIntervalFromDate:yesterdayAt4pm toReferenceDate:now];
// = yesterday at 4 PM
```

## Installation

LDOConditionalDateFormatter is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod "LDOConditionalDateFormatter"
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

2. `addFormat:(NSString *)format for:(LDOTimeUnit)unit`

	 Adds a format to be used for a specific time unit. The time unit needs to be a relative time unit like `LDOTimeUnitToday`, `LDOTimeUnitSameWeek` or `LDOTimeNextYear`. Check out the header for a complete list.

3. `addFormat:(NSString *)format forLast:(NSUInteger)count unit:(LDOTimeUnit)unit`

	Adds a format for a relative time span in the past. The time unit should be `LDOTimeUnitDays`, `LDOTimeUnitWeeks`, `LDOTimeUnitMonths` or `LDOTimeUnitYears`.

4. `addFormat:(NSString *)format forNext:(NSUInteger)count unit:(LDOTimeUnit)unit`

	Same as 3., but for a time span in the future.


The formats are checked in the same order they are added. If two formats satisfy the condition for a date, the date will be formatted with the one added first. Only one format will be applied.

If no format matches the condition for a given date, a default format will be used (if specified).

## Localization

The library provides localization for [many languages](https://github.com/lurado/LDOConditionalDateFormatter/tree/master/Pod/Assets). If you want to customize a string, simply add it to your own localization and it will be used instead of the bundled translation.

However that does not mean the localizations are perfect yet. Please check how to [contribute](#contribute)

## Examples

The pod contains a bunch of unit tests trying to prove things work as they should. They are also good to illustrate the usage. To run them, clone the repo, and run `pod install` from the Example directory first.

## Alternatives

Based on @mattt's work on [FormatterKit](https://github.com/mattt/FormatterKit) and everybody who contributed there. Go check it out, maybe it better suits your needs.

## Contribute

Issues and pull requests are always welcome! The localizations probably need improvements the most. So please check, correct and provide translations. The following keys are still missing for most languages:

- today
- this week
- this month
- this year

[twine](https://github.com/mobiata/twine) is used to manage all translations in a single [strings.txt](https://github.com/lurado/LDOConditionalDateFormatter/tree/master/Pod/Assets/strings.txt) file. If you want to regenerate the `.strings` files youself, use the following command from inside the `Assets` folder: `twine generate-all-localization-files strings.txt ./ --format apple --file-name LDOConditionalDateFormatter.strings --create-folders --developer-language en --include all`

## Author

Sebastian Ludwig, sebastian@lurado.de

## License

LDOConditionalDateFormatter is available under the MIT license. See the LICENSE file for more info.
