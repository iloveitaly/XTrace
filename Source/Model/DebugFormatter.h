//
//  DebugFormatter.h
//  XTrace
//
//  Created by Daniel Giribet on 4/26/06.
//  Copyright 2006 CALIDOS. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DebugFormatter : NSObject {
	
	NSFont			*defaultFont;
	NSUserDefaults	*userDefaults;		//user preferences used to do the formattings
	NSDictionary	*defaultAttributes;	//default text attributes
	NSDictionary	*attributeMapping;	//input string prefix to defaults prefix mapping
}

-(id)initWithUserDefaults: (NSUserDefaults *)defaults;

-(NSDictionary *) getDefaultFormatting;

-(NSAttributedString *) formatString: (NSString *)string;

@end
