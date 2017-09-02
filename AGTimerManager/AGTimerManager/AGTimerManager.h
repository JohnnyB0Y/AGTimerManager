//
//  AGTimerManager.h
//  
//
//  Created by JohnnyB0Y on 2017/5/3.
//  Copyright © 2017年 JohnnyB0Y. All rights reserved.
//

#import <Foundation/Foundation.h>
@class AGTimerManager;
NS_ASSUME_NONNULL_BEGIN

typedef BOOL(^AGTimerManagerCountdownBlock)(NSUInteger surplusCount);
typedef void(^AGTimerManagerCompletionBlock)(void);
typedef BOOL(^AGTimerManagerRepeatBlock)(void);

/** 
 // 使用须知
 1. ag_sharedTimerManager(id token)，一个 token 对应一组 Timer；
 调用 ag_stopAllTimers，会移除该 token 对应的所有 Timer；
 
 2. token 必须是 oc 对象，当对象销毁时，定时器会自动停止并移除。一般传 self 就可以了。
 如果传常量或全局变量作为 token 就要手动管理好定时器了。
 
 3. 如果用 LLDB 打印信息，token 传 nil 就好了。传 nil 后调用 ag_stopAllTimers 是移除内部全部 timer。
 
 4. 不支持异步线程调用。不太好上锁。😅😅😅😅😅😅
 
 
 
 // 使用示例
 __weak typeof(self) weakSelf = self;
 _countdownKey = [ag_sharedTimerManager(self) ag_startTimer:60
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
 
 */


/**
 获取 timerManager 实例。
 
 @param token 一个令牌对应一组 Timer；调用 ag_stopAllTimers，会移除该 token 对应的所有 Timer；
 @return timerManager
 */
AGTimerManager * ag_sharedTimerManager(id token);


@interface AGTimerManager : NSObject

#pragma mark - 定时器⏰
/**
 开始重复调用 repeatBlock，直到返回 NO  (NSRunLoopCommonModes)
 
 @param ti 调用间隔
 @param repeatBlock 执行的block 返回 NO 停止，返回 YES 继续。
 @return timer key
 */
- (NSString *) ag_startTimerWithTimeInterval:(NSTimeInterval)ti
                                      repeat:(AGTimerManagerRepeatBlock)repeatBlock;


/**
 开始重复调用 repeatBlock，直到返回 NO  (自定义NSRunLoopMode)
 
 @param ti 调用间隔
 @param repeatBlock 执行的block 返回 NO 停止，返回 YES 继续。
 @param mode 运行循环模式
 @return timer key
 */
- (NSString *) ag_startTimerWithTimeInterval:(NSTimeInterval)ti
                                      repeat:(AGTimerManagerRepeatBlock)repeatBlock
                                     forMode:(NSRunLoopMode)mode;


#pragma mark - 倒计时⏳
/**
 开始倒计时 (NSRunLoopCommonModes)

 @param count 计数值
 @param countdownBlock 计数回调 block 返回 NO 停止，返回 YES 继续。
 @param completionBlock 计数完成 block
 @return timer key
 */
- (NSString *) ag_startTimer:(NSUInteger)count
                   countdown:(nullable AGTimerManagerCountdownBlock)countdownBlock
                  completion:(AGTimerManagerCompletionBlock)completionBlock;


/**
 开始倒计时 (NSRunLoopCommonModes)

 @param count 计数值
 @param ti 计数间隔
 @param countdownBlock 计数回调 block 返回 NO 停止，返回 YES 继续。
 @param completionBlock 计数完成 block
 @return timer key
 */
- (NSString *) ag_startTimer:(NSUInteger)count
                timeInterval:(NSTimeInterval)ti
                   countdown:(nullable AGTimerManagerCountdownBlock)countdownBlock
                  completion:(AGTimerManagerCompletionBlock)completionBlock;

/**
 开始倒计时 (自定义NSRunLoopMode)
 
 @param count 计数值
 @param ti 计数间隔
 @param countdownBlock 计数回调 block 返回 NO 停止，返回 YES 继续。
 @param completionBlock 计数完成 block
 @param mode 运行循环模式
 @return timer key
 */
- (NSString *) ag_startTimer:(NSUInteger)count
                timeInterval:(NSTimeInterval)ti
                   countdown:(nullable AGTimerManagerCountdownBlock)countdownBlock
                  completion:(AGTimerManagerCompletionBlock)completionBlock
                     forMode:(NSRunLoopMode)mode;


#pragma mark - 停止定时器⚠️
/**
 通过 key 停止定时器

 @param key 停止定时器的 key
 */
- (void) ag_stopTimer:(NSString *)key;

/** 停止对应 token 的所有 timer；如果 token 为 nil 就清空所有的定时器。 */
- (void) ag_stopAllTimers;



/** 禁止调用 */
- (instancetype) init __attribute__((unavailable("call ag_sharedTimerManager(id token)")));
+ (instancetype) new __attribute__((unavailable("call ag_sharedTimerManager(id token)")));

@end

NS_ASSUME_NONNULL_END
