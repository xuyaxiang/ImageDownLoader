//
//  UIImageView+WebCache.m
//  MeiWen
//
//  Created by enghou on 17/1/5.
//  Copyright © 2017年 xyxorigation. All rights reserved.
//

#import "UIImageView+WebCache.h"
#import "ImageLoader.h"
@implementation UIImageView (WebCache)
-(void)setImageWithURL:(NSString *)url{
    __weak typeof(self)sself = self;
    [[ImageLoader sharedInstance]loadImageWithURL:url progress:nil completed:^(UIImage *image, NSData *data, BOOL finished) {
        [sself setImage:image];
    }];
}
@end
