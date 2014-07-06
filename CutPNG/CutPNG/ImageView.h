//
//  ImageView.h
//  CutPNG
//
//  Created by wujiajing on 13-10-30.
//  Copyright (c) 2013年 aatc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol ImageViewDelegate <NSObject>

- (void)dragFileToWindow:(NSString *)filepath;

@end

@interface ImageView : NSView <NSDraggingDestination>
{
    NSImage *myImage;
    id<ImageViewDelegate> _delegate;
}

@property (nonatomic, assign) id<ImageViewDelegate> delegate;

- (void)setImage:(NSImage *)image;
- (NSImage *)image;

@end
