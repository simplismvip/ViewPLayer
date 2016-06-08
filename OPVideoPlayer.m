//
//  OPVideoPlayer.m
//  ViewMoviewPlayer
//
//  Created by Mac on 16/6/8.
//  Copyright © 2016年 yijia. All rights reserved.
//

#import "OPVideoPlayer.h"
#import <MediaPlayer/MediaPlayer.h>
#import "Slider.h"
#import "DIYButton.h"

// 枚举值，包含水平移动方向和垂直移动方向
typedef NS_ENUM(NSInteger, PanDirection){
    PanDirectionHorizontalMoved,
    PanDirectionVerticalMoved
};

@interface OPVideoPlayer ()<ProgressDelegate>

@property (nonatomic, strong) NSTimer *timer; // 定时器
@property (nonatomic, strong, readonly) DIYButton *back; // 返回按钮
@property (nonatomic, weak) UIButton *backBtn;
@property (nonatomic, weak) UIButton *share;
@property (nonatomic, strong) MPMoviePlayerController *moviePlayer; // 视频播放控件
@property (nonatomic, weak) UIButton *play; // 播放按钮
@property (nonatomic, weak) UIButton *next; // 播放按钮
@property (nonatomic, weak) UILabel *begin; // 开始的时间label
@property (nonatomic, weak) UILabel *end; // 结束时间label
@property (nonatomic, weak) UISlider *volume; //声音进度条
@property (nonatomic, weak) UIView *sliderView; // 进度条和时间label底部的view
@property (nonatomic, strong) Slider *progress;
@property (nonatomic, weak) UILabel *thumbLabel; // 添加到滑块上的时间显示label
@property (nonatomic, weak) UISlider *volumeSlider; // 用来接收系统音量条
@property (nonatomic, weak) UILabel *horizontalLabel; // 水平滑动时显示进度
@property (nonatomic, strong) NSMutableArray *videoItems;
@property (nonatomic, assign) NSInteger index;


@end

@implementation OPVideoPlayer

{
    PanDirection panDirection; // 定义一个实例变量，保存枚举值
    BOOL isVolume; // 判断是否正在滑动音量
    CGFloat sumTime; // 用来保存快进的总时长
}

