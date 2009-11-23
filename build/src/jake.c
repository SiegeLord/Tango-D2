// rsp.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"

#define BUFSIZE 4096
//#define FOO

/*****************************************************************************


*****************************************************************************/
 
HANDLE  hChildStdinRd,
        hChildStdinWr,  
        hChildStdoutRd,
        hChildStdoutWr,
        hInputFile,
        hStdout;

char    *errors,
        *imports,
        *primary,
        *importDir;

int     errorLen = 0,
        importLen = 0;

/*****************************************************************************


*****************************************************************************/
 
VOID ErrorExit (LPTSTR lpszMessage)
{
        fprintf(stderr, "%s\n", lpszMessage);
        ExitProcess(0);
}

/*****************************************************************************


*****************************************************************************/
 
BOOL CreateChildProcess(char* szCmdline, bool inherit)
{
        PROCESS_INFORMATION piProcInfo;
        STARTUPINFO siStartInfo;
        BOOL bFuncRetn = FALSE;
 
        // Set up members of the PROCESS_INFORMATION structure.
 
        ZeroMemory( &piProcInfo, sizeof(PROCESS_INFORMATION) );
 
        // Set up members of the STARTUPINFO structure.
 
        ZeroMemory( &siStartInfo, sizeof(STARTUPINFO) );
        siStartInfo.cb = sizeof(STARTUPINFO);
        if (inherit)
           {
           siStartInfo.hStdError = hChildStdoutWr;
           siStartInfo.hStdOutput = hChildStdoutWr;
           siStartInfo.hStdInput = hChildStdinRd;
           siStartInfo.dwFlags |= STARTF_USESTDHANDLES;
           }
 
        // Create the child process.
        bFuncRetn = CreateProcess(NULL,
                                  szCmdline,     // command line
                                  NULL,          // process security attributes
                                  NULL,          // primary thread security attributes
                                  inherit,          // handles are inherited
                                  0,             // creation flags
                                  NULL,          // use parent's environment
                                  NULL,          // use parent's current directory
                                  &siStartInfo,  // STARTUPINFO pointer
                                  &piProcInfo);  // receives PROCESS_INFORMATION
   
        if (bFuncRetn == 0)
            ErrorExit("CreateProcess failed\n");
        else
           if (inherit)
              {
              CloseHandle(piProcInfo.hProcess);
              CloseHandle(piProcInfo.hThread);
              }
           else
              WaitForSingleObject (piProcInfo.hProcess, INFINITE);
        return bFuncRetn;
}
 
/*****************************************************************************


*****************************************************************************/
 
void append (char* s, int len)
{
           memcpy (imports+importLen, s, len);
           importLen += len;
}

/*****************************************************************************


*****************************************************************************/
 
void appendError (char* s, int len)
{
           memcpy (errors+errorLen, s, len);
           errorLen += len;
}

/*****************************************************************************


*****************************************************************************/
 
void parse (char*s, int length)
{
        if (length > 6 && (memcmp(s, "import", 6) == 0))
           {
           // printf ("found %.*s\n", length, s);

           int i=6;
           for (; i < length; ++i)
                  if (s[i] != ' ')
                      break;

           int start = i;

           for (; i < length; ++i)
                  if (s[i] == '.')
                      s[i] = '\\';
           
           int mark = importLen;
           append (importDir, strlen(importDir));
           append ("\\", 1);
           append (s+start, length-start);
           append (".d", 3);
           if (GetFileAttributes(imports+mark) != -1)
              {
              --importLen;
              append ("\n", 1);
              }
           else
              {
              // printf ("'%s' does not exist\n", imports+mark);
              importLen = mark;
              }
           }
        else
           for (int i=0; i < length; ++i)
                if (s[i] == ':')
                   {
                   appendError (s, length);
                   appendError ("\n", 1);
                   }
}

/*****************************************************************************


*****************************************************************************/
 
VOID ReadFromPipe()
{
        DWORD dwRead;
        CHAR chBuf[BUFSIZE];
        CHAR line[BUFSIZE];
        int  lineIdx = 0;

        // Close the write end of the pipe before reading from the
        // read end of the pipe.
 
        if (!CloseHandle(hChildStdoutWr))
             ErrorExit("Closing handle failed");
 
        // Read output from the child process, and write to parent's STDOUT.

        errorLen = importLen = 0;
        for (;;)
            {
            if(! ReadFile(hChildStdoutRd, chBuf, BUFSIZE, &dwRead, NULL) || dwRead == 0)
                 break;

            for (DWORD i=0; i < dwRead; ++i)
                {
                char c = chBuf[i];
                if (c == '\n' || c == '\r')
                   {
                   parse (line, lineIdx);
                   lineIdx = 0;
                   }
                else
                   line [lineIdx++] = c;
                }
#ifdef FOO
            DWORD dwWritten;
            if (! WriteFile(hStdout, chBuf, dwRead, &dwWritten, NULL))
                  break;
#endif
            }
}

/*****************************************************************************


*****************************************************************************/
 
