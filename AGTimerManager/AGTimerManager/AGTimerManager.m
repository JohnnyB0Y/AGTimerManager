//
//  AGTimerManager.m
//
//
//  Created by JohnnyB0Y on 2017/5/3.
//  Copyright © 2017年 JohnnyB0Y. All rights reserved.
//

#import "AGTimerManager.h"
#import <objc/runtime.h>

typedef BOOL(^AGTimerManagerTimerRepeatBlock)(NSTimer *timer, NSMutableDictionary *timerInfo);

static NSString * const kAGTimerManagerCountdownCount   = @"kAGTimerManagerCountdownCount";
static NSString * const kAGTimerManagerRepeatBlock      = @"kAGTimerManagerRepeatBlock";
static NSString * const kAGTimerManagerCompletionBlock  = @"kAGTimerManagerCompletionBlock";
static NSString * const kAGTimerManagerTimer            = @"kAGTimerManagerTimer";

// timer's userInfo key
static NSString * const kAGTimerManagerTimerRepeatBlock = @"kAGTimerManagerTimerRepeatBlock";
static NSString * const kAGTimerManagerToken   = @"kAGTimerManagerToken";



@interface AGTimerManager ()

@property (nonatomic, strong) NSMapTable<id, NSMutableDictionary *> *tokenMapTable;
@property (nonatomic, strong) id currentToken;
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
    
    // 准备 timer
    NSTimer *timer =
    [self _timerWithTimeInterval:ti repeatBlock:^BOOL(NSTimer *timer,
                                                      NSMutableDictionary *timerInfo) {
        // 倒计时
        NSUInteger ti = [timerInfo[kAGTimerManagerCountdownCount] unsignedIntegerValue];
        ti--;
        timerInfo[kAGTimerManagerCountdownCount] = [NSNumber numberWithUnsignedInteger:ti];
        
        // 用户计数 block
        AGTimerManagerCountdownBlock countdownBlock = timerInfo[kAGTimerManagerRepeatBlock];
        BOOL repeat = countdownBlock ? countdownBlock(ti) : YES;
        if ( ti <= 0 || ! repeat ) {
            // 计时为零 停止计时并调用完成代码块
            AGTimerManagerCompletionBlock completionBlock =
            timerInfo[kAGTimerManagerCompletionBlock];
            
            completionBlock ? completionBlock() : nil;
            
            return NO;
        }
        
        // 继续倒计时
        return YES;
    } delay:0.];
    
    // 记录 timer info
    NSMutableDictionary *timerInfo = [self _timerInfoWithTimer:timer
                                                countdownCount:count+1
                                                   repeatBlock:countdownBlock
                                               completionBlock:completionBlock];
    
    NSString *timerKey = [self _keyWithTimer:timer];
    [[self _timerInfoWithToken:self.currentToken] setObject:timerInfo forKey:timerKey];
    
    // 开始 timer
    [self _startTimer:timer forMode:mode];
    
    return timerKey;
}

- (NSString *) ag_startTimer:(NSUInteger)count
                timeInterval:(NSTimeInterval)ti
                   countdown:(AGTimerManagerCountdownBlock)countdownBlock
                  completion:(AGTimerManagerCompletionBlock)completionBlock
{
    return [self ag_startTimer:count
                  timeInterval:ti
                     countdown:countdownBlock
                    completion:completionBlock
                       forMode:NSRunLoopCommonModes];
}

- (NSString *)ag_startTimer:(NSUInteger)count
                  countdown:(AGTimerManagerCountdownBlock)countdownBlock
                 completion:(AGTimerManagerCompletionBlock)completionBlock
{
    return [self ag_startTimer:count
                  timeInterval:1.
                     countdown:countdownBlock
                    completion:completionBlock];
}

- (NSString *) ag_startTimerWithTimeInterval:(NSTimeInterval)ti
                                      repeat:(AGTimerManagerRepeatBlock)repeatBlock
{
    return [self ag_startTimerWithTimeInterval:ti
                                        repeat:repeatBlock
                                       forMode:NSRunLoopCommonModes];
}

- (NSString *) ag_startTimerWithTimeInterval:(NSTimeInterval)ti
                                      repeat:(AGTimerManagerRepeatBlock)repeatBlock
                                       delay:(NSTimeInterval)delay
{
    return [self ag_startTimerWithTimeInterval:ti repeat:repeatBlock forMode:NSRunLoopCommonModes delay:delay];
}

- (NSString *) ag_startTimerWithTimeInterval:(NSTimeInterval)ti
                                      repeat:(AGTimerManagerRepeatBlock)repeatBlock
                                     forMode:(NSRunLoopMode)mode
{
    return [self ag_startTimerWithTimeInterval:ti repeat:repeatBlock forMode:mode delay:0.];
}

