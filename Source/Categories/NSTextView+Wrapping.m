//
//  NSTextView+Wrapping.m
//  XTrace
//
//  Created by Michael Bianco on 2/28/07.
//  Copyright 2007 Prosit Software. All rights reserved.
//

#import "NSTextView+Wrapping.h"

// references:
//	http://developer.apple.com/documentation/Cocoa/Conceptual/TextUILayer/Tasks/TextInScrollView.html#//apple_ref/doc/uid/20000938-164652-BCIDFBBH
//	http://www.cocoabuilder.com/archive/message/cocoa/2003/12/28/89458


@implementation NSTextView (Wrapping)
- (void) setWrapsText:(BOOL)wraps {
	if(wraps) {
		// implement later
	} else {
		NSSize bigSize = NSMakeSize(FLT_MAX, FLT_MAX);
		
		[[self enclosingScrollView] setHasHorizontalScroller:YES];
		[self setHorizontallyResizable:YES];
		[self setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
		
		[[self textContainer] setContainerSize:bigSize];
		[[self textContainer] setWidthTracksTextView:NO];
	}
}
@end
