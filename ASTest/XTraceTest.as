/*
 Class: XTraceTest
 
 Description:
 An example of how to use 
 
 Usage:
 Compile with MTASC using the following command:
 |mtasc -main -header 200:300:30 XTraceTest.as -swf testtrace.swf
 
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
		
		for(var a = 0; a < 10; a++) {//say hi 10 times
			debug.trace("Hi server! "+a);
		}
	}
}