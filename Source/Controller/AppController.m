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
#import "shared.h"

#import <time.h>

static AppController *_sharedController = nil;

@implementation AppController
+(AppController *) sharedController {
	extern AppController *_sharedController;
	return _sharedController;
}


////////////////////////////////////////////////////////////////////////////////
// INITIALIZE: we setup the default formatting preferences, just in case it is
//			   the first time
+ (void)initialize {

	//TODO: convert to disposable
	 DebugFormatter *defaultHelperFormatter = [[DebugFormatter alloc] init]; //+1
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:
		[defaultHelperFormatter getDefaultFormatting]
	];
		
	[defaultHelperFormatter release];										//1-1=0
	
} //initialize


- (id) init {
	if (self = [super init]) {
		_isStartingServer = NO;
				
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(serverClosed:)
													 name:@"NSTaskDidTerminateNotification"
												   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(appWillTerminate:)
													 name:@"NSApplicationWillTerminateNotification"
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
		formatter = [[DebugFormatter alloc] initWithUserDefaults:			//+1
			[NSUserDefaults standardUserDefaults]
					];
	}
	
	return self;
}

-(void) awakeFromNib {
	[oTraceField setString:@""];
}

-(IBAction) visitHomePage:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:XTRACE_HOME_PAGE]];
}

-(IBAction) startServer:(id)sender {
	//[[[oTraceField textStorage] mutableString] setString:@""];
	
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
	_activityTimer = [[NSTimer scheduledTimerWithTimeInterval:ACTIVITY_CHECK_INTERVAL //check every half a minute
													   target:self
													 selector:@selector(checkForRecentActivity:)
													 userInfo:nil
													  repeats:YES] retain];
	_lastMessageTime = time(NULL);
	
	//change the state of the button
	[sender setAction:@selector(stopServer:)];
	[sender setTitle:@"Stop Trace Server"];
}

-(IBAction) stopServer:(id)sender {
	[_activityTimer invalidate];
	[_activityTimer release];
	_activityTimer = nil;
	
	[_traceServer terminate];
	[_traceServer release];
	_traceServer = nil;
	
	[_currHandle release];
	
	//change the state and action of the button
	[sender setAction:@selector(startServer:)];
	[sender setTitle:@"Start Trace Server"];
}

-(IBAction) showLogWindow:(id)sender {
	[oLogWindow makeKeyAndOrderFront:self];
	[oLogWindow setAlphaValue:[oLogWindow altAlpha]];
}


-(IBAction) clearLog:(id)sender {
	[oTraceField setString:@""];
}


-(void) checkForRecentActivity:(NSTimer *)timer {
#if DEBUG >= 1
	NSLog(@"Checking for recent activity...");
#endif
	
	if(_fadeTimer == nil && [oLogWindow isVisible] && ![oLogWindow isKeyWindow] && time(NULL) - _lastMessageTime > MAX_LAST_MESSAGE_TIME) {
		_fadeTimer = [[NSTimer scheduledTimerWithTimeInterval:FADE_INTERVAL
													   target:self
													 selector:@selector(_fadeWindow:)
													 userInfo:nil
													  repeats:YES] retain];
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
		[oLogWindow orderOut:self];
    }
}

//-----------------------
//	Getter & Setter
//-----------------------
-(BOOL) isStartingServer {
	return _isStartingServer;
}

-(void) setIsStartingServer:(BOOL)b {
	_isStartingServer = b;
}

//-----------------------
//	Notification Methods
//-----------------------
-(void) serverData:(NSNotification *) note {
	NSData *serverData;
	if(![serverData = [[note userInfo] valueForKey:FILE_HANDLE_DATA_KEY] length]) return; //check to make sure we font have EOF
	
#if DEBUG >= 1
	NSLog(@"Got Data: %s", [serverData bytes]);
#endif
	
	NSString *dataString = [[NSString alloc] initWithBytes:[serverData bytes] 
											 length:[serverData length]
											encoding:NSASCIIStringEncoding
							];											//+1
							
	NSEnumerator *linesEnum = [[dataString componentsSeparatedByString:@"\n"] objectEnumerator]; //+0
	
	NSString *line;
	NSString *line2;
	
	while ((line = [linesEnum nextObject])) {
	
		if ([line length]!=0) {
			line2 = [line stringByAppendingString:@"\n"]; //slow atorelease loop, I know
			[[oTraceField textStorage] appendAttributedString:[formatter formatString:line2]];
		}
	
	} //while
	
	[dataString release];												//1-1=0
	
	_lastMessageTime = time(NULL);
	if(![oLogWindow isVisible]) {
		[self showLogWindow:nil];
	}
	
	//keep the scroller at the bottom
	[oTraceField scrollRangeToVisible:NSMakeRange([[oTraceField string] length], 0)];
	
	[_currHandle readInBackgroundAndNotify];
}

-(void) serverClosed:(NSNotification *) note {
#if DEBUG
	NSLog(@"Task closed %@", note);
#endif
}

-(void) appWillTerminate:(NSNotification *) note {
#if DEBUG
	NSLog(@"App will terminate");
#endif
	
	[_traceServer terminate]; //kill off the child process before we die
}
@end
