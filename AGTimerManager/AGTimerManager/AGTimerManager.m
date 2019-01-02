//
//  AGTimerManager.m
//
//
//  Created by JohnnyB0Y on 2017/5/3.
//  Copyright © 2017年 JohnnyB0Y. All rights reserved.
//

#import "AGTimerManager.h"
#import <objc/runtime.h>

typedef BOOL(^AGTMTimerRepeatBlock)(NSTimer *timer, NSMutableDictionary *timerInfo);

//
static NSString * const kAGTMRepeatBlock        = @"kAGTMRepeatBlock";
static NSString * const kAGTMCompletionBlock    = @"kAGTMCompletionBlock";
static NSString * const kAGTMTasksInfo         = @"kAGTMTasksInfo"; // kAGTMRepeatBlock、kAGTMCompletionBlock

//
static NSString * const kAGTMToken              = @"kAGTMToken";
static NSString * const kAGTMTimer              = @"kAGTMTimer";
static NSString * const kAGTMTimerRepeatBlock   = @"kAGTMTimerRepeatBlock";
static NSString * const kAGTMTimerInterval      = @"kAGTMTimerInterval";
static NSString * const kAGTMTimerDelay         = @"kAGTMTimerDelay";
static NSString * const kAGTMTimerRunLoopMode   = @"kAGTMTimerRunLoopMode";


@interface NSTimer (AGTimerManager)
@property (nonatomic, strong) NSString *timerKey;
@end

static void *kAGTMTimerKeyProperty = &kAGTMTimerKeyProperty;

@implementation NSTimer (AGTimerManager)

- (NSString *)timerKey
{
    return objc_getAssociatedObject(self, kAGTMTimerKeyProperty);
}

- (void)setTimerKey:(NSString *)timerKey
{
    objc_setAssociatedObject(self, kAGTMTimerKeyProperty, timerKey, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


#pragma mark timer
@interface __AGTimerManager : NSObject

@property (nonatomic, strong) NSMapTable<id, NSMutableDictionary *> *tokenMapTable;

#pragma mark 任务定时器⏰
- (void) ag_prepareTaskTimer:(id)token
                    timerKey:(NSString **)timerKey
                    interval:(NSTimeInterval)ti
                       delay:(NSTimeInterval)delay;

- (void) ag_addTaskForTimer:(id)token
                   timerKey:(NSString *)timerKey
                  taskToken:(NSString *)taskToken
                     repeat:(AGTMRepeatBlock)repeatBlock
                 completion:(AGTMCompletionBlock)completionBlock;

- (void) ag_removeTaskForTimer:(id)token
                      timerKey:(NSString *)timerKey
                     taskToken:(NSString *)taskToken;

- (void) ag_startTaskTimer:(id)token
                  timerKey:(NSString *)timerKey
                   forMode:(NSRunLoopMode)mode;

#pragma mark 停止定时器⚠️
- (void) ag_stopTaskTimer:(id)token
                 timerKey:(NSString *)timerKey;

- (void) ag_stopAllTimers:(id)token;

+ (instancetype) sharedInstance;

@end


@implementation __AGTimerManager

#pragma mark ----------- Life Cycle ----------
+ (instancetype)sharedInstance
{
    static __AGTimerManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        instance.tokenMapTable = [NSMapTable weakToStrongObjectsMapTable];
    });
    return instance;
}

#pragma mark ---------- Public Methods ----------

