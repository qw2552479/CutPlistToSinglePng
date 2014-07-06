//
//  AppDelegate.m
//  CutPNG
//
//  Created by aatc on 13-10-29.
//  Copyright (c) 2013年 aatc. All rights reserved.
//

#import "AppDelegate.h"
#import "png.h"
#import <stdio.h>
#import <stdlib.h>
#import <stdint.h>
#import "zlib.h"
#define DEFAULTPATH @"/NCHUCutPng"

@implementation AppDelegate

/* A coloured pixel. */

typedef struct {
    uint8_t red;
    uint8_t green;
    uint8_t blue;
    uint8_t alpha;
} pixel_t;

/* A picture. */

typedef struct  {
    pixel_t *pixels;
    size_t width;
    size_t height;
} bitmap_t;


- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    NSRect rect = NSMakeRect(410, 19, 409, 440);
    imgView = [[ImageView alloc] initWithFrame:rect];

    [imgView setWantsLayer:YES];
    imgView.delegate = self;
    [self.window.contentView addSubview:imgView];
 
}

- (IBAction)publish:(id)sender
{
    NSString *filePath = _texturePath.stringValue;
    [self addSpriteFramesByPath:filePath];
}

-(void) addSpriteFramesByPath:(NSString*)plistPath
{
    NSDictionary *dic = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    NSRange rang = NSMakeRange(0, plistPath.length-6);
    NSString *imagePath = [plistPath substringWithRange:rang];
    [self addSpriteFramesWithDictionary:dic textureReference:[NSString stringWithFormat:@"%@.png", imagePath]];
}

