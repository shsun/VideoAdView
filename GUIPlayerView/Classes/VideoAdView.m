//
//  VideoAdView.m
//  XAdSDK
//
//  Created by shsun on 4/26/15
//
//
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "VideoAdView.h"
#import "UIView+UpdateAutoLayoutConstraints.h"

/**
 *
 *
 *
 */
@interface VideoAdView () <AVAssetResourceLoaderDelegate, NSURLConnectionDataDelegate>

@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) AVPlayerItem *currentItem;

@property (strong, nonatomic) UIView *controllersView;

@property (assign, nonatomic) int times;

@property (strong, nonatomic) UIButton *volumeButton;
@property (strong, nonatomic) UIButton *fullscreenButton;
@property (strong, nonatomic) MPVolumeView *volumeView;
@property (strong, nonatomic) UILabel *playheadTimeLabel;

@property (strong, nonatomic) UIView *spacerView;

@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) NSTimer *progressTimer;
@property (strong, nonatomic) NSTimer *controllersTimer;
@property (assign, nonatomic) BOOL fullscreen;
@property (assign, nonatomic) CGRect defaultFrame;

@end


/**
 *
 *
 *
 */
@implementation VideoAdView

@synthesize player, playerLayer, currentItem;
@synthesize controllersView;
@synthesize fullscreenButton, volumeButton, volumeView, playheadTimeLabel;
@synthesize activityIndicator, progressTimer, controllersTimer, fullscreen, defaultFrame, times;

@synthesize videoURL, delegate;


#pragma mark - ViewLifeCycle
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    defaultFrame = frame;
    times = 0;
    [self createUI];
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    times = 0;
    [self createUI];
    return self;
}


