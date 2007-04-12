/*
 Application: XTrace
 Copyright (C) 2005 Michael Bianco <software@mabwebdesign.com>
 
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import "AppController.h"
#import "NSTextView+Wrapping.h"
#import "shared.h"

#define FADE_TIMER [[NSTimer scheduledTimerWithTimeInterval:FADE_INTERVAL \
													 target:self \
												   selector:@selector(_fadeWindow:) \
												   userInfo:nil \
													repeats:YES] retain];

#import <time.h>

static AppController *_sharedController = nil;

@implementation AppController
+(AppController *) sharedController {
	extern AppController *_sharedController;
	return _sharedController;
}

+ (void)initialize {
	//TODO: convert to disposable
	DebugFormatter *defaultHelperFormatter = [[DebugFormatter alloc] init];
	NSDictionary *defaults = [[defaultHelperFormatter getDefaultFormatting] mutableCopy];
	
	[defaults setValue:[NSNumber numberWithBool:YES] forKey:XASH_NOWRAP];
	[defaults setValue:[NSNumber numberWithBool:YES] forKey:XASH_AUTO_CLOSE];
	[defaults setValue:[NSNumber numberWithBool:NO] forKey:XASH_QUIET];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
		
	[defaultHelperFormatter release];
	
}


- (id) init {
	if (self = [super init]) {				
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(serverClosed:)
													 name:@"NSTaskDidTerminateNotification"
												   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(appWillTerminate:)
													 name:@"NSApplicationWillTerminateNotification"
												   object:NSApp];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(applicationDidFinishLaunching:)
													 name:NSApplicationDidFinishLaunchingNotification
												   object:NSApp];
		
		//register to get data from the child process
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(serverData:)
													 name:@"NSFileHandleReadCompletionNotification"
												   object:nil];
		
		
		//set the shared controller
		extern AppController *_sharedController;
		_sharedController = self;
		
		//either app defaults or user set, we create the formatter object
		formatter = [[DebugFormatter alloc] initWithUserDefaults:[NSUserDefaults standardUserDefaults]];
	}
	
	autoHideActive = YES;
	
	return self;
}

-(void) awakeFromNib {	
	//make the shell script editor fixed at monaco pt 10 font
	NSMutableDictionary *editorAttributes = [NSMutableDictionary dictionary];
	NSFont *codeFont = [NSFont userFixedPitchFontOfSize:10];
	[editorAttributes setObject:codeFont forKey:NSFontAttributeName];
	[oTraceField setFont:codeFont];
	[oTraceField setTypingAttributes:editorAttributes];
	
	if(PREF_KEY_BOOL(XASH_NOWRAP))
		[oTraceField setWrapsText:NO];
}

- (void) applicationDidFinishLaunching:(NSNotification * )note {
	[self startServer:self];
}

-(IBAction) visitHomePage:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:XTRACE_HOME_PAGE]];
}

-(IBAction) startServer:(id)sender {	
	NSString *serverPath = [[NSBundle mainBundle] pathForResource:@"TraceServer" ofType:@"jar"];
	
	NSPipe *outPipe = [NSPipe pipe];
	_traceServer = [NSTask new];
	[_traceServer setLaunchPath:@"/usr/bin/java"];
	[_traceServer setStandardOutput:outPipe];
	[_traceServer setStandardError:outPipe];
	[_traceServer setArguments:[NSArray arrayWithObjects:@"-jar", serverPath, nil]];
	[_traceServer launch];
	
	_currHandle = [[outPipe fileHandleForReading] retain];
	
	[_currHandle readInBackgroundAndNotify];
	
	//create the activity timer
	[self createActivityTimer];
	
	_lastMessageTime = time(NULL);
}

-(IBAction) stopServer:(id)sender {
	[self releaseActivityTimer];
	
	[_traceServer terminate];
	[_traceServer release];
	_traceServer = nil;
	
	[_currHandle release];
}

-(IBAction) showLogWindow:(id)sender {
	[oLogWindow orderFront:self];
	[oLogWindow setAlphaValue:[oLogWindow altAlpha]];
	[self createActivityTimer];
}


-(IBAction) clearLog:(id)sender {
	[oTraceField setString:@""];
}

-(IBAction) toggleAutoHide:(id)sender {
	if([sender state] == NSOnState) {
		autoHideActive = YES;
		[self createActivityTimer];
		
	} else {
		autoHideActive = NO;
		[self releaseActivityTimer];
	}
	
}

-(void) checkForRecentActivity:(NSTimer *)timer {
#if DEBUG >= 1
	NSLog(@"Checking for recent activity...");
#endif

	if(_fadeTimer == nil && [oLogWindow isVisible] && ![oLogWindow isKeyWindow] && time(NULL) - _lastMessageTime > MAX_LAST_MESSAGE_TIME) {
		_fadeTimer = FADE_TIMER;
	}
}

-(void) _fadeWindow:(NSTimer *)theTimer {	
    if ([oLogWindow alphaValue] > FADE_INCR) {
        // If oLogWindow is still partially opaque, reduce its opacity.
        [oLogWindow setAlphaValue:[oLogWindow alphaValue] - FADE_INCR];
    } else {
        // Otherwise, if oLogWindow is completely transparent, destroy the timer and close the oLogWindow.
        [_fadeTimer invalidate];
        [_fadeTimer release];
        _fadeTimer = nil;
        
		//close the window. If you reset alpha weird stuff happens
		[self releaseActivityTimer];
		[oLogWindow orderOut:self];
    }
}

//-----------------------
//  Activity Timer Methods
//-----------------------
-(void) createActivityTimer {
	if(autoHideActive) {
		_activityTimer = [[NSTimer scheduledTimerWithTimeInterval:ACTIVITY_CHECK_INTERVAL //check every half a minute
														   target:self
														 selector:@selector(checkForRecentActivity:)
														 userInfo:nil
														  repeats:YES] retain];
	}
}

-(void) releaseActivityTimer {	
	[_activityTimer invalidate];
	[_activityTimer release];
	_activityTimer = nil;
}

//-----------------------
//	Notification Methods
//-----------------------
-(void) serverData:(NSNotification *) note {
	NSData *serverData = [[note userInfo] valueForKey:FILE_HANDLE_DATA_KEY];
	BOOL dontOutput = NO;
	
	//check to make sure we dont have EOF
	if(![serverData length])
		return; 
	
	//NSLog(@"Got Data: %s", [serverData bytes]);
	
	NSString *dataString = [[NSString alloc] initWithBytes:[serverData bytes] 
											 length:[serverData length]
											encoding:NSASCIIStringEncoding];
	
	if([dataString length] == 1) {
		// Flash returns a LF (hex 0xA) when the connection is closed...
		if([dataString characterAtIndex:0] == 0xA) {
			// dont write this string into the window... it will cause it to popup again
			dontOutput = YES;
		} else {
			NSLog(@"Seemingly empty string? Length 1, hex: 0x%c",[dataString characterAtIndex:0]);
		}
	}
	
	// if we are recieving a notification of a closed connection, close the window
	if([dataString isEqualToString:@"Connection Closed"] && PREF_KEY_BOOL(XASH_AUTO_CLOSE)) {
		[oLogWindow performClose:self];
		
		if(PREF_KEY_BOOL(XASH_QUIET))
			dontOutput = YES;
	} else if(([dataString isEqualToString:@"Connection Closed"] || [dataString isEqualToString:@"Connection Aquired"]) && PREF_KEY_BOOL(XASH_QUIET)) {
		dontOutput = YES;
	} else if(![oLogWindow isVisible] && !dontOutput) {
		[self showLogWindow:nil];
	}
	
	// debug formatting
	if(!dontOutput) {
		NSEnumerator *linesEnum = [[dataString componentsSeparatedByString:@"\n"] objectEnumerator];
		
		NSString *line;
		NSString *line2;
		
		while ((line = [linesEnum nextObject])) {
			if ([line length] != 0) {
				line2 = [line stringByAppendingString:@"\n"];
				[[oTraceField textStorage] appendAttributedString:[formatter formatString:line2]];
			}
		}

		// log the message time for auto-fade functionality
		_lastMessageTime = time(NULL);
		
		// keep the scroller at the bottom
		[oTraceField scrollRangeToVisible:NSMakeRange([[oTraceField string] length], 0)];
	}
	
	[dataString release];
	
	// read the next trace output
	[_currHandle readInBackgroundAndNotify];
}

- (void) serverClosed:(NSNotification *) note {
#if DEBUG
	NSLog(@"Task closed %@", note);
#endif
}

- (void) appWillTerminate:(NSNotification *) note {
#if DEBUG
	NSLog(@"App will terminate");
#endif
	
	[_traceServer terminate]; //kill off the child process before we die
}
@end
