//
//  OPVideoPlayer.h
//  ViewMoviewPlayer
//
//  Created by Mac on 16/6/8.
//  Copyright © 2016年 yijia. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OPVideoPlayerDelegate <NSObject>

- (void)dismissVc;

@end

@interface OPVideoPlayer : UIView

@property (nonatomic, weak) id<OPVideoPlayerDelegate>delegate;
- (void)setupVideoByArray:(NSMutableArray *)array page:(NSInteger)page;

@end