-(void) addSpriteFramesWithDictionary:(NSDictionary*)dictionary textureReference:(id)textureReference
{
    NSString *fulPath = @"";
    if ([_outputPath.stringValue isEqualToString:@""]) {
        NSArray *strArray = [textureReference componentsSeparatedByString:@"/"];
        for (int i = 1; i < strArray.count - 1; i++) {
            NSString *str = [NSString stringWithFormat:@"/%@", [strArray objectAtIndex:i]];
            fulPath = [fulPath stringByAppendingString:str];
        }
        fulPath = [fulPath stringByAppendingString:DEFAULTPATH];
        NSLog(@"%@", fulPath);
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDir = NO;
        BOOL existed = [fileManager fileExistsAtPath:fulPath isDirectory:&isDir];
        if ( !(isDir == YES && existed == YES) )
        {
            [fileManager createDirectoryAtPath:fulPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
    } else {
        fulPath = _outputPath.stringValue;
    }
    NSDictionary *metadataDict = [dictionary objectForKey:@"metadata"];
	NSDictionary *framesDict = [dictionary objectForKey:@"frames"];
    
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:textureReference];
    CGImageRef ref = [image CGImageForProposedRect:nil context:nil hints:nil];
	int format = 0;
    
	// get the format
	if(metadataDict != nil)
		format = [[metadataDict objectForKey:@"format"] intValue];
    
	// check the format
	NSAssert( format >= 0 && format <= 3, @"format is not supported for CCSpriteFrameCache addSpriteFramesWithDictionary:textureFilename:");
	// SpriteFrame info
	CGRect rectInPixels;
	BOOL isRotated;
	CGPoint frameOffset;
	CGSize originalSize;

	// add real frames
	for(NSString *frameDictKey in framesDict) {
		NSDictionary *frameDict = [framesDict objectForKey:frameDictKey];
        if(format == 0) {
			float x = [[frameDict objectForKey:@"x"] floatValue];
			float y = [[frameDict objectForKey:@"y"] floatValue];
			float w = [[frameDict objectForKey:@"width"] floatValue];
			float h = [[frameDict objectForKey:@"height"] floatValue];
			float ox = [[frameDict objectForKey:@"offsetX"] floatValue];
			float oy = [[frameDict objectForKey:@"offsetY"] floatValue];
			int ow = [[frameDict objectForKey:@"originalWidth"] intValue];
			int oh = [[frameDict objectForKey:@"originalHeight"] intValue];
			// abs ow/oh
			ow = abs(ow);
			oh = abs(oh);
            
			// set frame info
			rectInPixels = CGRectMake(x, y, w, h);
			isRotated = NO;
			frameOffset = CGPointMake(ox, oy);
			originalSize = CGSizeMake(ow, oh);
		} else if(format == 1 || format == 2) {
            CGRect frame = NSRectFromString([frameDict objectForKey:@"frame"]);
			BOOL rotated = NO;
            
			// rotation
			if(format == 2)
				rotated = [[frameDict objectForKey:@"rotated"] boolValue];
            
			CGPoint offset = NSPointFromString([frameDict objectForKey:@"offset"]);
			CGSize sourceSize = NSSizeFromString([frameDict objectForKey:@"sourceSize"]);
            
			// set frame info
			rectInPixels = frame;
			isRotated = rotated;
			frameOffset = offset;
			originalSize = sourceSize;
		} else if(format == 3) {
			// get values
			CGSize spriteSize = NSSizeFromString([frameDict objectForKey:@"spriteSize"]);
			CGPoint spriteOffset = NSPointFromString([frameDict objectForKey:@"spriteOffset"]);
			CGSize spriteSourceSize = NSSizeFromString([frameDict objectForKey:@"spriteSourceSize"]);
			CGRect textureRect = NSRectFromString([frameDict objectForKey:@"textureRect"]);
			BOOL textureRotated = [[frameDict objectForKey:@"textureRotated"] boolValue];
			// set frame info
			rectInPixels = CGRectMake(textureRect.origin.x, textureRect.origin.y, spriteSize.width, spriteSize.height);
			isRotated = textureRotated;
			frameOffset = spriteOffset;
			originalSize = spriteSourceSize;
		}
        
        NSRect nsrect = NSRectFromCGRect(rectInPixels);
        
        if (isRotated) {
            nsrect = [self convertRectBack:nsrect];
        }
      //  NSRect imageRect = NSMakeRect(0, 0, image.size.width, image.size.height);
        CGImageRef imgref = CGImageCreateWithImageInRect(ref, nsrect);

        NSString *path = [NSString stringWithFormat:@"/%@", frameDictKey];
        CFDataRef pixelData = CGDataProviderCopyData(CGImageGetDataProvider(imgref));
        const UInt8* data = (UInt8 *)CFDataGetBytePtr(pixelData);
        
        size_t width = CGImageGetWidth(imgref);
        size_t height = CGImageGetHeight(imgref);
        
        bitmap_t png;
        
        png.width = width;
        png.height = height;
        
        png.pixels = calloc (sizeof (pixel_t), png.width * png.height);
    
        int length = CFDataGetLength(pixelData);
        int index = 0;
        
        if (isRotated) {
            png.width = height;
            png.height = width;
            //width = 5, height = 4
            for (int y = 0; y < width; ++y) {
                for (int x = 0; x < height; ++x) {
                    //x从5 10 15 20开始
                    pixel_t *pixel = pixel_at(& png, x, y);
                    long k = ((x * width + width) - y) * 4;
                    pixel->red = data[k];
                    pixel->green = data[k+1];
                    pixel->blue = data[k+2];
                    pixel->alpha = data[k+3];
                }
            }
        } else {
            for (int y = 0; y < height; ++y) {
                for (int x = 0; x < width; ++x) {
                    pixel_t *pixel = pixel_at(& png, x, y);
                    pixel->red = data[index];
                    pixel->green = data[index+1];
                    pixel->blue = data[index+2];
                    pixel->alpha = data[index+3];
                    index += 4;
                }
            }

        }
        
        NSString *finalimagePath = [fulPath stringByAppendingString:path];
        save_png_to_file( & png, [finalimagePath UTF8String]);
    }

}

- (NSRect)convertRectBack:(NSRect)rect
{
    float oriX = rect.origin.x;
    float oriY = rect.origin.y;
    float width = rect.size.height;
    float height = rect.size.width;
    
    return CGRectMake(oriX, oriY, width, height);
}

static int pix (int value, int max)
{
    if (value < 0)
        return 0;
    return (int) (256.0 *((double) (value)/(double) max));
}

static pixel_t * pixel_at (bitmap_t * bitmap, int x, int y)
{
    return bitmap->pixels + bitmap->width * y + x;
}

static int save_png_to_file (bitmap_t *bitmap, const char *path)
{
    FILE * fp;
    png_structp png_ptr = NULL;
    png_infop info_ptr = NULL;
    size_t x, y;
    png_byte ** row_pointers = NULL;
    /* "status" contains the return value of this function. At first
     it is set to a value which means 'failure'. When the routine
     has finished its work, it is set to a value which means
     'success'. */
    int status = -1;
    /* The following number is set by trial and error only. I cannot
     see where it it is documented in the libpng manual.
     */
    int pixel_size = 4;
    int depth = 8;
    
    fp = fopen (path, "wb");
    if (! fp) {
        goto fopen_failed;
    }
    
    png_ptr = png_create_write_struct (PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    if (png_ptr == NULL) {
        goto png_create_write_struct_failed;
    }
    
    info_ptr = png_create_info_struct (png_ptr);
    if (info_ptr == NULL) {
        goto png_create_info_struct_failed;
    }
    
    /* Set up error handling. */
    
    if (setjmp (png_jmpbuf (png_ptr))) {
        goto png_failure;
    }
    
    /* Set image attributes. */
    
    
    png_set_IHDR (png_ptr,
                  info_ptr,
                  bitmap->width,
                  bitmap->height,
                  depth,
                  PNG_COLOR_TYPE_RGB_ALPHA,
                  PNG_INTERLACE_NONE,
                  PNG_COMPRESSION_TYPE_DEFAULT,
                  PNG_FILTER_TYPE_DEFAULT);
    
    /* Initialize rows of PNG. */
    
    row_pointers = png_malloc (png_ptr, bitmap->height * sizeof (png_byte *));
    for (y = 0; y < bitmap->height; ++y) {
        png_byte *row =
        png_malloc (png_ptr, sizeof (uint8_t) * bitmap->width * pixel_size);
        row_pointers[y] = row;
        for (x = 0; x < bitmap->width; ++x) {
            pixel_t * pixel = pixel_at (bitmap, x, y);
            *row++ = pixel->red;
            *row++ = pixel->green;
            *row++ = pixel->blue;
            *row++ = pixel->alpha;
        }
    }
    
    /* Write the image data to "fp". */
    
    png_init_io (png_ptr, fp);
    png_set_rows (png_ptr, info_ptr, row_pointers);
    png_write_png (png_ptr, info_ptr, PNG_TRANSFORM_IDENTITY, NULL);
    
    /* The routine has successfully written the file, so we set
     "status" to a value which indicates success. */
    
    status = 0;
    
    for (y = 0; y < bitmap->height; y++) {
        png_free (png_ptr, row_pointers[y]);
    }
    png_free (png_ptr, row_pointers);
    
png_failure:
png_create_info_struct_failed:
    png_destroy_write_struct (&png_ptr, &info_ptr);
png_create_write_struct_failed:
    fclose (fp);
fopen_failed:
    return status;
}

#pragma - mark ImageViewDelegate
- (void)dragFileToWindow:(NSString *)filepath
{
    NSRange rang = NSMakeRange(filepath.length-3, 3);
    NSString *suffix = [filepath substringWithRange:rang];
    NSString *imagePath;
    NSRange newRang;
    if ([suffix isEqualToString:@"png"]) {
        newRang = NSMakeRange(0, filepath.length-4);
        imagePath = [filepath substringWithRange:newRang];
        [_texturePath setStringValue:[NSString stringWithFormat:@"%@.plist", imagePath]];
    } else {
        [_texturePath setStringValue:filepath];
    }
}



@end
