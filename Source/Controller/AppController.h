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

#import <Cocoa/Cocoa.h>
#import <time.h>

#import "TraceWindow.h"
#import "DebugFormatter.h"

#define XTRACE_HOME_PAGE @"http://developer.mabwebdesign.com/xtrace.html"
#define FILE_HANDLE_DATA_KEY @"NSFileHandleNotificationDataItem"
#define DEBUG 0

//auto window fade constants
#define ACTIVITY_CHECK_INTERVAL 5.0 /* 5 seconds */
#define MAX_LAST_MESSAGE_TIME 30.0 /* 30 seconds */
#define FADE_INTERVAL 0.03
#define FADE_INCR 0.02

@interface AppController : NSObject {
	IBOutlet NSTextView *oTraceField;
	IBOutlet TraceWindow *oLogWindow;
	
	NSTask *_traceServer;
	NSFileHandle *_currHandle;
	BOOL _isStartingServer;
	
	//text formatting model class
	DebugFormatter *formatter;
	
	//auto window fade stuff
	NSTimer *_activityTimer, *_fadeTimer;
	time_t _lastMessageTime;
	BOOL autoHideActive;
}

+(AppController *) sharedController;

-(IBAction) visitHomePage:(id)sender;
-(IBAction) startServer:(id)sender;
-(IBAction) stopServer:(id)sender;
-(IBAction) clearLog:(id)sender;
-(IBAction) showLogWindow:(id)sender;
-(IBAction) toggleAutoHide:(id)sender;

-(void) checkForRecentActivity:(NSTimer *)timer;
-(void) _fadeWindow:(NSTimer *)theTimer;
-(void) createActivityTimer;
-(void) releaseActivityTimer;

//-----------------------
//	Getter & Setter
//-----------------------
-(BOOL) isStartingServer;
-(void) setIsStartingServer:(BOOL)b;

//-----------------------
//	Notification Methods
//-----------------------
-(void) serverData:(NSNotification *) note;
-(void) serverClosed:(NSNotification *) note;
-(void) appWillTerminate:(NSNotification *) note;
@end
