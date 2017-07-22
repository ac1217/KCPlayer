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
@property (nonatomic,strong) AVPlayerItem *item;
@property (nonatomic,assign) float rate;
@property (nonatomic,assign) NSTimeInterval startTime;
@property (nonatomic,assign) NSTimeInterval endTime;

- (instancetype)initWithURL:(NSURL *)url;
- (instancetype)initWithItem:(AVPlayerItem *)item;

@end
