# AGTimerManager
倒计时 - 定时器

### cocoapods 集成
```
platform :ios, '7.0'
target 'AGTimerManager' do

pod 'AGTimerManager'

end
```

## 开始倒计时
```objective-c
__weak typeof(self) weakSelf = self;
    _countdownKey = [[AGTimerManager sharedInstance] ag_startTimer:[self _countdownTi] 
                                                         countdown:^BOOL(NSUInteger surplusCount) {
        
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

```
### 提前结束倒计时
```objective-c
[[AGTimerManager sharedInstance] ag_stopTimer:_countdownKey];

```

## 开始定时任务
```objective-c
__weak typeof(self) weakSelf = self;
    _timerKey = [ag_sharedTimerManager() ag_startTimerWithTimeInterval:1. repeat:^BOOL{
        // ———————————————— 定时任务调用 ——————————————————
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSUInteger ti = [strongSelf _timerTi];
        [strongSelf.timerLabel setText:[NSString stringWithFormat:@"%@", @(++ti)]];
        
        // ———————————————— 继续 timer ——————————————————
        return strongSelf ? YES : NO;
        
    }];

```
### 结束定时任务
```objective-c
[ag_sharedTimerManager() ag_stopTimer:_timerKey];

```

