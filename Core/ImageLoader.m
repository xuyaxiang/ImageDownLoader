//
//  ImageLoader.m
//  MeiWen
//
//  Created by enghou on 16/12/24.
//  Copyright © 2016年 xyxorigation. All rights reserved.
//

#import "ImageLoader.h"
#import "ImageCacher.h"
#import "NSData+ImageContentType.h"
#import <objc/runtime.h>
@interface ImageLoader()

@property(nonatomic,strong)NSOperationQueue *netQueue;//负责网络请求的queue

@end
@implementation ImageLoader
+(instancetype)sharedInstance{
    static dispatch_once_t onceToken;
    static ImageLoader *i = nil;
    dispatch_once(&onceToken, ^{
        i = [ImageLoader new];
        i.netQueue = [[NSOperationQueue alloc]init];
        i.netQueue.maxConcurrentOperationCount = 6;
    });
    return  i;
}

-(void)loadImageWithURL:(NSString *)url progress:(progressBlock)progress completed:(completedBlock)completed{
    if (url==nil) {
        return;
    }
    [[ImageCacher sharedInstance]imageForKey:url completed:^(UIImage * _Nullable image, NSError * _Nullable error) {
        if (image==nil) {
            NSURL *targetUrl = [NSURL URLWithString:url];
            NSURLRequest *targetRequest = [NSURLRequest requestWithURL:targetUrl cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20];
            DownloadOperation *operation = [[DownloadOperation alloc]initWithRequest:targetRequest progress:progress complete:^(UIImage *image,NSData *data,BOOL finished) {
                if (finished) {
                    NSString *type = objc_getAssociatedObject(image, "type");
                    if ([type isEqual:@"image/gif"]) {
                        objc_setAssociatedObject(image, "data", data, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                    }
                    [[ImageCacher sharedInstance]cacheImage:image withKey:url];
                }
                completed(image,data,finished);
            }];
            [self.netQueue addOperation:operation];
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                completed(image,nil,YES);
            });
        }
    }];
}

-(void)suspendAllDownload{
    [_netQueue.operations enumerateObjectsUsingBlock:^(__kindof NSOperation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        DownloadOperation *op = (DownloadOperation *)obj;
        [op suspend];
    }];
}

-(void)cancelAllDownload{
    [_netQueue.operations enumerateObjectsUsingBlock:^(__kindof NSOperation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        DownloadOperation *op = (DownloadOperation *)obj;
        [op stop];
    }];
}

-(void)resumeAllDownload{
    [_netQueue.operations enumerateObjectsUsingBlock:^(__kindof NSOperation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        DownloadOperation *op = (DownloadOperation *)obj;
        [op resume];
    }];
}

@end
