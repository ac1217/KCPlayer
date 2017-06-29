//
//  KCPlayerItem.h
//  KCPlayerDemo
//
//  Created by iMac on 2017/6/29.
//  Copyright © 2017年 iMac. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@interface KCPlayerItem : NSObject
@property (nonatomic,strong, readonly) NSURL *URL;
@property (nonatomic,strong, readonly) AVPlayerItem *item;
@property (nonatomic,assign) float rate;

- (instancetype)initWithURL:(NSURL *)url;
- (instancetype)initWithItem:(AVPlayerItem *)item;

@end
