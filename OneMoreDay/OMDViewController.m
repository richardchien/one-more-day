//
//  OMDViewController.m
//  OneMoreDay
//
//  Created by Richard Chien on 8/2/14.
//  Copyright (c) 2014 Richard Chien. All rights reserved.
//

#import "OMDViewController.h"
#import "AMPopTip.h"

@interface OMDViewController ()
{
    CGRect goBtnDisplayFrame, daysViewDisplayFrame;
    NSDictionary *data;
    NSTimer *checkDateTimer;
    OMDDateCompareResult prevResult;
    AMPopTip *popTip;
}

@end

@implementation OMDViewController

#pragma mark - C Functions

#define FILEPATH CFDataFilePath()

NSString *CFDataFilePath()
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths[0] stringByAppendingPathComponent:@"data.plist"];
}

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
            break;
        case 2:
            red = rand() % 158;
            green = rand() % 158;
            blue = rand() % 255;
            break;
        default:
            break;
    }
    return [UIColor colorWithRed:(float)red/255.0 green:(float)green/255.0 blue:(float)blue/255.0 alpha:1.0];
}

BOOL CFYearIsLeapYear(NSInteger year)
{
    return ((year % 4 == 0 && year % 100 != 0) || year % 400 == 0) ? YES : NO;
}

#pragma mark - View Load and Layout

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self readOrCreateDataFile];
    
    NSDate *lastDate = data[kLastDateKey];
    NSDate *nowDate = [NSDate date];
    prevResult = [self compareOneDay:lastDate WithAnother:nowDate]; // Get current date compare result, for checkDateTimer
    
    UIColor *color = CFRandomColor(); // Get random color every time the view loaded
    [(UILabel *)[[self.view viewWithTag:kDaysViewTag] viewWithTag:1] setTextColor:color]; // DaysPersisted Label
    [(UILabel *)[[self.view viewWithTag:kDaysViewTag] viewWithTag:2] setTextColor:color]; // "You have persisted for" Label
    [(UIButton *)[self.view viewWithTag:kFormNewHabitBtnTag] setTintColor:color]; // Form new habit button at bottom of view
    
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"FirstLaunch"])
    {
        NSLog(@"First Launch");
        
        [self firstLaunch];// First launch, show tips
    } else {
        checkDateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkDateLoop) userInfo:nil repeats:YES]; // It's not first launch, so directly start checkDateTimer
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    // Autolayout help layout the view
    // Every time the view did layout subviews, update the frames of DaysView and GoBtn
    daysViewDisplayFrame = [self.view viewWithTag:kDaysViewTag].frame;
    goBtnDisplayFrame = [self.view viewWithTag:kGoBtnTag].frame;
    
    // Check the date to decide whether to show the DaysView or GoBtn
    NSDate *lastDate = data[kLastDateKey];
    NSDate *nowDate = [NSDate date];
    OMDDateCompareResult result = [self compareOneDay:lastDate WithAnother:nowDate];
    switch (result) {
        case OMDDateCompareResultFuture:
            data = [NSDictionary dictionaryWithObjectsAndKeys:
                    data[kLastDateKey], kLastDateKey,
                    [NSNumber numberWithInt:0], kDaysPersistedKey, nil]; // Over 2 days not punch the clock, clear the days
        case OMDDateCompareResultFutureOneDay:
            [self refreshDayLabel];
            
            CGRect daysViewRect = daysViewDisplayFrame;
            daysViewRect.origin = CGPointMake(daysViewRect.origin.x, -daysViewRect.size.height - 200.0);
            [self.view viewWithTag:kDaysViewTag].frame = daysViewRect;
            break;
        case OMDDateCompareResultPast:
        case OMDDateCompareResultSame:
            [self refreshDayLabel];
            
            CGRect goBtnRect = goBtnDisplayFrame;
            goBtnRect.origin = CGPointMake(goBtnRect.origin.x, self.view.frame.size.height + 200.0);
            [self.view viewWithTag:kGoBtnTag].frame = goBtnRect;
            break;
        default:
            break;
    }
}

