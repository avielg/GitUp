//
//  RPSyntaxColorScheme.m
//  RPSyntaxHighlighter
//
//  Created by Rhys Powell on 19/01/13.
//  Copyright (c) 2013 Rhys Powell. All rights reserved.
//

#import "RPSyntaxTheme.h"
#import "NSColor+RPSyntaxAdditions.h"

@interface RPSyntaxTheme ()

@property (nonatomic, strong) NSDictionary *styles;

@end

@implementation RPSyntaxTheme

- (instancetype)initWithContentsOfFile:(NSString *)filename
{
    if (self = [super init]) {
      NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        NSString *jsonPath = [bundle pathForResource:filename ofType:@"json"];
        NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
        
        NSError *error = nil;
        self.styles = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
        if (error) {
            NSLog(@"[RPSyntaxHighlighter] Error loading theme JSON: %@", error.localizedDescription);
        }
    }
    
    return self;
}

- (NSDictionary *)attributesForScope:(NSString *)scope defaultFont:(NSFont *)defaultFont
{
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];

    NSDictionary *style = self.styles[scope];
    NSColor *foregroundColor = [NSColor colorWithHexString:style[@"color"]];
    NSColor *backgroundColor = [NSColor colorWithHexString:style[@"background"]];
    NSString *fontName = style[@"font"];
    CGFloat fontSize = [style[@"fontSize"] floatValue];
    BOOL isBold = [style[@"bold"] boolValue];

    if (foregroundColor) {
        attributes[NSForegroundColorAttributeName] = foregroundColor;
    }
    
    if (backgroundColor) {
        attributes[NSBackgroundColorAttributeName] = backgroundColor;
    }
    
    if (fontName) {
        attributes[NSFontAttributeName] = [NSFont fontWithName:fontName size:fontSize];
    }

    if (isBold) {
      NSFontManager *fontMan = [NSFontManager sharedFontManager];
      NSFont *font = defaultFont ?: [NSFont systemFontOfSize:[NSFont systemFontSize]];
      attributes[NSFontAttributeName] = [fontMan convertFont:font toHaveTrait:NSBoldFontMask];
    }
    
    return attributes;
}

- (NSDictionary *)defaultStyles
{
    return [self attributesForScope:@"default" defaultFont:nil];
}

@end
