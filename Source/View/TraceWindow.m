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

#import "TraceWindow.h"

@implementation TraceWindow
- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)styleMask backing:(NSBackingStoreType)backingType defer:(BOOL)flag {
	if(self = [super initWithContentRect:contentRect styleMask:styleMask backing:backingType defer:flag]) {
		[self setLevel:NSStatusWindowLevel];
		[self setExcludedFromWindowsMenu:YES];
		_altAlpha = 1.0;
	}
	
	return self;
}

-(void) awakeFromNib {		
	[self setHidesOnDeactivate:NO];
}

-(float) altAlpha {
	return _altAlpha;
}

-(void) setAltAlpha:(float)f {
	_altAlpha = f;
	[self setAlphaValue: _altAlpha];
}
@end
