//
//  KCPlayerItem.m
//  KCPlayerDemo
//
//  Created by iMac on 2017/6/29.
//  Copyright © 2017年 iMac. All rights reserved.
//

#import "KCPlayerItem.h"

@interface KCPlayerItem ()
{
    NSURL *_URL;
    AVPlayerItem *_item;
}
@end

@implementation KCPlayerItem

- (instancetype)initWithURL:(NSURL *)url
{
    
    if (self = [self initWithItem:[AVPlayerItem playerItemWithURL:url]]) {
        _URL = url;
    }
    return self;
    
}

- (instancetype)initWithItem:(AVPlayerItem *)item
{
    if (self = [self init]) {
        
        _item = item;
        
    }
    return self;
}

- (instancetype)init
{
    if (self = [super init]) {
        
        _rate = 1;
    }
    return self;
}

- (void)setRate:(float)rate {
    
    float oldRate = _rate;
    
    _rate = rate;
    
    if (!self.URL) {
        return;
    }
    
    if (rate > 2) {
        
        AVAsset* playAsset = [AVAsset assetWithURL:self.URL];
        
        AVMutableComposition *composition = [AVMutableComposition composition];
        NSError *error = nil;
        [composition insertTimeRange:CMTimeRangeMake(kCMTimeZero, playAsset.duration)
                             ofAsset:playAsset
                              atTime:kCMTimeZero error:&error];
        [composition scaleTimeRange:CMTimeRangeMake(kCMTimeZero, playAsset.duration)
                         toDuration:CMTimeMultiplyByFloat64(playAsset.duration, 1/rate)];
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:composition];
        
        playerItem.audioTimePitchAlgorithm = AVAudioTimePitchAlgorithmSpectral;
        self.item = playerItem;
        
    }else if (oldRate > 2)  {
        
        self.item = [AVPlayerItem playerItemWithURL:self.URL];
        
    }
    
}

@end