- (NSString *) ag_startTimerWithTimeInterval:(NSTimeInterval)ti
                                      repeat:(AGTimerManagerRepeatBlock)repeatBlock
                                     forMode:(NSRunLoopMode)mode
                                       delay:(NSTimeInterval)delay
{
    if ( ! repeatBlock || ti <= 0 ) return nil;
    
    // 准备 timer
    NSTimer *timer =
    [self _timerWithTimeInterval:ti repeatBlock:^BOOL(NSTimer *timer,
                                                      NSMutableDictionary *timerInfo) {
        // 定时任务 block
        AGTimerManagerRepeatBlock repeatBlock = timerInfo[kAGTimerManagerRepeatBlock];
        return repeatBlock ? repeatBlock() : YES;
    } delay:delay];
    
    // 记录 timer info
    NSMutableDictionary *timerInfo = [self _timerInfoWithTimer:timer
                                                countdownCount:ti
                                                   repeatBlock:repeatBlock
                                               completionBlock:nil];
    
    NSString *timerKey = [self _keyWithTimer:timer];
    [[self _timerInfoWithToken:self.currentToken] setObject:timerInfo forKey:timerKey];
    
    // 开始 timer
    [self _startTimer:timer forMode:mode];
    
    return timerKey;
}

/**
 通过 key 停止定时器
 
 @param key 停止定时器的 key
 */
- (void) ag_stopTimer:(NSString *)key
{
    if ( key ) {
        [[self _timerInfoWithToken:self.currentToken] removeObjectForKey:key];
    }
    
}

/** 停止所有 timer */
- (void) ag_stopAllTimers
{
    if ( self.currentToken ) {
        [self.tokenMapTable removeObjectForKey:self.currentToken];
    }
    else {
        [self.tokenMapTable removeAllObjects];
    }
}

#pragma mark - ---------- Private Methods ----------
- (NSMutableDictionary *) _timerInfoWithTimer:(NSTimer *)timer
                               countdownCount:(NSTimeInterval)count
                                  repeatBlock:(id)repeatBlock
                              completionBlock:(id)completionBlock
{
    NSMutableDictionary *dictM = [NSMutableDictionary dictionaryWithCapacity:4];
    dictM[kAGTimerManagerTimer] = timer;
    dictM[kAGTimerManagerRepeatBlock] = repeatBlock;
    dictM[kAGTimerManagerCountdownCount] = [NSNumber numberWithFloat:count];
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
                               delay:(NSTimeInterval)delay
{
    NSDate *fireDate = [NSDate dateWithTimeIntervalSinceNow:delay];
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:2];
    userInfo[kAGTimerManagerTimerRepeatBlock] = [block copy];
    NSMapTable *tokenMapTable = [NSMapTable weakToWeakObjectsMapTable];
    [tokenMapTable setObject:self.currentToken forKey:kAGTimerManagerToken];
    userInfo[kAGTimerManagerToken] = tokenMapTable;
    
    return [[NSTimer alloc] initWithFireDate:fireDate
                                    interval:ti
                                      target:self
                                    selector:@selector(_repeatSelector:)
                                    userInfo:userInfo
                                     repeats:YES];
}

#pragma mark 执行block
- (void) _repeatSelector:(NSTimer *)timer
{
    NSDictionary *userInfo = timer.userInfo;
    AGTimerManagerTimerRepeatBlock repeatBlock = userInfo[kAGTimerManagerTimerRepeatBlock];
    id token = [userInfo[kAGTimerManagerToken] objectForKey:kAGTimerManagerToken];
    
    NSString *key = [self _keyWithTimer:timer];
    NSMutableDictionary *timerInfo = [self _timerInfoWithToken:token][key];
    BOOL repeat = repeatBlock ? repeatBlock(timer, timerInfo) : YES;
    
    if ( ! repeat ) {
        // 移除 timer
        [[self _timerInfoWithToken:token] removeObjectForKey:key];
    }
}

/** 从 timer 获取 timerInfo 的 key */
- (NSString *) _keyWithTimer:(NSTimer *)timer
{
    return [NSString stringWithFormat:@"tk_%p", timer];
}

/** 通过 token 获取 timerInfo */
- (NSMutableDictionary<NSString *,NSMutableDictionary *> *) _timerInfoWithToken:(id)token
{
    NSMutableDictionary *timerInfo = [self.tokenMapTable objectForKey:token];
    if ( ! timerInfo ) {
        timerInfo = [NSMutableDictionary dictionaryWithCapacity:10];
        [self.tokenMapTable setObject:timerInfo forKey:token];
    }
    return timerInfo;
}

#pragma mark - ----------- Override Methods ----------
- (NSString *) debugDescription
{
    return [NSString stringWithFormat:@"<%@: %p> -- %@", [self class] , self, self.tokenMapTable];
}

#pragma mark - ----------- Getter Methods ----------
- (NSMapTable *)tokenMapTable
{
    if (_tokenMapTable == nil) {
        _tokenMapTable = [NSMapTable weakToStrongObjectsMapTable];
    }
    return _tokenMapTable;
}

@end


/** 获取 timer manager */
AGTimerManager * ag_sharedTimerManager(id token)
{
    AGTimerManager *tm = [AGTimerManager sharedInstance];
    tm.currentToken = token;
    return tm;
}

