/*******************************************************************************

        @file ICU.d
        
        Copyright (c) 2004 Kris Bell
        
        This software is provided 'as-is', without any express or implied
        warranty. In no event will the authors be held liable for damages
        of any kind arising from the use of this software.
        
        Permission is hereby granted to anyone to use this software for any 
        purpose, including commercial applications, and to alter it and/or 
        redistribute it freely, subject to the following restrictions:
        
        1. The origin of this software must not be misrepresented; you must 
           not claim that you wrote the original software. If you use this 
           software in a product, an acknowledgment within documentation of 
           said product would be appreciated but is not required.

        2. Altered source versions must be plainly marked as such, and must 
           not be misrepresented as being the original software.

        3. This notice may not be removed or altered from any distribution
           of the source.

        4. Derivative works are permitted, but they must carry this notice
           in full and credit the original source.


                        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


        @version        Initial version; October 2004   
                        Updated to ICU v3.2; March 2005

        @author         Kris 
                        John Reimer
                        Anders F Bjorklund (Darwin patches)


*******************************************************************************/

module mango.icu.ICU;

/*******************************************************************************

        Library version identifiers

*******************************************************************************/

version (ICU30)
        {
        private static const final char[] ICULib = "30";
        private static const final char[] ICUSig = "_3_0\0";
        }
     else
        {
        private static const final char[] ICULib = "32";
        private static const final char[] ICUSig = "_3_2\0";
        }

/*******************************************************************************

*******************************************************************************/

private static extern (C) uint strlen (char *s);
private static extern (C) uint wcslen (wchar *s);


/*******************************************************************************
        
        Some low-level routines to help bind the ICU C-API to D.

*******************************************************************************/

protected class ICU
{
        /***********************************************************************

                The library names to load within the target environment

        ***********************************************************************/

        version(Win32) 
        {
        protected static char[] icuuc = "icuuc"~ICULib~".dll";     
        protected static char[] icuin = "icuin"~ICULib~".dll";     
        }
         else 
            version (linux)
            {
            protected static char[] icuuc = "libicuuc.so."~ICULib;
            protected static char[] icuin = "libicui18n.so."~ICULib;
           }
            else 
               version (darwin) 
               {
               protected static char[] icuuc = "libicuuc.dylib."~ICULib;
               protected static char[] icuin = "libicui18n.dylib."~ICULib;
               }
                else
                   {
                   static assert (false);
                   }

        /***********************************************************************
        
                Use this for the primary argument-type to most ICU functions

        ***********************************************************************/

        protected typedef void* Handle;

        /***********************************************************************
        
                Parse-error filled in by several functions

        ***********************************************************************/

        public struct   ParseError 
                        {
                        int             line,
                                        offset;
                        wchar[16]       preContext,
                                        postContext;
                        }

        /***********************************************************************

                The binary form of a version on ICU APIs is an array of 
                four bytes        

        ***********************************************************************/

        public struct   Version
                        {
                        ubyte[4] info;
                        }

        /***********************************************************************
        
                ICU error codes (the ones which are referenced)

        ***********************************************************************/

        protected enum  Error:int 
                        {
                        OK, 
                        BufferOverflow=15
                        }

        /***********************************************************************
        
        ***********************************************************************/

        protected static final bool isError (Error e)
        {
                return e > 0;
        }

        /***********************************************************************
        
        ***********************************************************************/

        protected static final void exception (char[] msg)
        {
                throw new ICUException (msg);
        }

        /***********************************************************************
        
        ***********************************************************************/

        protected static final void testError (Error e, char[] msg)
        {
                if (e > 0)
                    exception (msg);
        }

        /***********************************************************************
        
        ***********************************************************************/

        protected static final char* toString (char[] string)
        {
                static char[] empty = "";

                if (! string.length)
                      return (string.ptr) ? empty.ptr : null;

//                if (* (&string[0] + string.length))
                   {
                   // Need to make a copy
                   char[] copy = new char [string.length + 1];
                   copy [0..string.length] = string;
                   copy [string.length] = 0;
                   string = copy;
                   }
                return string.ptr;
        }

        /***********************************************************************
        
        ***********************************************************************/

        protected static final wchar* toString (wchar[] string)
        {
                static wchar[] empty = "";

                if (! string.length)
                      return (string.ptr) ? empty.ptr : null;

//                if (* (&string[0] + string.length))
                   {
                   // Need to make a copy
                   wchar[] copy = new wchar [string.length + 1];
                   copy [0..string.length] = string;
                   copy [string.length] = 0;
                   string = copy;
                   }
                return string.ptr;
        }

