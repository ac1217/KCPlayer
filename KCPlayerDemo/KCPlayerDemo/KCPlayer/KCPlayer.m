//
//  KSMediaTool.m
//  KCPhotoBrowser
//
//  Created by zhangweiwei on 2017/6/12.
//  Copyright © 2017年 Erica. All rights reserved.
//

#import "KCPlayer.h"

static NSString *const AVPlayerItemStatusKey = @"status";
static NSString *const AVPlayerCurrentItemKey = @"currentItem";
static NSString *const AVPlayerItemLoadedTimeRangesKey = @"loadedTimeRanges";
static NSString *const KCPlayerItemItemKey = @"item";
static NSString *const KCPlayerItemRateKey = @"rate";

@interface KCPlayer ()

@property (nonatomic,strong) id timeObserver;

@property (nonatomic,assign) NSInteger currentLoopCount;

@end

@implementation KCPlayer

#pragma mark -Getter
- (KCPlayerItem *)currentItem
{
    return [self KCPlayerItemOfAVPlayerItem:self.player.currentItem];
}

- (NSUInteger)currentItemIndex
{
    
    return [self KCPlayerItemIndexOfAVPlayerItem:self.player.currentItem];
}

- (void)setRate:(float)rate
{
    self.player.rate = rate;
}

- (float)rate
{
    return self.currentItem.rate;
}


- (void)setVolume:(float)volume
{
    self.player.volume = volume;
}

- (float)volume
{
    return self.player.volume;
}


- (float)duration
{
    return CMTimeGetSeconds(self.player.currentItem.duration);
}

- (KCPlayerView *)playerView
{
    if (!_playerView) {
        _playerView = [[KCPlayerView alloc] init];
        
    }
    return _playerView;
}

#pragma mark -Instance
+ (instancetype)sharedPlayer
{
    static id instance_;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance_ = [[self alloc] init];
    });
    return instance_;
}


#pragma mark -Public Method

- (void)seekToItem:(KCPlayerItem *)item completionHandler:(void (^)(BOOL finished))completionHandler
{
    
    if (item == self.currentItem) {
        
        [self seekToTime:item.startTime completionHandler:completionHandler];
        return;
    }
    
    [self.player removeItem:item.item];
    
    if ([self.player canInsertItem:item.item afterItem:self.player.currentItem]) {
        
        [self.player insertItem:item.item afterItem:self.player.currentItem];
        
        [self.player advanceToNextItem];
        
        if (!self.autoPlay) {
            [self.player pause];
            
        }
        
    }
    
}

- (void)seekToItemAtIndex:(NSUInteger)index completionHandler:(void (^)(BOOL finished))completionHandler
{
    
    if (index >= self.items.count) {
        return;
    }
    
    KCPlayerItem *item = self.items[index];
    
    [self seekToItem:item completionHandler:completionHandler];
    
}

- (void)seekToTime:(NSTimeInterval)time completionHandler:(void (^)(BOOL))completionHandler
{
    [self.player.currentItem seekToTime:CMTimeMake(time, 1) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:completionHandler];
    
    if (self.autoPlay) {
        [self.player play];
    }
    
}

- (void)seekToProgress:(float)progress completionHandler:(void (^)(BOOL finished))completionHandler
{
    
    [self seekToTime:self.duration * progress completionHandler:completionHandler];
}

- (void)play
{
    
    if (!self.items.count) {
        return;
    }
    
    [self.player play];
    
    if (self.currentItem.rate <= 2) {
        
        self.rate = self.currentItem.rate;
    }
    
    if (self.status != KCPlayerStatusPlaying) {
        
        self.status = KCPlayerStatusPlaying;
        !self.playerStatusDidChangedBlock? : self.playerStatusDidChangedBlock(self.status);
    }
    
}

- (void)pause
{
    
    if (!self.items.count) {
        return;
    }
    
    [self.player pause];
    
    if (self.status == KCPlayerStatusPlaying) {
        
        self.status = KCPlayerStatusPause;
        !self.playerStatusDidChangedBlock? : self.playerStatusDidChangedBlock(self.status);
    }
    
}

