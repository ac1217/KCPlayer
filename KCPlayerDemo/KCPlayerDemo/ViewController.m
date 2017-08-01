//
//  ViewController.m
//  KCPlayerDemo
//
//  Created by iMac on 2017/6/28.
//  Copyright © 2017年 iMac. All rights reserved.
//

#import "ViewController.h"
#import "KCPlayer.h"


@interface ViewController ()
@property (nonatomic,strong) KCPlayer *player;
@end

@implementation ViewController

- (KCPlayer *)player
{
    if (!_player) {
        _player = [[KCPlayer alloc] init];
        _player.autoPlay = NO;
    }
    return _player;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
//    self.navigationController.jp_useCustomPopAnimationForCurrentViewController = YES;
    self.title = @"视频";
    [self.view addSubview:self.player.playerView];
    self.player.playerView.backgroundColor = [UIColor orangeColor];
    self.player.playerView.frame = CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.width * 9 / 16);
    
    
    KCPlayerItem *item0 = [[KCPlayerItem alloc] initWithURL:[NSURL URLWithString:@"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"]];
    KCPlayerItem *item1 = [[KCPlayerItem alloc] initWithURL:[NSURL URLWithString:@"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"]];
    item1.rate = 2;
    
    self.player.items = @[item0, item1];
    
}
- (IBAction)back {
    
    
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    
    [self play];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    
}

- (IBAction)play {
    
    /**/
    [self.player play];
}

- (IBAction)pause {
    [self.player pause];
}


@end
