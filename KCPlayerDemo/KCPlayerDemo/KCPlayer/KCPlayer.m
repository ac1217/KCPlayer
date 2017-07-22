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

- (AVQueuePlayer *)player
{
    if (!_player) {
        _player = [[AVQueuePlayer alloc] init];
    }
    return _player;
}

- (KCPlayerView *)playerView
{
    if (!_playerView) {
        _playerView = [[KCPlayerView alloc] init];
        _playerView.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        
    }
    return _playerView;
}

+ (instancetype)sharedPlayer
{
    static id instance_;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance_ = [[self alloc] init];
    });
    return instance_;
}

- (instancetype)init
{
    if (self = [super init]) {
        
//        self.rate = 1;
        
        self.autoPlay = YES;
        self.loopCount = 1;
        
        [self.player addObserver:self
                      forKeyPath:AVPlayerCurrentItemKey
                         options:NSKeyValueObservingOptionOld
                         context:nil];
        
        
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(applicationWillResignActiveNotification) name:UIApplicationWillResignActiveNotification object:nil];
        
    }
    return self;
}


- (void)applicationWillResignActiveNotification
{
    if (self.playInBackground) {
        return;
    }
    [self pause];
}


- (void)dealloc
{
//    NSLog(@"销毁");
    
    for (KCPlayerItem *item in _items) {
        [item removeObserver:self forKeyPath:KCPlayerItemItemKey];
        [item removeObserver:self forKeyPath:KCPlayerItemRateKey];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self pause];
    [self removeObserverWithItem:self.player.currentItem];
    [self.player removeObserver:self forKeyPath:AVPlayerCurrentItemKey];
    [self.player removeAllItems];
    self.player = nil;
    
}

- (void)setItems:(NSArray<KCPlayerItem *> *)items
{
    if (self.status == KCPlayerStatusPlaying) {
        
        [self pause];
    }
    
    self.status = KCPlayerStatusDefault;
    
    for (KCPlayerItem *item in _items) {
        [item removeObserver:self forKeyPath:KCPlayerItemItemKey];
        [item removeObserver:self forKeyPath:KCPlayerItemRateKey];
    }
    
    _items = items;
    
    if (items.count > 1) {
        
        self.player.actionAtItemEnd = AVPlayerActionAtItemEndAdvance;
        
    }else {
        
        self.player.actionAtItemEnd = AVPlayerActionAtItemEndPause;
    }
    
    [self.player removeAllItems];
    
    for (KCPlayerItem *item in items) {
        
        if ([self.player canInsertItem:item.item afterItem:nil]) {
            
            [self.player insertItem:item.item afterItem:nil];
            
        }
        [item addObserver:self forKeyPath:KCPlayerItemItemKey options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
        [item addObserver:self forKeyPath:KCPlayerItemRateKey options:NSKeyValueObservingOptionNew context:nil];
        
    }
    
    [self.player pause];
    
    
}

- (void)setCurrentURL:(NSURL *)currentURL
{
    _currentURL = currentURL;
    
    if (currentURL) {
        
        self.currentURLs = @[currentURL];
    }else {
        self.currentURLs = nil;
    }
    
    
    
}

- (void)setCurrentURLs:(NSArray <NSURL *>*)currentURLs
{
    
    NSMutableArray *items = @[].mutableCopy;
    for (NSURL *url in currentURLs) {
        [items addObject:[[KCPlayerItem alloc] initWithURL:url]];
    }
    
    self.items = items;
    
}


- (void)seekToTime:(NSTimeInterval)time completionHandler:(void (^)(BOOL))completionHandler
{
    [self.player.currentItem seekToTime:CMTimeMake(time, 1) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:completionHandler];
}

- (void)seekToProgress:(float)progress completionHandler:(void (^)(BOOL finished))completionHandler
{
    [self seekToTime:self.duration * progress completionHandler:completionHandler];
}

- (void)play
{
    
    [self.player play];
    
    self.status = KCPlayerStatusPlaying;
    !self.playerStatusDidChangedBlock? : self.playerStatusDidChangedBlock(self.status);
    
    if (self.currentItem.rate <= 2) {
        
        self.rate = self.currentItem.rate;
    }
    
}

- (void)pause
{
    [self.player pause];
    
    self.status = KCPlayerStatusPause;
    !self.playerStatusDidChangedBlock? : self.playerStatusDidChangedBlock(self.status);
}

- (void)addObserverWithItem:(AVPlayerItem *)item
{
    
    if (!item || [item isKindOfClass:[NSNull class]]) {
        return;
    }
    
    [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [item addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidPlayToEndTimeNotification:) name:AVPlayerItemDidPlayToEndTimeNotification object:item];
    
    __weak typeof(self) weakSelf = self;
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 10) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        
        Float64 seconds = CMTimeGetSeconds(time);
        Float64 duration = CMTimeGetSeconds(weakSelf.player.currentItem.duration);
        
        if (isnan(duration)) {
            return;
        }
        
        !weakSelf.playerItemProgressDidChangeBlock ? : weakSelf.playerItemProgressDidChangeBlock(seconds, duration, seconds / duration);
        
        
        if (weakSelf.currentItem.endTime && seconds >= weakSelf.currentItem.endTime) {
            [weakSelf pause];
            [weakSelf playerItemDidPlayToEndTimeNotification:nil];
        }
        
        
    }];
    
}

