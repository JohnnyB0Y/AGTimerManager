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

@interface AGTimerManager ()

/** 方法调用锁 */
@property (nonatomic, strong) NSLock *invokeLock;

/** 令牌集合 */
@property (nonatomic, strong) NSMapTable *tokenMapTable;

/** 当前调用令牌 */
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
    
//    // 调用前 - 上锁
//    BOOL canLock = [instance.invokeLock tryLock];
//    NSAssert(canLock, @"您可能在某处单独调用了 ag_sharedTimerManager() 导致死锁了。 !");
    
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
    }];
    
    // 记录 timer info
    NSMutableDictionary *timerInfo = [self _timerInfoWithTimer:timer
                                                countdownCount:count+1
                                                   repeatBlock:countdownBlock
                                               completionBlock:completionBlock];
    
    NSString *timerKey = [self _keyWithTimer:timer];
    [self.timerInfo setObject:timerInfo forKey:timerKey];
    
    // 开始 timer
    [self _startTimer:timer forMode:mode];
    
    
//    // 调用完 - 解锁
//    [self.invokeLock unlock];
    
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
                                     forMode:(NSRunLoopMode)mode
{
    if ( ! repeatBlock || ti <= 0 ) return nil;
    
    // 准备 timer
    NSTimer *timer =
    [self _timerWithTimeInterval:ti repeatBlock:^BOOL(NSTimer *timer,
                                       NSMutableDictionary *timerInfo) {
        // 定时任务 block
        AGTimerManagerRepeatBlock repeatBlock = timerInfo[kAGTimerManagerRepeatBlock];
        return repeatBlock ? repeatBlock() : YES;
    }];
    
    // 记录 timer info
    NSMutableDictionary *timerInfo = [self _timerInfoWithTimer:timer
                                                countdownCount:ti
                                                   repeatBlock:repeatBlock
                                               completionBlock:nil];
    
    NSString *timerKey = [self _keyWithTimer:timer];
    [self.timerInfo setObject:timerInfo forKey:timerKey];
    
    // 开始 timer
    [self _startTimer:timer forMode:mode];
    
    
//    // 调用完 - 解锁
//    [self.invokeLock unlock];
    
    return timerKey;
}

/**
 通过 key 停止定时器
 
 @param key 停止定时器的 key
 */
- (void) ag_stopTimer:(NSString *)key
{
    if ( key ) {
        [self.timerInfo removeObjectForKey:key];
    }
    
//    // 调用完 - 解锁
//    [self.invokeLock unlock];
}

/** 停止所有 timer */
- (void) ag_stopAllTimers
{
    [self.tokenMapTable removeObjectForKey:self.currentToken];
//    // 调用完 - 解锁
//    [self.invokeLock unlock];
}

#pragma mark - ---------- Private Methods ----------
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
    return [[NSTimer alloc] initWithFireDate:[NSDate date]
                                    interval:ti
                                      target:self
                                    selector:@selector(_repeatSelector:)
                                    userInfo:[block copy]
                                     repeats:YES];
}

#pragma mark 执行block
- (void) _repeatSelector:(NSTimer *)timer
{
    AGTimerManagerTimerRepeatBlock repeatBlock = timer.userInfo;
    NSString *key = [self _keyWithTimer:timer];
    NSMutableDictionary *timerInfo = self.timerInfo[key];
    BOOL repeat = repeatBlock ? repeatBlock(timer, timerInfo) : YES;
    if ( ! repeat ) {
        // 移除 timer
        [self.timerInfo removeObjectForKey:key];
    }
}

/** 从 timer 获取 timerInfo 的 key */
- (NSString *) _keyWithTimer:(NSTimer *)timer
{
    return [NSString stringWithFormat:@"tk_%p", timer];
}

#pragma mark - ----------- Override Methods ----------
- (NSString *) debugDescription
{
    uint count;
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    
    NSMutableDictionary *dictM = [NSMutableDictionary dictionaryWithCapacity:count];
    for ( int i = 0; i<count; i++ ) {
        objc_property_t property = properties[i];
        NSString *name = @(property_getName(property));
        id value = [self valueForKey:name] ?: @"nil";
        [dictM setObject:value forKey:name];
    }
    
    free(properties);
    return [NSString stringWithFormat:@"<%@: %p> -- %@", [self class] , self, dictM];
}

#pragma mark - ----------- Getter Methods ----------
- (NSMutableDictionary<NSString *,NSMutableDictionary *> *)timerInfo
{
    NSMutableDictionary *timerInfo = [self.tokenMapTable objectForKey:self.currentToken];
    
    if ( ! timerInfo ) {
        timerInfo = [NSMutableDictionary dictionaryWithCapacity:10];
        [self.tokenMapTable setObject:timerInfo forKey:self.currentToken];
    }
    return timerInfo;
}

- (NSMapTable *)tokenMapTable
{
    if (_tokenMapTable == nil) {
        _tokenMapTable = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsWeakMemory
                                               valueOptions:NSPointerFunctionsStrongMemory];
    }
    return _tokenMapTable;
}

- (NSLock *)invokeLock
{
    if (_invokeLock == nil) {
        _invokeLock = [[NSLock alloc] init];
    }
    return _invokeLock;
}

@end


/** 获取 timer manager */
AGTimerManager * ag_sharedTimerManager(id token)
{
    AGTimerManager *tm = [AGTimerManager sharedInstance];
    tm.currentToken = token;
    return tm;
}

