//
//  AGCountdownManager.h
//  
//
//  Created by JohnnyB0Y on 2017/5/3.
//  Copyright © 2017年 JohnnyB0Y. All rights reserved.
//  倒计时 manager

#import <Foundation/Foundation.h>

typedef BOOL(^AGTimerManagerCountdownBlock)(NSUInteger surplusCount);
typedef void(^AGTimerManagerCompletionBlock)(void);
typedef BOOL(^AGTimerManagerRepeatBlock)(void);

/** 
 
 __weak typeof(self) weakSelf = self;
 
 [[AGTimerManager sharedInstance] ag_startTimer:60 countdown:^BOOL(NSUInteger surplusCount) {
 
     // ———————————————— 设置计时按钮 ——————————————————
     __strong typeof(weakSelf) strongSelf = weakSelf;
     [strongSelf.rightBtn setEnabled:NO];
     [strongSelf.rightBtn ag_setDisTitle:[NSString stringWithFormat:@"从新获取%lu", (unsigned long)surplusCount]];
     
     // ———————————————— 结束 timer ——————————————————
     return strongSelf ? YES : NO;
 
 } completion:^{
 
     // ———————————————— 完成倒计时 ——————————————————
     __strong typeof(weakSelf) strongSelf = weakSelf;
     [strongSelf.rightBtn setEnabled:YES];
 
 }];
 
 */


@interface AGTimerManager : NSObject

/** timer count */
@property (nonatomic, assign, readonly) NSUInteger timerCount;


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
                   countdown:(AGTimerManagerCountdownBlock)countdownBlock
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
                   countdown:(AGTimerManagerCountdownBlock)countdownBlock
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
                   countdown:(AGTimerManagerCountdownBlock)countdownBlock
                  completion:(AGTimerManagerCompletionBlock)completionBlock
                     forMode:(NSRunLoopMode)mode;


#pragma mark - 停止定时器⚠️
/**
 通过 key 停止定时器

 @param key 停止定时器的 key
 */
- (void) ag_stopTimer:(NSString *)key;

/** 停止所有 timer */
- (void) ag_stopAllTimers;

#pragma mark - 获取对象🙈
+ (instancetype) sharedInstance;

@end

/** 获取 timer manager */
AGTimerManager * ag_sharedTimerManager();

