/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Feb 2005 
        version:        Heavily revised for unicode; November 2005
        
        author:         Kris

*******************************************************************************/

module tango.io.Console;

private import  tango.sys.OS;

private import  tango.io.Buffer,
                tango.io.DeviceConduit;


/*******************************************************************************

        Bring in native Windows functions

*******************************************************************************/

version (Win32)
{
        private extern (Windows) 
        {
                HANDLE GetStdHandle   (DWORD);
                DWORD  GetConsoleMode (HANDLE, LPDWORD);
                BOOL   ReadConsoleW   (HANDLE, VOID*, DWORD, LPDWORD, LPVOID);
                BOOL   WriteConsoleW  (HANDLE, VOID*, DWORD, LPDWORD, LPVOID);

                const uint CP_UTF8 = 65001;
                int    WideCharToMultiByte(UINT, DWORD, wchar*, int, void*, int, LPCSTR, LPBOOL);
                int    MultiByteToWideChar(UINT, DWORD, void*, int,  wchar*, int);
        }
}

/*******************************************************************************

        low level console IO support. 
        
        Note that for a while this was templated for each of char, wchar, 
        and dchar. It became clear after some usage that the console is
        more useful if it sticks to Utf8 only. See ConsoleConduit below
        for details.

        Redirecting the standard IO handles (via a shell) operates as one 
        would expect.

*******************************************************************************/

struct Console 
{
        /**********************************************************************

                Model console input as a buffer. Note that we read utf8
                only.

        **********************************************************************/

        class Input : Buffer
        {
                alias getConduit conduit;
                
                /**************************************************************

                        Attach console input to the provided device

                **************************************************************/

                private this (FileDevice device)
                {
                        super (new ConsoleConduit (device));
                }

                /**************************************************************

                        Return available input from the console. Note that 
                        you may obtain a slice from the buffer instead by
                        setting copy to false.
                         
                **************************************************************/

                char[] get (bool copy = true)
                {
                        if (readable is 0)
                            fill ();

                        auto x = cast(char[]) super.get (readable);
                        return (copy ? x.dup : x);
                }
        }


        /**********************************************************************

                Model console output as a buffer. Note that we accept 
                utf8 only: the superclass append() methods are hidden
                from view. Buffer.consume is left open, for those who
                require lower-level access ~ along with Buffer.write

        **********************************************************************/

        class Output : Buffer
        {
                alias newline    nl;
                alias flush      opCall;
                alias append     opCall;
                alias getConduit conduit;

                /**************************************************************

                        Attach console output to the provided device

                **************************************************************/

                private this (FileDevice device)
                {
                        super (new ConsoleConduit (device));
                }

                /**************************************************************

                        Append to the console. We accept UTF8 only, so
                        all other encodings should be handled via some
                        higher level API

                **************************************************************/

                Output append (char[] x)
                {
                        super.append(x);
                        return this;
                } 
                          
                /**************************************************************

                        Append content

                        Params:
                        other = an object with a useful toUtf8() method

                        Returns:
                        Returns a chaining reference if all content was 
                        written. Throws an IOException indicating eof or 
                        eob if not.

                        Remarks:
                        Append the result of other.toUtf8() to the console, 
                        and flush.

                **************************************************************/

                Output append (Object o)        
                {           
                        return append (o.toUtf8);
                }

                /**************************************************************

                        Append a newline

                        Returns:
                        Returns a chaining reference if content was written. 
                        Throws an IOException indicating eof or eob if not.

                        Remarks:
                        Emit a platform-specific newline into the buffer

                **************************************************************/

                Output newline ()
                {
                        super.append ("\n").flush;
                        return this;
                }           
        }


        /***********************************************************************

                Conduit for specifically handling the console devices. This 
                takes care of certain implementation details on the Win32 
                platform.

                Note that the console is fixed at Utf8 for both linux and
                Win32. The latter is actually Utf16 native, but it's just
                too much hassle for a developer to handle the distinction
                when it really should be a no-brainer. In particular, the
                Win32 console functions don't work with redirection. This
                causes additional difficulties that can be ameliorated by
                asserting console I/O is always Utf8, in all modes.

        ***********************************************************************/

        class ConsoleConduit : DeviceConduit
        {
                /***************************************************************
        
                        Returns true if this conduit is text-based

                ***************************************************************/

                override bool isTextual ()
                {
                        return true;
                }       
                        
                /***************************************************************

                        Windows-specific code

                ***************************************************************/

