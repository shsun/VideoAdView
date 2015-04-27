//
//  ViewController.m
//  XAdSDK
//
//  Created by shsun on 4/26/15
//
//


#import "ViewController.h"
#import "VideoAdView.h"

@interface ViewController () <VideoAdViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *addPlayerButton;
@property (weak, nonatomic) IBOutlet UIButton *removePlayerButton;
@property (weak, nonatomic) IBOutlet UILabel *copyrightLabel;

- (IBAction)addPlayer:(UIButton *)sender;
- (IBAction)removePlayer:(UIButton *)sender;

@property (strong, nonatomic) VideoAdView *mVideoAdView;

@end


/**
 *
 *
 *
 */
@implementation ViewController

@synthesize addPlayerButton, removePlayerButton, copyrightLabel, mVideoAdView;

- (IBAction)addPlayer:(UIButton *)sender {
    self.view.backgroundColor = [UIColor grayColor];
    
    [copyrightLabel setHidden:NO];
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    
    //playerView = [[GUIPlayerView alloc] initWithFrame:CGRectMake(5, 64, width, width * 9.0f / 16.0f)];
    
    mVideoAdView = [[VideoAdView alloc] initWithFrame:CGRectMake(20, 100, 240, 180)];
    mVideoAdView.backgroundColor = [UIColor greenColor];
    //playerView.alpha = 0.20f;
    [mVideoAdView setDelegate:self];
    [[self view] addSubview:mVideoAdView];
    
    NSURL *URL = [NSURL URLWithString:@"http://211.151.146.65:8080/wlantest/shanghai_sun/wanghan.mp4"];
    [mVideoAdView setVideoURL:URL];
    [mVideoAdView prepareAndPlay:YES WithSilentMode:YES];
    
    [addPlayerButton setEnabled:NO];
    [removePlayerButton setEnabled:YES];
}

- (IBAction)removePlayer:(UIButton *)sender {
    [copyrightLabel setHidden:YES];
    
    [mVideoAdView dispose];
    
    [addPlayerButton setEnabled:YES];
    [removePlayerButton setEnabled:NO];
}

#pragma mark - VideoAdView Delegate Methods
- (void)playerWillEnterFullscreen {
    [[self navigationController] setNavigationBarHidden:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
}

- (void)playerWillLeaveFullscreen {
    [[self navigationController] setNavigationBarHidden:NO];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

- (void)playerDidEnd {
    [copyrightLabel setHidden:YES];
    
    [mVideoAdView dispose];
    
    [addPlayerButton setEnabled:YES];
    [removePlayerButton setEnabled:NO];
}

- (void)playerFailedToPlayToEnd {
    NSLog(@"Error: could not play video");
    [mVideoAdView dispose];
}

@end
