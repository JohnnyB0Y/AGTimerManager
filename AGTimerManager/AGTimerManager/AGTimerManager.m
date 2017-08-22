//
//  AGCountdownManager.m
//  
//
//  Created by JohnnyB0Y on 2017/5/3.
//  Copyright © 2017年 JohnnyB0Y. All rights reserved.
//  倒计时 manager

#import "AGTimerManager.h"

typedef BOOL(^AGTimerManagerTimerRepeatBlock)(NSTimer *timer, NSMutableDictionary *timerInfo);

static NSString * const kAGTimerManagerCountdownCount   = @"kAGTimerManagerCountdownCount";
static NSString * const kAGTimerManagerRepeatBlock      = @"kAGTimerManagerRepeatBlock";
static NSString * const kAGTimerManagerCompletionBlock  = @"kAGTimerManagerCompletionBlock";
static NSString * const kAGTimerManagerTimer            = @"kAGTimerManagerTimer";

@interface AGTimerManager ()

/** timer 信息仓库 */
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableDictionary *> *timerInfoStorehouse;

@end

@implementation AGTimerManager

#pragma mark - ----------- Life Cycle ----------
+ (instancetype)sharedInstance
{
    static AGTimerManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}

#pragma mark - ---------- Public Methods ----------

- (NSString *) ag_startTimer:(NSUInteger)count
                timeInterval:(NSTimeInterval)ti
                   countdown:(AGTimerManagerCountdownBlock)countdownBlock
                  completion:(AGTimerManagerCompletionBlock)completionBlock
                     forMode:(NSRunLoopMode)mode
{
    if ( ! countdownBlock && ! completionBlock ) return nil;
    if ( count <= 0 || ti <= 0 ) return nil;
    
    @synchronized (self) {
        // 准备 timer
        NSTimer *timer = [self _timerWithTimeInterval:ti repeatBlock:^BOOL(NSTimer *timer, NSMutableDictionary *timerInfo) {
            // 倒计时
            NSUInteger ti = [timerInfo[kAGTimerManagerCountdownCount] unsignedIntegerValue];
            ti--;
            timerInfo[kAGTimerManagerCountdownCount] = [NSNumber numberWithUnsignedInteger:ti];
            
            // 用户计数block
            AGTimerManagerCountdownBlock countdownBlock = timerInfo[kAGTimerManagerRepeatBlock];
            BOOL repeat = countdownBlock ? countdownBlock(ti) : YES;
            if ( ti <= 0 || ! repeat ) {
                // 计时为零 停止计时并调用完成代码块
                AGTimerManagerCompletionBlock completionBlock = timerInfo[kAGTimerManagerCompletionBlock];
                completionBlock ? completionBlock() : nil;
                
                return NO;
            }
            else {
                // 继续倒计时
                return YES;
            }
            
        }];
        
        // 记录 timer info
        NSString *timerKey = [self _keyWithTimer:timer];
        NSMutableDictionary *timerInfo =
        [self _timerInfoWithTimer:timer countdownCount:count+1 repeatBlock:countdownBlock completionBlock:completionBlock];
        [self.timerInfoStorehouse setObject:timerInfo forKey:timerKey];
        
        // 开始 timer
        [self _startTimer:timer forMode:mode];
        return timerKey;
    }
}

- (NSString *) ag_startTimer:(NSUInteger)count
                timeInterval:(NSTimeInterval)ti
                   countdown:(AGTimerManagerCountdownBlock)countdownBlock
                  completion:(AGTimerManagerCompletionBlock)completionBlock
{
    return [self ag_startTimer:count timeInterval:ti countdown:countdownBlock completion:completionBlock forMode:NSRunLoopCommonModes];
}

- (NSString *)ag_startTimer:(NSUInteger)count
                  countdown:(AGTimerManagerCountdownBlock)countdownBlock
                 completion:(AGTimerManagerCompletionBlock)completionBlock
{
    return [self ag_startTimer:count timeInterval:1. countdown:countdownBlock completion:completionBlock];
}

- (NSString *) ag_startTimerWithTimeInterval:(NSTimeInterval)ti repeat:(AGTimerManagerRepeatBlock)repeatBlock
{
    return [self ag_startTimerWithTimeInterval:ti repeat:repeatBlock forMode:NSRunLoopCommonModes];
}