                version (Win32)
                        {
                        private wchar[] input;
                        private wchar[] output;

                        private bool redirect = false;

                        /*******************************************************

                                Create a FileConduit on the provided 
                                FileDevice. 

                                This is strictly for adapting existing 
                                devices such as Stdout and friends

                        *******************************************************/

                        private this (FileDevice device)
                        {
                                super (device);
                                input = new wchar [1024 * 1];
                                output = new wchar [1024 * 1];
                        }    

                        /*******************************************************
        
                                Return a preferred size for buffering 
                                console I/O. This must be less than 32KB 
                                for Win32!

                        *******************************************************/

                        uint bufferSize ()
                        {
                                return 1024 * 8;
                        }

                        /*******************************************************

                                Gain access to the standard IO handles 

                        *******************************************************/

                        protected override void reopen (FileDevice device)
                        {
                                static const DWORD[] id = [
                                                          cast(DWORD) -10, 
                                                          cast(DWORD) -11, 
                                                          cast(DWORD) -12
                                                          ];
                                static const char[][] f = [
                                                          "CONIN$\0", 
                                                          "CONOUT$\0", 
                                                          "CONOUT$\0"
                                                          ];

                                assert (device.id < 3);
                                handle = GetStdHandle (id[device.id]);
                                if (! handle)
                                      handle = CreateFileA (f[device.id], 
                                               GENERIC_READ | GENERIC_WRITE,  
                                               FILE_SHARE_READ | FILE_SHARE_WRITE, 
                                               null, OPEN_EXISTING, 0, null);
                                if (! handle)
                                      error ();

                                // are we redirecting?
                                DWORD mode;
                                if (! GetConsoleMode (handle, &mode))
                                      redirect = true;
                        }

                        /*******************************************************

                                Write a chunk of bytes to the console from the 
                                provided array (typically that belonging to 
                                an IBuffer)

                        *******************************************************/

                        version (Win32SansUnicode) 
                                {} 
                             else
                                {
                                protected override uint writer (void[] src)
                                {
                                if (redirect)
                                    return super.writer (src);
                                else
                                   {
                                   DWORD i = src.length;

                                   // protect conversion from empty strings
                                   if (i is 0)
                                       return 0;

                                   // expand buffer appropriately
                                   if (output.length < i)
                                       output.length = i;

                                   // convert into output buffer
                                   i = MultiByteToWideChar (CP_UTF8, 0, src.ptr, i, 
                                                            output.ptr, output.length);
                                            
                                   // flush produced output
                                   for (wchar* p=output.ptr, end=output.ptr+i; p < end; p+=i)
                                       {
                                       const int MAX = 32767;

                                       // avoid console limitation of 64KB 
                                       DWORD len = end - p; 
                                       if (len > MAX)
                                          {
                                          len = MAX;
                                          // check for trailing surrogate ...
                                          if ((p[len-1] & 0xfc00) is 0xdc00)
                                               --len;
                                          }
                                       if (! WriteConsoleW (handle, p, len, &i, null))
                                             error();
                                       }
                                   return src.length;
                                   }
                                }
                                }
                        
                        /*******************************************************

                                Read a chunk of bytes from the console into the 
                                provided array (typically that belonging to 
                                an IBuffer)

                        *******************************************************/

                        version (Win32SansUnicode) 
                                {} 
                             else
                                {
                                protected override uint reader (void[] dst)
                                {
                                if (redirect)
                                    return super.reader (dst);
                                else
                                   {
                                   DWORD i = dst.length / 4;

                                   assert (i);

                                   if (i > input.length)
                                       i = input.length;
                                       
                                   // read a chunk of wchars from the console
                                   if (! ReadConsoleW (handle, input.ptr, i, &i, null))
                                         error();

                                   // no input ~ go home
                                   if (i is 0)
                                       return Eof;

                                   // translate to utf8, directly into dst
                                   i = WideCharToMultiByte (CP_UTF8, 0, input.ptr, i, 
                                                            dst.ptr, dst.length, null, null);
                                   if (i is 0)
                                       error ();

                                   return i;
                                   }
                                }
                                }

                        }
                     else
                        {
                        /*******************************************************

                                Create a FileConduit on the provided 
                                FileDevice. 

                                This is strictly for adapting existing 
                                devices such as Stdout and friends

                        *******************************************************/

                        private this (FileDevice device)
                        {
                                super (device);
                        }
                        }
        }
}


/******************************************************************************

******************************************************************************/

static Console.Input    Cin;

/******************************************************************************

******************************************************************************/

static Console.Output   Cout, 
                        Cerr;

/******************************************************************************

******************************************************************************/

static this ()
{
        Cin  = new Console.Input  (new FileDevice (0, DeviceConduit.Access.Read));
        Cout = new Console.Output (new FileDevice (1, DeviceConduit.Access.Write));
        Cerr = new Console.Output (new FileDevice (2, DeviceConduit.Access.Write));
}