- (void)createUI {
    NSArray *tmpHorizontalConstraints;
    NSArray *tmpVerticalConstraints;
    
    //
    [self setBackgroundColor:[UIColor blackColor]];
    
    // event listeners
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerDidFinishPlaying:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerFailedToPlayToEnd:)
                                                 name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerStalled:)
                                                 name:AVPlayerItemPlaybackStalledNotification object:nil];
    
    // Container View
    controllersView = [UIView new];
    [controllersView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [controllersView setBackgroundColor:[UIColor colorWithWhite:0.0f alpha:0.30f]];
    [self addSubview:controllersView];
    tmpHorizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[CV]|"
                                                                    options:0
                                                                    metrics:nil
                                                                      views:@{@"CV" : controllersView}];
    
    tmpVerticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[CV(40)]|"
                                                                  options:0
                                                                  metrics:nil
                                                                    views:@{@"CV" : controllersView}];
    [self addConstraints:tmpHorizontalConstraints];
    [self addConstraints:tmpVerticalConstraints];
    
    // UIController
    volumeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [volumeButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [volumeButton setImage:[UIImage imageNamed:@"xadsdk_ad_mute"] forState:UIControlStateNormal];
    [volumeButton setImage:[UIImage imageNamed:@"xadsdk_ad_unmute"] forState:UIControlStateSelected];
    
    
    volumeView = [MPVolumeView new];
    [volumeView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [volumeView setShowsRouteButton:YES];
    [volumeView setShowsVolumeSlider:YES];
    [volumeView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    
    fullscreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [fullscreenButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [fullscreenButton setImage:[UIImage imageNamed:@"xadsdk_ad_expand"] forState:UIControlStateNormal];
    [fullscreenButton setImage:[UIImage imageNamed:@"xadsdk_ad_shrink"] forState:UIControlStateSelected];
    
    //
    playheadTimeLabel = [UILabel new];
    [playheadTimeLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [playheadTimeLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:13.0f]];
    [playheadTimeLabel setTextAlignment:NSTextAlignmentCenter];
    [playheadTimeLabel setTextColor:[UIColor whiteColor]];
    
    [controllersView addSubview:volumeButton];
    [controllersView addSubview:fullscreenButton];
    [controllersView addSubview:volumeView];
    [controllersView addSubview:playheadTimeLabel];
    //[controllersView addSubview:spacerView];
    /*
    horizontalConstraints = [NSLayoutConstraint
                             constraintsWithVisualFormat:@"H:|[P(40)][S(10)][C]-5-[I]-5-[R][F(40)][V(40)]|"
                             options:0
                             metrics:nil
                             views:@{@"P" : playButton,
                                     @"S" : spacerView,
                                     @"C" : currentTimeLabel,
                                     @"I" : progressIndicator,
                                     @"R" : remainingTimeLabel,
                                     @"V" : volumeView,
                                     @"F" : fullscreenButton}];
    */
    tmpHorizontalConstraints = [NSLayoutConstraint
                             constraintsWithVisualFormat:@"H:|[VB(40)][R][F(40)][V(40)]|"
                             options:0
                             metrics:nil
                             views:@{@"R" : playheadTimeLabel,
                                     @"V" : volumeView,
                                     @"F" : fullscreenButton,
                                     @"VB" : volumeButton}];
    
    [controllersView addConstraints:tmpHorizontalConstraints];
    [volumeView hideByWidth:YES];
    
    for (UIView *view in [controllersView subviews]) {
        tmpVerticalConstraints = [NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:|-0-[V(40)]"
                               options:NSLayoutFormatAlignAllCenterY
                               metrics:nil
                               views:@{@"V" : view}];
        [controllersView addConstraints:tmpVerticalConstraints];
    }
    
    // loadingUI
    activityIndicator = [UIActivityIndicatorView new];
    activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    activityIndicator.layer.cornerRadius = 6;
    activityIndicator.layer.masksToBounds = YES;
    CGRect frame = self.frame;
    frame.origin = CGPointZero;
    [activityIndicator setFrame:frame];
    [activityIndicator stopAnimating];
    [self addSubview:activityIndicator];
    
    [volumeButton addTarget:self action:@selector(onVolumeButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [fullscreenButton addTarget:self action:@selector(toggleFullscreen:) forControlEvents:UIControlEventTouchUpInside];
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showControllers)]];
    [self showControllers];
}

#pragma mark - UI Action
- (void)onVolumeButtonClicked:(UIButton *)button {
    if(player.volume <= 0.00f) {
        [player setVolume:0.80f];
        [button setSelected:YES];
        
        if ([delegate respondsToSelector:@selector(playerDidMute)]) {
            [delegate playerDidMute];
        }
    } else {
        [player setVolume:0.00f];
        [button setSelected:NO];
        
        if ([delegate respondsToSelector:@selector(playerDidUnMute)]) {
            [delegate playerDidUnMute];
        }
    }
}
- (void)toggleFullscreen:(UIButton *)button {
    if (fullscreen) {
        if ([delegate respondsToSelector:@selector(playerWillLeaveFullscreen)]) {
            [delegate playerWillLeaveFullscreen];
        }
        
        [UIView animateWithDuration:0.2f animations:^{
            [self setTransform:CGAffineTransformMakeRotation(0)];
            [self setFrame:defaultFrame];
            
            CGRect frame = defaultFrame;
            frame.origin = CGPointZero;
            [playerLayer setFrame:frame];
            [activityIndicator setFrame:frame];
        } completion:^(BOOL finished) {
            fullscreen = NO;
            
            if ([delegate respondsToSelector:@selector(playerDidLeaveFullscreen)]) {
                [delegate playerDidLeaveFullscreen];
            }
        }];
        
        [button setSelected:NO];
    } else {
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        
        CGFloat width = [[UIScreen mainScreen] bounds].size.width;
        CGFloat height = [[UIScreen mainScreen] bounds].size.height;
        CGRect frame;
        
        if (UIInterfaceOrientationIsPortrait(orientation)) {
            CGFloat aux = width;
            width = height;
            height = aux;
            frame = CGRectMake((height - width) / 2, (width - height) / 2, width, height);
        } else {
            frame = CGRectMake(0, 0, width, height);
        }
        
        if ([delegate respondsToSelector:@selector(playerWillEnterFullscreen)]) {
            [delegate playerWillEnterFullscreen];
        }
        
        [UIView animateWithDuration:0.2f animations:^{
            [self setFrame:frame];
            [playerLayer setFrame:CGRectMake(0, 0, width, height)];
            [activityIndicator setFrame:CGRectMake(0, 0, width, height)];
            if (UIInterfaceOrientationIsPortrait(orientation)) {
                [self setTransform:CGAffineTransformMakeRotation(M_PI_2)];
                [activityIndicator setTransform:CGAffineTransformMakeRotation(M_PI_2)];
            }
        } completion:^(BOOL finished) {
            fullscreen = YES;
            if ([delegate respondsToSelector:@selector(playerDidEnterFullscreen)]) {
                [delegate playerDidEnterFullscreen];
            }
        }];
        
        [button setSelected:YES];
    }
    
    [self showControllers];
}

- (void)seek:(UISlider *)slider {
    int timescale = currentItem.asset.duration.timescale;
    float time = slider.value * (currentItem.asset.duration.value / timescale);
    [player seekToTime:CMTimeMakeWithSeconds(time, timescale)];
    
    [self showControllers];
}


- (NSTimeInterval)availableDuration {
    NSTimeInterval result = 0;
    NSArray *loadedTimeRanges = player.currentItem.loadedTimeRanges;
    
    if ([loadedTimeRanges count] > 0) {
        CMTimeRange timeRange = [[loadedTimeRanges objectAtIndex:0] CMTimeRangeValue];
        Float64 startSeconds = CMTimeGetSeconds(timeRange.start);
        Float64 durationSeconds = CMTimeGetSeconds(timeRange.duration);
        result = startSeconds + durationSeconds;
    }
    
    return result;
}

- (void)refreshProgressUI
{
    CGFloat duration = CMTimeGetSeconds(currentItem.asset.duration);
    
    if (duration == 0 || isnan(duration))
    {
        [playheadTimeLabel setText:nil];
    }
    else
    {
        CGFloat playheadTime = CMTimeGetSeconds(player.currentTime);
        [playheadTimeLabel setText:[NSString stringWithFormat:@"%f / %f", round(playheadTime), round(duration)]];
    }
}


- (void)showControllers {
    [UIView animateWithDuration:0.2f animations:^{
        [controllersView setAlpha:1.0f];
    } completion:^(BOOL finished) {
        [controllersTimer invalidate];        
    }];
}

#pragma mark - Public Methods

- (void)prepareAndPlay:(BOOL)autoPlay {
    if (player) {
        [self stop];
    }
    
    player = [[AVPlayer alloc] initWithPlayerItem:nil];
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    [asset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:@"playable"] completionHandler:^{
        currentItem = [AVPlayerItem playerItemWithAsset:asset];
        [player replaceCurrentItemWithPlayerItem:currentItem];
        if (autoPlay) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self play];
            });
        }
    }];
    
    [player setAllowsExternalPlayback:YES];
    playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    [self.layer addSublayer:playerLayer];
    
    defaultFrame = self.frame;
    
    CGRect frame = self.frame;
    frame.origin = CGPointZero;
    [playerLayer setFrame:frame];
    
    [self bringSubviewToFront:controllersView];
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    //
    [player addObserver:self forKeyPath:@"rate" options:0 context:nil];
    [currentItem addObserver:self forKeyPath:@"status" options:0 context:nil];
    
    [player seekToTime:kCMTimeZero];
    [player setRate:0.0f];
    
    if (autoPlay)
    {
        [activityIndicator startAnimating];
    }
}

