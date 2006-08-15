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

module tango.sys.ProcessConduit;

private import tango.sys.OS;
private import tango.io.Conduit;
private import tango.stdc.stdlib;

private import tango.sys.PipeConduit;

version(Windows) { 
	extern(Windows) {
		struct PROCESS_INFORMATION {
		    HANDLE hProcess;
		    HANDLE hThread;
		    DWORD dwProcessId;
		    DWORD dwThreadId;
		}
		alias PROCESS_INFORMATION* PPROCESS_INFORMATION, LPPROCESS_INFORMATION;		
		
		struct STARTUPINFOA {
		    DWORD   cb;
		    LPSTR   lpReserved;
		    LPSTR   lpDesktop;
		    LPSTR   lpTitle;
		    DWORD   dwX;
		    DWORD   dwY;
		    DWORD   dwXSize;
		    DWORD   dwYSize;
		    DWORD   dwXCountChars;
		    DWORD   dwYCountChars;
		    DWORD   dwFillAttribute;
		    DWORD   dwFlags;
		    WORD    wShowWindow;
		    WORD    cbReserved2;
		    LPBYTE  lpReserved2;
		    HANDLE  hStdInput;
		    HANDLE  hStdOutput;
		    HANDLE  hStdError;
		}		
		alias STARTUPINFOA* LPSTARTUPINFOA;
		
		struct STARTUPINFOW {
		    DWORD   cb;
		    LPWSTR  lpReserved;
		    LPWSTR  lpDesktop;
		    LPWSTR  lpTitle;
		    DWORD   dwX;
		    DWORD   dwY;
		    DWORD   dwXSize;
		    DWORD   dwYSize;
		    DWORD   dwXCountChars;
		    DWORD   dwYCountChars;
		    DWORD   dwFillAttribute;
		    DWORD   dwFlags;
		    WORD    wShowWindow;
		    WORD    cbReserved2;
		    LPBYTE  lpReserved2;
		    HANDLE  hStdInput;
		    HANDLE  hStdOutput;
		    HANDLE  hStdError;
		}
		alias STARTUPINFOW* LPSTARTUPINFOW;
		
		VOID GetStartupInfoA(LPSTARTUPINFOA lpStartupInfo);
		VOID GetStartupInfoW(LPSTARTUPINFOW lpStartupInfo);
		
		uint STARTF_USESHOWWINDOW    = 0x00000001;
		uint STARTF_USESIZE          = 0x00000002;
		uint STARTF_USEPOSITION      = 0x00000004;
		uint STARTF_USECOUNTCHARS    = 0x00000008;
		uint STARTF_USEFILLATTRIBUTE = 0x00000010;
		uint STARTF_RUNFULLSCREEN    = 0x00000020;
		uint STARTF_FORCEONFEEDBACK  = 0x00000040;
		uint STARTF_FORCEOFFFEEDBACK = 0x00000080;
		uint STARTF_USESTDHANDLES    = 0x00000100;
		/+#if(WINVER >= 0x0400)
		const DWORD STARTF_USEHOTKEY        0x00000200
		#endif /* WINVER >= 0x0400 */
		+/
		
		BOOL CreateProcessA(
		    LPCSTR lpApplicationName,
		    LPSTR lpCommandLine,
		    LPSECURITY_ATTRIBUTES lpProcessAttributes,
		    LPSECURITY_ATTRIBUTES lpThreadAttributes,
		    BOOL bInheritHandles,
		    DWORD dwCreationFlags,
		    LPVOID lpEnvironment,
		    LPCSTR lpCurrentDirectory,
		    LPSTARTUPINFOA lpStartupInfo,
		    LPPROCESS_INFORMATION lpProcessInformation
		);
		
		BOOL CreateProcessW(
		    LPCWSTR lpApplicationName,
		    LPWSTR lpCommandLine,
		    LPSECURITY_ATTRIBUTES lpProcessAttributes,
		    LPSECURITY_ATTRIBUTES lpThreadAttributes,
		    BOOL bInheritHandles,
		    DWORD dwCreationFlags,
		    LPVOID lpEnvironment,
		    LPCWSTR lpCurrentDirectory,
		    LPSTARTUPINFOW lpStartupInfo,
		    LPPROCESS_INFORMATION lpProcessInformation
		);
		    
		BOOL CreateProcessAsUserA(
		    HANDLE hToken,
		    LPCSTR lpApplicationName,
		    LPSTR lpCommandLine,
		    LPSECURITY_ATTRIBUTES lpProcessAttributes,
		    LPSECURITY_ATTRIBUTES lpThreadAttributes,
		    BOOL bInheritHandles,
		    DWORD dwCreationFlags,
		    LPVOID lpEnvironment,
		    LPCSTR lpCurrentDirectory,
		    LPSTARTUPINFOA lpStartupInfo,
		    LPPROCESS_INFORMATION lpProcessInformation
		);
		
		BOOL CreateProcessAsUserW(
		    HANDLE hToken,
		    LPCWSTR lpApplicationName,
		    LPWSTR lpCommandLine,
		    LPSECURITY_ATTRIBUTES lpProcessAttributes,
		    LPSECURITY_ATTRIBUTES lpThreadAttributes,
		    BOOL bInheritHandles,
		    DWORD dwCreationFlags,
		    LPVOID lpEnvironment,
		    LPCWSTR lpCurrentDirectory,
		    LPSTARTUPINFOW lpStartupInfo,
		    LPPROCESS_INFORMATION lpProcessInformation
    	);
		    
		//
		// dwCreationFlag values
		//

		uint DEBUG_PROCESS               = 0x00000001;
		uint DEBUG_ONLY_THIS_PROCESS     = 0x00000002;

		uint CREATE_SUSPENDED            = 0x00000004;

		uint DETACHED_PROCESS            = 0x00000008;

		uint CREATE_NEW_CONSOLE          = 0x00000010;

		uint NORMAL_PRIORITY_CLASS       = 0x00000020;
		uint IDLE_PRIORITY_CLASS         = 0x00000040;
		uint HIGH_PRIORITY_CLASS         = 0x00000080;
		uint REALTIME_PRIORITY_CLASS     = 0x00000100;

		uint CREATE_NEW_PROCESS_GROUP    = 0x00000200;
		uint CREATE_UNICODE_ENVIRONMENT  = 0x00000400;

		uint CREATE_SEPARATE_WOW_VDM     = 0x00000800;
		uint CREATE_SHARED_WOW_VDM       = 0x00001000;
		uint CREATE_FORCEDOS             = 0x00002000;

		uint CREATE_DEFAULT_ERROR_MODE   = 0x04000000;
		uint CREATE_NO_WINDOW            = 0x08000000;

		uint PROFILE_USER                = 0x10000000;
		uint PROFILE_KERNEL              = 0x20000000;
		uint PROFILE_SERVER              = 0x40000000;
		
		BOOL TerminateProcess(HANDLE hProcess, UINT uExitCode);
		
		/*
		BOOL OpenProcessToken(
		    HANDLE ProcessHandle,
		    DWORD DesiredAccess,
		    PHANDLE TokenHandle
		);

		const DWORD TOKEN_ASSIGN_PRIMARY    = (0x0001);
		const DWORD TOKEN_DUPLICATE         = (0x0002);
		const DWORD TOKEN_IMPERSONATE       = (0x0004);
		const DWORD TOKEN_QUERY             = (0x0008);
		const DWORD TOKEN_QUERY_SOURCE      = (0x0010);
		const DWORD TOKEN_ADJUST_PRIVILEGES = (0x0020);
		const DWORD TOKEN_ADJUST_GROUPS     = (0x0040);
		const DWORD TOKEN_ADJUST_DEFAULT    = (0x0080);
		
		const DWORD TOKEN_ALL_ACCESS = (STANDARD_RIGHTS_REQUIRED  |
		                          TOKEN_ASSIGN_PRIMARY      |
		                          TOKEN_DUPLICATE           |
		                          TOKEN_IMPERSONATE         |
		                          TOKEN_QUERY               |
		                          TOKEN_QUERY_SOURCE        |
		                          TOKEN_ADJUST_PRIVILEGES   |
		                          TOKEN_ADJUST_GROUPS       |
		                          TOKEN_ADJUST_DEFAULT);
		
		
		const DWORD TOKEN_READ       = (STANDARD_RIGHTS_READ      |
		                          TOKEN_QUERY);
		
		
		const DWORD TOKEN_WRITE      = (STANDARD_RIGHTS_WRITE     |
		                          TOKEN_ADJUST_PRIVILEGES   |
		                          TOKEN_ADJUST_GROUPS       |
		                          TOKEN_ADJUST_DEFAULT);
		
		const DWORD TOKEN_EXECUTE    = (STANDARD_RIGHTS_EXECUTE);
		*/
	}
}

