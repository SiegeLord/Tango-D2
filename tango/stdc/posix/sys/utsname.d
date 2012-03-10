/**
 * D header file for POSIX.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Jacob Carlborg
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 * References: The Open Group $(LINK2 http://www.opengroup.org/onlinepubs/009695399/functions/uname.html, sys/utsname.h) $(BR)
 * 			   Mac OS X $(LINK2 http://developer.apple.com/documentation/Darwin/Reference/Manpages/man3/uname.3.html, sys/utsname.h) $(BR) 
 * 			   FreeBSD $(LINK2 http://www.freebsd.org/cgi/man.cgi?query=uname&sektion=3&apropos=0&manpath=FreeBSD+7.1-RELEASE, sys/utsname.h) $(BR)
 * 			   Linux $(LINK2 http://www.gnu.org/software/libc/manual/html_node/Platform-Type.html, sys/utsname.h)
 */
module tango.stdc.posix.sys.utsname;

extern (C):

version (darwin)
{
	private const size_t len = 256;

	struct utsname
	{
		char[len] sysname;
		char[len] nodename;
		char[len] release;
		char[len] version_; // appended a _ because of the otherwise keyword conflict
		char[len] machine;
	}
}

else version (FreeBSD)
{
	private const size_t len = 256;
	
	struct utsname
	{
		char[len] sysname;
		char[len] nodename;
		char[len] release;
		char[len] version_; // appended a _ because of the otherwise keyword conflict
		char[len] machine;
	}
}

else version (linux)
{
	private const size_t len = 65;
	
	struct utsname
	{
		char[len] sysname;
		char[len] nodename;
		char[len] release;
		char[len] version_; // appended a _ because of the otherwise keyword conflict
		char[len] machine;
		char[len] domainname;
	}
}

else version (solaris)
{
	private const size_t len = 257;
	
	struct utsname
	{
		char[len] sysname;
		char[len] nodename;
		char[len] release;
		char[len] version_; // appended a _ because of the otherwise keyword conflict
		char[len] machine;
	}
}

else
	static assert(false, "utsname is not available on this platform");

int uname(utsname*);