#pragma mark -Setter

- (void)setItems:(NSArray<KCPlayerItem *> *)items
{
    
    if (self.status == KCPlayerStatusPlaying) {
        [self pause];
    }
    
    self.status = KCPlayerStatusDefault;
    !self.playerStatusDidChangedBlock? : self.playerStatusDidChangedBlock(self.status);
    
    [self removePlayerObserver];
    [self removePlayerItemObserver];
    
    _items = items;
    
    
    NSMutableArray *avPlayerItems = @[].mutableCopy;
    for (KCPlayerItem *item in items) {
        
        [avPlayerItems addObject:item.item];
        [item.item seekToTime:CMTimeMake(item.startTime, 1)];
        
    }
    
    self.player = [AVQueuePlayer queuePlayerWithItems:avPlayerItems];
    self.player.actionAtItemEnd = AVPlayerActionAtItemEndPause;
    self.playerView.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    [self addPlayerObserver];
    [self addPlayerItemObserver];
    
    [self.player pause];
    
}

- (void)setURL:(NSURL *)URL
{
    
    if (URL) {
        
        self.URLs = @[URL];
    }else {
        self.URLs = nil;
    }
    
    
    
}

- (void)setURLs:(NSArray <NSURL *>*)URLs
{
    
    if (URLs) {
        
        NSMutableArray *items = @[].mutableCopy;
        for (NSURL *url in URLs) {
            [items addObject:[[KCPlayerItem alloc] initWithURL:url]];
        }
        
        self.items = items;
    }else {
        self.items = nil;
    }
    
}

#pragma mark -Life Cycle

- (instancetype)init
{
    if (self = [super init]) {
        
        self.autoPlay = YES;
        self.loopCount = 1;
        
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(applicationWillResignActiveNotification) name:UIApplicationWillResignActiveNotification object:nil];
        
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(applicationDidBecomeActiveNotification) name:UIApplicationDidBecomeActiveNotification object:nil];
        
    }
    return self;
}


- (void)dealloc
{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removePlayerObserver];
    [self removePlayerItemObserver];
    [self.player removeAllItems];
    self.player = nil;
    
}

#pragma mark -KVO
- (void)addPlayerObserver
{
    
    [self.player addObserver:self
                  forKeyPath:AVPlayerCurrentItemKey
                     options:NSKeyValueObservingOptionOld
                     context:nil];
    
    
    
    [self addObserverWithAVPlayerItem:self.player.currentItem];
    
}

- (void)removePlayerObserver
{
    [self.player removeObserver:self forKeyPath:AVPlayerCurrentItemKey];
    
    [self removeObserverWithAVPlayerItem:self.player.currentItem];
    
    
}


- (void)addPlayerItemObserver {
    
    for (KCPlayerItem *item in self.items) {
        
        [item addObserver:self forKeyPath:KCPlayerItemItemKey options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
        [item addObserver:self forKeyPath:KCPlayerItemRateKey options:NSKeyValueObservingOptionNew context:nil];
        
    }
}

- (void)removePlayerItemObserver {
    
    
    for (KCPlayerItem *item in self.items) {
        
        [item removeObserver:self forKeyPath:KCPlayerItemItemKey];
        [item removeObserver:self forKeyPath:KCPlayerItemRateKey];
        
    }
}


- (void)addObserverWithAVPlayerItem:(AVPlayerItem *)item
{
    
    if (!item || [item isKindOfClass:[NSNull class]]) {
        return;
    }
    
    [item addObserver:self forKeyPath:AVPlayerItemStatusKey options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld  context:nil];
    [item addObserver:self forKeyPath:AVPlayerItemLoadedTimeRangesKey options:NSKeyValueObservingOptionNew context:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidPlayToEndTimeNotification:) name:AVPlayerItemDidPlayToEndTimeNotification object:item];
    
    __weak typeof(self) weakSelf = self;
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 10) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        
        Float64 seconds = CMTimeGetSeconds(time);
        Float64 duration = CMTimeGetSeconds(weakSelf.player.currentItem.duration);
        
        if (isnan(duration)) {
            return;
        }
        Float64 progress = seconds / duration;
        
        !weakSelf.playerItemProgressDidChangeBlock ? : weakSelf.playerItemProgressDidChangeBlock(seconds, duration, progress);
        
        if (weakSelf.currentItem.endTime && seconds >= weakSelf.currentItem.endTime) {
            [weakSelf.player pause];
            [weakSelf playerItemDidPlayToEndTimeNotification:nil];
        }
        
        
    }];
    
    self.status = KCPlayerStatusBuffering;
    
    !self.playerStatusDidChangedBlock? : self.playerStatusDidChangedBlock(self.status);
    
}

