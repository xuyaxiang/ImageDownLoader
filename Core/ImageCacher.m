//
//  ImageCacher.m
//  MeiWen
//
//  Created by enghou on 16/12/24.
//  Copyright © 2016年 xyxorigation. All rights reserved.
//

#import "ImageCacher.h"
#import "NSString+Encrypt.h"
#import <objc/runtime.h>
#import "UIImage+MultiFormat.h"
#import "NSData+ImageContentType.h"
@interface ImageCacher()<NSCacheDelegate>

@property(nonatomic,strong)NSCache *memCache;

@property(nonatomic,strong)dispatch_queue_t searchQueue;
@end
@implementation ImageCacher

+(instancetype)sharedInstance{
    static dispatch_once_t onceToken;
    static ImageCacher * m = nil;
    dispatch_once(&onceToken, ^{
        m= [ImageCacher new];
        m.searchQueue = dispatch_queue_create("search", DISPATCH_QUEUE_CONCURRENT);
        m.memCache=[[NSCache alloc]init];
        m.memCache.totalCostLimit = 20 * 1024 *1024;
        m.memCache.delegate = m;
    });
    return m;
}


-(CacheType)imageExistsForKey:(NSString *)url{
    if ([self imageExistsAtMemoryForKey:url]) {
        return MEM;
    }
    if ([self imageExistsAtDiskForKey:url]) {
        return DISK;
    }
    return NOTFIND;
}

//判断磁盘中是否有缓存

-(void)removeAllCache{
    NSString *path = [self cacheBasePath];
    NSArray *subpaths = [[NSFileManager defaultManager]subpathsAtPath:path];
    NSLog(@"%@",subpaths);
    [subpaths enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSError *error=nil;
        NSString *p = [path stringByAppendingPathComponent:obj];
        [[NSFileManager defaultManager]removeItemAtPath:p error:&error];
        NSLog(@"%@",error);
    }];
}

-(BOOL)imageExistsAtMemoryForKey:(NSString *)url{
    if ([url length]>0) {
        NSString *key = [url md5];
        if ([self.memCache objectForKey:key]) {
            return YES;
        }
    }
    return NO;
}

-(BOOL)imageExistsAtDiskForKey:(NSString *)url{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *path = [self cacheBasePath];
    BOOL directoryExists = [manager fileExistsAtPath:path];
    if (directoryExists) {
        
        url=[url md5];
        NSArray *array = [manager subpathsAtPath:path];
        [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSLog(@"%@",obj);
        }];
        path = [path stringByAppendingPathComponent:url];

        BOOL result = [manager fileExistsAtPath:path];
        
        return result;
    }else{
        NSError *error = nil;
        BOOL result = [manager createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:&error];
        if (!result) {
            NSLog(@"%@",error.description);
        }
        return NO;
    }
}

//获取存文件的地址
-(NSString *)cacheBasePath{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    path = [path stringByAppendingPathComponent:@"XYXImageCache"];
    return path;
}

-(UIImage *)imageForKey:(NSString *)url{
    CacheType exists = [self imageExistsForKey:url];
    switch (exists) {
        case MEM:
        {
            NSString *name = [url md5];
            UIImage *image = [_memCache objectForKey:name];
            return image;
        }
            break;
        case DISK:
        {
            NSString *path = [self cacheBasePath];
            path = [path stringByAppendingPathComponent:[url md5]];
            NSData *data = [NSData dataWithContentsOfFile:path];
            UIImage *image = [UIImage createWithData:data];
            NSString *type = objc_getAssociatedObject(image, "type");
            if ([type isEqualToString:@"image/gif"]) {
                objc_setAssociatedObject(image, "data", data, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
            [self.memCache setObject:image forKey:[url md5]];
            return image;
        }
            break;
        default:
            return nil;
            break;
    }
}

//查找图片缓存,通过一个block回调
-(void)imageForKey:(NSString *)url completed:(searchCompleted)complete{
    __weak typeof(self)sself = self;
    dispatch_async(self.searchQueue, ^{
        UIImage *image = [sself imageForKey:url];
        if (image) {
            complete(image,nil);
        }else{
            complete(nil,[NSError errorWithDomain:NSURLErrorDomain code:404 userInfo:nil]);
        }
    });
}

//存储缓存
-(void)cacheImage:(UIImage *)image withKey:(NSString *)key{
    if (key!=nil) {
        NSString *name = [key md5];
        objc_setAssociatedObject(image, "name", name, OBJC_ASSOCIATION_COPY_NONATOMIC);
        [_memCache setObject:image forKey:name];
    }
}

-(void)toDisk:(UIImage *)image{
    id name = objc_getAssociatedObject(image, "name");
    id type = objc_getAssociatedObject(image, "type");
    NSString *base = [self cacheBasePath];
    NSString *target = [base stringByAppendingPathComponent:name];
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([type isEqualToString:@"image/png"]) {
        NSData *data = UIImagePNGRepresentation(image);
        [manager createFileAtPath:target contents:data attributes:nil];
    }else if ([type isEqualToString:@"image/gif"]){
        id data = objc_getAssociatedObject(image, "data");
        if (data) {
            [manager createFileAtPath:target contents:data attributes:nil];
        }
    }else{
        NSData *data = UIImageJPEGRepresentation(image, 1.0);
        [manager createFileAtPath:target contents:data attributes:nil];
    }
    
}

#pragma mark-处理未知key
-(id)valueForUndefinedKey:(NSString *)key{
    return nil;
}

#pragma mark -当内存缓存被清理时调用
-(void)cache:(NSCache *)cache willEvictObject:(id)obj{
    UIImage *image = (UIImage *)obj;
    if (image) {
        [self toDisk:obj];
    }
}




@end
