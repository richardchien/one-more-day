//
//  OMDViewController.m
//  OneMoreDay
//
//  Created by Richard Chien on 8/2/14.
//  Copyright (c) 2014 Richard Chien. All rights reserved.
//

#import "OMDViewController.h"

@interface OMDViewController ()
{
    CGRect goBtnDisplayFrame, daysViewDisplayFrame;
    NSDictionary *data;
    NSTimer *checkDateTimer;
    OMDDateCompareResult prevResult;
}

@end

@implementation OMDViewController

NSString *CFDataFilePath()
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths[0] stringByAppendingPathComponent:@"data.plist"];
}

#define FILEPATH CFDataFilePath()

UIColor *CFRandomColor()
{
    srand((unsigned)time(0));
    int r = rand() % 3;
    int red, green, blue;
    switch (r) {
        case 0: // Red value range from 0~255, other 0~158(0.62 * 255)
            red = rand() % 255;
            green = rand() % 158;
            blue = rand() % 158;
            break;
        case 1:
            red = rand() % 158;
            green = rand() % 255;
            blue = rand() % 158;
        case 2:
            red = rand() % 158;
            green = rand() % 158;
            blue = rand() % 255;
        default:
            break;
    }
    return [UIColor colorWithRed:(float)red/255.0 green:(float)green/255.0 blue:(float)blue/255.0 alpha:1.0];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self readOrCreateDataFile];
    
    NSDate *lastDate = data[kLastDateKey];
    NSDate *nowDate = [NSDate date];
    prevResult = [self compareOneDay:lastDate WithAnother:nowDate];
    
    UIColor *color = CFRandomColor();
    [(UILabel *)[[self.view viewWithTag:kDaysViewTag] viewWithTag:1] setTextColor:color]; // DaysPersisted Label
    [(UILabel *)[[self.view viewWithTag:kDaysViewTag] viewWithTag:2] setTextColor:color]; // "You have persisted for" Label
    
    checkDateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkDateLoop) userInfo:nil repeats:YES];
}

