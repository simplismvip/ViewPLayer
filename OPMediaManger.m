//
//  OPMediaManger.m
//  ViewMoviewPlayer
//
//  Created by Mac on 16/6/6.
//  Copyright © 2016年 yijia. All rights reserved.
//

#import "OPMediaManger.h"
#import "OPVideoController.h"
#import "OPVideoVC.h"
#import "OPVideoPlayer.h"

@interface OPMediaManger()

@end

@implementation OPMediaManger

// 过滤视频文件
+ (OPVideoController *)videoByPath:(NSString *)path page:(NSInteger)page
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableArray *muArr = [NSMutableArray array];
    NSMutableArray *local = [NSMutableArray array];
    NSMutableArray *url = [NSMutableArray array];
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:path error:nil];
    
    // 1> 首先过滤出 M_ 开头的文件
    for (NSString *fileName in contents) {
        
        NSArray *array;
        if ([fileName pathExtension].length > 0) {
            
            array = [fileName componentsSeparatedByString:@"_"];
        }
        
        if (array.count >= 2) {
            
            if ([array[1] isEqualToString:[NSString stringWithFormat:@"%ld", page]]) {
                
                NSRange range = NSMakeRange(0, 2);
                NSString *m_ = [fileName substringWithRange:range];
                if ([m_ isEqualToString:@"M_"]) {
                    
                    [muArr addObject:fileName];
                }
            }
        }
    }
    
    for (NSString *name in muArr) {
        
        NSString *extension = [[name pathExtension] lowercaseString];
        
        // 本地 local
        if ([extension isEqualToString:@"mp4"] || [extension isEqualToString:@"mov"] || [extension isEqualToString:@"3gp"] || [extension isEqualToString:@"mpv"]) {
            
            // 首先要对文件进行一次筛查, page页
            NSString *key = [name componentsSeparatedByString:@"_"][1];
            if ([key isEqualToString:[NSString stringWithFormat:@"%ld", page]]) {
                
                [local addObject:[path stringByAppendingPathComponent:name]];
            }
            
        }else {// 网络 URL
            
            // 首先要对文件进行一次筛查, page页
            NSString *key = [name componentsSeparatedByString:@"_"][1];
            if ([key isEqualToString:[NSString stringWithFormat:@"%ld", page]]) {
                
                // 去掉换行符和空格等不合法格式
                NSString *pathString = [path stringByAppendingPathComponent:name];
                NSString *pathStr = [NSString stringWithContentsOfFile:pathString encoding:NSUTF8StringEncoding error:nil];
                pathStr = [pathStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                NSString *newString = [pathStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                NSString *ext = [[newString pathExtension] lowercaseString];
                
                if ([ext isEqualToString:@"mp4"] || [ext isEqualToString:@"mov"] || [ext isEqualToString:@"3gp"] || [ext isEqualToString:@"mpv"]) {
                    
                    [url addObject:newString];
                }
            }
        }
    }
    if (local.count > 0) {
    
        OPVideoController *vc = [[OPVideoController alloc] init];
        [vc setupVideoByArray:local page:page];
        return vc;
        
    } else if (url.count > 0){
        
        OPVideoController *vc = [[OPVideoController alloc] init];
        
        [vc setupVideoByArray:url page:page];
        return vc;
    }else{
        
        return nil;
    }
}


// 过滤视频文件
+ (OPVideoVC *)viewByPath:(NSString *)path page:(NSInteger)page
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableArray *muArr = [NSMutableArray array];
    NSMutableArray *local = [NSMutableArray array];
    NSMutableArray *url = [NSMutableArray array];
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:path error:nil];
    
    // 1> 首先过滤出 M_ 开头的文件
    for (NSString *fileName in contents) {
        
        NSArray *array;
        if ([fileName pathExtension].length > 0) {
            
            array = [fileName componentsSeparatedByString:@"_"];
        }
        
        if (array.count >= 2) {
            
            if ([array[1] isEqualToString:[NSString stringWithFormat:@"%ld", page]]) {
                
                NSRange range = NSMakeRange(0, 2);
                NSString *m_ = [fileName substringWithRange:range];
                if ([m_ isEqualToString:@"M_"]) {
                    
                    [muArr addObject:fileName];
                }
            }
        }
    }
    
    for (NSString *name in muArr) {
        
        NSString *extension = [[name pathExtension] lowercaseString];
        
        // 本地 local
        if ([extension isEqualToString:@"mp4"] || [extension isEqualToString:@"mov"] || [extension isEqualToString:@"3gp"] || [extension isEqualToString:@"mpv"]) {
            
            // 首先要对文件进行一次筛查, page页
            NSString *key = [name componentsSeparatedByString:@"_"][1];
            if ([key isEqualToString:[NSString stringWithFormat:@"%ld", page]]) {
                
                [local addObject:[path stringByAppendingPathComponent:name]];
            }
            
        }else {// 网络 URL
            
            // 首先要对文件进行一次筛查, page页
            NSString *key = [name componentsSeparatedByString:@"_"][1];
            if ([key isEqualToString:[NSString stringWithFormat:@"%ld", page]]) {
                
                // 去掉换行符和空格等不合法格式
                NSString *pathString = [path stringByAppendingPathComponent:name];
                NSString *pathStr = [NSString stringWithContentsOfFile:pathString encoding:NSUTF8StringEncoding error:nil];
                pathStr = [pathStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                NSString *newString = [pathStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                NSString *ext = [[newString pathExtension] lowercaseString];
                
                if ([ext isEqualToString:@"mp4"] || [ext isEqualToString:@"mov"] || [ext isEqualToString:@"3gp"] || [ext isEqualToString:@"mpv"]) {
                    
                    [url addObject:newString];
                }
            }
        }
    }
    if (local.count > 0) {
        
        OPVideoVC *vc = [[OPVideoVC alloc] init];
        [vc setupVCByArray:local page:page];
        return vc;
        
    } else if (url.count > 0){
        
        OPVideoVC *vc = [[OPVideoVC alloc] init];
        [vc setupVCByArray:url page:page];
        return vc;
    }else{
        
        return nil;
    }
}



// 过滤视频文件
+ (BOOL)audioByPath:(NSString *)path page:(NSInteger)page
{
    // 首先给索引赋值
    // self.index = page;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSMutableArray *muArr = [NSMutableArray array];
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:path error:nil];
    
    // 1> 首先过滤出 M_ 开头的文件
    for (NSString *fileName in contents) {
        
        NSArray *array;
        if ([fileName pathExtension].length > 0) {
            
            array = [fileName componentsSeparatedByString:@"_"];
        }
        
        if (array.count >= 2) {
            
            if ([array[1] isEqualToString:[NSString stringWithFormat:@"%ld", page]]) {
                
                NSRange range = NSMakeRange(0, 2);
                NSString *m_ = [fileName substringWithRange:range];
                if ([m_ isEqualToString:@"V_"]) {
                    
                    [muArr addObject:fileName];
                }
            }
        }
    }
    
    for (NSString *name in muArr) {
        
        NSString *extension = [[name pathExtension] lowercaseString];
        
        // 本地 local
        if ([extension isEqualToString:@"mp3"]) {
            
            // 首先要对文件进行一次筛查, page页
            NSString *key = [name componentsSeparatedByString:@"_"][1];
            if ([key isEqualToString:[NSString stringWithFormat:@"%ld", page]]) {
                
                return YES;
            }
            
        }else{// 网络 URL
            
            // 首先要对文件进行一次筛查, page页
            NSString *key = [name componentsSeparatedByString:@"_"][1];
            if ([key isEqualToString:[NSString stringWithFormat:@"%ld", page]]) {
                
                // 去掉换行符和空格等不合法格式
                NSString *pathString = [path stringByAppendingPathComponent:name];
                NSString *pathStr = [NSString stringWithContentsOfFile:pathString encoding:NSUTF8StringEncoding error:nil];
                pathStr = [pathStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                NSString *newString = [pathStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                NSString *ext = [[newString pathExtension] lowercaseString];
                
                if ([ext isEqualToString:@"mp3"]) {
                    
                    return YES;
                }
            }
            
        }
    }
    
    return NO;
}


@end
