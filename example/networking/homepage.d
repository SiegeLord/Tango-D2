
private import  tango.io.Console;

private import  tango.net.http.HttpClient,
                tango.net.http.HttpHeaders;

/*******************************************************************************

        Shows how to use HttpClient to retrieve content from the D website
        
*******************************************************************************/

void main()
{
        auto client = new HttpClient (HttpClient.Get, "http://www.digitalmars.com/d/intro.html");
        client.open;
        scope (exit)
               client.close;
        
        if (client.isResponseOK)
           {
           // extract content length
           int length = client.getResponseHeaders.getInt (HttpHeader.ContentLength, int.max);

           // display response
           client.read (&Cout.buffer.consume, length);
           Cout.newline;
           }
        else
           Cout ("failed to return the D home page").newline;  
}