- (void)checkDateLoop
{
    NSDate *lastDate = data[kLastDateKey];
    NSDate *nowDate = [NSDate date];
    OMDDateCompareResult currentResult = [self compareOneDay:lastDate WithAnother:nowDate];
    NSLog(@"%d - %d", prevResult, currentResult);
    if (prevResult == OMDDateCompareResultFuture || prevResult == OMDDateCompareResultFutureOneDay) {
        prevResult = currentResult;
        if (currentResult == OMDDateCompareResultSame || currentResult == OMDDateCompareResultPast) {
            [self displayDaysView];
        }
    } else {
        prevResult = currentResult;
        if (currentResult == OMDDateCompareResultFuture || currentResult == OMDDateCompareResultFutureOneDay) {
            [self displayGoBtn];
        }
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    daysViewDisplayFrame = [self.view viewWithTag:kDaysViewTag].frame;
    goBtnDisplayFrame = [self.view viewWithTag:kGoBtnTag].frame;
    
    NSDate *lastDate = data[kLastDateKey];
    NSDate *nowDate = [NSDate date];
    OMDDateCompareResult result = [self compareOneDay:lastDate WithAnother:nowDate];
    /*if (result == OMDDateCompareResultFutureOneDay) {
        [(UILabel *)[[self.view viewWithTag:kDaysViewTag] viewWithTag:1] setText:[NSString stringWithFormat:@"%@ Days", data[kDaysPersistedKey]]];
        CGRect daysViewRect = daysViewDisplayFrame;
        daysViewRect.origin = CGPointMake(daysViewRect.origin.x, -daysViewRect.size.height - 50.0);
        [self.view viewWithTag:kDaysViewTag].frame = daysViewRect;
    } else if (result == OMDDateCompareResultFuture) {
        //[data setValue:[NSNumber numberWithInt:0] forKey:@"DaysPersisted"];
        data = [NSDictionary dictionaryWithObjectsAndKeys:
                data[kLastDateKey], kLastDateKey,
                [NSNumber numberWithInt:0], kDaysPersistedKey, nil];
        [(UILabel *)[[self.view viewWithTag:kDaysViewTag] viewWithTag:1] setText:[NSString stringWithFormat:@"%@ Days", data[kDaysPersistedKey]]];
        CGRect daysViewRect = daysViewDisplayFrame;
        daysViewRect.origin = CGPointMake(daysViewRect.origin.x, -daysViewRect.size.height - 50.0);
        [self.view viewWithTag:kDaysViewTag].frame = daysViewRect;
    } else {
        [(UILabel *)[[self.view viewWithTag:kDaysViewTag] viewWithTag:1] setText:[NSString stringWithFormat:@"%@ Days", data[kDaysPersistedKey]]];
        CGRect goBtnRect = goBtnDisplayFrame;
        goBtnRect.origin = CGPointMake(goBtnRect.origin.x, self.view.frame.size.height + 50.0);
        [self.view viewWithTag:kGoBtnTag].frame = goBtnRect;
    }*/
    switch (result) {
        case OMDDateCompareResultFuture:
            data = [NSDictionary dictionaryWithObjectsAndKeys:
                    data[kLastDateKey], kLastDateKey,
                    [NSNumber numberWithInt:0], kDaysPersistedKey, nil];
        case OMDDateCompareResultFutureOneDay:
            [(UILabel *)[[self.view viewWithTag:kDaysViewTag] viewWithTag:1] setText:[NSString stringWithFormat:@"%@ Days", data[kDaysPersistedKey]]];
            CGRect daysViewRect = daysViewDisplayFrame;
            daysViewRect.origin = CGPointMake(daysViewRect.origin.x, -daysViewRect.size.height - 50.0);
            [self.view viewWithTag:kDaysViewTag].frame = daysViewRect;
            break;
        case OMDDateCompareResultPast:
        case OMDDateCompareResultSame:
            [(UILabel *)[[self.view viewWithTag:kDaysViewTag] viewWithTag:1] setText:[NSString stringWithFormat:@"%@ Days", data[kDaysPersistedKey]]];
            CGRect goBtnRect = goBtnDisplayFrame;
            goBtnRect.origin = CGPointMake(goBtnRect.origin.x, self.view.frame.size.height + 50.0);
            [self.view viewWithTag:kGoBtnTag].frame = goBtnRect;
            break;
        default:
            break;
    }
}

BOOL CFYearIsLeapYear(NSInteger year)
{
    return ((year % 4 == 0 && year % 100 != 0) || year % 400 == 0) ? YES : NO;
}

- (OMDDateCompareResult)compareOneDay:(NSDate *)oneDay WithAnother:(NSDate *)anotherDay
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy";
    NSMutableString *yearStrA = [NSMutableString stringWithString:[dateFormatter stringFromDate:oneDay]];
    NSMutableString *yearStrB = [NSMutableString stringWithString:[dateFormatter stringFromDate:anotherDay]];
    dateFormatter.dateFormat = @"MM";
    NSMutableString *monthStrA = [NSMutableString stringWithString:[dateFormatter stringFromDate:oneDay]];
    NSMutableString *monthStrB = [NSMutableString stringWithString:[dateFormatter stringFromDate:anotherDay]];
    dateFormatter.dateFormat = @"dd";
    NSMutableString *dayStrA = [NSMutableString stringWithString:[dateFormatter stringFromDate:oneDay]];
    NSMutableString *dayStrB = [NSMutableString stringWithString:[dateFormatter stringFromDate:anotherDay]];
    
    NSInteger yearA = [yearStrA integerValue];
    NSInteger yearB = [yearStrB integerValue];
    NSInteger monthA = [monthStrA integerValue];
    NSInteger monthB = [monthStrB integerValue];
    NSInteger dayA = [dayStrA integerValue];
    NSInteger dayB = [dayStrB integerValue];
    
    if (yearA < yearB) {
        if (!(monthA == 12 && monthB == 1 && dayA == 31 && dayB == 1)) {
            return OMDDateCompareResultFuture;
        } else {
            return OMDDateCompareResultFutureOneDay;
        }
    } else if (yearA > yearB) {
        return OMDDateCompareResultPast;
    } else {
        NSArray *lastDayOfMonth = [NSArray arrayWithObjects:
                                        [NSNumber numberWithInt:31],
                                        [NSNumber numberWithInt:CFYearIsLeapYear(yearA) ? 29 : 28],
                                        [NSNumber numberWithInt:31],
                                        [NSNumber numberWithInt:30],
                                        [NSNumber numberWithInt:31],
                                        [NSNumber numberWithInt:30],
                                        [NSNumber numberWithInt:31],
                                        [NSNumber numberWithInt:31],
                                        [NSNumber numberWithInt:30],
                                        [NSNumber numberWithInt:31],
                                        [NSNumber numberWithInt:30],
                                        [NSNumber numberWithInt:31], nil];
        if (monthA < monthB) {
            if (!(monthA == monthB - 1 && dayA == [lastDayOfMonth[monthA-1] integerValue] && dayB == 1)) {
                return OMDDateCompareResultFuture;
            } else {
                return OMDDateCompareResultFutureOneDay;
            }
        } else if (monthA > monthB) {
            return OMDDateCompareResultPast;
        } else {
            if (dayA == dayB - 1) {
                return OMDDateCompareResultFutureOneDay;
            } else if (dayA < dayB - 1) {
                return OMDDateCompareResultFuture;
            } else if (dayA == dayB) {
                return OMDDateCompareResultSame;
            } else {
                return OMDDateCompareResultPast;
            }
        }
    }
}