- (void)removeObserverWithAVPlayerItem:(AVPlayerItem *)item
{
    
    if (!item || [item isKindOfClass:[NSNull class]]) {
        return;
    }
    
    [item removeObserver:self forKeyPath:AVPlayerItemStatusKey];
    [item removeObserver:self forKeyPath:AVPlayerItemLoadedTimeRangesKey];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:item];
    
    if (self.timeObserver) {
        
        [self.player removeTimeObserver:self.timeObserver];
    }
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    
    if ([keyPath isEqualToString:AVPlayerItemStatusKey]) {
        
        if (object != self.currentItem.item) {
            return;
        }
        
        KCPlayerItem *item = self.currentItem;
        
        !self.playerItemStatusDidChangedBlock ? : self.playerItemStatusDidChangedBlock(item, item.item.status);
        
        AVPlayerItemStatus oldStatus = [change[NSKeyValueChangeOldKey] integerValue];
        
        if (item.item.status == AVPlayerItemStatusReadyToPlay && item.item.status != oldStatus && self.status != KCPlayerStatusPlaying) {
            
            self.status = KCPlayerStatusReady;
            
            !self.playerStatusDidChangedBlock? : self.playerStatusDidChangedBlock(self.status);
            
            if (self.autoPlay) {
                [self play];
            }
            
        }else if (item.item.status == AVPlayerItemStatusFailed) {
            
            self.status = KCPlayerStatusFailed;
            
            !self.playerStatusDidChangedBlock? : self.playerStatusDidChangedBlock(self.status);
            
        }
        
        
    }else if ([keyPath isEqualToString:AVPlayerItemLoadedTimeRangesKey]) {
        
        CMTimeRange timeRange = self.player.currentItem.loadedTimeRanges.firstObject.CMTimeRangeValue;
        
        Float64 start = CMTimeGetSeconds(timeRange.start);
        Float64 duration = CMTimeGetSeconds(timeRange.duration);
        
        Float64 completedTime = start + duration;
        
        Float64 totalTime = CMTimeGetSeconds(self.player.currentItem.duration);
        
        if (isnan(totalTime)) {
            return;
        }
        !self.playerItemLoadedTimeRangesDidChangedBlock ? : self.playerItemLoadedTimeRangesDidChangedBlock(totalTime, completedTime, completedTime / totalTime);
        
    }else if ([keyPath isEqualToString:AVPlayerCurrentItemKey]) {
        
        AVPlayerItem *oldAVPlayerItem = change[NSKeyValueChangeOldKey];
        
        [self removeObserverWithAVPlayerItem:oldAVPlayerItem];
        
        [self addObserverWithAVPlayerItem:self.player.currentItem];
        
        KCPlayerItem *oldItem = [self KCPlayerItemOfAVPlayerItem:oldAVPlayerItem];
        KCPlayerItem *newItem = [self KCPlayerItemOfAVPlayerItem:self.player.currentItem];
        
        !self.playerItemDidChangedBlock ? : self.playerItemDidChangedBlock(oldItem, newItem);
        
        if ([oldAVPlayerItem isKindOfClass:[AVPlayerItem class]]) {
            
            [oldItem.item seekToTime:CMTimeMake(oldItem.startTime, 1)];
        }
        
        
    }else if ([keyPath isEqualToString:KCPlayerItemItemKey]) {
        
        AVPlayerItem *newAvItem = change[NSKeyValueChangeNewKey];
        AVPlayerItem *oldAvItem = change[NSKeyValueChangeOldKey];
        
        [self.player removeItem:oldAvItem];
        
        if ([self.player canInsertItem:newAvItem afterItem:nil]) {
            [self.player insertItem:newAvItem afterItem:nil];
        }
        
    }else if ([keyPath isEqualToString:KCPlayerItemRateKey]){
        
        CGFloat rate = [change[NSKeyValueChangeNewKey] floatValue];
        
        if (rate > 2 || object != self.currentItem) {
            return;
        }
        
        self.rate = rate;
        
    }
    
}

