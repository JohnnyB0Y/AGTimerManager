# AGTimerManager
####倒计时 - 定时器：
######使用 AGTimerManager 管理一组 Timer，当 AGTimerManager 对象销毁时，自动停止所有 Timer。

### cocoapods 集成
```
platform :ios, '7.0'
target 'AGTimerManager' do

pod 'AGTimerManager'

end
```

## 使用须知
 1. AGTimerManager 对象管理一组 Timer，当 AGTimerManager 对象销毁时，自动停止所有 Timer。
 
 2. 调用ag_stopAllTimers( ) 方法停止所有 Timer。
 
 3. LLDB 打印所有 Timer信息，po timerManager。
 

## 开始倒计时
```objective-c
__weak typeof(self) weakSelf = self;
	_countdownKey =
	[self.timerManager ag_startCountdownTimer:60 countdown:^BOOL(NSUInteger surplus) {
		
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

```
### 提前结束倒计时
```objective-c
[self.timerManager ag_stopTimerForKey:_countdownKey];

```

## 开始定时任务
```objective-c
__weak typeof(self) weakSelf = self;
    _timerKey = [self.timerManager ag_startRepeatTimer:1. repeat:^BOOL{
        
        // ———————————————— 定时任务调用 ——————————————————
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSUInteger ti = [strongSelf _timerTi];
        [strongSelf.timerLabel setText:[NSString stringWithFormat:@"%@", @(++ti)]];
        
        // ———————————————— 继续 Timer ——————————————————
        return strongSelf ? YES : NO;
        
    }];

```
### 结束所有定时任务
```objective-c
[self.timerManager ag_stopAllTimers];

```

