//
//  RPSyntaxHighlighter.m
//  RPSyntaxHighlighter
//
//  Created by Rhys Powell on 19/01/13.
//  Copyright (c) 2013 Rhys Powell. All rights reserved.
//

#import <AppKit/AppKit.h>

#import "RPSyntaxHighlighter.h"
#import "RPSyntaxMatcher.h"
#import "RPSyntaxTheme.h"
#import "RPScopedMatch.h"

@implementation RPSyntaxHighlighter

@synthesize scopedMatches = _scopedMatches;
@synthesize defaultAttributes = _defaultAttributes;

+ (NSAttributedString *)highlightCode:(NSString *)code
                         withExtension:(NSString *)extension
{
  return [self highlightCode:code withExtension:extension defaultAttributes:nil];
}

+ (NSAttributedString *)highlightCode:(NSString *)code
                        withExtension:(NSString *)extension
                    defaultAttributes:(NSDictionary *)defaultAttributes
{
  return [self highlightCode:code
                withLanguage:[self languageForExtension:extension]
           defaultAttributes:defaultAttributes];
}

+ (NSAttributedString *)highlightCode:(NSString *)code
                         withLanguage:(NSString *)language
                    defaultAttributes:(NSDictionary *)defaultAttributes
{
    RPSyntaxHighlighter *highlighter = [[RPSyntaxHighlighter alloc] init];
    
    highlighter.code = code;
    
    NSMutableString *name = [@"tomorrow" mutableCopy];
    if (@available(macOS 11.0, *)) {
        if ([[NSAppearance currentDrawingAppearance] name] == NSAppearanceNameDarkAqua) {
            [name appendString:@"-dark"];
        }
    }
    highlighter.theme = [[RPSyntaxTheme alloc] initWithContentsOfFile:name];
    highlighter.defaultAttributes = defaultAttributes;
    highlighter.language = language;
  
    return highlighter.highlightedCode;
}

+ (NSString *)languageForExtension:(NSString *)nsExtension
{
  const char *extension = [nsExtension cStringUsingEncoding:NSUTF8StringEncoding];
  return
  !strcmp(extension, "swift") ? @"swift"
  : (!strcmp(extension, "m") | !strcmp(extension, "mm") | !strcmp(extension, "h")) ? @"objectivec"
  : @"generic";
}

- (NSArray *)matchers
{
    if (_matchers) {
        return _matchers;
    }
  
    NSString *language = self.language ?: @"generic";
    _matchers = [RPSyntaxMatcher matchersWithFile:language];

    return _matchers;
}

- (NSArray *)scopedMatches
{
    if (_scopedMatches) {
        return _scopedMatches;
    }
    
    NSMutableArray *matches = [[NSMutableArray alloc] init];
    
    [self.matchers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        RPSyntaxMatcher *matcher = (RPSyntaxMatcher *)obj;
        [[matcher matchesInString:self.code] enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            RPScopedMatch *match = obj;
            __block BOOL shouldAdd = YES;
            
            [matches enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                if ([match overlapsMatch:obj] || [match containedByMatch:obj]) {
                    shouldAdd = NO;
                }
            }];
            
            if (shouldAdd) {
                [matches addObject:obj];
            }
        }];
    }];
    
    _scopedMatches = [NSArray arrayWithArray:matches];
    
    return _scopedMatches;
}

- (NSAttributedString *)highlightedCode
{
    NSMutableAttributedString *highligtedCode = [[NSMutableAttributedString alloc] initWithString:self.code attributes:[self.theme defaultStyles]];

    NSDictionary *attributesCopy = [self.defaultAttributes copy];
    if (attributesCopy) {
        NSRange range = (NSRange){0, [self.code length]};
        [highligtedCode addAttributes:self.defaultAttributes range:range];
    }

    NSFont *defaultFont = self.defaultAttributes[NSFontAttributeName];

    [self.scopedMatches enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        RPScopedMatch *match = obj;
        [match.scopes enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
          
            NSUInteger lineStart;
            NSUInteger lineEnd;
            [self.code getLineStart:&lineStart end:&lineEnd contentsEnd:NULL forRange:match.range];
            NSRange lineRange = NSMakeRange(lineStart, lineEnd - lineStart);
            NSString *line = [self.code substringWithRange:lineRange];
            line = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if ([line hasPrefix:@"@@"] && [line hasSuffix:@"@@"]) {
              [highligtedCode addAttribute:(NSString *)kCTForegroundColorFromContextAttributeName value:@YES range:lineRange];
            } else {
              NSDictionary *textAttributes = [self.theme attributesForScope:obj defaultFont:defaultFont];
              [highligtedCode addAttributes:textAttributes range:match.range];
            }
        }];
    }];
    
    return highligtedCode;
}

@end
