/*
	HTMLget written by Christopher E. Miller
	This code is public domain.
	You may use it for any purpose.
	This code has no warranties and is provided 'as-is'.
*/


//debug = HTMLGET;

import phobos.string, phobos.conv, phobos.stream;
import phobos.socket, phobos.socketstream;
import tango.stdc.stdio;


int main(char[][] args)
{
	if(args.length < 2)
	{
		printf("Usage:\n   htmlget <web-page>\n");
		return 0;
	}
	char[] url = args[1];
	int i;
	
	i = phobos.string.find(url, "://");
	if(i != -1)
	{
		if(icmp(url[0 .. i], "http"))
			throw new Exception("http:// expected");
	}
	
	i = phobos.string.find(url, '#');
	if(i != -1) // Remove anchor ref.
		url = url[0 .. i];
	
	i = phobos.string.find(url, '/');
	char[] domain;
	if(i == -1)
	{
		domain = url;
		url = "/";
	}
	else
	{
		domain = url[0 .. i];
		url = url[i .. url.length];
	}
	
	uint port;
	i = phobos.string.find(domain, ':');
	if(i == -1)
	{
		port = 80; // Default HTTP port.
	}
	else
	{
		port = phobos.conv.toUshort(domain[i + 1 .. domain.length]);
		domain = domain[0 .. i];
	}
	
	debug(HTMLGET)
		printf("Connecting to " ~ domain ~ " on port " ~ phobos.string.toUtf8(port) ~ "...\n");
	
	auto Socket sock = new TcpSocket(new InternetAddress(domain, port));
	Stream ss = new SocketStream(sock);
	
	debug(HTMLGET)
		printf("Connected!\nRequesting URL \"" ~ url ~ "\"...\n");
	
	if(port != 80)
		domain = domain ~ ":" ~ phobos.string.toString(port);
	ss.writeString("GET " ~ url ~ " HTTP/1.1\r\n"
		"Host: " ~ domain ~ "\r\n"
		"\r\n");
	
	// Skip HTTP header.
	char[] line;
	for(;;)
	{
		line = ss.readLine();
		if(!line.length)
			break;
		
		const char[] CONTENT_TYPE_NAME = "Content-Type: ";
		if(line.length > CONTENT_TYPE_NAME.length &&
			!icmp(CONTENT_TYPE_NAME, line[0 .. CONTENT_TYPE_NAME.length]))
		{
			char[] type;
			type = line[CONTENT_TYPE_NAME.length .. line.length];
			if(type.length <= 5 || icmp("text/", type[0 .. 5]))
				throw new Exception("URL is not text");
		}
	}
	
	print_lines:
	while(!ss.eof())
	{
		line = ss.readLine();
		printf("%.*s\n", line);
		
		//if(phobos.string.ifind(line, "</html>") != -1)
		//	break;
		size_t iw;
		for(iw = 0; iw != line.length; iw++)
		{
			if(!icmp("</html>", line[iw .. line.length]))
				break print_lines;
		}
	}
	
	return 0;
}