        /***********************************************************************
        
        ***********************************************************************/

        protected static final uint length (char* s)
        {
                return strlen (s);
        }

        /***********************************************************************
        
        ***********************************************************************/

        protected static final uint length (wchar* s)
        {
                return wcslen (s);
        }

        /***********************************************************************
        
        ***********************************************************************/

        protected static final char[] toArray (char* s)
        {
                if (s)
                    return s[0..strlen (s)];
                return null;
        }

        /***********************************************************************
        
        ***********************************************************************/

        protected static final wchar[] toArray (wchar* s)
        {
                if (s)
                    return s[0..wcslen (s)];
                return null;   
        }
}


/*******************************************************************************

*******************************************************************************/

class ICUException : Exception
{
        /***********************************************************************
        
                Construct exception with the provided text string

        ***********************************************************************/

        this (char[] msg)
        {
                super (msg);
        }
}


/*******************************************************************************
        
        Function address loader for Win32

*******************************************************************************/

version (Win32)
{
        typedef void* HANDLE;
        extern (Windows) HANDLE LoadLibraryA (char*);
        extern (Windows) HANDLE GetProcAddress (HANDLE, char*);
        extern (Windows) void   FreeLibrary (HANDLE);

        /***********************************************************************

        ***********************************************************************/

        class FunctionLoader
        {
                /***************************************************************

                ***************************************************************/

                protected struct Bind
                {
                        void**  fnc;
                        char[]  name;      
                }

                /***************************************************************

                ***************************************************************/

                static final void* bind (char[] library, inout Bind[] targets)
                {
                        HANDLE lib = LoadLibraryA (ICU.toString(library));

                        foreach (Bind b; targets)
                                {
                                char[] name = b.name ~ ICUSig;
                                *b.fnc = GetProcAddress (lib, name.ptr);
                                if (*b.fnc)
                                   {}// printf ("bound '%.*s'\n", name);
                                else
                                   throw new Exception ("required " ~ name ~ " in library " ~ library);
                                }
                        return lib;
                }

                /***************************************************************

                ***************************************************************/

                static final void unbind (void* library)
                {       
                        version (CorrectedTeardown)
                                 FreeLibrary (cast(HANDLE) library);
                }
        }
}


/*******************************************************************************
        
        2004-11-26:  Added Linux shared library support -- John Reimer

*******************************************************************************/

else version (linux)
{
        //Tell build to link with dl library
        version(build) { pragma(link, dl); }

        // from include/bits/dlfcn.h on Linux
        const int RTLD_LAZY     = 0x00001;      // Lazy function call binding
        const int RTLD_NOW      = 0x00002;      // Immediate function call binding
        const int RTLD_NOLOAD   = 0x00004;      // no object load
        const int RTLD_DEEPBIND = 0x00008;
        const int RTLD_GLOBAL   = 0x00100;      // make object available to whole program    
        
        extern(C)
        {       
                void* dlopen(char* filename, int flag);
                char* dlerror();
                void* dlsym(void* handle, char* symbol);
                int   dlclose(void* handle);
        }
                
        class FunctionLoader
        {
                /***************************************************************

                ***************************************************************/

                protected struct Bind
                {
                        void**  fnc;
                        char[]  name;      
                }

                /***************************************************************

                ***************************************************************/

                static final void* bind (char[] library, inout Bind[] targets)
                {
                        static char[] errorInfo;
                        // printf("the library is %s\n", ICU.toString(library));
                        void* lib = dlopen(ICU.toString(library), RTLD_NOW);
                        
                        // clear the error buffer
                        dlerror();

                        foreach (Bind b; targets)
                        {
                                char[] name = b.name ~ ICUSig;
                                
                                *b.fnc = dlsym (lib, name);
                                if (*b.fnc)
                                   {}// printf ("bound '%.*s'\n", name);
                                else {
                                        // errorInfo = ICU.toArray(dlerror());
                                        // printf("%s", dlerror());
                                        throw new Exception ("required " ~ name ~ " in library " ~ library);
                                }
                        }
                        return lib;
                }

                /***************************************************************

                ***************************************************************/

                static final void unbind (void* library)
                {       
                        version (CorrectedTeardown)
                                {
                                if (! dlclose (library))
                                      throw new Exception ("close library failed\n");       
                                }
                }
        }
}


/*******************************************************************************
        
        2004-12-20:  Added Darwin shared library support -- afb

*******************************************************************************/

