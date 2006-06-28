
private import  tango.io.Console;

private import  tango.net.http.HttpClient,
                tango.net.http.HttpHeaders;

/*******************************************************************************

        Directive to include the winsock2 library

*******************************************************************************/

version (Win32)
         pragma (lib, "wsock32");

/*******************************************************************************

        Shows how to use HttpClient to retrieve content from the D website
        
*******************************************************************************/

void main()
{
        auto client = new HttpClient (HttpClient.Get, "http://www.digitalmars.com/d/intro.html");
        client.open ();

        if (client.isResponseOK)
           {
           // extract content length
           int length = client.getResponseHeaders.getInt (HttpHeader.ContentLength, int.max);

           // display response
           client.read (&Cout.consume, length);
           }
        else
           Cout ("failed to return the D home page");  

        client.close(); 
}