- (NSMutableArray *)videoItems
{
    if (!_videoItems) {
        
        self.videoItems = [NSMutableArray array];
    }
    
    return _videoItems;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        // 返回
        UIButton *backBtn = [UIButton buttonWithType:(UIButtonTypeSystem)];
        backBtn.hidden = YES;
        UIImage *image = [UIImage imageNamed:@"back"];
        [backBtn setImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:(UIControlStateNormal)];
        backBtn.frame = CGRectMake(0, 0, 60, 50);
        [backBtn addTarget:self action:@selector(back:) forControlEvents:(UIControlEventTouchUpInside)];
        [self addSubview:backBtn];
        self.backBtn = backBtn;
        
        // 分享
        UIButton *share = [UIButton buttonWithType:(UIButtonTypeSystem)];
        share.hidden = YES;
        UIImage *imageShare = [UIImage imageNamed:@"share"];
        [share setImage:[imageShare imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:(UIControlStateNormal)];
        share.frame = CGRectMake(self.frame.size.height - 50, 0, 60, 50);
        [share addTarget:self action:@selector(share:) forControlEvents:(UIControlEventTouchUpInside)];
        [self addSubview:share];
        self.share = share;
        
        // 暂停/播放
        UIButton *play = [UIButton buttonWithType:UIButtonTypeCustom];
        play.frame = CGRectMake(0, 0, 60, 60);
        play.center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
        [play setImage:[UIImage imageNamed:@"stop"] forState:UIControlStateNormal];
        [play setImage:[UIImage imageNamed:@"play"] forState:UIControlStateSelected];
        play.hidden = YES;
        [play addTarget:self action:@selector(playMovie:) forControlEvents:UIControlEventTouchUpInside];
        [play addTarget:self action:@selector(viewNoDismiss) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:play];
        self.play = play;
        
        // 添加底部进度条和时间显示
        // 1.添加底部view
        CGFloat height = 45; // 进度条高度
        UIView *sliderView = [[UIView alloc]initWithFrame:CGRectMake(0, self.frame.size.height - height, self.frame.size.width, height)];
        sliderView.backgroundColor = [UIColor blackColor];
        sliderView.hidden = YES;
        [self addSubview:sliderView];
        self.sliderView = sliderView;
        
        // 添加下一曲按钮
        UIButton *next = [UIButton buttonWithType:UIButtonTypeCustom];
        next.frame = CGRectMake(20, 5, 30, 30);
        [next setImage:[UIImage imageNamed:@"nextSong32"] forState:UIControlStateNormal];
        next.hidden = YES;
        [next addTarget:self action:@selector(nextMovie:) forControlEvents:UIControlEventTouchUpInside];
        [_sliderView addSubview:next];
        self.next = next;
        
        // 2.添加开始时间label
        UILabel *begin = [[UILabel alloc]initWithFrame:CGRectMake(70, 0, 60, height)];
        begin.textColor = [UIColor whiteColor];
        begin.textAlignment = NSTextAlignmentCenter;
        [_sliderView addSubview:begin];
        self.begin = begin;
        
        // 3.添加进度条
        CGFloat progressX = self.begin.frame.size.width + 70;
        self.progress = [[Slider alloc]initWithFrame:CGRectMake(progressX, 0, self.frame.size.width - progressX * 2, height)];
        [self.progress.slider addTarget:self action:@selector(progressAction:event:) forControlEvents:UIControlEventValueChanged];
        [_sliderView addSubview:_progress];
        
        // 4.添加总时长label
        UILabel *end = [[UILabel alloc]initWithFrame:CGRectMake(self.frame.size.width - progressX, 0, 60, height)];
        end.textColor = [UIColor whiteColor];
        end.textAlignment = NSTextAlignmentCenter;
        
        // 设置代理
        self.progress.delegate = self;
        
        // 缓冲条背景颜色
        self.progress.cacheColor = [UIColor greenColor];
        [_sliderView addSubview:end];
        self.end = end;
        
        // 接收视屏加载好后的通知
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(durationAvailable) name:MPMovieDurationAvailableNotification object:nil];
        
        // 在滑块上添加时间显示label，拖动滑块的时候显示进度
        UILabel *thumbLabel = [[UILabel alloc]initWithFrame:CGRectMake(-15, -40, 50, 25)];
        thumbLabel.layer.masksToBounds = YES; // 显示label的边框，不然没有圆角效果
        thumbLabel.layer.cornerRadius = 3; // 显示圆角
        thumbLabel.textAlignment = NSTextAlignmentCenter;
        thumbLabel.backgroundColor = [UIColor whiteColor];
        thumbLabel.hidden = YES;
        [self.progress.thumbView addSubview:thumbLabel];
        self.thumbLabel = thumbLabel;
        
        // 创建自己的音量条
        UISlider *volume = [[UISlider alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.height / 3.8, 30)]; // 先让slider横放
        volume.center = CGPointMake(40, self.frame.size.height / 2);
        [volume setThumbImage:[UIImage imageNamed:@"nil"] forState:UIControlStateNormal]; // 给滑块一个空白的图片
        // 把slider旋转90度
        volume.transform = CGAffineTransformMakeRotation(M_PI * 1.5); // M_PI_2是90度，M_PI * 1.5是180度
        [self addSubview:volume];
        self.volume = volume;
        
        // 添加并接收系统的音量条
        // 把系统音量条放在可视范围外，用我们自己的音量条来控制
        MPVolumeView *volum = [[MPVolumeView alloc]initWithFrame:CGRectMake(-100, 0, 30, 30)];
        // 遍历volumView上控件，取出音量slider
        for (UIView *view in volum.subviews) {
            if ([view isKindOfClass:[UISlider class]]) {
                // 接收系统音量条
                self.volumeSlider = (UISlider *)view;
                // 把系统音量的值赋给自定义音量条
                self.volume.value = self.volumeSlider.value;
            }
        }
        // 添加系统音量控件
        [self addSubview:volum];
        
        // 创建两个UIImageView，用来展示音量的max，min图标
        CGFloat volumWidth = self.volumeSlider.frame.size.height; // 图标的高度
        UIImageView *maxImageView = [[UIImageView alloc]initWithFrame:CGRectMake(self.volume.frame.size.height, 0, volumWidth, volumWidth)];
        maxImageView.image = [UIImage imageNamed:@"yinliangda"];
        [self.volume addSubview:maxImageView];
        UIImageView *minImageView = [[UIImageView alloc]initWithFrame:CGRectMake(- volumWidth, 0, volumWidth, volumWidth)];
        minImageView.image = [UIImage imageNamed:@"yinliangxiao"];
        [self.volume addSubview:minImageView];
        
        // 一开始先隐藏音量条,让其上下滑动的时候出现，手势在加载完成后添加
        self.volume.hidden = YES;
        
        // 水平滑动显示的进度label
        UILabel *horizontalLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, self.frame.size.height / 1.3, self.frame.size.width, 40)];
        horizontalLabel.textColor = [UIColor whiteColor];
        horizontalLabel.textAlignment = NSTextAlignmentCenter;
        horizontalLabel.text = @"00:00 / --:--";
        // 一上来先隐藏
        horizontalLabel.hidden = YES;
        [self addSubview:horizontalLabel];
        self.horizontalLabel = horizontalLabel;
  
        
    }
    return self;
}

