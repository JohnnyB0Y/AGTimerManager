//
//  ViewController.m
//  AGTimerManager
//
//  Created by JohnnyB0Y on 2017/8/22.
//  Copyright © 2017年 JohnnyB0Y. All rights reserved.
//

#import "ViewController.h"
#import "AGTimerManager/AGTMKit.h"
#import <AGCategories/UIColor+AGExtensions.h>

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *countdownLabel;
- (IBAction)countdownClick:(UISwitch *)sender;

@property (weak, nonatomic) IBOutlet UILabel *timerLabel;
- (IBAction)timerClick:(UISwitch *)sender;

@property (weak, nonatomic) IBOutlet UILabel *dateCountDownLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateCountDownLabel2;


/** 测试 nil 时，定时器是否停止 */
@property (nonatomic, strong) AGTimerManager *testNilTM;

/** 计时器 */
@property (nonatomic, strong) AGTimerManager *timerManager;

@end

@implementation ViewController {
    NSString *_countdownKey;
    NSString *_timerKey;
}

#pragma mark - ----------- Life Cycle ----------
- (void)viewDidLoad {
    [super viewDidLoad];
    
#pragma mark - ++++++++++++++++++++++ 测试 nil 时，定时器是否停止 ++++++++++++++++++++++
    self.testNilTM = [AGTimerManager new];
    for (NSInteger i = 0; i<6; i++) {
        
        __block NSString *key;
        key = [self.testNilTM ag_startCountdownTimer:6 countdown:^BOOL(NSTimeInterval surplus) {
            
            NSLog(@"%@ -- %@", key, @(surplus));
            return YES;
            
        } completion:^{
            
            NSLog(@"完成倒计时！");
            
        }];
        
    }
	
	// 3秒后，制空 testNilTM；倒计时会停止，此时不会调用 completion代码块。正常退出才会调用completion代码块。
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3. * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.testNilTM = nil;
        NSLog(@"当 self.testNilTM = nil时，停止 testNilTM 的所有定时器！");
    });
	
    
    // 开始界面上的计时器
    [self _startTimer];
    
#pragma mark - ++++++++++++++++++++++ 日期倒计时 ++++++++++++++++++++
    // 活动倒计时，未来的日期直接使用。
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:13606.];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    
    __weak typeof(self) weakSelf = self;
    [self.timerManager ag_startCountdownDate:date interval:1. countdown:^BOOL(NSCalendar * _Nonnull calendar, NSDateComponents * _Nonnull comp) {
        
        __strong typeof(weakSelf) self = weakSelf;
        NSDate *outputDate = [calendar dateFromComponents:comp];
        NSString *showString = [NSString stringWithFormat:@"活动倒计时：%@", [formatter stringFromDate:outputDate]];
        [self.dateCountDownLabel setText:showString];
        
        return YES;
        
    } completion:^{
        
        __strong typeof(weakSelf) self = weakSelf;
        [self.dateCountDownLabel setText:@"活动已结束！"];
        
    }];
    
    // 抢购倒计时 68秒
    [self.timerManager ag_startCountdownDateInterval:68. countdown:^BOOL(NSCalendar * _Nonnull calendar, NSDateComponents * _Nonnull comp) {
        NSLog(@"xxxxx");
        __strong typeof(weakSelf) self = weakSelf;
        NSDate *outputDate = [calendar dateFromComponents:comp];
        NSString *showString = [NSString stringWithFormat:@"抢购倒计时：%@", [formatter stringFromDate:outputDate]];
        [self.dateCountDownLabel2 setText:showString];
        
        return YES;
        
    } completion:^{
        
        __strong typeof(weakSelf) self = weakSelf;
        [self.dateCountDownLabel2 setText:@"抢购已结束！"];
        
    }];
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"——————-----------------");
	NSLog(@"%@", self.timerManager);
}

#pragma mark - ---------- Event Methods ----------
- (IBAction)countdownClick:(UISwitch *)sender
{
    sender.isOn ? [self _startCountdownTimer] : [self _stopCountdownTimer];
}

- (IBAction)timerClick:(UISwitch *)sender
{
    sender.isOn ? [self _stopTimer] : [self _startTimer];
}

#pragma mark - ---------- Private Methods ----------
- (NSUInteger) _countdownTi
{
    return self.countdownLabel.text.integerValue;
}

- (NSUInteger) _timerTi
{
    return self.timerLabel.text.integerValue;
}

#pragma mark - ++++++++++++++++++++++ 时间倒计时 ++++++++++++++++++++++
- (void) _startCountdownTimer
{
    __weak typeof(self) weakSelf = self;
	_countdownKey =
	[self.timerManager ag_startCountdownTimer:[self _countdownTi] countdown:^BOOL(NSTimeInterval surplus) {
		
		// ———————————————— 倒计时显示 ——————————————————
		__strong typeof(weakSelf) strongSelf = weakSelf;
		[strongSelf.countdownLabel setText:[NSString stringWithFormat:@"%@", @(surplus)]];
		
		// ———————————————— 继续 Timer ——————————————————
		return strongSelf ? YES : NO;
		
	} completion:^{
		
		// ———————————————— 完成倒计时 ——————————————————
		__strong typeof(weakSelf) strongSelf = weakSelf;
		strongSelf.view.backgroundColor = [UIColor orangeColor];
		
	}];
	
}

- (void) _stopCountdownTimer
{
    [self.timerManager ag_stopTimerForKey:_countdownKey];
}

#pragma mark - ++++++++++++++++++++++ 定时执行重复任务 ++++++++++++++++++++++
- (void) _startTimer
{
    __weak typeof(self) weakSelf = self;
    _timerKey = [self.timerManager ag_startRepeatTimer:1. repeat:^BOOL{
        
        // ———————————————— 定时任务调用 ——————————————————
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSUInteger ti = [strongSelf _timerTi];
        [strongSelf.timerLabel setText:[NSString stringWithFormat:@"%@", @(++ti)]];
        
        // ———————————————— 继续 Timer ——————————————————
        return strongSelf ? YES : NO;
        
    }];
}

- (void) _stopTimer
{
    [self.timerManager ag_stopTimerForKey:_timerKey];
}


#pragma mark - ----------- Getter Methods ----------
- (AGTimerManager *)timerManager
{
    if (_timerManager == nil) {
        _timerManager = [AGTimerManager new];
    }
    return _timerManager;
}

@end
