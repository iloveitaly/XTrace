/*
 Class: XTraceTest
 
 Description:
 An example of how to use XTrace
 
 Usage:
 Compile with MTASC using the following command:
 |mtasc -main -trace com.mab.util.debug.trace -header 200:300:30 XTraceTest.as -swf XTraceTest.swf
 
 Version:
 1.0
 
 Author:
 Michael Bianco
 */

import com.mab.util.debug;

class XTraceTest {	
	static function main() {
		debug.waitForSocketConnection = true;
		debug.initSocket("127.0.0.1");
		
		debug.trace("Yo, whaz up?");
		debug.trace("This is a really really really really really really really really really really really long string");
		debug.trace("[DEBUG] This is a debug string");
		debug.trace("[WARN] This is a warning");
		debug.trace("[NORMAL] This is a normal formatter string");
		debug.trace("[CRITICAL] This is a critical warning");
		
		for(var a = 0; a < 10; a++) {//say hi 10 times
			debug.trace("Hi server! " + a);
		}
		
		var testOb = {question:"Are you cool?", response:"Of course!"};
		debug.dumpObject(testOb);
	}
}