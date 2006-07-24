/**
 * The layout module exposes platform-specific routines for describing an
 * application's memory layout.
 *
 * Copyright: Copyright (C) 2005-2006 Sean Kelly.  All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Sean Kelly
 */
module layout;


private
{
    version( linux )
    {
        version = SimpleLibcStackEnd;

        version( SimpleLibcStackEnd )
        {
            extern (C) void* __libc_stack_end;
        }
    }
}


/**
 *
 */
extern (C) void* os_query_stackBottom()
{
    version( Win32 )
    {
        asm
        {
    	    naked;
    	    mov	EAX,FS:4;
    	    ret;
        }
    }
    else version( linux )
    {
        version( SimpleLibcStackEnd )
        {
            return __libc_stack_end;
        }
        else
        {
            // See discussion: http://autopackage.org/forums/viewtopic.php?t=22
	        static void** libc_stack_end;

	        if( libc_stack_end == libc_stack_end.init )
	        {
	            void* handle = dlopen( null, RTLD_NOW );
	            libc_stack_end = cast(void**) dlsym( handle, "__libc_stack_end" );
	            dlclose( handle );
	        }
	        return *libc_stack_end;
        }
    }
    else
    {
        static assert( false, "Operating system not supported." );
    }
}


/**
 *
 */
extern (C) void* os_query_stackTop()
{
    version( X86 )
    {
        asm
        {
            naked;
            mov EAX, ESP;
            ret;
        }
    }
    else
    {
	    static assert( false, "Architecture not supported." );
    }
}


private
{
    version( Win32 )
    {
        extern (C)
        {
            extern int _xi_a;	// &_xi_a just happens to be start of data segment
            extern int _edata;	// &_edata is start of BSS segment
            extern int _end;	// &_end is past end of BSS
        }
    }
    else version( linux )
    {
        extern (C) int _data;
        extern (C) int __data_start;
        extern (C) int _end;
        extern (C) int _data_start__;
        extern (C) int _data_end__;
        extern (C) int _bss_start__;
        extern (C) int _bss_end__;
        extern (C) int __fini_array_end;

	    alias __data_start  Data_Start;
	    alias _end          Data_End;
    }
}


/**
 *
 */
extern (C) void[] os_query_staticData()
{
    static void[] data;

    if( data !is null )
        return data;

    version( Win32 )
    {
        data = (cast(void*) &_xi_a)[0 .. cast(void*) &_end - cast(void*) &_xi_a];
    }
    else version( linux )
    {
        // Can't assume the input addresses are word-aligned
        static void* adjust_up( void* p )
        {
    	    const int S = (void *).sizeof;
    	    return p + ((S - (cast(uint)p & (S-1))) & (S-1)); // cast ok even if 64-bit
        }

        static void * adjust_down( void* p )
        {
    	    const int S = (void *).sizeof;
    	    return p - (cast(uint) p & (S-1));
        }

	    void* main_data_start = adjust_up( &Data_Start );
	    void* main_data_end   = adjust_down( &Data_End );

        data = main_data_start[0 .. main_data_end - main_data_start];
    }
    else
    {
        static assert( false, "Operating system not supported." );
    }
    return data;
}