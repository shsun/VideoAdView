//
//  VideoAdView.h
//  XAdSDK
//
//  Created by shsun on 4/26/15
//
//

#import <UIKit/UIKit.h>

@class VideoAdView;

@protocol VideoAdViewDelegate <NSObject>

@optional
- (void)playerDidPause;
- (void)playerDidResume;
- (void)playerDidEnd;
- (void)playerWillEnterFullscreen;
- (void)playerDidEnterFullscreen;
- (void)playerWillLeaveFullscreen;
- (void)playerDidLeaveFullscreen;
- (void)playerFailedToPlayToEnd;
- (void)playerStalled;
- (void)playerDidMute;
- (void)playerDidUnMute;
@end


/**
 *
 *
 *
 */
@interface VideoAdView : UIView

@property (strong, nonatomic) NSURL *videoURL;
@property (weak, nonatomic) id<VideoAdViewDelegate> delegate;

- (void)prepareAndPlay:(BOOL)autoPlay WithSilentMode:(BOOL)silent;

- (void)play;
- (void)pause;
- (void)stop;

- (BOOL)isPlaying;

- (void)dispose;

@end
