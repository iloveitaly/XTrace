/*
 Class: com.mab.util.debug

 Description:
 Debug without the Flash IDE.

 Usage:
 >import com.mab.util.debug;
 >debug.setColor(0x0000FF);
 >debug.trace("Hello World!");
 >debug.clear();

 Version:
 2.0

 Author:
 Michael Bianco, http://developer.mabwebdesign.com/
 
 Date:
 06/01/05
*/

package mab.util {
	import flash.net.XMLSocket;
	import Boolean;
	import flash.text.TextField;
	import flash.events.Event;
	import flash.display.*;
	
	public class debug {
	/*
	 Property: logField
	 Reference to the text field used for displaying trace()'s
	 
	 Property: count
	 How many trace() calls have been made, used for determining when to call clear()
	 
 	 Property: maxResults
	 The max amount of lines that will fit on the screen
	  
	 Variable: socket
	 If initSocket() was called, socket represents the XMLSocket connection to a 'trace server'
	 
	 Variable: connected
	 Bool representing if the socket is currently connected to a 'trace server'
	 
	 Variable: useMtascMethodTrace
	 Bool. If it is true the MTASC method trace string is prepended to str
	 
	 Variable: useMtascFileTrace
	 Bool. When true prepends MTASC's file data (file name and line #) to the trace str
	 
	 Variable: waitForSocketConnection
	 Bool. When true and you are trying to connect to a scoket
	 
	 Variable: disableTracing
	 Bool. When true the debug.trace() funtion will not trace any data
	*/
	static private var logField:TextField;
	static private var count:Number = 0;
	static private var maxResults:Number;
	static private var socket:XMLSocket;
	static private var msgStack:Array;
	
	static public var connected:Boolean = false;
	static public var waitForSocketConnection:Boolean = false;
	static public var disableTracing:Boolean = false;
		static public var rootElement:Object;
	
	/*
	 function: trace
	 Send output to the debug text field
	 
	 Parameters:
	 	str - a string to send to the debugger text field
	 */
		static public function send(str:*) : void {
		if(disableTracing) return;
		
		initDebugField();
		
		/*
		if(arguments.length > 1 && (useMtascMethodTrace || useMtascFileTrace)) {
			if(useMtascMethodTrace && useMtascFileTrace) {
				str = "["+arguments[3]+":"+arguments[2]+":"+arguments[1]+"]"+str;
			} else if(useMtascMethodTrace) {
				str = "["+arguments[1]+"]"+str;
			} else if(useMtascFileTrace) {
				str = "["+arguments[2]+":"+arguments[3]+"]"+str;
			}
		}
		*/
		
		str += "\n"; //add the newline to end of the str
		
		if(socket && connected) {//we have a socket server connection!
			socket.send(str);
			return;
		} else if(socket && waitForSocketConnection) {
			if(!msgStack) {
				msgStack = new Array();
			}
			
			msgStack.push(str);
			return; //make sure this message doesn't do anywhere but the msg stack
		}
		
		if(count >= maxResults) {
			debug.clear();
			count = 0;
		}
		
			logField.appendText(str);
		
		//count += str.toString().countOf("\n") + 1;
		count++; //comment the above line and uncomment this line if you dont want to have to use the string additions
	}
	
		public static function dumpObject(ob:Object) : void {
			var str:String = "{\n";
		
			for(var i:String in ob) {
			str += i+":"+ob[i]+"\n";
		}
		
		trace(str+="}");
	}
		
		static public function init(root:DisplayObjectContainer) : void {
			debug.rootElement = root;
		}
	
	/*
	 function: initDebugField
	 creates & inializes the debug text field 
	 */
	static public function initDebugField() : void {
		if(logField) return;
		
		logField = new TextField();
		logField.addEventListener(Event.ADDED_TO_STAGE, function(evn:Event) : void {
			evn.target.stage.setChildIndex(evn.target, 0);
			evn.target.width = evn.target.stage.stageWidth;
			evn.target.height = evn.target.stage.stageHeight;
		});
		
		rootElement.addChild(logField);
				
		//formatting
		/*
		var format = new TextFormat();
		format.size = 17;
		
		_root.createTextField("__traceTextField", 10000, 0, 0, Stage.width, Stage.height);
		txtRef = _root.__traceTextField;
		txtRef.setNewTextFormat(format);
		txtRef.selectable = false;
		maxResults = Math.floor(Stage.height/format.size);
		 */
	}
	
	/*
	 function: setColor
	 sets the color of the text in the debug field

	 Parameters:
	
	 	c - The color to set the textfield to
	*/
	static public function setColor(c:int) : void {
		debug.initDebugField();
		//var format = new TextFormat();
		//format.color = c;
		
		//apply the formatting
		//txtRef.setTextFormat(format);
		//txtRef.setNewTextFormat(format);
	}
	
		/*
		 function: clear
		 clears the text that is currently in the text field
		 */
		static public function clear() : void {
			logField.text = "";
		}
	
		/*
		 Function: initSocket
		 Initalizes a socket connection to send trace() input to.
		 If the connection succeeds all output is sent to the socket server instead of the textfield
		 
		 Parameters:
			h - String specifing a specific host to connect to. If this argument is not specified "localhost" is used
			p - Number specifing the port to connect to on the host. If this argument is not specified ----
		 
		 Returns:
		 Boolean;
		 Return value from XMLSocket.connect, if this function returns true it actually doesn't mean you've successfully connected with the server
		 */
		static public function initSocket(h:String = "127.0.0.1", p:int = 9994, wait:Boolean = true) : void {
			mab.util.debug.waitForSocketConnection = wait;
			
			socket = new XMLSocket();
			socket.addEventListener(Event.CONNECT, function(evn:Event) : void {
				if(evn.target.connected) {
					trace("Successfull connection to socket server!");
				} else {
					trace("Connection to server failed!");
					mab.util.debug.socket = null; //set the socket to null
				}
				
				mab.util.debug.connected = evn.target.connected;
				
				mab.util.debug._clearMsgStack(); //clear the message stack
			});
			
			socket.addEventListener(Event.CLOSE, function(evn:Event) : void {
				trace("Connection lost");
				mab.util.debug.connected = false;				
			});
			
			socket.connect(h, p);
		}
	
		/*
		 Function: _clearMsgStack
		 Clears the msgStack if there is one. This is called from the sockets onConnect event, and should not be called anywhere else.
		 */
		static public function _clearMsgStack() : void {
			if(socket && connected && waitForSocketConnection && msgStack) {//if we have a message stack and we have a successfull connection to the server
				while(msgStack.length) {
					socket.send(msgStack.shift());
				}
				
				msgStack = null;
			} else if(!socket && !connected && waitForSocketConnection && msgStack) {//if we have a message stack but no successful connection
				while(msgStack.length) {
					trace(msgStack.shift());
				}
				
				msgStack = null;
			}
		}
	}
}