#pragma mark -Notification


- (void)applicationDidBecomeActiveNotification
{
    if (self.playInBackground) {
        return;
    }
    
    if (self.status == KCPlayerStatusPlaying) {
        
        [self.player play];
    }
}

- (void)applicationWillResignActiveNotification
{
    
    if (self.playInBackground) {
        return;
    }
    
    if (self.status == KCPlayerStatusPlaying) {
        [self.player pause];
    }
}


- (void)playerItemDidPlayToEndTimeNotification:(NSNotification *)note
{
    
    !self.playerItemDidPlayToEndTimeBlock ? : self.playerItemDidPlayToEndTimeBlock(self.currentItem);
    
    if (self.currentItem == self.items.lastObject) {
        self.currentLoopCount++;
        
    }
    
    switch (self.playMode) {
        case KCPlayerPlayModeDefault:
        {
            
            if (self.currentLoopCount >= self.loopCount) {
                
                self.currentLoopCount = 0;
                
                self.status = KCPlayerStatusCompleted;
                !self.playerStatusDidChangedBlock? : self.playerStatusDidChangedBlock(self.status);
                
            }else {
                
                NSInteger index = [self.items indexOfObject:self.currentItem];
                
                if (index >= self.items.count) {
                    index = 0;
                }
                
                [self seekToItemAtIndex:index completionHandler:nil];
                [self play];
            }
            
        }
            break;
        case KCPlayerPlayModeLoop: {
            
            NSInteger index = [self.items indexOfObject:self.currentItem];
            
            if (index >= self.items.count) {
                index = 0;
            }
            
            [self seekToItemAtIndex:index completionHandler:nil];
            [self play];
            
        }
            break;
        case KCPlayerPlayModeSingleLoop:{
            
            [self seekToTime:self.currentItem.startTime completionHandler:nil];
            [self play];
            
        }
            break;
        case KCPlayerPlayModeRandom:
        {
            
            [self seekToItemAtIndex:arc4random_uniform((int)self.items.count) completionHandler:nil];
            
            [self play];
        }
            
            break;
            
        case KCPlayerPlayModeSingle:
        {
            self.status = KCPlayerStatusCompleted;
            !self.playerStatusDidChangedBlock? : self.playerStatusDidChangedBlock(self.status);
            
        }
            break;
        default:
            break;
    }

}

#pragma mark -Helper
- (KCPlayerItem *)KCPlayerItemOfAVPlayerItem:(AVPlayerItem *)item
{
    NSInteger index = [self KCPlayerItemIndexOfAVPlayerItem:item];
    
    if (index == NSNotFound) {
        return nil;
    }
    
    return self.items[index];
}

- (NSInteger)KCPlayerItemIndexOfAVPlayerItem:(AVPlayerItem *)item
{
    NSInteger index = NSNotFound;
    for (int i = 0; i < self.items.count; i++) {
        
        if (self.items[i].item == item) {
            
            index = i;
            break;
        }
    }
    
    return index;
    
}

@end
