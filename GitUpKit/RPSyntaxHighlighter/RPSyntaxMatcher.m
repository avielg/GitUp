//
//  RPSyntaxMatcher.m
//  RPSyntaxHighlighter
//
//  Created by Rhys Powell on 19/01/13.
//  Copyright (c) 2013 Rhys Powell. All rights reserved.
//

#import <AppKit/AppKit.h>

#import "RPSyntaxMatcher.h"
#import "RPScopedMatch.h"

@implementation RPSyntaxMatcher

+ (NSArray<RPSyntaxMatcher *> *)matchersWithFile:(NSString *)filename
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *jsonPath = [bundle pathForResource:filename ofType:@"json"];
    NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
    
    NSError *error = nil;
    id matcherArray = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    if (error) {
        NSLog(@"[RPSyntaxHighlighter] Error loading matcher JSON: %@", error.localizedDescription);
        NSAssert(false, @"BAD");
    }
    
    NSMutableArray *matchers = [[NSMutableArray alloc] init];
    for (NSDictionary *matcherDict in (NSArray *)matcherArray) {
        RPSyntaxMatcher *matcher = [[RPSyntaxMatcher alloc] init];
        NSString *pattern = matcherDict[@"pattern"];
      
        NSData *encodedString = [pattern dataUsingEncoding:NSUTF8StringEncoding];
        NSAttributedString *htmlString =
          [[NSAttributedString alloc]
            initWithData:encodedString
            options: @{
              NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
              NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)
            }
            documentAttributes:nil
            error:nil];
        pattern = [htmlString string];
      
        matcher.pattern = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
        matcher.scopes = matcherDict[@"scopes"];
        [matchers addObject:matcher];
    }
    
    return matchers;
}

- (NSSet *)matchesInString:(NSString *)string
{
    NSMutableSet *matches = [[NSMutableSet alloc] init];
    
    [self.pattern enumerateMatchesInString:string options:0 range:NSMakeRange(0, [string length]) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        RPScopedMatch *match = [[RPScopedMatch alloc] init];
        match.scopes = self.scopes;
        match.range = [result range];
        [matches addObject:match];
    }];
    
    return [NSSet setWithSet:matches];
}

@end
