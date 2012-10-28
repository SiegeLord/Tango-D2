/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Feb 2005: Initial release
                        Nov 2005: Heavily revised for unicode
                        Dec 2006: Outback release

        author:         Kris

*******************************************************************************/

module tango.io.Console;

private import  tango.sys.Common;

private import  tango.io.device.Device,
                tango.io.stream.Buffered;

version (Posix)
         private import tango.stdc.posix.unistd;  // needed for isatty()

/*******************************************************************************

        Low-level console IO support.

        Note that for a while this was templated for each of char, wchar,
        and dchar. It became clear after some usage that the console is
        more useful if it sticks to UTF8 only. See Console.Conduit below
        for details.

        Redirecting the standard IO handles (via a shell) operates as one
        would expect, though the redirected content should likely restrict
        itself to UTF8.

*******************************************************************************/

struct Console
{
        version (Win32)
                 __gshared immutable immutable(char)[] Eol = "\r\n";
        else
                 __gshared immutable immutable(char)[] Eol = "\n";


        /**********************************************************************

                Model console input as a buffer. Note that we read UTF8
                only.

        **********************************************************************/

        class Input
        {
                private Bin     buffer;
                private bool    redirect;

                public alias    copyln get;

                /**************************************************************

                        Attach console input to the provided device.

                **************************************************************/

                private this (Conduit conduit, bool redirected)
                {
                        redirect = redirected;
                        buffer = new Bin (conduit);
                }

                /**************************************************************

                        Return the next line available from the console,
                        or null when there is nothing available. The value
                        returned is a duplicate of the buffer content (it
                        has .dup applied).

                        Each line ending is removed unless parameter raw is
                        set to true.

                **************************************************************/

                final char[] copyln (bool raw = false)
                {
                        char[] line;

                        return readln (line, raw) ? line.dup : null;
                }

                /**************************************************************

                        Retreive a line of text from the console and map
                        it to the given argument. The input is sliced,
                        not copied, so use .dup appropriately. Each line
                        ending is removed unless parameter raw is set to
                        true.

                        Returns false when there is no more input.

                **************************************************************/

                final bool readln (ref char[] content, bool raw=false)
                {
                        size_t line (const(void)[] input)
                        {
                                auto text = cast(const(char[])) input;
                                foreach (i, c; text)
                                         if (c is '\n')
                                            {
                                            auto j = i;
                                            if (raw)
                                                ++j;
                                            else
                                               if (j && (text[j-1] is '\r'))
                                                   --j;
                                            content = cast(char[])text [0 .. j];
                                            return i+1;
                                            }
                                return IConduit.Eof;
                        }

                        // get next line, return true
                        if (buffer.next (&line))
                            return true;

                        // assign trailing content and return false
                        content = cast(char[]) buffer.slice (buffer.readable());
                        return false;
                }

                /**************************************************************

                        Return the associated stream.

                **************************************************************/

                @property final InputStream stream ()
                {
                        return buffer;
                }

                /**************************************************************

                        Is this device redirected?

                        Returns:
                        True if redirected, false otherwise.

                        Remarks:
                        Reflects the console redirection status from when
                        this module was instantiated.

                **************************************************************/

                @property final bool redirected ()
                {
                        return redirect;
                }

                /**************************************************************

                        Set redirection state to the provided boolean.

                        Remarks:
                        Configure the console redirection status, where
                        a redirected console is more efficient (dictates
                        whether newline() performs automatic flushing or
                        not.)

                **************************************************************/

                @property final Input redirected (bool yes)
                {
                         redirect = yes;
                         return this;
                }

                /**************************************************************

                        Returns the configured source

                        Remarks:
                        Provides access to the underlying mechanism for
                        console input. Use this to retain prior state
                        when temporarily switching inputs.

                **************************************************************/

                @property final InputStream input ()
                {
                        return buffer.input;
                }

                /**************************************************************

                        Divert input to an alternate source.

                **************************************************************/

                @property final Input input (InputStream source)
                {
                        buffer.input = source;
                        return this;
                }
        }


        /**********************************************************************

                Console output accepts UTF8 only.

        **********************************************************************/

        class Output
        {
                private Bout    buffer;
                private bool    redirect;

                public  alias   append opCall;
                public  alias   flush  opCall;

                /**************************************************************

                        Attach console output to the provided device.

                **************************************************************/

                private this (Conduit conduit, bool redirected)
                {
                        redirect = redirected;
                        buffer = new Bout (conduit);
                }

