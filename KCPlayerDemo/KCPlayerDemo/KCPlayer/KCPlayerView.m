//
//  KCPlayerView.m
//  KCPlayerDemo
//
//  Created by zhangweiwei on 2017/6/17.
//  Copyright © 2017年 erica. All rights reserved.
//

#import "KCPlayerView.h"
static NSString *const AVPlayerLayerReadyForDisplayKey = @"readyForDisplay";

@interface KCPlayerView ()

@end

@implementation KCPlayerView

- (void)dealloc
{
    [self removeKVO];
}

- (void)setPlayerLayer:(AVPlayerLayer *)playerLayer
{
    
    [_playerLayer removeFromSuperlayer];
    [self removeKVO];
    _playerLayer = playerLayer;
    [self.layer addSublayer:playerLayer];
    [self addKVO];
    [self setNeedsLayout];
}

- (void)addKVO
{
    [self.playerLayer addObserver:self forKeyPath:AVPlayerLayerReadyForDisplayKey options:NSKeyValueObservingOptionNew context:nil];
}

- (void)removeKVO
{
    [self.playerLayer removeObserver:self forKeyPath:AVPlayerLayerReadyForDisplayKey];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:AVPlayerLayerReadyForDisplayKey]) {
        
        !self.playerViewDidReadyForDisplayBlock ? : self.playerViewDidReadyForDisplayBlock(self.playerLayer.isReadyForDisplay);
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.playerLayer.frame = self.layer.bounds;
}

@end