else version (darwin)
{
        // #include <mach-o/loader.h>

        struct mach_header
        {
            uint    magic;      /* mach magic number identifier */
            uint    cputype;    /* cpu specifier */
            uint    cpusubtype; /* machine specifier */
            uint    filetype;   /* type of file */
            uint    ncmds;      /* number of load commands */
            uint    sizeofcmds; /* the size of all the load commands */
            uint    flags;      /* flags */
        }
        
        /* Constant for the magic field of the mach_header */
        const uint MH_MAGIC = 0xfeedface;   // the mach magic number
        const uint MH_CIGAM = 0xcefaedfe;   // x86 variant

        // #include <mach-o/dyld.h>
        
        typedef void *NSObjectFileImage;
        
        typedef void *NSModule;
        
        typedef void *NSSymbol;

        enum // DYLD_BOOL: uint
        {
            FALSE,
            TRUE
        }
        alias uint DYLD_BOOL;

        enum // NSObjectFileImageReturnCode: uint
        {
            NSObjectFileImageFailure, /* for this a message is printed on stderr */
            NSObjectFileImageSuccess,
            NSObjectFileImageInappropriateFile,
            NSObjectFileImageArch,
            NSObjectFileImageFormat, /* for this a message is printed on stderr */
            NSObjectFileImageAccess
        }
        alias uint NSObjectFileImageReturnCode;
        
        enum // NSLinkEditErrors: uint
        {
            NSLinkEditFileAccessError,
            NSLinkEditFileFormatError,
            NSLinkEditMachResourceError,
            NSLinkEditUnixResourceError,
            NSLinkEditOtherError,
            NSLinkEditWarningError,
            NSLinkEditMultiplyDefinedError,
            NSLinkEditUndefinedError
        }
        alias uint NSLinkEditErrors;
        
        extern(C)
        {       
            NSObjectFileImageReturnCode NSCreateObjectFileImageFromFile(char *pathName, NSObjectFileImage* objectFileImage);
            DYLD_BOOL NSDestroyObjectFileImage(NSObjectFileImage objectFileImage);

            mach_header * NSAddImage(char *image_name, uint options);
            const uint NSADDIMAGE_OPTION_NONE = 0x0;
            const uint NSADDIMAGE_OPTION_RETURN_ON_ERROR = 0x1;
            const uint NSADDIMAGE_OPTION_WITH_SEARCHING = 0x2;
            const uint NSADDIMAGE_OPTION_RETURN_ONLY_IF_LOADED = 0x4;
            const uint NSADDIMAGE_OPTION_MATCH_FILENAME_BY_INSTALLNAME = 0x8;

            NSModule NSLinkModule(NSObjectFileImage objectFileImage, char* moduleName, uint options);
            const uint NSLINKMODULE_OPTION_NONE = 0x0;
            const uint NSLINKMODULE_OPTION_BINDNOW = 0x01;
            const uint NSLINKMODULE_OPTION_PRIVATE = 0x02;
            const uint NSLINKMODULE_OPTION_RETURN_ON_ERROR = 0x04;
            const uint NSLINKMODULE_OPTION_DONT_CALL_MOD_INIT_ROUTINES = 0x08;
            const uint NSLINKMODULE_OPTION_TRAILING_PHYS_NAME = 0x10;
            DYLD_BOOL NSUnLinkModule(NSModule module_, uint options);

            void NSLinkEditError(NSLinkEditErrors *c, int *errorNumber, char **fileName, char **errorString);

            DYLD_BOOL NSIsSymbolNameDefined(char *symbolName);
            DYLD_BOOL NSIsSymbolNameDefinedInImage(mach_header *image, char *symbolName);
            NSSymbol NSLookupAndBindSymbol(char *symbolName);
            NSSymbol NSLookupSymbolInModule(NSModule module_, char* symbolName);
            NSSymbol NSLookupSymbolInImage(mach_header *image, char *symbolName, uint options);
            const uint NSLOOKUPSYMBOLINIMAGE_OPTION_BIND = 0x0;
            const uint NSLOOKUPSYMBOLINIMAGE_OPTION_BIND_NOW = 0x1;
            const uint NSLOOKUPSYMBOLINIMAGE_OPTION_BIND_FULLY = 0x2;
            const uint NSLOOKUPSYMBOLINIMAGE_OPTION_RETURN_ON_ERROR = 0x4;

            void* NSAddressOfSymbol(NSSymbol symbol);
            char* NSNameOfSymbol(NSSymbol symbol);
        }
   
   
        class FunctionLoader
        {
                /***************************************************************

                ***************************************************************/

                protected struct Bind
                {
                        void**  fnc;
                        char[]  name;      
                }

                /***************************************************************

                ***************************************************************/

                private static NSModule open(char* filename)
                {
                        NSModule mod = null;
                        NSObjectFileImage fileImage = null;
                        debug printf("Trying to load: %s\n", filename);

                        NSObjectFileImageReturnCode returnCode =
                                NSCreateObjectFileImageFromFile(filename, &fileImage);
                        if(returnCode == NSObjectFileImageSuccess)
                        {
                                mod = NSLinkModule(fileImage,filename, 
                                        NSLINKMODULE_OPTION_RETURN_ON_ERROR |
                                        NSLINKMODULE_OPTION_PRIVATE |
                                        NSLINKMODULE_OPTION_BINDNOW);
                                NSDestroyObjectFileImage(fileImage);
                        }
                        else if(returnCode == NSObjectFileImageInappropriateFile)
                        {
                                NSDestroyObjectFileImage(fileImage);
                                /* Could be a dynamic library rather than a bundle */
                                mod = cast(NSModule) NSAddImage(filename,
                                        NSADDIMAGE_OPTION_RETURN_ON_ERROR);
                        }
                        else
                        {
                                debug printf("FileImage Failed: %d\n", returnCode);
                        }
                        return mod;
                }

                private static void* symbol(NSModule mod, char* name)
                {
                        NSSymbol symbol = null;
                        uint magic = (* cast(mach_header *) mod).magic;

                        if ( (mod == cast(NSModule) -1) && NSIsSymbolNameDefined(name))
                                /* Global context, use NSLookupAndBindSymbol */
                                symbol = NSLookupAndBindSymbol(name);
                        else if ( ( magic == MH_MAGIC || magic == MH_CIGAM ) &&
                                NSIsSymbolNameDefinedInImage(cast(mach_header *) mod, name))
                                symbol = NSLookupSymbolInImage(cast(mach_header *) mod, name,
                                        NSLOOKUPSYMBOLINIMAGE_OPTION_BIND |
                                        NSLOOKUPSYMBOLINIMAGE_OPTION_RETURN_ON_ERROR);
                        else
                                symbol = NSLookupSymbolInModule(mod, name);

                        return NSAddressOfSymbol(symbol);
                }

                static final void* bind (char[] library, inout Bind[] targets)
                {
                        static char[] errorInfo;

                        debug printf("the library is %s\n", ICU.toString(library));
                        
                        void* lib = null;
                        static char[][] usual_suspects = [ "", "/usr/local/lib/", "/usr/lib/",
                            /* Fink */ "/sw/lib/", /* DarwinPorts */ "/opt/local/lib/" ];
                        foreach (char[] prefix; usual_suspects)
                        {
                            lib = cast(void*) open(ICU.toString(prefix ~ library));
                            if (lib != null) break;
                        }
                        if (lib == null)
                        {
                            throw new Exception ("could not open library " ~ library);
                        }
                        
                        // clear the error buffer
                        // error();
                        
                        foreach (Bind b; targets)
                        {
                                // Note: all C functions have a underscore prefix in Mach-O symbols
                                char[] name = "_" ~ b.name ~ ICUSig;
                                 
                                *b.fnc = symbol(cast(NSModule) lib, name);
                                if (*b.fnc != null)
                                {
                                        debug printf ("bound '%.*s'\n", name);
                                }
                                else
                                {                             
                                        // errorInfo = ICU.toArray(error());
                                        throw new Exception ("required " ~ name ~ " in library " ~ library);
                                }
                        }
                        return lib;
                }

                /***************************************************************

                ***************************************************************/

                private static bool close(NSModule mod)
                {
                        uint magic = (* cast(mach_header *) mod).magic;
                        if ( magic == MH_MAGIC || magic == MH_CIGAM )
                        {
                                // Can not unlink dynamic libraries on Darwin
                                return true;
                        }

                        return (NSUnLinkModule(mod, 0) == TRUE);
                }

                static final void unbind (void* library)
                {       
                        version (CorrectedTeardown)
                                {
                                if (! close(cast(NSModule) library))
                                        throw new Exception ("close library failed\n");       
                                }
                }
        }
}

/*******************************************************************************
        
        unknown platform

*******************************************************************************/

else static assert(0); // need an implementation of FunctionLoader for this OS