#pragma mark 任务定时器⏰
- (void) ag_prepareTaskTimer:(id)token
                    timerKey:(NSString **)timerKey
                    interval:(NSTimeInterval)ti
                       delay:(NSTimeInterval)delay
{
    NSParameterAssert(token);
    NSParameterAssert(timerKey);
    NSAssert(ti > 0, @"Interval must > 0.");
    
    // prepare timer
    NSTimer *timer = [self _timerWithToken:token interval:ti delay:delay];
    
    // timer info
    NSMutableDictionary *timerInfo = [NSMutableDictionary dictionaryWithCapacity:4];
    timerInfo[kAGTMTimerInterval] = [NSNumber numberWithDouble:ti];
    timerInfo[kAGTMTimerDelay] = [NSNumber numberWithDouble:delay];
    timerInfo[kAGTMTimer] = timer;
    
    *timerKey = [self _keyWithTimer:timer];
    timer.timerKey = *timerKey;
    [[self _timersInfoWithToken:token] setObject:timerInfo forKey:timer.timerKey];
}

- (void) ag_addTaskForTimer:(id)token
                   timerKey:(NSString *)timerKey
                  taskToken:(NSString *)taskToken
                     repeat:(AGTMRepeatBlock)repeatBlock
                 completion:(AGTMCompletionBlock)completionBlock
{
    NSParameterAssert(token);
    NSParameterAssert(timerKey);
    NSParameterAssert(taskToken);
    NSParameterAssert(repeatBlock);
    
    if ( ! repeatBlock ) return;
    
    NSMutableDictionary *timerInfo = [self _timersInfoWithToken:token][timerKey];
    if ( timerInfo ) {
        
        [self _addTaskForTimer:token timerKey:timerKey taskToken:taskToken repeat:repeatBlock completion:completionBlock];
        
        NSTimer *timer = timerInfo[kAGTMTimer];
        if ( nil == timer ) {
            // timer stop
            // restart timer
            [self _restartRepeatTimer:token timerKey:timerKey timerInfo:timerInfo];
        }
    }
}

- (void) ag_removeTaskForTimer:(id)token
                      timerKey:(NSString *)timerKey
                     taskToken:(NSString *)taskToken
{
    NSParameterAssert(token);
    NSParameterAssert(timerKey);
    NSParameterAssert(taskToken);
    
    NSMutableDictionary *timerInfo = [self _timersInfoWithToken:token][timerKey];
    NSMutableDictionary *tasksInfo = timerInfo[kAGTMTasksInfo];
    NSMutableDictionary *taskInfo = tasksInfo[taskToken];
    
    if ( taskInfo ) {
        [tasksInfo removeObjectForKey:taskToken];
        // completion call
        [self _completionTaskCallWithTaskInfo:taskInfo];
    }
}

- (void) ag_startTaskTimer:(id)token
                  timerKey:(NSString *)timerKey
                   forMode:(NSRunLoopMode)mode
{
    NSParameterAssert(token);
    NSParameterAssert(timerKey);
    NSParameterAssert(mode);
    
    NSMutableDictionary *timerInfo = [self _timersInfoWithToken:token][timerKey];
    
    NSTimer *timer = timerInfo[kAGTMTimer];
    if ( timer ) {
        timerInfo[kAGTMTimerRunLoopMode] = mode;
        // start timer
        [self _startTimer:timer forMode:mode];
    }
}

#pragma mark 停止定时器⚠️
- (void) ag_stopTaskTimer:(id)token
                 timerKey:(NSString *)timerKey
{
    NSParameterAssert(token);
    NSParameterAssert(timerKey);
    
    if ( timerKey && token ) {
        NSMutableDictionary *timerInfo = [self _timersInfoWithToken:token][timerKey];
        if ( timerInfo ) {
            [[self _timersInfoWithToken:token] removeObjectForKey:timerKey];
            // completion call
            [self _completionBlockCallWithTasksInfo:timerInfo[kAGTMTasksInfo]];
        }
    }
}

- (void) ag_stopAllTimers:(id)token
{
    NSParameterAssert(token);
    if ( token ) {
        
        NSMutableDictionary *timersInfo = [self _timersInfoWithToken:token];
        [self.tokenMapTable removeObjectForKey:token];
        
        [timersInfo enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull timerKey,
                                                        NSMutableDictionary * _Nonnull timerInfo,
                                                        BOOL * _Nonnull stop) {
            
            NSMutableDictionary *tasksInfo = timerInfo[kAGTMTasksInfo];
            if ( tasksInfo ) {
                // completion call
                [self _completionBlockCallWithTasksInfo:tasksInfo];
            }
            
        }];
    }
}