// 根据路径初始化播放器
- (void)setupVideoByArray:(NSMutableArray *)array page:(NSInteger)page
{
    // 拿到文件路径
    [self.videoItems removeAllObjects];
    self.videoItems = array;
    self.index = page;
    
    // 初始化视频播放控制器
    // 首先判断是本地资源还是网络资源
    NSString *sourceStr = self.videoItems.firstObject;
    NSRange range = NSMakeRange(0, 4);
    NSString *httpStr = [sourceStr substringWithRange:range];
    
    NSURL *url;
    if ([httpStr isEqualToString:@"http"]) {
        url = [NSURL URLWithString:self.videoItems[self.index]];
    }else{
        url = [NSURL fileURLWithPath:self.videoItems[self.index]];
    }
    self.moviePlayer = [[MPMoviePlayerController alloc]initWithContentURL:url];
    self.moviePlayer.view.frame = self.bounds;
    
    // 去除系统自带的控件
    self.moviePlayer.controlStyle = MPMovieControlStyleNone;
    // 视屏开始播放的时候，这个view开始响应用户的操作，把它关闭
    self.moviePlayer.view.userInteractionEnabled = NO;
    [self.moviePlayer play];
    [self insertSubview:_moviePlayer.view atIndex:0];
}


#pragma mark - 执行滑块代理方法
- (void)touchView:(float)value
{
    // 跳转到指定位置
    self.moviePlayer.currentPlaybackTime = value;
}

#pragma mark - 拖进度条执行的方法
- (void)progressAction:(UISlider *)progress event:(UIEvent *)event
{
    // 拿到手势
    UITouch *touch = [[event allTouches]anyObject];
    // 保证视图不消失
    [self viewNoDismiss];
    
    switch (touch.phase) {
        case UITouchPhaseBegan:{
            //            NSLog(@"开始移动");
            // 开始拖动滑块的时候，让时间label显示
            self.thumbLabel.hidden = NO;
            break;
        }
        case UITouchPhaseMoved:{
            //            NSLog(@"正在移动");
            // 移动的时候把value给时间label
            self.thumbLabel.text = [self durationStringWithTime:(int)progress.value];
            break;
        }
        case UITouchPhaseEnded:{
            // 跳转到指定位置
            //            NSLog(@"移动结束");
            self.begin.text = [self durationStringWithTime:progress.value];
            self.moviePlayer.currentPlaybackTime = progress.value;
            // 移动结束隐藏时间显示label
            self.thumbLabel.hidden = YES;
            break;
        }
        default:
            break;
    }
}

#pragma mark - 播放状态，timer方法
- (void)playbackStates:(NSTimer *)timer
{
    // 给进度条赋值
    // 当用户互动滑块的时候不去赋值
    // 这里不用 touchInside，因为touchInside有yes和no，松手后滑块有可能不走
    if (!self.progress.slider.highlighted) {
        self.progress.slider.value  = self.moviePlayer.currentPlaybackTime;
        // 没点滑块的时候时间label隐藏
        self.thumbLabel.highlighted = YES;
    }
    
    // 实时播放时间
    self.begin.text = [self durationStringWithTime:(int)self.moviePlayer.currentPlaybackTime];
    self.progress.cache = self.moviePlayer.playableDuration;
}

