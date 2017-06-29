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
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
    
    if (self = [self initWithItem:item]) {
        _URL = url;
    }
    return self;
}

- (instancetype)initWithItem:(AVPlayerItem *)item
{
    if (self = [super init]) {
        
        _item = item;
        
    }
    return self;
}

@end
