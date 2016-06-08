//
//  OPMediaManger.h
//  ViewMoviewPlayer
//
//  Created by Mac on 16/6/6.
//  Copyright © 2016年 yijia. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OPVideoVC;
@class OPVideoController;
@interface OPMediaManger : NSObject

+ (OPVideoController *)videoByPath:(NSString *)path page:(NSInteger)page;
+ (OPVideoVC *)viewByPath:(NSString *)path page:(NSInteger)page;
// + (BOOL)audioByPath:(NSString *)path page:(NSInteger)page;
@end
