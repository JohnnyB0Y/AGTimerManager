//
//  ViewController.m
//  AGTimerManager
//
//  Created by JohnnyB0Y on 2017/8/22.
//  Copyright © 2017年 JohnnyB0Y. All rights reserved.
//

#import "ViewController.h"
#import "AGTimerManager.h"

@interface ViewController ()


@property (weak, nonatomic) IBOutlet UILabel *countdownLabel;
- (IBAction)countdownClick:(UISwitch *)sender;

@property (weak, nonatomic) IBOutlet UILabel *timerLabel;
- (IBAction)timerClick:(UISwitch *)sender;


@end

@implementation ViewController {
    NSString *_countdownKey;
    NSString *_timerKey;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // 开始计时
    [self _startTimer];
}

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

- (void) _startCountdownTimer
{
    __weak typeof(self) weakSelf = self;
    _countdownKey = [[AGTimerManager sharedInstance] ag_startTimer:[self _countdownTi] countdown:^BOOL(NSUInteger surplusCount) {
        
        // ———————————————— 设置计时 ——————————————————
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.countdownLabel setText:[NSString stringWithFormat:@"%@", @(surplusCount)]];
        
        // ———————————————— 结束 timer ——————————————————
        return strongSelf ? YES : NO;
        
    } completion:^{
        
        // ———————————————— 完成倒计时 ——————————————————
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.view.backgroundColor = [UIColor orangeColor];
    }];
}

- (void) _stopCountdownTimer
{
    [ag_sharedTimerManager() ag_stopTimer:_countdownKey];
}

- (void) _startTimer
{
    __weak typeof(self) weakSelf = self;
    _timerKey = [ag_sharedTimerManager() ag_startTimerWithTimeInterval:1. repeat:^BOOL{
        // ———————————————— 设置计时 ——————————————————
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSUInteger ti = [strongSelf _timerTi];
        [strongSelf.timerLabel setText:[NSString stringWithFormat:@"%@", @(++ti)]];
        
        // ———————————————— 结束 timer ——————————————————
        return strongSelf ? YES : NO;
        
    }];
}

- (void) _stopTimer
{
    [ag_sharedTimerManager() ag_stopTimer:_timerKey];
}

@end