version(Posix) {
	private import tango.stdc.time;
	private import tango.stdc.stdio;
	private import tango.stdc.posix.unistd;
	private import tango.stdc.posix.signal;
	private import tango.stdc.posix.fcntl;
	private import tango.stdc.posix.sys.wait;

}

class ProcessException : Exception
{
	version(Windows) {
		this(char[] msg) { super(msg ~ ": " ~ OS.error()); }
	}
	version(Posix) {	
		//for some reason getErrno does not link for me?
		this(char[] msg) { super(msg ~ ": " ~ OS.error()); }
	}
}

class ProcessConduit : Conduit
{
	this()
	{
                super (Access.ReadWrite, false);
	}
	
	this(char[] command)
	{
		this();
		execute(command);
	}

	void execute(char[] command)
	{
		if (running) kill();
		startProcess(command);
	}
	
        uint bufferSize ()
        {
                return 8 * 1024;
        } 
                     
	void kill()
	{
		if (!running) return;
		stopProcess(0);
	}	

	void addEnv(char[] label, char[] value)
	{
		addEnv(label~"="~value);
	}
	
	void addEnv(char[] value)
	{
		enviroment ~= value;
	}
	
	uint reader (void[] dst)
	{
		return pout.reader(dst);
	}
	
	uint errors(void[] dst)
	{
		return perr.reader(dst);
	}

