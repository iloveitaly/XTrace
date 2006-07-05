//
//  DebugFormatter.m
//  XTrace
//
//  Created by Daniel Giribet on 4/26/06.
//  Copyright 2006 CALIDOS. All rights reserved.
//

#import "DebugFormatter.h"


@implementation DebugFormatter

////////////////////////////////////////////////////////////////////////////////
// INIT: basic initialization
-(id) init {
	if (self = [super init]) {
		defaultFont = [[NSFont userFontOfSize:11.0F] retain];		//+1
		defaultAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
			defaultFont, NSFontAttributeName,nil 
		] retain];															//+1
		
		attributeMapping = [[NSDictionary dictionaryWithObjectsAndKeys: 
				@"debug",@"[DEBUG] ",
				@"warn", @"[WARN] ",
				@"normal", @"[NORMAL] ",
				@"critical", @"[CRITICAL] ",nil
			] retain];														//+1
		
	}
	return self;
} //init


////////////////////////////////////////////////////////////////////////////////
// INIT WITH USER DEFAULTS
-(id)initWithUserDefaults: (NSUserDefaults *)defaults {
	if (self = [self init]) {
		[defaults retain];													//+1
		userDefaults = defaults;
	}
	return self;
} //initWithUserDefaults


////////////////////////////////////////////////////////////////////////////////
// GET DEFAULT FORMATTING: (should really implement this with a class method, it's
//							disposable instance after all)
-(NSDictionary *) getDefaultFormatting {
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[NSArchiver archivedDataWithRootObject:[NSColor grayColor] ],@"debugColor",
			@"NO",@"debugBoldEnabled",
			[NSArchiver archivedDataWithRootObject:[NSColor blueColor] ],@"warnColor",
			@"NO",@"warnBoldEnabled",
			[NSArchiver archivedDataWithRootObject:[NSColor blackColor] ],@"normalColor",
			@"NO",@"normalBoldEnabled",
			[NSArchiver archivedDataWithRootObject:[NSColor redColor] ],@"criticalColor",
			@"YES",@"criticalBoldEnabled",
			@"YES",@"removeDebugTextEnabled",
			nil];															 //0
} //getDefaultFormatting


////////////////////////////////////////////////////////////////////////////////
// FORMAT STRING
-(NSAttributedString *) formatString: (NSString *)string {

	// first of all, sanity checks
	if (string==nil || userDefaults==nil) return nil; //return error in this case
	
	//checkout if the string has any of the debug prefixes
	NSString *prefix;
	NSString *debugLevel;
	BOOL found = FALSE;
	NSEnumerator *prefixes = [attributeMapping keyEnumerator];			//0
	
	while ((prefix = [prefixes nextObject]) && !found) {
		found = [string hasPrefix:prefix]==YES;
		if (found)
			debugLevel = prefix;	//should be valid as it points to the key itself
	}
	if (!found) return [[[NSAttributedString alloc] initWithString:string attributes:defaultAttributes ]
						  autorelease];									//0
	
	//we obtain the debug string prefix to lookup in the defaults dict and build
	//the appropiate keys
	NSString *attribPrefix = [attributeMapping objectForKey:debugLevel];
	NSString *forecolorKey = [attribPrefix stringByAppendingString:@"Color"]; //0
	NSString *boldKey = [attribPrefix stringByAppendingString:@"BoldEnabled"]; //0
	
	//now we check if this debug prefix requires bold enabled and setup the font
	NSFont *usedFont = [defaultFont copy];								//+1
	if ([userDefaults boolForKey:boldKey])
			usedFont = [[NSFontManager sharedFontManager] convertFont:usedFont toHaveTrait:NSBoldFontMask];
	
	NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                        usedFont, 
						NSFontAttributeName,
                        [NSUnarchiver unarchiveObjectWithData:[userDefaults objectForKey:forecolorKey]],
						NSForegroundColorAttributeName, nil];			//+1
						
	//we have the attributes, let's format the string and so on, but before
	//we check if te user prefers the debug prefix to be removed
	NSString *usedString;
	if ([userDefaults boolForKey:@"removeDebugTextEnabled"])
		usedString = [string substringFromIndex:[debugLevel length]];	 //0
	else
		usedString = string;
	NSAttributedString *str = [[NSAttributedString alloc] initWithString:usedString
															  attributes:attributes ];
															  
	[usedFont release];													//-1
	[attributes release];												//-1
	
	return [str autorelease];
} //formatString


////////////////////////////////////////////////////////////////////////////////
// DEALLOC
-(void) dealloc {

	[super dealloc];
	[defaultFont release];												//-1
	[defaultAttributes release];										//-1
	[userDefaults release];												//-1
	[attributeMapping release];											//-1

}

@end
