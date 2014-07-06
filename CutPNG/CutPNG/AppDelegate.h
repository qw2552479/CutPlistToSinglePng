//
//  AppDelegate.h
//  CutPNG
//
//  Created by aatc on 13-10-29.
//  Copyright (c) 2013年 aatc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

#import "ImageView.h"
@interface AppDelegate : NSObject <NSApplicationDelegate, ImageViewDelegate>
{
    __weak NSTextField *_texturePath;
    __weak NSTextField *_outputPath;
    ImageView *imgView;
}

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *texturePath;
@property (weak) IBOutlet NSTextField *outputPath;

- (IBAction)publish:(id)sender;

@end
