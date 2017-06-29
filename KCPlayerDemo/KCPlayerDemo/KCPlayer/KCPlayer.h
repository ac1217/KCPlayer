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
    KCPlayerStatusPause, // 暂停状态
    KCPlayerStatusPlay // 播放状态
} KCPlayerStatus;

typedef enum : NSUInteger {
    KCPlayerPlayModeSingleLoop, // 单曲循环
    KCPlayerPlayModeListLoop, // 列表循环
    KCPlayerPlayModeListPlay, // 列表播放
    KCPlayerPlayModePlayRandom // 随机播放
} KCPlayerPlayMode;

@interface KCPlayer : NSObject

+ (instancetype)sharedPlayer;

@property (nonatomic,strong) NSArray <KCPlayerItem *>*currentItems;
@property (nonatomic,strong, readonly) KCPlayerItem *currentItem;
@property (nonatomic,assign, readonly) NSUInteger currentItemIndex;


@property (nonatomic,strong) AVQueuePlayer *player;
@property (nonatomic,strong) KCPlayerView *playerView;

@property (nonatomic,assign) KCPlayerStatus status;

@property (nonatomic,copy) void(^playerItemDidChangedBlock)(KCPlayerItem *oldItemL, KCPlayerItem *newItem);

@property (nonatomic,copy) void(^playerItemStatusDidChangedBlock)(AVPlayerItemStatus status);

@property (nonatomic,copy) void(^playerStatusDidChangedBlock)(KCPlayerStatus status);

@property (nonatomic,copy) void(^playerItemProgressDidChangeBlock)(float currentTime, float duration, float progress);

@property (nonatomic,copy) void(^playerItemLoadedTimeRangesDidChangedBlock)(float currentTime, float duration, float progress);

@property (nonatomic,copy) void(^playerItemDidPlayToEndTimeBlock)(KCPlayerItem *item);
@property (nonatomic,copy) void(^allPlayerItemDidPlayToEndTimeBlock)();

- (void)seekToTime:(NSTimeInterval)time completionHandler:(void (^)(BOOL finished))completionHandler;

- (void)seekToProgress:(float)progress completionHandler:(void (^)(BOOL finished))completionHandler;

@property (nonatomic,assign) float rate;

@property (nonatomic,assign) float volume;

@property (nonatomic,assign, readonly) float duration;

@property (nonatomic,assign) NSInteger loopCount;

@property (nonatomic,assign) BOOL autoPlay;

@property (nonatomic,assign) BOOL playInBackground;


- (void)play;
- (void)pause;

/*********** desperate ***********/
@property (nonatomic,strong) NSURL *currentURL;
@property (nonatomic,strong) NSArray *currentURLs;

@end
