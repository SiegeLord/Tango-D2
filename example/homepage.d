
private import  tango.io.Console;

private import  tango.http.client.HttpClient;

private import  tango.http.server.HttpHeaders;

private import std.exception;

/*******************************************************************************

        Directive to include the winsock2 library

*******************************************************************************/

version (Win32)
         pragma (lib, "wsock32");

bool foo (Object o)
{
        Cout ("releasing object ") (o.classinfo.name) .newline;
        return false;
}

/*******************************************************************************

        Shows how to use HttpClient to retrieve content from the D website
        
*******************************************************************************/

void main()
{
        setCollectHandler (&foo);

        auto client = new HttpClient (HttpClient.Get, "http://www.digitalmars.com/d/intro.html");
        client.open ();

        if (client.isResponseOK)
           {
           // extract content length
           int length = client.getResponseHeaders.getInt (HttpHeader.ContentLength, int.max);

           // display response
           client.read (delegate(char[] c){Cout (c);}, length);
           }
        else
           Cout ("failed to return the D home page");  

        client.close(); 
}
