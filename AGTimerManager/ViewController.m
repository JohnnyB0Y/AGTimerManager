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

/** 测试 nil 时，定时器是否停止 */
@property (nonatomic, strong) UITextView *textView;

@end

@implementation ViewController {
    NSString *_countdownKey;
    NSString *_timerKey;
}

#pragma mark - ----------- Life Cycle ----------
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 测试 nil 时，定时器是否停止
    self.textView = [[UITextView alloc] init];
	
    for (NSInteger i = 0; i<24; i++) {
		
		[ag_timerManager(self.textView) ag_startCountdownTimer:24 countdown:^BOOL(NSUInteger surplus) {
			
			NSLog(@"----- %@", @(surplus));
			return YES;
			
		} completion:^{
			
			NSLog(@"完成倒计时！");
			
		}];
		
    }
	
	// 5 秒后，制空 self.textView；倒计时会停止，此时不会调用 completion代码块。正常退出才会调用completion代码块。
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5. * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.textView = nil;
    });
	
    // 开始计时器
    [self _startTimer];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    NSLog(@"——————-----------------");
	NSLog(@"%@", ag_timerManager(nil));
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
	[ag_timerManager(self) ag_startCountdownTimer:[self _countdownTi] countdown:^BOOL(NSUInteger surplus) {
		
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
    [ag_timerManager(self) ag_stopTimerForKey:_countdownKey];
}

- (void) _startTimer
{
    __weak typeof(self) weakSelf = self;
    _timerKey = [ag_timerManager(self) ag_startRepeatTimer:1. repeat:^BOOL{
        
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
    [ag_timerManager(self) ag_stopTimerForKey:_timerKey];
}


#pragma mark - ----------- Getter Methods ----------


@end
