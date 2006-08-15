/*
 * Copyright (c) 2005
 * Regan Heath
 *
 * Permission to use, copy, modify, distribute and sell this software
 * and its documentation for any purpose is hereby granted without fee,
 * provided that the above copyright notice appear in all copies and
 * that both that copyright notice and this permission notice appear
 * in supporting documentation.  Author makes no representations about
 * the suitability of this software for any purpose. It is provided
 * "as is" without express or implied warranty.
 */

module tango.sys.PipeConduit;


import tango.sys.OS;
import tango.io.Conduit;
import tango.io.Exception;

version(Windows)
{
	extern(Windows) {
		alias HANDLE* PHANDLE;		
		
		BOOL CreatePipe(
		    PHANDLE hReadPipe, 
		    PHANDLE hWritePipe, 
		    LPSECURITY_ATTRIBUTES lpPipeAttributes, 
		    DWORD nSize
		    );
		
		BOOL PeekNamedPipe(
		    HANDLE hNamedPipe,
		    LPVOID lpBuffer,
		    DWORD nBufferSize,
		    LPDWORD lpBytesRead,
		    LPDWORD lpTotalBytesAvail,
		    LPDWORD lpBytesLeftThisMessage
		    );
	}

	class PipeException : IOException
	{
		this(char[] msg) { super(msg ~ ": " ~ OS.error()); }
	}

	class PipeConduit : Conduit
	{
		this()
		{
                        super (Access.ReadWrite, false);

			SECURITY_ATTRIBUTES security;
		
			security.nLength = security.sizeof;
			security.lpSecurityDescriptor = null;
			security.bInheritHandle = true;
			
                        // last arg is buffer size
			if (!CreatePipe(&read,&write,&security, 0))
				throw new PipeException("CreatePipe");
		}

                override Handle getHandle()
                {
                        return readHandle();

                }

                override uint bufferSize ()
                {
                        return 8 * 1024;
                } 
                               
		Handle readHandle()
		{
			return cast(Handle) read;
		}
		
		Handle writeHandle()
		{
			return cast(Handle) write;
		}		
		
		void closeRead()
		{			
			CloseHandle(read);
			read = INVALID_HANDLE_VALUE;
		}
		
		void closeWrite()
		{
			CloseHandle(write);
			write = INVALID_HANDLE_VALUE;
		}
		
		override void close()
		{
                        super.close();
			closeRead();
			closeWrite();
		}
		
		override uint reader(void[]dst)
		{
			uint bytes = 0;
			if (!ReadFile(read,dst.ptr,dst.length,&bytes,null)) 
                             return Eof;
			return bytes;
		}

		override uint writer(void[] src)
		{
			uint bytes = 0;
			if (!WriteFile(write,src.ptr,src.length,&bytes,null)) 
                             return Eof;
			return bytes;
		}
		
	private:
		HANDLE write = INVALID_HANDLE_VALUE;
		HANDLE read = INVALID_HANDLE_VALUE;
	}
}




version(Posix)
{		
	private import tango.stdc.stdlib;
	private import tango.stdc.posix.unistd;

	class PipeException : IOException
	{
		//for some reason getErrno does not link for me?
		this(char[] msg) { super(msg ~ ": " ~ OS.error()); }
	}

	class PipeConduit : Conduit
	{
		this(uint dummy = 0)
		{
                        super (Access.ReadWrite, false);

			if (pipe(handle) == -1) throw new PipeException("pipe(handle)");
		}
		
                override Handle getHandle()
                {
                        return readHandle();

                }

                override uint bufferSize ()
                {
                        return 8 * 1024;
                } 

		Handle readHandle()
		{
			return cast(Handle) handle[0];
		}

		Handle writeHandle()
		{
			return cast(Handle) handle[1];
		}
		
		void closeRead()
		{
			posix.close(handle[0]);
                        handle[0] = -1;
		}
		
		void closeWrite()
		{
			posix.close(handle[1]);
                        handle[1] = -1;
		}
		
		override void close()
		{
                        super.close();
			closeRead();
			closeWrite();
		}
		
		override uint reader(void[]dst)
		{
			uint bytes = 0;
			bytes = posix.read(handle[0] , dst.ptr, dst.length);
			if (bytes is -1) 
                            return Eof;
			return bytes;
		}

		override uint writer(void[] src)
		{
			uint bytes = 0;
			bytes = posix.write(handle[1], src.ptr, src.length);
			if (bytes is -1)
                            return Eof;
			return bytes;
		}
		
	private:
		int handle[2];
	}
}