- (NSString *) ag_startTimerWithTimeInterval:(NSTimeInterval)ti
                                      repeat:(AGTimerManagerRepeatBlock)repeatBlock
                                     forMode:(NSRunLoopMode)mode
{
    if ( ! repeatBlock || ti <= 0 ) return nil;
    
    @synchronized (self) {
        // 准备 timer
        NSTimer *timer = [self _timerWithTimeInterval:ti repeatBlock:^BOOL(NSTimer *timer, NSMutableDictionary *timerInfo) {
            // 用户计数block
            AGTimerManagerRepeatBlock repeatBlock = timerInfo[kAGTimerManagerRepeatBlock];
            return repeatBlock ? repeatBlock() : YES;
        }];
        
        // 记录 timer info
        NSString *timerKey = [self _keyWithTimer:timer];
        NSMutableDictionary *timerInfo =
        [self _timerInfoWithTimer:timer countdownCount:ti repeatBlock:repeatBlock completionBlock:nil];
        [self.timerInfoStorehouse setObject:timerInfo forKey:timerKey];
        
        // 开始 timer
        [self _startTimer:timer forMode:mode];
        
        return timerKey;
    }
}

/**
 通过 key 停止定时器
 
 @param key 停止定时器的 key
 */
- (void) ag_stopTimer:(NSString *)key
{
    @synchronized (self) {
        if ( key ) {
            // 停止 - 移除 timer
            NSMutableDictionary *timerInfo = self.timerInfoStorehouse[key];
            NSTimer *timer = timerInfo[kAGTimerManagerTimer];
            [timer invalidate];
            [self.timerInfoStorehouse removeObjectForKey:key];
        }
    }
}

/** 停止所有 timer */
- (void) ag_stopAllTimers
{
    @synchronized (self) {
        [self.timerInfoStorehouse removeAllObjects];
    }
}

#pragma mark - ---------- Private Methods ----------=
- (NSMutableDictionary *) _timerInfoWithTimer:(NSTimer *)timer
                               countdownCount:(NSUInteger)count
                                  repeatBlock:(id)repeatBlock
                              completionBlock:(id)completionBlock
{
    NSMutableDictionary *dictM = [NSMutableDictionary dictionaryWithCapacity:4];
    dictM[kAGTimerManagerTimer] = timer;
    dictM[kAGTimerManagerRepeatBlock] = repeatBlock;
    dictM[kAGTimerManagerCountdownCount] = @(count);
    dictM[kAGTimerManagerCompletionBlock] = completionBlock;
    return dictM;
}

#pragma mark 开始 timer
- (void) _startTimer:(NSTimer *)timer forMode:(NSRunLoopMode)mode
{
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:mode];
}

#pragma mark 获取 timer
- (NSTimer *) _timerWithTimeInterval:(NSTimeInterval)ti
                         repeatBlock:(AGTimerManagerTimerRepeatBlock)block
{
    return [[NSTimer alloc] initWithFireDate:[NSDate date] interval:ti target:self selector:@selector(_repeatSelector:) userInfo:[block copy] repeats:YES];
}

#pragma mark 执行block
- (void) _repeatSelector:(NSTimer *)timer
{
    @synchronized (self) {
        AGTimerManagerTimerRepeatBlock block = timer.userInfo;
        NSString *key = [self _keyWithTimer:timer];
        NSMutableDictionary *timerInfo = self.timerInfoStorehouse[key];
        BOOL repeat = block ? block(timer, timerInfo) : YES;
        if ( ! repeat ) {
            // 停止 - 移除 timer
            [timer invalidate];
            [self.timerInfoStorehouse removeObjectForKey:key];
        }
    }
}

/** 从 timer 获取 timerInfoStorehouse 的 key */
- (NSString *) _keyWithTimer:(NSTimer *)timer
{
    return [NSString stringWithFormat:@"key_%p", timer];
}

#pragma mark - ----------- Getter Methods ----------
- (NSMutableDictionary<NSString *,NSMutableDictionary *> *)timerInfoStorehouse
{
    if (_timerInfoStorehouse == nil) {
        _timerInfoStorehouse = [NSMutableDictionary dictionaryWithCapacity:10];
    }
    return _timerInfoStorehouse;
}

- (NSUInteger)timerCount
{
    @synchronized (self) {
        return self.timerInfoStorehouse.count;
    }
}

@end


/** 获取 timer manager */
AGTimerManager * ag_sharedTimerManager()
{
    return [AGTimerManager sharedInstance];
}
