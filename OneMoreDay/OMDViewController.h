//
//  OMDViewController.h
//  OneMoreDay
//
//  Created by Richard Chien on 8/2/14.
//  Copyright (c) 2014 Richard Chien. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LCAlertView.h"

const int kGoBtnTag = 101;
const int kDaysViewTag = 102;
const int kFormNewHabitBtnTag = 103;

typedef enum {
    OMDDateCompareResultPast,
    OMDDateCompareResultSame,
    OMDDateCompareResultFutureOneDay,
    OMDDateCompareResultFuture
} OMDDateCompareResult;

const NSString *kLastDateKey = @"LastDate";
const NSString *kDaysPersistedKey = @"DaysPersisted";

@interface OMDViewController : UIViewController <LCAlertViewDelegate>

- (IBAction)goOneMoreDay;
- (IBAction)formNewHabit:(id)sender;

@end