	uint writer(void[] src)
	{
		return pin.writer(src);
	}

private:
	char[][] enviroment = null;
	char* cmd = null;
	bool running = false;
	PipeConduit pout = null;
	PipeConduit perr = null;
	PipeConduit pin = null;

	version(Windows)
	{
		PROCESS_INFORMATION *info = null;
		
		char* makeBlock(char[][] from)
		{
			char* result = null;
			uint length = 0;
			uint upto = 0;			
			
			foreach(char[] s; from) length += s.length; //total length of strings
			length += from.length; //add space for a \0 for each string
			length++; //add space for final terminating \0
			
			result = cast(char*)calloc(1,length);
			
			foreach(char[] s; from) {				
				result[upto..upto+s.length] = s[0..s.length];
				upto += s.length+1;
			}
			
			return result;
		}
		
		void freeBlock(char* data)
		{
			free(data);
		}

		void startProcess(char[] command)
		{
			STARTUPINFOA startup;
			char* env = null;
			
			try {
				pout = new PipeConduit();
				perr = new PipeConduit();
				pin = new PipeConduit();

				GetStartupInfoA(&startup);
				startup.hStdInput = cast(HANDLE) pin.readHandle;
				startup.hStdOutput = cast(HANDLE) pout.writeHandle;
				startup.hStdError = cast(HANDLE) perr.writeHandle;
				startup.dwFlags = STARTF_USESTDHANDLES;

				info = new PROCESS_INFORMATION();
				env = makeBlock(enviroment);
					
				if (!CreateProcessA(null,command~"\0",null,null,true,DETACHED_PROCESS,env,null,&startup,info))
					throw new ProcessException("CreateProcess");
					
				running = true;
			} finally {
				if (env) freeBlock(env);
				if (running) {
					CloseHandle(info.hThread);
					pin.closeRead();
					pout.closeWrite();
					perr.closeWrite();
				}
				else {
					if (info) info = null;
					pout = null;
					perr = null;
					pin = null;
				}
			}
		}
		
		void stopProcess(uint exitCode)
		{			
			if (!TerminateProcess(info.hProcess,exitCode))
				throw new ProcessException("TerminateProcess");
				
			running = false;
			
			CloseHandle(info.hProcess);
			info = null;
			pout = null;
			perr = null;
			pin = null;
		}
	}




	
	version(Posix)
	{
		int pid;
		
		char** makeBlock(char[][] from)
		{
			char** result = null;

			result = cast(char**)calloc(1,(enviroment.length+1) * typeid(char*).sizeof);
			foreach(uint i, char[] s; from)
				result[i] = strdup( s ~ "\0" ); 

			return result;
		}
			
		void freeBlock(char** block)
		{
			for(uint i = 0; block[i]; i++) free(block[i]);
			free(block);
		}
		
		bool find (char[] list, char match)
                {
                        foreach (c; list)
                                 if (c is match)
                                     return true;
                        return false;
                }

		char[][] splitArgs(char[] string, char[] delims = " \t\r\n")
		{
			char[][] results = null;			
			bool isquot = false;
			int start = -1;
			int i;
			
			for(i = 0; i < string.length; i++)
			{
				if (string[i] == '\"') isquot = !isquot;
				if (isquot) continue;
				if (find(delims, string[i])) {
					if (start == -1) continue;
					results ~= string[start..i];
					start = -1;
					continue;
				}
				if (start == -1) start = i;
			}
			results ~= string[start..i];
			
			return results;
		}

		void startProcess(char[] command)
		{
			try {
				pin = new PipeConduit();
				pout = new PipeConduit();
				perr = new PipeConduit();
				
				if (fcntl(cast(int)pin.writeHandle, F_SETFD, 1) == -1) throw new ProcessException("fcntl(pin.writeHandle)");
				if (fcntl(cast(int)pout.readHandle, F_SETFD, 1) == -1) throw new ProcessException("fcntl(pout.readHandle)");
				if (fcntl(cast(int)perr.readHandle, F_SETFD, 1) == -1) throw new ProcessException("fcntl(perr.readHandle)");
				if (fcntl(fileno(stdin), F_SETFD, 1) == -1) throw new ProcessException("fcntl(stdin)");
				if (fcntl(fileno(stdout), F_SETFD, 1) == -1) throw new ProcessException("fcntl(stdout)");
				if (fcntl(fileno(stderr), F_SETFD, 1) == -1) throw new ProcessException("fcntl(stderr)");
				
				pid = fork();
				if (pid == 0) {
					char[][] args;
				
					/* child */
					//not sure if we can even throw here?
					if (dup2(cast(int) pout.writeHandle,STDOUT_FILENO) == -1) {} //throw new ProcessException("dup2(xwrite[1])");
					if (dup2(cast(int) perr.writeHandle,STDERR_FILENO) == -1) {} //throw new ProcessException("dup2(xread[0])");
					if (dup2(cast(int) pin.readHandle,STDIN_FILENO) == -1) {} //throw new ProcessException("dup2(xread[0])");
					
					pout.closeWrite();
					perr.closeWrite();
					pin.closeRead();

					/* set child uid/gid here */
					//if (setuid(uid) == -1) throw new ProcessException("setuid");
					//if (setgid(gid) == -1) throw new ProcessException("setgid");

					args = splitArgs(command);
					// args are not null terminated
					char*[] argptrs;
					foreach( char[] a; args ){
					    argptrs ~= ( a ~ '\0' ).ptr;
					}
					argptrs ~= null;
					// enviroments are not null terminated
					char*[] envptrs;
					foreach( char[] e; enviroment ){
					    envptrs ~= ( e ~ '\0' ).ptr;
					}
					envptrs ~= null;
					execve(args[0],argptrs.ptr,envptrs.ptr); //this does not return on success
					//can we throw? how to notify parent of failure?
					exit(1);
				}
				/* parent */
				running = true;
			} finally {
				if (running) {
					pout.closeWrite();
					perr.closeWrite();
					pin.closeRead();
				}
				else {
					pin = null;
					pout = null;
					perr = null;
				}
			}
		}
				
		void stopProcess(uint dummy)
		{
			int r;

			if (pid == 0) return;

			if (.kill(pid, SIGTERM) == -1) throw new ProcessException("kill");
			
			for(uint i = 0; i < 100; i++) {
				r = waitpid(pid,null,WNOHANG|WUNTRACED);
				if (r == -1) throw new ProcessException("waitpid");
				if (r == pid) break;
				usleep(50000);
			}			
			running = false;
			pin = null;
			pout = null;
			perr = null;
			pid = 0;
		}		
	}
}


debug (Main)
{
extern (C) uint printf(char*, ...);

void main()
{
        char[256] buf;
	auto p = new ProcessConduit("cmd /c dir");
        uint len;

        while ((len = p.reader(buf)) != p.Eof)
                printf("%.*s", buf[0..len]);
}
}


