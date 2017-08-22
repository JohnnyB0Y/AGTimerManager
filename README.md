# AGTimerManager
倒计时 - 定时器

## 开始倒计时
```objective-c
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

```
### 结束倒计时
```objective-c
[[AGTimerManager sharedInstance] ag_stopTimer:_countdownKey];

```

## 开始定时任务
```objective-c
__weak typeof(self) weakSelf = self;
    _timerKey = [ag_sharedTimerManager() ag_startTimerWithTimeInterval:1. repeat:^BOOL{
        // ———————————————— 设置计时 ——————————————————
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSUInteger ti = [strongSelf _timerTi];
        [strongSelf.timerLabel setText:[NSString stringWithFormat:@"%@", @(++ti)]];
        
        // ———————————————— 结束 timer ——————————————————
        return strongSelf ? YES : NO;
        
    }];

```
### 结束定时任务
```objective-c
[ag_sharedTimerManager() ag_stopTimer:_timerKey];

```

