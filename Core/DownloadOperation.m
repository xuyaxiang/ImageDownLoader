//
//  DownloadOperation.m
//  MeiWen
//
//  Created by enghou on 17/1/2.
//  Copyright © 2017年 xyxorigation. All rights reserved.
//

#import "DownloadOperation.h"
#import <ImageIO/ImageIO.h>
#import "UIImage+MultiFormat.h"
#import <objc/runtime.h>
#import "ImageCacher.h"
@interface DownloadOperation()<NSURLSessionDataDelegate>
@property(nonatomic,strong)NSMutableData *imageData;
@property(nonatomic,assign)long long expectedSize;
@property(nonatomic,assign,getter=isFinished)BOOL finished;
@property(nonatomic,assign,getter=isExecuting)BOOL excuting;
@end
@implementation DownloadOperation
{
    size_t width,height;
    UIImageOrientation orientation;
}
@synthesize finished = _finished;
@synthesize excuting = _excuting;
-(instancetype)initWithRequest:(NSURLRequest *)request progress:(progressBlock)progress complete:(completedBlock)completed{
    if ((self=[super init])) {
        _downloadProgress = progress;
        _downloadCompleted = completed;
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
        _task = [session dataTaskWithRequest:request];
        _imageData = [NSMutableData data];
        
        _expectedSize = 0;
    }
    return self;
}

-(void)start{
    if (self.isCancelled) {
        return;
    }
    [_task resume];
}

-(void)setExcuting:(BOOL)excuting{
    [self willChangeValueForKey:@"isExcuting"];
    _excuting=excuting;
    [self didChangeValueForKey:@"isExcuting"];
}

-(void)setFinished:(BOOL)finished{
    [self willChangeValueForKey:@"isFinished"];
    _finished=finished;
    [self didChangeValueForKey:@"isFinished"];
}


-(void)stop{
    self.excuting=NO;
    self.finished=YES;
    _downloadProgress = nil;
    _downloadCompleted = nil;
    _task = nil;
    _imageData=nil;
}

-(void)suspend{
    [_task suspend];
}

-(void)resume{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc]initWithURL:_task.currentRequest.URL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20];
    NSString *range = [NSString stringWithFormat:@"bytes=%zd-",[_imageData length]];
    [request setValue:range forHTTPHeaderField:@"Range"];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    _task = [session dataTaskWithRequest:request];
    [_task resume];
}

#pragma mark - URLSessionDelegate
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    if (error!=nil) {
        [session invalidateAndCancel];
        [self stop];
    }else{
        [session finishTasksAndInvalidate];
        //这里需要将数据保存到内存或者磁盘
        UIImage *image = [UIImage createWithData:self.imageData];
        __weak typeof(self)sself = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (sself.downloadCompleted) {
                sself.downloadCompleted(image,sself.imageData,YES);
                [sself stop];
            }
        });
    }       
}

//-(void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error{
//    [self stop];
//}

-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler{
    if(![response respondsToSelector:@selector(statusCode)] || ([((NSHTTPURLResponse *)response) statusCode] < 400 && [((NSHTTPURLResponse *)response) statusCode] != 304)){
        NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
        _expectedSize = [res expectedContentLength];
        NSString *type = [[res MIMEType]substringToIndex:5];
        if (![type isEqualToString:@"image"]) {
            completionHandler(NSURLSessionResponseCancel);
            return;
        }
        if (_downloadProgress) {
            dispatch_async(dispatch_get_main_queue(), ^{
               _downloadProgress((long long)0,_expectedSize);
            });
        }
        completionHandler(NSURLSessionResponseAllow);
    }else{
        completionHandler(NSURLSessionResponseCancel);
        [self stop];
    }
}

-(void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler{
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential , credential);
    }
}

//监控进度
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
    [_imageData appendData:data];
//    __weak typeof(self) sself = self;
//    dispatch_async(dispatch_get_main_queue(), ^{
//        if (sself.downloadProgress) {
//            sself.downloadProgress([sself.imageData length],sself.expectedSize);
//        }
//    });
//    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)_imageData, NULL);
//    	if (width + height == 0) {
//    		CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
//    		if (properties) {
//    			NSInteger orientationValue = -1;
//    			CFTypeRef val = CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
//    			if (val) {
//    				CFNumberGetValue(val, kCFNumberLongType, &height);
//    			}
//    		val=CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
//    			if (val) {
//    				CFNumberGetValue(val, kCFNumberLongType, &width);
//    			}
//    			val=CFDictionaryGetValue(properties, kCGImagePropertyOrientation);
//    			if (val) {
//    				CFNumberGetValue(val, kCFNumberNSIntegerType, &orientationValue);
//    			}
//    			orientation = [[self class]orientationFromPropertyValue:orientationValue];
//    			CFRelease(properties);
//    		}
//    	}
//    	if (width+height > 0) {
//    		CGImageRef partialImageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
//    #ifdef TARGET_OS_IPHONE
//    		if (partialImageRef) {
//    			const size_t partialHeight = CGImageGetHeight(partialImageRef);
//    			CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//    			CGContextRef bmContext = CGBitmapContextCreate(NULL, width, height, 8, width*4, colorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
//    			CGColorSpaceRelease(colorSpace);
//    			if (bmContext) {
//    				CGContextDrawImage(bmContext, (CGRect){.origin.x = 0.0f, .origin.y = 0.0f, .size.width = width, .size.height = partialHeight}, partialImageRef);
//    				CGImageRelease(partialImageRef);
//    				partialImageRef = CGBitmapContextCreateImage(bmContext);
//                    
//    				CGContextRelease(bmContext);
//    			}else{
//    				CGImageRelease(partialImageRef);
//    				partialImageRef = nil;
//    			}
//    		}
//    #endif
//    		if (partialImageRef) {
//    			UIImage *image = [UIImage imageWithCGImage:partialImageRef scale:[[UIScreen mainScreen]scale] orientation:orientation];
//    			if (image) {
//    				if (self.downloadCompleted) {
//    					__weak typeof(self) sself = self;
//    					BOOL finished = (sself.expectedSize == [self.imageData length] ? YES : NO);
//    					dispatch_sync(dispatch_get_main_queue(), ^{
//    						sself.downloadCompleted(image,self.imageData ,finished);
//    					});
//    				}
//    			}
//    			CGImageRelease(partialImageRef);
//    		}
//    	}else{
//    		[self stop];
//    	}
//    	CFRelease(imageSource);
}

+ (UIImageOrientation)orientationFromPropertyValue:(NSInteger)value {
    switch (value) {
        case 1:
            return UIImageOrientationUp;
        case 3:
            return UIImageOrientationDown;
        case 8:
            return UIImageOrientationLeft;
        case 6:
            return UIImageOrientationRight;
        case 2:
            return UIImageOrientationUpMirrored;
        case 4:
            return UIImageOrientationDownMirrored;
        case 5:
            return UIImageOrientationLeftMirrored;
        case 7:
            return UIImageOrientationRightMirrored;
        default:
            return UIImageOrientationUp;
    }
}

-(void)dealloc{
    NSLog(@"the end!");
}
@end
