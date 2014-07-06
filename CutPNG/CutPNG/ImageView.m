//
//  ImageView.m
//  CutPNG
//
//  Created by wujiajing on 13-10-30.
//  Copyright (c) 2013年 aatc. All rights reserved.
//

#import "ImageView.h"

@implementation ImageView

@synthesize delegate = _delegate;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        [self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
        myImage = [NSImage imageNamed:@"tip.png"];
        [self setNeedsDisplay:YES];
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    
	[super drawRect:dirtyRect];
    // Drawing code here.
    NSRect ourBounds = [self bounds];
    [myImage setSize:ourBounds.size];
    [myImage compositeToPoint:(ourBounds.origin) operation:NSCompositeSourceOver];
}

- (void)setImage:(NSImage *)image
{
    NSImage *temp = [image retain];
    [myImage release];
    myImage = temp;
}
- (NSImage *)image
{
    return myImage;
}

#pragma - mark NSDraggingDelegate
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];

    if ( [[pboard types] containsObject:NSColorPboardType] ) {
        if (sourceDragMask & NSDragOperationGeneric) {
            return NSDragOperationGeneric;
        }
    }
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        if (sourceDragMask & NSDragOperationLink) {
            return NSDragOperationLink;
        } else if (sourceDragMask & NSDragOperationCopy) {
            return NSDragOperationCopy;
        }
    }
    return NSDragOperationNone;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    
}
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];

    if ( [[pboard types] containsObject:NSColorPboardType] ) {

    } else if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        
        if (sourceDragMask & NSDragOperationLink) {
            NSString *filepath = [files objectAtIndex:0];
            NSRange rang = NSMakeRange(filepath.length-3, 3);
            NSString *suffix = [filepath substringWithRange:rang];
            NSString *imagePath;
            NSRange newRang;
            NSImage *image;
            if ([suffix isEqualToString:@"png"] || [suffix isEqualToString:@"ccz"]) {
                newRang = NSMakeRange(0, filepath.length-4);
                imagePath = [filepath substringWithRange:newRang];
                image = [[NSImage alloc] initWithContentsOfFile:filepath];
            }  else {
                rang = NSMakeRange(0, filepath.length-6);
                imagePath = [filepath substringWithRange:rang];
                image = [[NSImage alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@.png", imagePath]];
            }
            [self.delegate dragFileToWindow:filepath];
            [self setImage:image];
            [self setNeedsDisplay:YES];
            
        } else {
            NSLog(@"%@", files);
        }
    }
    return YES;
}

@end