#pragma mark ---------- Private Methods ----------
- (NSMutableDictionary *) _timerInfoWithTimer:(NSTimer *)timer
                                     blockKey:(NSString *)blockKey
                                  repeatBlock:(id)repeatBlock
                              completionBlock:(id)completionBlock
{
    NSMutableDictionary *timerInfo = [NSMutableDictionary dictionaryWithCapacity:4];
    timerInfo[kAGTMTimer] = timer;
    
    NSMutableDictionary *tasksInfo = [NSMutableDictionary dictionaryWithCapacity:2];
    timerInfo[kAGTMTasksInfo] = tasksInfo;
    
    NSMutableDictionary *taskInfo = [NSMutableDictionary dictionaryWithCapacity:2];
    tasksInfo[blockKey] = taskInfo;
    
    taskInfo[kAGTMRepeatBlock] = repeatBlock;
    taskInfo[kAGTMCompletionBlock] = completionBlock;
    
    return timerInfo;
}

- (void) _addTaskForTimer:(id)token
                 timerKey:(NSString *)timerKey
                taskToken:(NSString *)taskToken
                   repeat:(AGTMRepeatBlock)repeatBlock
               completion:(AGTMCompletionBlock)completionBlock
{
    NSMutableDictionary *timerInfo = [self _timersInfoWithToken:token][timerKey];
    
    NSMutableDictionary *tasksInfo = [NSMutableDictionary dictionaryWithCapacity:2];
    timerInfo[kAGTMTasksInfo] = tasksInfo;
    
    NSMutableDictionary *taskInfo = [NSMutableDictionary dictionaryWithCapacity:2];
    tasksInfo[taskToken] = taskInfo;
    
    taskInfo[kAGTMRepeatBlock] = repeatBlock;
    taskInfo[kAGTMCompletionBlock] = completionBlock;
}

- (NSTimer *) _timerWithToken:(id)token
                     interval:(NSTimeInterval)ti
                        delay:(NSTimeInterval)delay
{
    return [self _timerWithToken:token interval:ti delay:delay repeatBlock:^BOOL(NSTimer *timer,
                                                                                 NSMutableDictionary *timerInfo) {
        
        // blocks
        NSMutableDictionary<NSString *, NSMutableDictionary *> *tasksInfo = timerInfo[kAGTMTasksInfo];
        for (NSString *taskToken in tasksInfo.allKeys) {
            
            NSMutableDictionary *taskInfo = tasksInfo[taskToken];
            AGTMRepeatBlock repeatBlock = [taskInfo objectForKey:kAGTMRepeatBlock];
            AGTMCompletionBlock completionBlock = [taskInfo objectForKey:kAGTMCompletionBlock];
            
            // repeat ?
            BOOL repeat = NO;
            if ( repeatBlock ) {
                repeat = repeatBlock();
            }
            
            if ( NO == repeat ) {
                [tasksInfo removeObjectForKey:taskToken];
                
                // completion ?
                completionBlock ? completionBlock() : nil;
            }
        }
        
        return tasksInfo.count > 0;
    }];
}

#pragma mark 开始 timer
- (void) _startTimer:(NSTimer *)timer forMode:(NSRunLoopMode)mode
{
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:mode];
}