- (void)readOrCreateDataFile
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:FILEPATH]) {
        data = [NSDictionary dictionaryWithContentsOfFile:FILEPATH];
    } else {
        data = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSDate dateWithTimeIntervalSince1970:0], kLastDateKey,
                [NSNumber numberWithInt:0], kDaysPersistedKey, nil];
        [data writeToFile:FILEPATH atomically:YES];
    }
}

- (IBAction)goOneMoreDay
{
    NSDate *lastDate = data[kLastDateKey];
    NSDate *nowDate = [NSDate date];
    OMDDateCompareResult result = [self compareOneDay:lastDate WithAnother:nowDate];
    if (result == OMDDateCompareResultFuture) {
        data = [NSDictionary dictionaryWithObjectsAndKeys:
                data[kLastDateKey], kLastDateKey,
                [NSNumber numberWithInt:0], kDaysPersistedKey, nil];
    }
    
    int daysPersisted = [data[kDaysPersistedKey] intValue];
    //[data setValue:[NSNumber numberWithInt:daysPersisted+1] forKey:@"DaysPersisted"];
    //[data setValue:[NSDate date] forKey:@"LastDate"];
    data = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSDate date], kLastDateKey,
            [NSNumber numberWithInt:daysPersisted+1], kDaysPersistedKey, nil];
    [data writeToFile:FILEPATH atomically:YES];
    
    [(UILabel *)[[self.view viewWithTag:kDaysViewTag] viewWithTag:1] setText:[NSString stringWithFormat:@"%@ Days", data[kDaysPersistedKey]]];
    
    [self displayDaysView];
}

- (void)displayDaysView
{
    CGRect goBtnRect = goBtnDisplayFrame;
    goBtnRect.origin = CGPointMake(goBtnRect.origin.x, self.view.frame.size.height + 50.0);
    [UIView beginAnimations:@"Display DaysView" context:nil];
    [self.view viewWithTag:kGoBtnTag].frame = goBtnRect;
    [self.view viewWithTag:kDaysViewTag].frame = daysViewDisplayFrame;
    [UIView commitAnimations];
}

- (void)displayGoBtn
{
    CGRect daysViewRect = daysViewDisplayFrame;
    daysViewRect.origin = CGPointMake(daysViewRect.origin.x, -daysViewRect.size.height - 50.0);
    [UIView beginAnimations:@"Display GoBtn" context:nil];
    [self.view viewWithTag:kDaysViewTag].frame = daysViewRect;
    [self.view viewWithTag:kGoBtnTag].frame = goBtnDisplayFrame;
    [UIView commitAnimations];
}

@end
