//
//  KSMediaTool.h
//  KCPhotoBrowser
//
//  Created by zhangweiwei on 2017/6/12.
//  Copyright © 2017年 Erica. All rights reserved.
//



#import <AVFoundation/AVFoundation.h>

#import "KCPlayerView.h"
#import "KCPlayerItem.h"

typedef enum : NSUInteger {
    KCPlayerStatusDefault,
    KCPlayerStatusBuffering,
    KCPlayerStatusReady,
    KCPlayerStatusPause, // 暂停状态
    KCPlayerStatusPlaying, // 播放状态
    KCPlayerStatusCompleted,
    KCPlayerStatusFailed
} KCPlayerStatus;

typedef enum : NSUInteger {
    KCPlayerPlayModeDefault, // 顺序播放
    KCPlayerPlayModeLoop, // 循环播放
    KCPlayerPlayModeSingle, // 单曲播放
    KCPlayerPlayModeSingleLoop, // 单曲循环
    KCPlayerPlayModeRandom // 随机播放
} KCPlayerPlayMode;

@interface KCPlayer : NSObject

+ (instancetype)sharedPlayer;
// 需要播放的资源
@property (nonatomic,strong) NSArray <KCPlayerItem *>*items;
// 当前播放的资源
@property (nonatomic,strong, readonly) KCPlayerItem *currentItem;
// 当前播放的资源索引
@property (nonatomic,assign, readonly) NSUInteger currentItemIndex;

// 播放器
@property (nonatomic,strong) AVQueuePlayer *player;
// 播放器视图
@property (nonatomic,strong) KCPlayerView *playerView;

// 播放器状态
@property (nonatomic,assign) KCPlayerStatus status;

// 播放器资源切换回调
@property (nonatomic,copy) void(^playerItemDidChangedBlock)(KCPlayerItem *oldItemL, KCPlayerItem *newItem);

// 播放器资源状态改变回调
@property (nonatomic,copy) void(^playerItemStatusDidChangedBlock)(KCPlayerItem *item, AVPlayerItemStatus status);

// 播放器状态改变回调
@property (nonatomic,copy) void(^playerStatusDidChangedBlock)(KCPlayerStatus status);

// 播放进度回调
@property (nonatomic,copy) void(^playerItemProgressDidChangeBlock)(float currentTime, float duration, float progress);

// 加载进度回调
@property (nonatomic,copy) void(^playerItemLoadedTimeRangesDidChangedBlock)(float currentTime, float duration, float progress);

// 资源播放结束回调
@property (nonatomic,copy) void(^playerItemDidPlayToEndTimeBlock)(KCPlayerItem *item);

// 所有资源播放结束回调
@property (nonatomic,copy) void(^allPlayerItemDidPlayToEndTimeBlock)();

// 跳到某个时间点
- (void)seekToTime:(NSTimeInterval)time completionHandler:(void (^)(BOOL finished))completionHandler;

- (void)seekToItemAtIndex:(NSUInteger)index;

// 跳到某个进度
- (void)seekToProgress:(float)progress completionHandler:(void (^)(BOOL finished))completionHandler;

// 播放速率,此属性只支持0.5-2倍速率，需要使用其他速率请设置item的rate
@property (nonatomic,assign) float rate;

// 播放音量
@property (nonatomic,assign) float volume;

// 当前资源播放时长
@property (nonatomic,assign, readonly) float duration;

// 所有资源循环次数
@property (nonatomic,assign) NSInteger loopCount;

// 是否自动开始播放
@property (nonatomic,assign) BOOL autoPlay;

// 是否支持后台播放
@property (nonatomic,assign) BOOL playInBackground;

// 播放模式
@property (nonatomic,assign) KCPlayerPlayMode playMode;

// 播放
- (void)play;
// 暂停
- (void)pause;

/*********** desperate ***********/
@property (nonatomic,strong) NSURL *currentURL;
@property (nonatomic,strong) NSArray <NSURL *>*currentURLs;

@end