#pragma mark - Basic

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

- (void)checkDateLoop
{
    // This loop is to check the date's change, in order to switch views at about 00:00
    
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

#pragma mark - First Launch

- (void)firstLaunch
{
    UIButton *nextTipBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 90.0, [self.view viewWithTag:kDaysViewTag].frame.origin.y/2 + 20.0, 180.0, 40.0)];
    nextTipBtn.backgroundColor = [UIColor blueColor];
    [nextTipBtn setTitle:NSLocalizedString(@"NEXT_TIP_BTN_TITLE", nil) forState:UIControlStateNormal];
    [nextTipBtn addTarget:self action:@selector(nextTip:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:nextTipBtn];
    
    // Disable all items while showing tips
    [self.view viewWithTag:kFormNewHabitBtnTag].userInteractionEnabled = NO;
    [self.view viewWithTag:kDaysViewTag].userInteractionEnabled = NO;
    [self.view viewWithTag:kGoBtnTag].userInteractionEnabled = NO;
    [[self.view viewWithTag:kDaysViewTag] viewWithTag:1].userInteractionEnabled = NO;
    [[self.view viewWithTag:kDaysViewTag] viewWithTag:2].userInteractionEnabled = NO;
    
    [[AMPopTip appearance] setFont:[UIFont fontWithName:@"Avenir-Medium" size:12]];
    popTip = [AMPopTip popTip];
    popTip.popoverColor = [UIColor lightGrayColor];
    [popTip showText:NSLocalizedString(@"TIP1_MSG", nil)
           direction:AMPopTipDirectionDown
            maxWidth:240.0
              inView:self.view
           fromFrame:CGRectMake((self.view.frame.size.width - 180.0)/2, self.view.frame.size.height/2 - 72.0, 180.0, 143)]; // Show tip 1
}

- (void)nextTip:(id)sender
{
    static int tipNum = 1;
    tipNum++;
    
    if (tipNum == 2) {
        [popTip hide];
        [popTip showText:NSLocalizedString(@"TIP2_MSG", nil)
               direction:AMPopTipDirectionDown
                maxWidth:240.0
                  inView:self.view
               fromFrame:CGRectMake((self.view.frame.size.width - 180.0)/2, self.view.frame.size.height/2 - 72.0, 180.0, 143)]; // Show tip 2
    } else if (tipNum == 3) {
        [popTip hide];
        [sender setTitle:NSLocalizedString(@"START_USING_BTN_TITLE", nil) forState:UIControlStateNormal];
        [popTip showText:NSLocalizedString(@"TIP3_MSG", nil)
               direction:AMPopTipDirectionUp
                maxWidth:240.0
                  inView:self.view
               fromFrame:[self.view viewWithTag:kFormNewHabitBtnTag].frame]; // Show tip 3
    } else {
        [popTip hide]; // All tips have been shown already
        [sender removeFromSuperview];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"FirstLaunch"];
        
        // Enable all items
        [self.view viewWithTag:kFormNewHabitBtnTag].userInteractionEnabled = YES;
        [self.view viewWithTag:kDaysViewTag].userInteractionEnabled = YES;
        [self.view viewWithTag:kGoBtnTag].userInteractionEnabled = YES;
        [[self.view viewWithTag:kDaysViewTag] viewWithTag:1].userInteractionEnabled = YES;
        [[self.view viewWithTag:kDaysViewTag] viewWithTag:2].userInteractionEnabled = YES;
        checkDateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkDateLoop) userInfo:nil repeats:YES]; // Start checkDateTimer
    }
}

#pragma mark - Data Compare

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
    
    // FutureOneDay: "anotherDay" is "oneDay" + 1 day
    // Future: "anotherDay" is "oneDay" + 2 or more days
    // Same: same
    // Past: "anotherDay" is former than "oneDay"
}

#pragma mark - Button Actions

