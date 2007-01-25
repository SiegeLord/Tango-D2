module tango.net.pop3.Pop3;

private import tango.net.ftp.Telnet;
private import tango.net.pop3.Exception;
private import tango.text.convert.Integer;
debug ( Pop3Debug ) { private import tango.io.Stdout; }

// The sendData, sendLine, readData, readLine functions were all ripped from Telnet.d
// these have a good potentila for reuse, perhaps move them into their own class ? TextNetworkClient or something
// for now just inherits from Telnet

/// Response from POP3 server
struct POP3Response
{
    char [] resp;
    char [] [] lines;

}

class POP3Connection : Telnet
{



    void exception (char[] msg) // dont nessicarly agree with making this abstract in Telnet, what if there is more than one exception type ?
    {
	throw new POP3Exception(msg);

    }

    this(char[] hostname, char[] username, char[] password, int port = 110)
    {
	this.connect(hostname, username, password,port);
    }

    /// Connect to an POP3 server with a username and password.
    ///
    /// Params:
    ///    hostname =        the hostname or IP address to connect to
    ///    port =            the port number to connect to
    ///    username =        username to be sent
    ///    password =        password to be sent, if requested
    public void connect(char[] hostname, char[] username, char[] password, int port = 110)
	in
    {
	// We definitely need a hostname and port.
	assert (hostname.length > 0);
	assert (port > 0);
    }
    body
    {
	// Close any active connection.

	if (this.socket !is null)
	    this.close();
                

	// Connect to whichever FTP server responds first.
	this.findAvailableServer(hostname, port);

	this.socket.blocking = false;

	scope (failure)
	    {
		char [] msg = this.close();
		exception(msg);
	    }

	getShortResponse(); // get welcome response
	shortCmd("USER " ~ username); 
	shortCmd("PASS " ~ password );
	
	// we are logged in


    }


    /* Commands */

    /// Delete a message on the server
    POP3Response del(int messageNumber )
    {
	POP3Response r;
	r.resp = shortCmd("DELE " ~ Integer.toUtf8(messageNumber));
	return r;
    }

    /// Retrieves the message, remeber its 1 based !
    POP3Response retr(uint messageNumber) 
    {
	return pop3Cmd("RETR " ~ Integer.toUtf8(messageNumber));
    }
   

    /// Get a list of all messages on the server, or the size of a specific message
    POP3Response list(int messageNumber = -1)
    {
	POP3Response r;

	if (messageNumber == -1) 
	    {
		r = pop3Cmd("LIST");
	    }
	else r.resp = shortCmd("LIST " ~ Integer.toUtf8(messageNumber));

	return r;
    }
    /// Retrieves a Unique IDentifier Listing of a message or all, used for 'Save messages on server'
    POP3Response uidl(int messageNumber = -1)
    {
	POP3Response r;
	if (messageNumber == -1) 
	    {
		r = pop3Cmd("UIDL");
	    }
	else r.resp = shortCmd("UIDL " ~ Integer.toUtf8(messageNumber));

	return r;
    }


    /// Lists the header and numberOfLines of the body for a given messages.  Not all servers implement this
    POP3Response top(uint messageNumber, uint numberOfLines)
    {
	return pop3Cmd("TOP " ~ Integer.toUtf8(messageNumber) ~ " " ~ Integer.toUtf8(numberOfLines) ); // TODO
    }
  
  // Lists all messages on server and total size
    POP3Response stat(inout uint totalMessages, inout totalSize)
    {
      POP3Response r;
      r.resp = shortCmd("STAT");

    }


    /* ~ Commands */


    /// Close the connection to the server.
    char [] close()
    {
        assert (this.socket !is null);
	char[] resp;

        // Don't even try to close it if it's not open.
        if (this.socket !is null)
            {

		try
		    {
			resp = shortCmd("QUIT");
		    }
		catch (POP3Exception err)
		    {
			resp = err.msg;
		    }


                // Clear out everything.
                delete this.socket;
            }
	return resp;
    }

    /// Send command and get only one line from server
    char[] shortCmd(char[] cmd)
    {
	debug ( Pop3Debug ) { Stdout("[shortCmd] Command : " ~ cmd ) ().newline; }
	sendLine(cast(void[])cmd);
	return getShortResponse();
    }

    /// Send command and read several lines, until . appears alone on line
    POP3Response pop3Cmd(char[] cmd)
    {
	debug ( Pop3Debug ) { Stdout("[pop3Cmd] Command : " ~ cmd ) ().newline; }
	sendLine(cast(void[])cmd);
	return getLongResponse();
    }

    /// Read one line
    char[] getShortResponse()
    {
	char[] resp = readLine();
	debug ( Pop3Debug ) { Stdout("[getShortResponse] Response : " ~ resp ) ().newline; }
	if (resp.length < 1 || resp[0] != '+') exception(resp);
	return resp;
    }


    /// Read several lines
    POP3Response getLongResponse()
    {
	POP3Response resp;
			
	resp.resp = getShortResponse();

	char[] line = readLine();
			
	while (line != ".")
	    {
		debug ( Pop3Debug ) { Stdout("[getLongResponse] Line : " ~ line ) ().newline; }

		if (line.length >= 2 && line[0 .. 2] == "..")
		    line = line[1 .. $];
				
		resp.lines ~= line;
		line = readLine();
	    }
			
	return resp;
    }




}

debug (UnitTest )
{
unittest 
    {

    try 
	{
    
	    auto pop3 = new POP3Connection("mail.debug.com","debug","debug");

	    int count = pop3.list().lines.length;
	    Stdout("Message Count : " ~ toUtf8(count ) );
	    for ( int i = 0 ; i < count; i++ )
		{
		    Stdout.formatln("Message Number {0}: {1}",toUtf8(i),pop3.retr(i+1).resp)().newline;

      
		}
	    pop3.close();
	}
    catch ( POP3Exception e ) { Stdout("Exception Caught: ")(e.toUtf8)().newline; } 
    }
}
