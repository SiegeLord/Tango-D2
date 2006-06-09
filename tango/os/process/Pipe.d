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

module tango.os.process.Pipe;
import tango.os.OS;
import tango.io.DeviceConduit;
import tango.stdc.stdio;

extern(C) char* strdup(char*);

version(Windows) { 
	import tango.os.windows.c.windows;
	import tango.os.windows.c.syserror;
	
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
}

version(Posix) {
	private import tango.stdc.stdlib;
	private import tango.os.linux.c.linux;

	extern (C) {
		//char* strerror(int);
		int ioctl(int, int, ...);
	}
	uint FIONREAD = 0x541B;
}

version(Windows)
{
	class PipeException : Exception
	{
		this(char[] msg) { super(msg ~ ": " ~ OS.error(OS.error())); }
	}

	class PipeStream : Stream
	{
		this(uint bufferSize = 0)
		{
			SECURITY_ATTRIBUTES security;
		
			security.nLength = security.sizeof;
			security.lpSecurityDescriptor = null;
			security.bInheritHandle = true;
			
			if (!CreatePipe(&read,&write,&security,bufferSize))
				throw new PipeException("CreatePipe");
			
			writeable = true;
			readable = true;			
			seekable = false;
			isopen = true;
		}

		HANDLE readHandle()
		{
			return read;
		}
		
		HANDLE writeHandle()
		{
			return write;
		}		
		
		void closeRead()
		{			
			CloseHandle(readHandle);
			read = INVALID_HANDLE_VALUE;
			readable = false;
			if (!writeable) isopen = false;
		}
		
		void closeWrite()
		{
			CloseHandle(writeHandle);
			write = INVALID_HANDLE_VALUE;
			writeable = false;
			if (!readable) isopen = false;
		}
		
		override void close()
		{
			closeRead();
			closeWrite();
		}
		
		override ulong seek(long offset, SeekPos whence)
		{
			assertSeekable();
		}

		
		override size_t readBlock(void* buffer, size_t size)
		{
			size_t bytes = 0;
			assertReadable();
			if (!ReadFile(readHandle,buffer,size,&bytes,null)) throw new PipeException("ReadFile");
			return bytes;
		}

		override size_t available()
		{
			size_t bytes = 0;
			assertReadable();
			if (!PeekNamedPipe(readHandle,null,0,null,&bytes,null)) throw new PipeException("PeekNamedPipe");
			return bytes;
		}

		override size_t writeBlock(void* buffer, size_t size)
		{
			size_t bytes = 0;
			assertWriteable();
			if (!WriteFile(writeHandle,buffer,size,&bytes,null)) throw new PipeException("WriteFile");
			return bytes;
		}
		
		override void flush()
		{
			assertWriteable();
			FlushFileBuffers(writeHandle);
		}
		
	private:
		HANDLE write = INVALID_HANDLE_VALUE;
		HANDLE read = INVALID_HANDLE_VALUE;
	}
}

version(Posix)
{		
	class PipeException : Exception
	{
		//for some reason getErrno does not link for me?
		this(char[] msg) { super(msg ~ ": " ~ OS.error(OS.error())); }
	}

	class PipeStream : Stream
	{
		this(uint dummy = 0)
		{
			if (pipe(handle) == -1) throw new PipeException("pipe(handle)");
			writeable = true;
			readable = true;			
			seekable = false;
			isopen = true;
		}
		
		int readHandle()
		{
			return handle[0];
		}

		int writeHandle()
		{
			return handle[1];
		}
		
		void closeRead()
		{
			std.c.linux.linux.close(readHandle);
			readable = false;
			if (!writeable) isopen = false;
		}
		
		void closeWrite()
		{
			std.c.linux.linux.close(writeHandle);
			writeable = false;
			if (!readable) isopen = false;
		}
		
		override void close()
		{
			closeRead();
			closeWrite();
		}
		
		override ulong seek(long offset, SeekPos whence)
		{
			assertSeekable();
		}
		
		override size_t readBlock(void* buffer, size_t size)
		{
			size_t bytes;
			assertReadable();
			bytes = std.c.linux.linux.read(readHandle,buffer,size);
			if (bytes == -1) throw new PipeException("read(handle[0])");
			return bytes;
		}

		override size_t available()
		{
			size_t bytes;
			assertReadable();
			if (ioctl(readHandle,FIONREAD,&bytes) == -1) throw new PipeException("ioctl(handle[0])");
			return bytes;			
		}

		override size_t writeBlock(void* buffer, size_t size)
		{
			size_t bytes;
			assertWriteable();
			bytes = std.c.linux.linux.write(writeHandle,buffer,size);
			if (bytes == -1) throw new PipeException("write(handle[1])");
			return bytes;
		}
	
		override void flush()
		{
			assertWriteable();
			//writeHandle
		}

	private:
		int handle[2];
	}
}