- (void)dispose
{
    // remove observer
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemPlaybackStalledNotification object:nil];
    //
    [player setAllowsExternalPlayback:NO];
    [self stop];
    [player removeObserver:self forKeyPath:@"rate"];
    [self setPlayer:nil];
    [self setPlayerLayer:nil];
    //
    [self removeFromSuperview];
}

- (void)play {
    [player play];
    progressTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f
                                                     target:self
                                                   selector:@selector(refreshProgressUI)
                                                   userInfo:nil
                                                    repeats:YES];
}

- (void)pause {
    [player pause];
    
    if ([delegate respondsToSelector:@selector(playerDidPause)]) {
        [delegate playerDidPause];
    }
}

- (void)stop {
    if (player) {
        [player pause];
        [player seekToTime:kCMTimeZero];
    }
}

- (BOOL)isPlaying {
    return [player rate] > 0.0f;
}

- (void)playerDidFinishPlaying:(NSNotification *)notification {
    [self stop];
    
    
    times += 1;
    
    /*
    // backward to non-fullscreen state when the video complete
    if (fullscreen) {
        [self toggleFullscreen:fullscreenButton];
    }
    */
    
    /*
    //
    if ([delegate respondsToSelector:@selector(playerDidEnd)]) {
        [delegate playerDidEnd];
    }
    */
    
    [player play];
}

- (void)playerFailedToPlayToEnd:(NSNotification *)notification {
    [self stop];
    if ([delegate respondsToSelector:@selector(playerFailedToPlayToEnd)]) {
        [delegate playerFailedToPlayToEnd];
    }
}

- (void)playerStalled:(NSNotification *)notification {
    if ([delegate respondsToSelector:@selector(playerStalled)]) {
        [delegate playerStalled];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"status"]) {
        if (currentItem.status == AVPlayerItemStatusFailed) {
            if ([delegate respondsToSelector:@selector(playerFailedToPlayToEnd)]) {
                [delegate playerFailedToPlayToEnd];
            }
        }
    }
    
    if ([keyPath isEqualToString:@"rate"]) {
        CGFloat rate = [player rate];
        if (rate > 0) {
            [activityIndicator stopAnimating];
        }
    }
}

@end
