//
//  OPVideoVC.m
//  ViewMoviewPlayer
//
//  Created by Mac on 16/6/8.
//  Copyright © 2016年 yijia. All rights reserved.
//

#import "OPVideoVC.h"
#import "OPVideoPlayer.h"
#import "OPMediaManger.h"
@interface OPVideoVC ()<OPVideoPlayerDelegate>

@end

@implementation OPVideoVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    }

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupVCByArray:(NSMutableArray *)array page:(NSInteger)page
{

    OPVideoPlayer *view = [[OPVideoPlayer alloc] initWithFrame:self.view.bounds];
    view.delegate = self;
    [view setupVideoByArray:array page:page];
    [self.view addSubview:view];

}

- (void)dismissVc
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