int run(char* cmd, int argc, char *argv[])
{
        SECURITY_ATTRIBUTES saAttr;
        BOOL fSuccess;
 
        // Set the bInheritHandle flag so pipe handles are inherited.
 
        saAttr.nLength = sizeof(SECURITY_ATTRIBUTES);
        saAttr.bInheritHandle = TRUE;
        saAttr.lpSecurityDescriptor = NULL;

        // Get the handle to the current STDOUT.
 
        hStdout = GetStdHandle(STD_OUTPUT_HANDLE);
 
        // Create a pipe for the child process's STDOUT.
 
        if (! CreatePipe(&hChildStdoutRd, &hChildStdoutWr, &saAttr, 0))
              ErrorExit("Stdout pipe creation failed\n");

        // Ensure the read handle to the pipe for STDOUT is not inherited.

        SetHandleInformation( hChildStdoutRd, HANDLE_FLAG_INHERIT, 0);

        // Create a pipe for the child process's STDIN.
 
        if (! CreatePipe(&hChildStdinRd, &hChildStdinWr, &saAttr, 0))
              ErrorExit("Stdin pipe creation failed\n");

        // Ensure the write handle to the pipe for STDIN is not inherited.
 
        SetHandleInformation( hChildStdinWr, HANDLE_FLAG_INHERIT, 0);
 
        // Now create the child process.
        fSuccess = CreateChildProcess(cmd, true);

        if (! fSuccess)
              ErrorExit("Create process failed with");

        // Get a handle to the parent's input file.
 /*

        printf( "\nContents of %s:\n\n", argv[1]);

 
        // Write to pipe that is the standard input for a child process.
 
        WriteToPipe();
 
        // Read from pipe that is the standard output for child process.
*/         
        ReadFromPipe();
 
        return 0;
}


/*****************************************************************************


*****************************************************************************/
 
void buildCmd (char* output, char* argv[], int argc, char* delim)
{
        for (int i=1; i < argc; ++i)
            {
            int j = strlen (argv[i]);
            memcpy (output, argv[i], j);
            output += j;

            memcpy (output, delim, strlen(delim));
            output += 1;
            }
        *output = 0;
}


/*****************************************************************************


*****************************************************************************/
 
void writeResponse (char* hdr, char* s, int len)
{
        char tmp[256];

        int i = strlen(primary);
        memcpy (tmp, primary, i);
        memcpy (tmp+i, ".rsp", 4);

        HANDLE output = CreateFile("rsp", GENERIC_WRITE, 0, NULL,
                                   CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);

        if (output == INVALID_HANDLE_VALUE)
            ErrorExit("CreateFile failed");

        DWORD dwWritten;
        if (! WriteFile(output, hdr, strlen(hdr), &dwWritten, NULL))
              ErrorExit("WriteFile failed");

        if (! WriteFile(output, s, len, &dwWritten, NULL))
              ErrorExit("WriteFile failed");
 
        if (! CloseHandle(output))
              ErrorExit("Close file failed\n");
}

/*****************************************************************************


*****************************************************************************/
 
int main(int argc, char* argv[])
{
        if (argc < 2)
            ErrorExit
            (
            "Jake needs a D module or program to compile\n"            
            "     there are no Jake-specific flags, though the -I compiler flag is required\n"
            "     use of the compiler flag -op is recommended\n"             
            "     Jake emits a file called 'rsp', which can be used directly: dmd @rsp\n"            
            "     example: jake -I\\d\\tango -op myprogram.d"            
            );

        for (int i=1; i < argc; ++i)
             if (strlen(argv[i]) > 2 && memcmp (argv[i], "-I", 2) == 0)
                 importDir = argv[i];
             else
                if (argv[i][0] != '-' && primary == 0)
                    primary = argv[i];
                                 

        char dir[256];
        if (importDir == 0)
            ErrorExit ("no -I specified");
        else
           {
           int i = strlen (importDir);
           if (i < 3)
               ErrorExit ("-I should indicate the package-root folder");

           // remove optional trailing '/'
           if (importDir[i-1] == '\\' || importDir[i-1] == '/')
               --i;

           i -= 2;
           memcpy (dir, importDir+2, i);
           dir [i] = 0;
           importDir = dir;
           }

        char tmp[256];
        char* cmd = "dmd -v -c -o- ";

        int x = strlen (cmd);
        memcpy (tmp, cmd, x);
        buildCmd (tmp+x, argv, argc, " ");

        //printf ("command:'%s'\n", tmp);

        errors = (char*) malloc (8192);
        imports = (char*) malloc (8192);
        if (imports != 0 && errors != 0)
           {
           run (tmp, argc, argv);
           append ("", 1);
           appendError ("", 1);
           if (errorLen > 1)
               printf (errors);
           else
              {
              // printf (imports);
              buildCmd (tmp, argv, argc, "\n");
              writeResponse (tmp, imports, importLen);
              CreateChildProcess ("dmd @rsp", false);
              }
           }
        else
           ErrorExit ("Failed to allocate");
    return 0;
}