- (void) _restartRepeatTimer:(id)token
                    timerKey:(NSString *)timerKey
                   timerInfo:(NSMutableDictionary *)timerInfo
{
    NSParameterAssert(token);
    NSParameterAssert(timerKey);
    NSParameterAssert(timerInfo);
    
    NSTimeInterval ti = [timerInfo[kAGTMTimerInterval] doubleValue];
    NSTimeInterval delay = [timerInfo[kAGTMTimerDelay] doubleValue];
    NSRunLoopMode mode = timerInfo[kAGTMTimerRunLoopMode];
    
    // prepare timer
    NSTimer *timer = [self _timerWithToken:token interval:ti delay:delay];
    timer.timerKey = timerKey;
    timerInfo[kAGTMTimer] = timer;
    
    // start timer
    [self _startTimer:timer forMode:mode];
}

- (void) _completionBlockCallWithTasksInfo:(NSMutableDictionary *)tasksInfo
{
    NSParameterAssert(tasksInfo);
    [tasksInfo enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key,
                                                   NSMutableDictionary * _Nonnull taskInfo,
                                                   BOOL * _Nonnull stop) {
        [self _completionTaskCallWithTaskInfo:taskInfo];
    }];
}

- (void) _completionTaskCallWithTaskInfo:(NSMutableDictionary *)taskInfo
{
    NSParameterAssert(taskInfo);
    AGTMCompletionBlock completion = taskInfo[kAGTMCompletionBlock];
    // completion
    if ( completion ) {
        completion();
    }
}

#pragma mark 获取 timer
- (NSTimer *) _timerWithToken:(id)token
                     interval:(NSTimeInterval)ti
                        delay:(NSTimeInterval)delay
                  repeatBlock:(AGTMTimerRepeatBlock)repeatBlock
{
    NSDate *fireDate = [NSDate dateWithTimeIntervalSinceNow:delay];
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:2];
    userInfo[kAGTMTimerRepeatBlock] = [repeatBlock copy];
    NSMapTable *tokenMapTable = [NSMapTable weakToWeakObjectsMapTable];
    [tokenMapTable setObject:token forKey:kAGTMToken];
    userInfo[kAGTMToken] = tokenMapTable;
    
    return [[NSTimer alloc] initWithFireDate:fireDate
                                    interval:ti
                                      target:self
                                    selector:@selector(_repeatSelector:)
                                    userInfo:userInfo
                                     repeats:YES];
}

#pragma mark timer repeat action
- (void) _repeatSelector:(NSTimer *)timer
{
    NSDictionary *userInfo = timer.userInfo;
    id token = [userInfo[kAGTMToken] objectForKey:kAGTMToken];
    NSMutableDictionary *timerInfo = [self _timersInfoWithToken:token][timer.timerKey];
    
    if ( timerInfo ) {
        AGTMTimerRepeatBlock repeatBlock = userInfo[kAGTMTimerRepeatBlock];
        BOOL repeat = repeatBlock ? repeatBlock(timer, timerInfo) : YES;
        if ( ! repeat ) {
            // remove timer
            [timer invalidate];
            [timerInfo removeObjectForKey:kAGTMTimer];
        }
    }
    else {
        // stop timer
        [timer invalidate];
    }
}

/** generation timerInfo`s key */
- (NSString *) _keyWithTimer:(NSTimer *)timer
{
    return [NSString stringWithFormat:@"tk_%p", timer];
}

/** get timersInfo */
- (NSMutableDictionary<NSString *, NSMutableDictionary *> *) _timersInfoWithToken:(id)token
{
    if ( token == nil ) return nil;
    
    NSMutableDictionary *timerInfo = [self.tokenMapTable objectForKey:token];
    if ( ! timerInfo ) {
        timerInfo = [NSMutableDictionary dictionaryWithCapacity:3];
        [self.tokenMapTable setObject:timerInfo forKey:token];
    }
    return timerInfo;
}

@end



@implementation AGTimerManager

#pragma mark 共享定时器🍩
- (void) ag_prepareTaskTimer:(NSString **)timerKey
                    interval:(NSTimeInterval)ti
                       delay:(NSTimeInterval)delay
{
    __AGTimerManager *tm = [__AGTimerManager sharedInstance];
    [tm ag_prepareTaskTimer:self timerKey:timerKey interval:ti delay:delay];
}

