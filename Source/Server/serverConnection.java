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

import java.io.*;
import java.net.*;

public class serverConnection extends Thread {
	private Socket connection;
	private BufferedReader in;
	private PrintWriter out;
	
	public serverConnection(Socket s) {
		super("serverConnection");
		
		try {
			connection = s;
			connection.setTcpNoDelay(true);
			
			in = new BufferedReader(new InputStreamReader(connection.getInputStream()));
			out = new PrintWriter(connection.getOutputStream());
		}
		
		catch (Exception a) {
			System.out.println(a);
		}
	}
	
	public void run() {
		try {
			String traceInput;
			int lastChar = '\0';
			
			while((traceInput = in.readLine()) != null) {//read all input until we get null, which means the connection closed
				if(lastChar != '\0') {
					traceInput = String.valueOf((char)lastChar)+traceInput;
				}
				
				serverStart.trace(traceInput);
				lastChar = in.read(); //skip the null (0) byte
			}
			
			//no more input, close all connections
			in.close();
			out.close();
			connection.close();
			
			serverStart.trace("Connection Closed");
		}
		
		catch (Exception a) {
			System.out.println(a);
		}
	}
}