- (void)removeObserverWithItem:(AVPlayerItem *)item
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

- (void)playerItemDidPlayToEndTimeNotification:(NSNotification *)note
{
    
    !self.playerItemDidPlayToEndTimeBlock ? : self.playerItemDidPlayToEndTimeBlock([self KCPlayerItemOfAVPlayerItem:self.player.currentItem]);
    
    if (self.items.count <= 1) {
        
        self.currentLoopCount++;
        
        if (self.currentLoopCount >= self.loopCount) {
            
            [self pause];
            self.currentLoopCount = 0;
            self.status = KCPlayerStatusCompleted;
            
        }else {
            
            [self seekToTime:self.currentItem.startTime completionHandler:nil];
            [self play];
        }
        
    }else {
        
        if (self.currentItemIndex == self.items.count - 1) { // 最后一个
            self.currentLoopCount++;
            
            if (self.currentLoopCount >= self.loopCount) {
                
                [self pause];
                self.currentLoopCount = 0;
                self.status = KCPlayerStatusCompleted;
                
            }
            
        }
        
        
    }
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    
    if ([keyPath isEqualToString:AVPlayerItemStatusKey]) {
        
        KCPlayerItem *item = self.currentItem;
        
        !self.playerItemStatusDidChangedBlock ? : self.playerItemStatusDidChangedBlock(item, item.item.status);
        
        if (self.autoPlay && self.status == KCPlayerStatusBuffering && item.item.status == AVPlayerItemStatusReadyToPlay) {
            [self play];
        }
        
        
    }else if ([keyPath isEqualToString:AVPlayerItemLoadedTimeRangesKey]) {
        
        CMTimeRange timeRange = self.player.currentItem.loadedTimeRanges.firstObject.CMTimeRangeValue;
        
        Float64 start = CMTimeGetSeconds(timeRange.start);
        Float64 duration = CMTimeGetSeconds(timeRange.duration);
        
        Float64 completedTime = start + duration;
        
        Float64 totalTime = CMTimeGetSeconds(self.player.currentItem.duration);
        
        !self.playerItemLoadedTimeRangesDidChangedBlock ? : self.playerItemLoadedTimeRangesDidChangedBlock(totalTime, completedTime, completedTime / totalTime);
        
    }else if ([keyPath isEqualToString:AVPlayerCurrentItemKey]) {
        
        AVPlayerItem *oldAVPlayerItem = change[NSKeyValueChangeOldKey];
        
        [self removeObserverWithItem:oldAVPlayerItem];
        
        [self addObserverWithItem:self.player.currentItem];
        
        KCPlayerItem *oldItem = [self KCPlayerItemOfAVPlayerItem:oldAVPlayerItem];
        KCPlayerItem *newItem = [self KCPlayerItemOfAVPlayerItem:self.player.currentItem];
        
        !self.playerItemDidChangedBlock ? : self.playerItemDidChangedBlock(oldItem, newItem);
        
        [self seekToTime:newItem.startTime completionHandler:nil];
        
        self.status = KCPlayerStatusBuffering;
        !self.playerStatusDidChangedBlock? : self.playerStatusDidChangedBlock(self.status);
        
        if (newItem.rate <= 2) {
            
            self.rate = newItem.rate;
        }
        
        if (oldItem && oldItem.item.status == AVPlayerItemStatusReadyToPlay) {
            [oldItem.item seekToTime:kCMTimeZero];
            if ([self.player canInsertItem:oldItem.item afterItem:nil]) {
                [self.player insertItem:oldItem.item afterItem:nil];
            }
        }
        
    }else if ([keyPath isEqualToString:KCPlayerItemItemKey]) {
        
        AVPlayerItem *newAvItem = change[NSKeyValueChangeNewKey];
        AVPlayerItem *oldAvItem = change[NSKeyValueChangeOldKey];
        
        NSInteger index = [self.player.items indexOfObject:oldAvItem];
        
        if (index != NSNotFound) {
            
            index -= 1;
            
            if (index < 0) {
                if ([self.player canInsertItem:newAvItem afterItem:oldAvItem]) {
                    [self.player insertItem:newAvItem afterItem:oldAvItem];
                }
            }else {
                
                AVPlayerItem *item = self.player.items[index];
                
                if ([self.player canInsertItem:newAvItem afterItem:item]) {
                    [self.player insertItem:newAvItem afterItem:item];
                }
            }
            
            [self.player removeItem:oldAvItem];
            
            
        }
        
    }else if ([keyPath isEqualToString:KCPlayerItemRateKey]){
        
        CGFloat rate = [change[NSKeyValueChangeNewKey] floatValue];
        
        if (rate > 2 || object != self.currentItem) {
            return;
        }
        
        self.rate = rate;
        
    }
    
}

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
            return i;
            break;
        }
    }
    return index;
    
}

@end