- (void) ag_addTaskForTimer:(NSString *)timerKey
                  taskToken:(NSString *)taskToken
                     repeat:(AGTMRepeatBlock)repeatBlock
                 completion:(AGTMCompletionBlock)completionBlock
{
    __AGTimerManager *tm = [__AGTimerManager sharedInstance];
    [tm ag_addTaskForTimer:self timerKey:timerKey taskToken:taskToken repeat:repeatBlock completion:completionBlock];
}

- (void) ag_removeTaskForTimer:(NSString *)timerKey
                     taskToken:(NSString *)taskToken
{
    [[__AGTimerManager sharedInstance] ag_removeTaskForTimer:self  timerKey:timerKey taskToken:taskToken];
}

- (void) ag_startTaskTimer:(NSString *)timerKey
                   forMode:(NSRunLoopMode)mode
{
    [[__AGTimerManager sharedInstance] ag_startTaskTimer:self timerKey:timerKey forMode:mode];
}

/**
 通过 key 停止定时器
 
 @param key 停止定时器的 key
 */
- (void) ag_stopTimerForKey:(NSString *)key
{
	[[__AGTimerManager sharedInstance] ag_stopTaskTimer:self timerKey:key];
}

/** 停止所有 timer */
- (void) ag_stopAllTimers
{
	[[__AGTimerManager sharedInstance] ag_stopAllTimers:self];
}

#pragma mark ----------- Override Methods ----------
- (NSString *) debugDescription
{
    return [self description];
}

- (NSString *)description
{
	__AGTimerManager *tm = [__AGTimerManager sharedInstance];
    NSMutableDictionary *timerInfo = [tm.tokenMapTable objectForKey:self];
	return [NSString stringWithFormat:@"<%@: %p> -- %@", [tm class] , tm, timerInfo];
}

@end


@implementation AGTimerManager (AGRepeatTimer)

#pragma mark 定时器⏰
- (NSString *) ag_startRepeatTimer:(NSTimeInterval)ti
                            repeat:(AGTMRepeatBlock)repeatBlock
{
    return [self ag_startRepeatTimer:ti delay:0. forMode:NSRunLoopCommonModes repeat:repeatBlock];
}

- (NSString *) ag_startRepeatTimer:(NSTimeInterval)ti
                             delay:(NSTimeInterval)delay
                            repeat:(AGTMRepeatBlock)repeatBlock
{
    return [self ag_startRepeatTimer:ti delay:delay forMode:NSRunLoopCommonModes repeat:repeatBlock];
}

- (NSString *) ag_startRepeatTimer:(NSTimeInterval)ti
                           forMode:(NSRunLoopMode)mode
                            repeat:(AGTMRepeatBlock)repeatBlock
{
    return [self ag_startRepeatTimer:ti delay:0. forMode:NSRunLoopCommonModes repeat:repeatBlock];
}

- (NSString *) ag_startRepeatTimer:(NSTimeInterval)ti
                             delay:(NSTimeInterval)delay
                           forMode:(NSRunLoopMode)mode
                            repeat:(AGTMRepeatBlock)repeatBlock
{
    NSString *timerKey;
    [self ag_prepareTaskTimer:&timerKey interval:ti delay:0.];
    [self ag_addTaskForTimer:timerKey taskToken:@"__AGRepeatTaskToken" repeat:repeatBlock completion:nil];
    [self ag_startTaskTimer:timerKey forMode:mode];
    return timerKey;
}

@end


@implementation AGTimerManager (AGDateTimer)

