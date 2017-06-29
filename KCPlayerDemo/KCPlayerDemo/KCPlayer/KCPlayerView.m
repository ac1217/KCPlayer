//
//  KCPlayerView.m
//  KCPlayerDemo
//
//  Created by zhangweiwei on 2017/6/17.
//  Copyright © 2017年 erica. All rights reserved.
//

#import "KCPlayerView.h"

@interface KCPlayerView ()

@end

@implementation KCPlayerView

- (void)setPlayerLayer:(AVPlayerLayer *)playerLayer
{
    [_playerLayer removeFromSuperlayer];
    _playerLayer = playerLayer;
    [self.layer addSublayer:playerLayer];
    
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.playerLayer.frame = self.layer.bounds;
}

@end