#pragma mark - 视频加载好之后执行的通知
- (void)durationAvailable
{
    // 隐藏返回按钮
    self.back.hidden = YES;
    
    // 添加一个tap手势,在视频加载好之后添加轻拍
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapAction)];
    [self addGestureRecognizer:tap];
    
    // 给视频总时长赋值
    self.end.text = [self durationStringWithTime:(int)self.moviePlayer.duration];
    // 修改progress的最大值和最小值
    self.progress.slider.maximumValue = self.moviePlayer.duration;
    self.progress.slider.minimumValue = 0;
    
    // 加载完后添加timer
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(playbackStates:) userInfo:nil repeats:YES];
    [self.timer fire];
    
    // 添加平移手势，用来控制音量和快进快退
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panDirection:)];
    [self addGestureRecognizer:pan];
}


#pragma mark - 平移手势方法
- (void)panDirection:(UIPanGestureRecognizer *)pan
{
    // 我们要响应水平移动和垂直移动
    // 根据上次和本次移动的位置，算出一个速率的point
    CGPoint veloctyPoint = [pan velocityInView:self];
    // 判断是垂直移动还是水平移动
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:{ // 开始移动
            //            NSLog(@"x:%f  y:%f",veloctyPoint.x, veloctyPoint.y);
            // 使用绝对值来判断移动的方向
            CGFloat x = fabs(veloctyPoint.x);
            CGFloat y = fabs(veloctyPoint.y);
            if (x > y) { // 水平移动
                panDirection = PanDirectionHorizontalMoved;
                // 取消隐藏
                self.horizontalLabel.hidden = NO;
                // 给sumTime初值
                sumTime = self.moviePlayer.currentPlaybackTime;
            }
            else if (x < y){ // 垂直移动
                panDirection = PanDirectionVerticalMoved;
                // 显示音量控件
                self.volume.hidden = NO;
                // 开始滑动的时候，状态改为正在控制音量
                isVolume = YES;
            }
            break;
        }
        case UIGestureRecognizerStateChanged:{ // 正在移动
            switch (panDirection) {
                case PanDirectionHorizontalMoved:{
                    [self horizontalMoved:veloctyPoint.x]; // 水平移动的方法只要x方向的值
                    break;
                }
                case PanDirectionVerticalMoved:{
                    [self verticalMoved:veloctyPoint.y]; // 垂直移动方法只要y方向的值
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case UIGestureRecognizerStateEnded:{ // 移动停止
            // 移动结束也需要判断垂直或者平移
            // 比如水平移动结束时，要快进到指定位置，如果这里没有判断，当我们调节音量完之后，会出现屏幕跳动的bug
            switch (panDirection) {
                case PanDirectionHorizontalMoved:{
                    // 隐藏视图
                    self.horizontalLabel.hidden = YES;
                    // ⚠️在滑动结束后，视屏要跳转
                    self.moviePlayer.currentPlaybackTime = sumTime;
                    // 把sumTime滞空，不然会越加越多
                    sumTime = 0;
                    break;
                }
                case PanDirectionVerticalMoved:{
                    // 垂直移动结束后，隐藏音量控件
                    self.volume.hidden = YES;
                    // 且，把状态改为不再控制音量
                    isVolume = NO;
                    break;
                }
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
}

#pragma mark - pan垂直移动的方法
- (void)verticalMoved:(CGFloat)value
{
    // 更改音量控件value
    self.volume.value -= value / 10000; // 越小幅度越小
    
    // 更改系统的音量
    self.volumeSlider.value = self.volume.value;
}
#pragma mark - pan水平移动的方法
- (void)horizontalMoved:(CGFloat)value
{
    // 快进快退的方法
    NSString *style = @"";
    if (value < 0) {
        style = @"<<";
    }
    else if (value > 0){
        style = @">>";
    }
    
    // 每次滑动需要叠加时间
    sumTime += value / 200;
    
    // 需要限定sumTime的范围
    if (sumTime > self.moviePlayer.duration) {
        sumTime = self.moviePlayer.duration;
    }else if (sumTime < 0){
        sumTime = 0;
    }
    
    // 当前快进的时间
    NSString *nowTime = [self durationStringWithTime:(int)sumTime];
    // 总时间
    NSString *durationTime = [self durationStringWithTime:(int)self.moviePlayer.duration];
    // 给label赋值
    self.horizontalLabel.text = [NSString stringWithFormat:@"%@ %@ / %@",style, nowTime, durationTime];
}

#pragma mark - 根据时长求出字符串
- (NSString *)durationStringWithTime:(int)time
{
    // 获取分钟
    NSString *min = [NSString stringWithFormat:@"%02d",time / 60];
    // 获取秒数
    NSString *sec = [NSString stringWithFormat:@"%02d",time % 60];
    return [NSString stringWithFormat:@"%@:%@", min, sec];
}

#pragma mark - 播放暂停方法
- (void)playMovie:(UIButton *)button
{
    button.selected = !button.selected;
    if (button.selected) {
        // 暂停
        [self.moviePlayer pause];
    }else{
        // 播放
        [self.moviePlayer play];
    }
}

#pragma mark - tap手势方法
- (void)tapAction
{
    [self viewNoDismiss];
    self.play.hidden = !self.play.hidden;
    self.backBtn.hidden = !self.backBtn.hidden;
    self.share.hidden = !self.share.hidden;
    self.next.hidden = !self.next.hidden;
    self.sliderView.hidden = !self.sliderView.hidden;
    self.back.hidden = !self.back.hidden;
    
    // 音量视图不是和其他视图一起出现的，如果取反，会有交替出现的bug，让它接收前面控件的hidden状态，使之同步
    self.volume.hidden = self.back.hidden;
    
}

#pragma mark - 保证视图不消失的方法,每次调用这个方法，把之前的倒计时抹去，添加一个新的3秒倒计时
- (void)viewNoDismiss
{
    // 先取消一个3秒后的方法，保证不管点击多少次，都只有一个方法在3秒后执行
    [UIView cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismissAction) object:nil];
    
    // 3秒后执行的方法
    [self performSelector:@selector(dismissAction) withObject:nil afterDelay:3];
}

// 3秒后执行的方法
- (void)dismissAction
{
    self.play.hidden = YES;
    self.next.hidden = YES;
    self.share.hidden = YES;
    self.backBtn.hidden = YES;
    self.sliderView.hidden = YES;
    self.back.hidden = YES;
    
    // 如果没有在控制音量，则隐藏
    if (!isVolume) {
        self.volume.hidden = YES;
    }
}

#pragma mark -- 返回弹出按钮
- (void)stopAction
{
    // 关闭定时器
    [self.timer invalidate];
    // 移除通知
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMovieDurationAvailableNotification object:nil];
    // 暂停视屏播放
    [self.moviePlayer stop];
}

// 返回
- (void)back:(UIButton *)btn
{
    // 暂停视屏播放
    [self stopAction];
    
    // 执行代理完成退出
    if ([self.delegate performSelector:@selector(dismissVc)]) {
        
        [self.delegate dismissVc];
    }
    
}

// 分享
- (void)share:(UIButton *)btn
{
    NSLog(@"分享");
}

// 下一首
- (void)nextMovie:(UIButton *)btn
{
    self.index++;
    if (self.index<self.videoItems.count) {
        
        [self.moviePlayer.view removeFromSuperview];
        
        // 初始化视频播放控制器
        NSString *sourceStr = self.videoItems.firstObject;
        NSRange range = NSMakeRange(0, 4);
        NSString *httpStr = [sourceStr substringWithRange:range];
        
        NSURL *url;
        if ([httpStr isEqualToString:@"http"]) {
            url = [NSURL URLWithString:self.videoItems[self.index]];
        }else{
            url = [NSURL fileURLWithPath:self.videoItems[self.index]];
        }
        self.moviePlayer = [[MPMoviePlayerController alloc]initWithContentURL:url];
        self.moviePlayer.view.frame = CGRectMake(0, 0, self.bounds.size.height, self.bounds.size.width);
        
        self.moviePlayer.controlStyle = MPMovieControlStyleNone;
        // 视屏开始播放的时候，这个view开始响应用户的操作，把它关闭
        self.moviePlayer.view.userInteractionEnabled = NO;
        [self.moviePlayer play];
        [self insertSubview:_moviePlayer.view atIndex:0];
    }else{
        return;
    }
}


@end