#pragma mark 日期倒计时📆
- (NSString *)ag_startCountdownDate:(NSDate *)date
                           interval:(NSTimeInterval)ti
                          countdown:(AGTMDateCountdownBlock)countdownBlock
                         completion:(AGTMCompletionBlock)completionBlock
{
    NSTimeInterval timeInterval = [date timeIntervalSinceDate:[NSDate date]];
    if ( timeInterval <= 0 ) {
        completionBlock ? completionBlock() : nil;
        return nil;
    }
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSCalendarUnit unitFlags
    = NSCalendarUnitYear| NSCalendarUnitMonth| NSCalendarUnitDay| NSCalendarUnitHour| NSCalendarUnitMinute| NSCalendarUnitSecond;
    
    return [self ag_startCountdownTimer:timeInterval interval:ti countdown:^BOOL(NSTimeInterval surplus) {
        
        if ( countdownBlock ) {
            NSDateComponents *comp = [calendar components:unitFlags fromDate:[NSDate date] toDate:date options:0];
            countdownBlock(calendar, comp);
        }
        
        return YES;
        
    } completion:^{
        
        if ( completionBlock ) {
            completionBlock();
        }
        
    }];
    
}

- (NSString *)ag_startCountdownDate:(NSDate *)date
                          countdown:(AGTMDateCountdownBlock)countdownBlock
                         completion:(AGTMCompletionBlock)completionBlock
{
    return [self ag_startCountdownDate:date interval:1. countdown:countdownBlock completion:completionBlock];
}

- (NSString *)ag_startCountdownDateInterval:(NSTimeInterval)timeIntervalSinceNow
                                  countdown:(AGTMDateCountdownBlock)countdownBlock
                                 completion:(AGTMCompletionBlock)completionBlock
{
    if ( timeIntervalSinceNow <= 0 ) {
        completionBlock ? completionBlock() : nil;
        return nil;
    }
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:timeIntervalSinceNow];
    return [self ag_startCountdownDate:date interval:1. countdown:countdownBlock completion:completionBlock];
}

@end


@implementation AGTimerManager (AGCountDownTimer)

#pragma mark 倒计时⏳
- (NSString *) ag_startCountdownTimer:(NSTimeInterval)duration
                             interval:(NSTimeInterval)ti
                              forMode:(NSRunLoopMode)mode
                            countdown:(AGTMCountdownBlock)countdownBlock
                           completion:(AGTMCompletionBlock)completionBlock
{
    if ( duration <= 0 ) return nil;
    
    NSString *timerKey;
    __block NSTimeInterval countdown = duration;
    [self ag_prepareTaskTimer:&timerKey interval:ti delay:0.];
    
    [self ag_addTaskForTimer:timerKey taskToken:@"__AGCountdownTaskToken" repeat:^BOOL{
        
        countdown -= ti;
        
        BOOL repeat = YES;
        if ( countdownBlock ) {
            repeat = countdownBlock(countdown);
        }
        
        if ( NO == repeat ) {
            return NO;
        }
        
        if ( countdown <= 0 && completionBlock ) {
            completionBlock();
        }
        
        return countdown > 0;
        
    } completion:nil];
    
    [self ag_startTaskTimer:timerKey forMode:mode];
    
    return timerKey;
}

- (NSString *) ag_startCountdownTimer:(NSTimeInterval)duration
                            countdown:(AGTMCountdownBlock)countdownBlock
                           completion:(AGTMCompletionBlock)completionBlock
{
    return [self ag_startCountdownTimer:duration
                               interval:1.
                                forMode:NSRunLoopCommonModes
                              countdown:countdownBlock
                             completion:completionBlock];
}

- (NSString *) ag_startCountdownTimer:(NSTimeInterval)duration
                             interval:(NSTimeInterval)ti
                            countdown:(AGTMCountdownBlock)countdownBlock
                           completion:(AGTMCompletionBlock)completionBlock
{
    return [self ag_startCountdownTimer:duration
                               interval:ti
                                forMode:NSRunLoopCommonModes
                              countdown:countdownBlock
                             completion:completionBlock];
}

@end
