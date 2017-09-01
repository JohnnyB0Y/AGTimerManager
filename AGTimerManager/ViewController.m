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

/** 令牌集合 */
@property (nonatomic, strong) NSMapTable *tokenMapTable;

/** key */
@property (nonatomic, strong) NSArray *key;

@end

@implementation ViewController {
    NSString *_countdownKey;
    NSString *_timerKey;
}

#pragma mark - ----------- Life Cycle ----------
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.key = @[@1];
    [self.tokenMapTable setObject:@"abc" forKey:self.key];
    [self.tokenMapTable setObject:@"ABC" forKey:self.key];
    
    ag_sharedTimerManager(self);
    
    // 开始计时器
    [self _startTimer];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"%@", self.tokenMapTable);
    
    NSLog(@"%@", [self.tokenMapTable objectForKey:self.key]);
    
    self.key = nil;
    
    NSLog(@"%@", self.tokenMapTable);
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

- (void) _startCountdownTimer
{
    __weak typeof(self) weakSelf = self;
    _countdownKey =
    [ag_sharedTimerManager(self) ag_startTimer:[self _countdownTi] countdown:^BOOL(NSUInteger surplusCount) {
        
        // ———————————————— 倒计时显示 ——————————————————
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.countdownLabel setText:[NSString stringWithFormat:@"%@", @(surplusCount)]];
        
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
    [ag_sharedTimerManager(self) ag_stopTimer:_countdownKey];
}

- (void) _startTimer
{
    __weak typeof(self) weakSelf = self;
    _timerKey = [ag_sharedTimerManager(self) ag_startTimerWithTimeInterval:1. repeat:^BOOL{
        
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
    [ag_sharedTimerManager(self) ag_stopTimer:_timerKey];
}


#pragma mark - ----------- Getter Methods ----------
- (NSMapTable *)tokenMapTable
{
    if (_tokenMapTable == nil) {
        _tokenMapTable = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsWeakMemory
                                               valueOptions:NSPointerFunctionsStrongMemory];
    }
    return _tokenMapTable;
}

@end
