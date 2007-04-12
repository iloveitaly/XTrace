/*
 Copyright (c) 2006 Michael Bianco
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), 
 to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
 and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
 INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, 
 DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, 
 ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import java.net.*;
import java.io.*;

public class serverStart {
	public static int port = 9994; //port to listen on
	public static PrintWriter traceLog = null;
	
	public static void main(String[] args) {
		try {
			if(args.length >= 1) {//if we have a log file path
				String filePath = args[0];
				File logFile = new File(filePath);
				if(!logFile.exists()) {
					if(!logFile.createNewFile()) {
						System.err.println("Error creating log file at path: "+filePath);
					} else {
						System.out.println("Log file created at path: "+filePath);
						traceLog = new PrintWriter(new FileWriter(logFile));
					}
				} else {
					System.out.println("Using log file at path: "+filePath);
					traceLog = new PrintWriter(new FileWriter(logFile));
				}
			}
			
			//printAvailIp();
			
			System.out.println("Server Starting...");
			
			ServerSocket servSock = new ServerSocket(port, 20);
			
			System.out.println("Server listening on host: " + servSock.getInetAddress().getHostName());
			System.out.println("----------------------------------------------------------");
			
			while(true) {
				//accept new connections and start a new thread for each connection that is recieved
				new serverConnection(servSock.accept()).start();
				trace("Connection Aquired");
			}
		}
		
		catch (Exception a) {
			System.err.println(a);
		}
	}
	
	public static void trace(String str) {
		System.err.println(str);
		
		if(traceLog != null) {
			traceLog.println(str);
		}
	}
	
	private static void printAvailIp() {//debug function to trace all availible local ip addresses
		try {
			InetAddress[] ips = InetAddress.getAllByName(InetAddress.getLocalHost().getHostName());
			for(int a = 0; a < ips.length; a++) {
				System.out.println(ips[a]);
			}
		}
		
		catch (Exception a) {
			System.err.println(a);
		}
	}	
}