- (IBAction)goOneMoreDay
{
    // Check the date, if 2 days not punch the clock, clear the days
    NSDate *lastDate = data[kLastDateKey];
    NSDate *nowDate = [NSDate date];
    OMDDateCompareResult result = [self compareOneDay:lastDate WithAnother:nowDate];
    if (result == OMDDateCompareResultFuture) {
        data = [NSDictionary dictionaryWithObjectsAndKeys:
                data[kLastDateKey], kLastDateKey,
                [NSNumber numberWithInt:0], kDaysPersistedKey, nil];
    }
    
    // Add the days and save data
    int daysPersisted = [data[kDaysPersistedKey] intValue];
    data = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSDate date], kLastDateKey,
            [NSNumber numberWithInt:daysPersisted+1], kDaysPersistedKey, nil];
    [data writeToFile:FILEPATH atomically:YES];
    
    [self refreshDayLabel];
    
    if (popTip != nil) { // If is first launch, show congratulation popup
        LCAlertView *alert = [[LCAlertView alloc] initWithTitle:NSLocalizedString(@"CONGRATULATION", nil)
                                                        message:NSLocalizedString(@"CONG_MSG", nil)
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"I_GOT_IT_BTN_TITLE", nil)
                                              otherButtonTitles:nil, nil];
        alert.alertAnimationStyle = LCAlertAnimationDefault;
        [alert show];
    }
    
    [self displayDaysView]; // Switch to DaysView
}

- (IBAction)formNewHabit:(id)sender
{
    LCAlertView *alert = [[LCAlertView alloc] initWithTitle:NSLocalizedString(@"NOTICE", nil)
                                                    message:NSLocalizedString(@"NOTICE_MSG", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"YES_BTN_TITLE", nil)
                                          otherButtonTitles:NSLocalizedString(@"NO_BTN_TITLE", nil), nil];
    alert.alertAnimationStyle = LCAlertAnimationDefault;
    [alert show];
}

#pragma mark - Adjust Views

- (void)displayDaysView
{
    CGRect goBtnRect = goBtnDisplayFrame;
    goBtnRect.origin = CGPointMake(goBtnRect.origin.x, self.view.frame.size.height + 200.0);
    [UIView beginAnimations:@"Display DaysView" context:nil];
    [self.view viewWithTag:kGoBtnTag].frame = goBtnRect;
    [self.view viewWithTag:kDaysViewTag].frame = daysViewDisplayFrame;
    [UIView commitAnimations];
}

- (void)displayGoBtn
{
    CGRect daysViewRect = daysViewDisplayFrame;
    daysViewRect.origin = CGPointMake(daysViewRect.origin.x, -daysViewRect.size.height - 200.0);
    [UIView beginAnimations:@"Display GoBtn" context:nil];
    [self.view viewWithTag:kDaysViewTag].frame = daysViewRect;
    [self.view viewWithTag:kGoBtnTag].frame = goBtnDisplayFrame;
    [UIView commitAnimations];
}

- (void)refreshDayLabel
{
    NSString *dayStr = [NSString stringWithFormat:@"%@ %@", data[kDaysPersistedKey], NSLocalizedString(@"DAY", nil)];
    if ([dayStr hasSuffix:@"Day"] || [dayStr hasSuffix:@"Jour"]) { // System language is English or French
        dayStr = [dayStr stringByAppendingString:[data[kDaysPersistedKey] intValue] > 1 ? @"s" : @""];
    }
    [(UILabel *)[[self.view viewWithTag:kDaysViewTag] viewWithTag:1] setText:dayStr];
}

#pragma mark - Form New Habit Alert View Delegate

- (void)alertView:(LCAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"%ld", (long)buttonIndex);
    const NSInteger kYesBtn = 0;
    
    if (buttonIndex == kYesBtn) {
        data = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSDate dateWithTimeIntervalSince1970:0], kLastDateKey,
                [NSNumber numberWithInt:0], kDaysPersistedKey, nil];
        [data writeToFile:FILEPATH atomically:YES];
        
        [self displayGoBtn];
    }
}

@end
