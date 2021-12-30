//  Copyright (C) 2015-2019 Pierre-Olivier Latour <info@pol-online.net>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.

#if !__has_feature(objc_arc)
#error This file requires ARC
#endif

#import "GIPrivate.h"
#import "GIAppKit.h"

#define kTextLineHeightPadding 3
#define kTextLineDescentAdjustment 1

const char* GIDiffViewMissingNewlinePlaceholder = "🚫\n";

@interface GIDiffView ()

@property(nonatomic, assign) CGFloat lastFontSize;

@end

@implementation GIDiffView

- (void)updateMetricsFromCurrentFontSize {
  CGFloat newSize = GIFontSize();
// This comparison is safe because the values being compared are both read from user defaults with no additional floating point operations.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wfloat-equal"
  if (newSize == _lastFontSize) {
#pragma clang diagnostic pop
    return;
  }
  _lastFontSize = newSize;

  NSFont* font = [NSFont userFixedPitchFontOfSize:newSize];
  if (_textAttributes) CFRelease(_textAttributes);
  _textAttributes = CFBridgingRetain(@{(id)kCTFontAttributeName : font, (id)kCTForegroundColorFromContextAttributeName : (id)kCFBooleanTrue});
  
  if (_codeAttributes) CFRelease(_codeAttributes);
  _codeAttributes = CFBridgingRetain(@{(id)kCTFontAttributeName : font});

  CFAttributedStringRef addedString = CFAttributedStringCreate(kCFAllocatorDefault, CFSTR("+"), _textAttributes);
  if (_addedLine) CFRelease(_addedLine);
  _addedLine = CTLineCreateWithAttributedString(addedString);
  CFRelease(addedString);

  CFAttributedStringRef deletedString = CFAttributedStringCreate(kCFAllocatorDefault, CFSTR("-"), _textAttributes);
  if (_deletedLine) CFRelease(_deletedLine);
  _deletedLine = CTLineCreateWithAttributedString(deletedString);
  CFRelease(deletedString);

  CGFloat ascent;
  CGFloat descent;
  CGFloat leading;
  CTLineGetTypographicBounds(_addedLine, &ascent, &descent, &leading);
  _lineHeight = ceilf(ascent + descent + leading) + kTextLineHeightPadding;
  _lineDescent = ceilf(descent) + kTextLineDescentAdjustment;

  [self setNeedsDisplay:YES];
}

// WARNING: This is called *several* times when the default has been changed
- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
  if (context == (__bridge void*)[GIDiffView class]) {
    if ([keyPath isEqualToString:GIUserDefaultKey_FontSize]) {
      [self updateMetricsFromCurrentFontSize];
    } else {
      XLOG_UNREACHABLE();
    }
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

- (void)_windowKeyDidChange:(NSNotification*)notification {
  if ([self hasSelection]) {
    [self setNeedsDisplay:YES];  // TODO: Only redraw what's needed
  }
}

- (void)viewDidMoveToWindow {
  [super viewDidMoveToWindow];

  if (self.window) {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_windowKeyDidChange:) name:NSWindowDidBecomeKeyNotification object:self.window];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_windowKeyDidChange:) name:NSWindowDidResignKeyNotification object:self.window];
  } else {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignKeyNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeKeyNotification object:nil];
  }
}

- (void)didFinishInitializing {
  _backgroundColor = NSColor.textBackgroundColor;
  [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:GIUserDefaultKey_FontSize options:NSKeyValueObservingOptionInitial context:(__bridge void*)[GIDiffView class]];
}

- (instancetype)initWithFrame:(NSRect)frameRect {
  if ((self = [super initWithFrame:frameRect])) {
    [self didFinishInitializing];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder*)coder {
  if ((self = [super initWithCoder:coder])) {
    [self didFinishInitializing];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignKeyNotification object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeKeyNotification object:nil];

  [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:GIUserDefaultKey_FontSize context:(__bridge void*)[GIDiffView class]];

  if (_textAttributes) CFRelease(_textAttributes);
  if (_codeAttributes) CFRelease(_codeAttributes);
  if (_addedLine) CFRelease(_addedLine);
  if (_deletedLine) CFRelease(_deletedLine);
}

- (BOOL)isOpaque {
  return YES;
}

- (BOOL)isEmpty {
  [self doesNotRecognizeSelector:_cmd];
  return NO;
}

- (void)didUpdatePatch {
  [self clearSelection];
}

- (void)setPatch:(GCDiffPatch*)patch {
  if (patch != _patch) {
    _patch = patch;
    [self didUpdatePatch];

    [self setNeedsDisplay:YES];
  }
}

- (CGFloat)updateLayoutForWidth:(CGFloat)width {
  [self doesNotRecognizeSelector:_cmd];
  return 0.0;
}

- (void)drawRect:(NSRect)dirtyRect {
  [self doesNotRecognizeSelector:_cmd];
}

- (BOOL)hasSelection {
  [self doesNotRecognizeSelector:_cmd];
  return NO;
}

- (BOOL)hasSelectedText {
  [self doesNotRecognizeSelector:_cmd];
  return NO;
}

- (BOOL)hasSelectedLines {
  [self doesNotRecognizeSelector:_cmd];
  return NO;
}

- (void)clearSelection {
  [self doesNotRecognizeSelector:_cmd];
}

- (void)getSelectedText:(NSString**)text oldLines:(NSIndexSet**)oldLines newLines:(NSIndexSet**)newLines {
  [self doesNotRecognizeSelector:_cmd];
}

- (BOOL)acceptsFirstResponder {
  return YES;
}

- (BOOL)becomeFirstResponder {
  if (self.hasSelection) {
    [self setNeedsDisplay:YES];
  }
  return YES;
}

- (BOOL)resignFirstResponder {
  if (self.hasSelection) {
    [self setNeedsDisplay:YES];
  }
  return YES;
}

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item {
  if (item.action == @selector(copy:)) {
    return [self hasSelection];
  }

  return NO;
}

- (void)copy:(id)sender {
  [[NSPasteboard generalPasteboard] declareTypes:@[ NSPasteboardTypeString ] owner:nil];
  NSString* text;
  [self getSelectedText:&text oldLines:NULL newLines:NULL];
  [[NSPasteboard generalPasteboard] setString:text forType:NSPasteboardTypeString];
}

@end
