//
//  DownloadOperation.h
//  MeiWen
//
//  Created by enghou on 17/1/2.
//  Copyright © 2017年 xyxorigation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
typedef void(^progressBlock)(NSInteger receivedBytes,NSInteger totalBytes);

typedef void(^completedBlock)(UIImage *image,NSData *data,BOOL finished);

@interface DownloadOperation : NSOperation

@property(nonatomic,copy,readonly)progressBlock downloadProgress;
@property(nonatomic,copy,readonly)completedBlock downloadCompleted;
@property(nonatomic,strong,readonly)NSURLSessionDataTask *task;


-(instancetype)initWithRequest:(NSURLRequest *)request progress:(progressBlock)progress complete:(completedBlock)completed ;

-(void)stop;

-(void)suspend;

-(void)resume;


@end
