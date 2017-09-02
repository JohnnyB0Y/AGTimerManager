# AGTimerManager
倒计时 - 定时器

### cocoapods 集成
```
platform :ios, '7.0'
target 'AGTimerManager' do

pod 'AGTimerManager'

end
```
## 使用须知
 1. ag_sharedTimerManager(id token)，一个 token 对应一组 Timer；
 调用 ag_stopAllTimers，会移除该 token 对应的所有 Timer；
 
 2. token 必须是 oc 对象，当对象销毁时，定时器会自动停止并移除。一般传 self 就可以了。
 如果传常量或全局变量作为 token 就要手动管理好定时器了。
 
 3. 如果用 LLDB 打印信息，token 传 nil 就好了。传 nil 后调用 ag_stopAllTimers 是移除内部全部 timer。
 
 4. 不支持异步线程调用。不太好上锁。😅😅😅😅😅😅


## 开始倒计时
```objective-c
__weak typeof(self) weakSelf = self;
    _countdownKey = 
    [[ag_sharedTimerManager(self) ag_startTimer:60 countdown:^BOOL(NSUInteger surplusCount) {
        
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
[ag_sharedTimerManager(self) ag_stopTimer:_countdownKey];

```

## 开始定时任务
```objective-c
__weak typeof(self) weakSelf = self;
    _timerKey = 
    [ag_sharedTimerManager(self) ag_startTimerWithTimeInterval:1. repeat:^BOOL{
    
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
[ag_sharedTimerManager(self) ag_stopTimer:_timerKey];

```

