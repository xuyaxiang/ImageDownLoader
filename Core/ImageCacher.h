//
//  ImageCacher.h
//  MeiWen
//
//  Created by enghou on 16/12/24.
//  Copyright © 2016年 xyxorigation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
typedef void(^searchCompleted)(UIImage * _Nullable image,NSError * _Nullable error);
typedef NS_ENUM(NSInteger,CacheType){
    NOTFIND = 0,
    MEM = 1,
    DISK = 2
};

NS_ASSUME_NONNULL_BEGIN
@interface ImageCacher : NSObject

+(instancetype)sharedInstance;

-(CacheType)imageExistsForKey:(NSString *)url;

-(void)imageForKey:(NSString *)url completed:(searchCompleted)complete;

-(UIImage *)imageForKey:(NSString *)url;

-(void)cacheImage:(UIImage *)image withKey:(NSString *)key;

-(void)removeAllCache;
@end
NS_ASSUME_NONNULL_END
