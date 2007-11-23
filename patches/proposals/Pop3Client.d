module tango.net.pop3.Pop3Client;

private import tango.net.ftp.Telnet;
private import tango.net.pop3.Exception;
private import tango.text.convert.Integer;
private import tango.text.Util;
private import tango.io.Stdout; 
debug ( Pop3Debug ) { private import tango.io.Stdout; }

/**
Example:

{
POP3Connection pop3 = new POP3Connection("mail.server.com","username","password");

int messageCount = pop3.messageCount();
int totalMessageSize = pop3.totalSize(); // size of all messages
int messageSize = pop3.size(1); // size of individual message

POP3Response resp  = pop3.retrieve(1); // get a message

char [] [] to = extractField("To:",resp ); // get all To fields
char [] [] from = extractField("From:",resp ); // all From fields
char [] [] subject = extractField("Subject:",resp ); // all Subject fields

char [] messageBody = extractBody(resp);

pop3.remove(1); // remove message

foreach ( POP3Response message; pop3 )
{

  char [] [] to = extractField("To:",message );

}

foreach_reverse ( POP3Response message; pop3 )
{

  char [] [] to = extractField("To:",message );

}

*/





/*
This pop3 client supports all standard pop3 commands, with method names matching the pop3 commands.
It also has common methods and aliases for easy manipulation.

The POP3Response structure represents the response from the pop3 server, with single line responses in the 'resp' field ,
and multiline responses in the 'lines' field.

The common name functions should be enough for most usage:

retrieve
remove
size
totalSize
messageCount

*/



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
	scope (failure)
	    {
		char [] msg = this.close();
		exception(msg);
	    }

	// Close any active connection.

	if (this.socket !is null)
	    this.close();
                

	// Connect to whichever pop3 server responds first.
	this.findAvailableServer(hostname, port);

	this.socket.blocking = false;


	getShortResponse(); // get welcome response
	shortCmd("USER " ~ username); 
	shortCmd("PASS " ~ password );
	
	// we are logged in


    }

  /* Aliases */
  alias dele remove; /// remove a message
  alias retr retrieve; /// retrieve a message
  alias rset reset;  /// reset all messages marked for deleton

  /// size of particular message
  int messageSize( int messageNumber )
  {
    POP3Response resp = list(messageNumber );
    int spacePos = locatePrior(resp.resp,' '); // locate the last space
    char [] size = resp.resp[spacePos+1 .. $]; // extract the size

    return atoi(size);
  }

  /// total message count
  int messageCount()
  {

    uint count, dummy;
    POP3Response resp = stat(count,dummy  );

    return count;

  }

  /// size of all messages on server
  uint totalSize ( )
  {
    uint dummy, size;
    POP3Response resp = stat(dummy,size );

    return size;

  }



    /* Commands */

    /// Delete a message on the server
    POP3Response dele(int messageNumber )
    {
	POP3Response r;
	r.resp = shortCmd("DELE " ~ Integer.toString(messageNumber));
	return r;
    }

    /// Retrieves the message, remeber its 1 based !
    POP3Response retr(uint messageNumber) 
    {
	return pop3Cmd("RETR " ~ Integer.toString(messageNumber));
    }
   

    /// Get a list of all messages on the server, or the size of a specific message
    POP3Response list(int messageNumber = -1)
    {
	POP3Response r;

	if (messageNumber == -1) 
	    {
		r = pop3Cmd("LIST");
	    }
	else r.resp = shortCmd("LIST " ~ Integer.toString(messageNumber));

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
	else r.resp = shortCmd("UIDL " ~ Integer.toString(messageNumber));

	return r;
    }


    /// Lists the header and numberOfLines of the body for a given messages.  Not all servers implement this
    POP3Response top(uint messageNumber, uint numberOfLines)
    {
	return pop3Cmd("TOP " ~ Integer.toString(messageNumber) ~ " " ~ Integer.toString(numberOfLines) ); // TODO
    }
  
  /// Lists all messages on server and total size
    POP3Response stat(inout uint totalMessages, inout uint totalSize)
    {
      POP3Response r;
      r.resp = shortCmd("STAT");
      char [] [] totalAndSize = split(r.resp," " );

      assert(totalAndSize.length == 3 );

      totalMessages = Integer.parse(totalAndSize[1] );
      totalSize = Integer.parse(totalAndSize[2] );
      
      return r;
    }

  /// Unmark all messages for deletion 
  POP3Response rset()
    {
      POP3Response r;
      r.resp = shortCmd("RSET");
      return r;

    }


  /// NOOP for keepalive
  POP3Response noop()
    {
      POP3Response r;
      r.resp = shortCmd("NOOP");
      return r;

    }

  /// Make it foreachable
  int opApply( int delegate (inout POP3Response resp ) dg )
  {
    int result;
      int count = list().lines.length;
      for ( int i = 1; i <= count; i++ )
	{

	  result = dg(retr(i) );
	  if ( result ) break;

	}
      
      return result;


  }

  /// Make it foreachable_reverse
  int opApplyReverse( int delegate (inout POP3Response resp ) dg )
  {
    int result;
      int count = list().lines.length;
      for ( int i = count; i >0; i-- )
	{

	  result = dg(retr(i) );
	  if ( result ) break;

	}
      
      return result;


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
	    Stdout("Message Count : " ~ toString(count ) );
	    for ( int i = 0 ; i < count; i++ )
		{
		  POP3Response resp = pop3.retr(i+1);
		  
		  char [] to = extractField("To:",resp );
		  char [] subject = extractField("Subject:",resp );
		  char [] from = extractField("From:",resp );
		  char [] returnPath = extractField("Return-Path:",resp );
		  char [] msg = extractBody(resp);

		  Stdout.formatln("To: {0}\nFrom:{1}\nSubject: {2}\nReturnPath: {3}\n[{4}]",to,from,subject,returnPath,msg)().newline;

      
		}
	    pop3.close();
	}
    catch ( POP3Exception e ) { Stdout("Exception Caught: ")(e.toString)().newline; } 
    }
}