                /**************************************************************

                        Append to the console. We accept UTF8 only, so
                        all other encodings should be handled via some
                        higher level API.

                **************************************************************/

                final Output append (const(char[]) x)
                {
                        buffer.append (x.ptr, x.length);
                        return this;
                }

                /**************************************************************

                        Append content.

                        Params:
                        other = An object with a useful toString() method.

                        Returns:
                        Returns a chaining reference if all content was
                        written. Throws an IOException indicating Eof or
                        Eob if not.

                        Remarks:
                        Append the result of other.toString() to the console.

                **************************************************************/

                final Output append (Object other)        
                {           
                        return append (other.toString());
                }

                /**************************************************************

                        Append a newline and flush the console buffer. If
                        the output is redirected, flushing does not occur
                        automatically.

                        Returns:
                        Returns a chaining reference if content was written.
                        Throws an IOException indicating Eof or Eob if not.

                        Remarks:
                        Emit a newline into the buffer, and autoflush the
                        current buffer content for an interactive console.
                        Redirected consoles do not flush automatically on
                        a newline.

                **************************************************************/

                @property final Output newline ()
                {
                        buffer.append (Eol);
                        if (redirect is false)
                            buffer.flush();

                        return this;
                }

                /**************************************************************

                        Explicitly flush console output.

                        Returns:
                        Returns a chaining reference if content was written.
                        Throws an IOException indicating Eof or Eob if not.

                        Remarks:
                        Flushes the console buffer to attached conduit.

                **************************************************************/

                final Output flush ()
                {
                        buffer.flush();
                        return this;
                }

                /**************************************************************

                        Return the associated stream.

                **************************************************************/

                @property final OutputStream stream ()
                {
                        return buffer;
                }

                /**************************************************************

                        Is this device redirected?

                        Returns:
                        True if redirected, false otherwise.

                        Remarks:
                        Reflects the console redirection status.

                **************************************************************/

                @property final bool redirected ()
                {
                        return redirect;
                }

                /**************************************************************

                        Set redirection state to the provided boolean.

                        Remarks:
                        Configure the console redirection status, where
                        a redirected console is more efficient (dictates
                        whether newline() performs automatic flushing or
                        not.)

                **************************************************************/

                @property final Output redirected (bool yes)
                {
                         redirect = yes;
                         return this;
                }

                /**************************************************************

                        Returns the configured output sink.

                        Remarks:
                        Provides access to the underlying mechanism for
                        console output. Use this to retain prior state
                        when temporarily switching outputs.

                **************************************************************/

                @property final OutputStream output ()
                {
                        return buffer.output;
                }

                /**************************************************************

                        Divert output to an alternate sink.

                **************************************************************/

                @property final Output output (OutputStream sink)
                {
                        buffer.output = sink;
                        return this;
                }
        }


        /***********************************************************************

                Conduit for specifically handling the console devices. This
                takes care of certain implementation details on the Win32
                platform.

                Note that the console is fixed at UTF8 for both linux and
                Win32. The latter is actually UTF16 native, but it's just
                too much hassle for a developer to handle the distinction
                when it really should be a no-brainer. In particular, the
                Win32 console functions don't work with redirection. This
                causes additional difficulties that can be ameliorated by
                asserting console I/O is always UTF8, in all modes.

        ***********************************************************************/

        class Conduit : Device
        {
                private bool redirected = false;

                /***********************************************************************

                        Return the name of this conduit.

                ***********************************************************************/

                override immutable(char)[] toString()
                {
                        return "<console>";
                }

                /***************************************************************

                        Windows-specific code.

                ***************************************************************/

