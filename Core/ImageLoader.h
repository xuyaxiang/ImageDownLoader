//
//  ImageLoader.h
//  MeiWen
//
//  Created by enghou on 16/12/24.
//  Copyright © 2016年 xyxorigation. All rights reserved.
//  负责去下载

#import <Foundation/Foundation.h>
#import "DownloadOperation.h"
NS_ASSUME_NONNULL_BEGIN
@interface ImageLoader : NSObject

+(instancetype)sharedInstance;
//下载
-(void)loadImageWithURL:(NSString *)url progress:(progressBlock _Nullable)progress completed:(completedBlock)completed;

-(void)cancelAllDownload;

-(void)suspendAllDownload;

-(void)resumeAllDownload;
@end
NS_ASSUME_NONNULL_END