                version (Win32)
                        {
                        private wchar[] input;
                        private wchar[] output;

                        /*******************************************************

                                Associate this device with a given handle.

                                This is strictly for adapting existing
                                devices such as Stdout and friends.

                        *******************************************************/

                        this (size_t handle)
                        {
                                input = new wchar [1024 * 1];
                                output = new wchar [1024 * 1];
                                reopen (handle);
                        }

                        /*******************************************************

                                Gain access to the standard IO handles.

                        *******************************************************/

                        private void reopen (size_t handle_)
                        {
                                __gshared immutable DWORD[] id = [
                                                                 cast(DWORD) -10,
                                                                 cast(DWORD) -11,
                                                                 cast(DWORD) -12
                                                                 ];
                                __gshared immutable char[][] f = [
                                                                 "CONIN$\0",
                                                                 "CONOUT$\0",
                                                                 "CONOUT$\0"
                                                                 ];

                                assert (handle_ < 3);
                                io.handle = GetStdHandle (id[handle_]);
                                if (io.handle is null || io.handle is INVALID_HANDLE_VALUE)
                                    io.handle = CreateFileA ( cast(PCHAR) f[handle_].ptr,
                                                GENERIC_READ | GENERIC_WRITE,
                                                FILE_SHARE_READ | FILE_SHARE_WRITE,
                                                null, OPEN_EXISTING, 0, cast(HANDLE) 0);

                                // allow invalid handles to remain, since it
                                // may be patched later in some special cases
                                if (io.handle != INVALID_HANDLE_VALUE)
                                   {
                                   DWORD mode;
                                   // are we redirecting? Note that we cannot
                                   // use the 'appending' mode triggered via
                                   // setting overlapped.Offset to -1, so we
                                   // just track the byte-count instead
                                   if (! GetConsoleMode (io.handle, &mode))
                                         redirected = io.track = true;
                                   }
                        }

                        /*******************************************************

                                Write a chunk of bytes to the console from
                                the provided array.

                        *******************************************************/

                        version (Win32SansUnicode)
                                {}
                             else
                                {
                                override size_t write (const(void)[] src)
                                {
                                if (redirected)
                                    return super.write (src);
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
                                   i = MultiByteToWideChar (CP_UTF8, 0, cast(PCHAR) src.ptr, i,
                                                            output.ptr, output.length);

                                   // flush produced output
                                   for (wchar* p=output.ptr, end=output.ptr+i; p < end; p+=i)
                                       {
                                       const int MAX = 16 * 1024;

                                       // avoid console limitation of 64KB
                                       DWORD len = end - p;
                                       if (len > MAX)
                                          {
                                          len = MAX;
                                          // check for trailing surrogate ...
                                          if ((p[len-1] & 0xfc00) is 0xdc00)
                                               --len;
                                          }
                                       if (! WriteConsoleW (io.handle, p, len, &i, null))
                                             error();
                                       }
                                   return src.length;
                                   }
                                }
                                }

                        /*******************************************************

                                Read a chunk of bytes from the console into
                                the provided array.

                        *******************************************************/

                        version (Win32SansUnicode)
                                {}
                             else
                                {
                                protected override size_t read (void[] dst)
                                {
                                if (redirected)
                                    return super.read (dst);
                                else
                                   {
                                   DWORD i = dst.length / 4;

                                   assert (i);

                                   if (i > input.length)
                                       i = input.length;

                                   // read a chunk of wchars from the console
                                   if (! ReadConsoleW (io.handle, input.ptr, i, &i, null))
                                         error();

                                   // no input ~ go home
                                   if (i is 0)
                                       return Eof;

                                   // translate to utf8, directly into dst
                                   i = WideCharToMultiByte (CP_UTF8, 0, input.ptr, i,
                                                            cast(PCHAR) dst.ptr, dst.length, null, null);
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

                                Associate this device with a given handle.

                                This is strictly for adapting existing
                                devices such as Stdout and friends.

                        *******************************************************/

                        private this (size_t handle)
                        {
                                this.handle = cast(Handle) handle;
                                redirected = (isatty(cast(int)handle) is 0);
                        }
                        }
        }
}


/******************************************************************************

        Globals representing Console IO.

******************************************************************************/

static __gshared Console.Input    Cin;  /// The standard input stream.
static __gshared Console.Output   Cout; /// The standard output stream.
static __gshared Console.Output   Cerr; /// The standard error stream.


/******************************************************************************

        Instantiate Console access.

******************************************************************************/

shared static this ()
{
        auto conduit = new Console.Conduit (0);
        Cin  = new Console.Input (conduit, conduit.redirected);

        conduit = new Console.Conduit (1);
        Cout = new Console.Output (conduit, conduit.redirected);

        conduit = new Console.Conduit (2);
        Cerr = new Console.Output (conduit, conduit.redirected);
}

/******************************************************************************

        Flush outputs before we exit.

        (Good idea from Frits Van Bommel.)

******************************************************************************/

static ~this()
{
   synchronized (Cout.stream)
        Cout.flush();

   synchronized (Cerr.stream)
        Cerr.flush();
}


/******************************************************************************

******************************************************************************/

debug (Console)
{
        void main()
        {
            Cout ("hello world").newline;
        }
}
