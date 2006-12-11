/**
 * This module exposes functionality for inspecting and manipulating memory.
 *
 * Copyright: Copyright (C) 2005-2006 Digital Mars, www.digitalmars.com.
 *            All rights reserved.
 * License:
 *  This software is provided 'as-is', without any express or implied
 *  warranty. In no event will the authors be held liable for any damages
 *  arising from the use of this software.
 *
 *  Permission is granted to anyone to use this software for any purpose,
 *  including commercial applications, and to alter it and redistribute it
 *  freely, in both source and binary form, subject to the following
 *  restrictions:
 *
 *  o  The origin of this software must not be misrepresented; you must not
 *     claim that you wrote the original software. If you use this software
 *     in a product, an acknowledgment in the product documentation would be
 *     appreciated but is not required.
 *  o  Altered source versions must be plainly marked as such, and must not
 *     be misrepresented as being the original software.
 *  o  This notice may not be removed or altered from any source
 *     distribution.
 * Authors:   Walter Bright, Sean Kelly
 */
module memory;


private
{
    version( GC_Use_Stack_FreeBSD )
    {
        extern (C) int _d_gcc_gc_freebsd_stack(void**);
    }
    else version( GC_Use_Stack_GLibC )
    {
        extern (C) extern void* __libc_stack_end;
    }
}


public
{
    version( GC_Use_Stack_Guess )
    {
        // NOTE: This method of getting the stack base really stinks and should
        //       probably just be removed to force the implementer to sort out
        //       something a bit better for new systems.
        void* stackOriginGuess;
    }
}


/**
 *
 */
extern (C) void* cr_stackBottom()
{
    version( Win32 )
    {
        asm
        {
            naked;
            mov EAX,FS:4;
            ret;
        }
    }
    else version( GC_Use_Stack_GLibC )
    {
        return __libc_stack_end;
    }
    else version( GC_Use_Stack_Guess )
    {
        return stackOriginGuess;
    }
    else version( GC_Use_Stack_FreeBSD )
    {
        void* stack_origin;

        if( _d_gcc_gc_freebsd_stack(&stack_origin) )
            return stack_origin;
        else // No way to signal an error
            return null;
    }
    else version( GC_Use_Stack_Scan )
    {
        static assert( false );
    }
    else version( GC_Use_Stack_Fixed )
    {
        version( darwin )
            return cast(void*) 0xc0000000;
        else
            static assert( false );
    }
    else
    {
        static assert( false, "Operating system not supported." );
    }
}


/**
 *
 */
extern (C) void* cr_stackTop()
{
    version( D_InlineAsm_X86 )
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
        void*   ptr;
        return &ptr;
    }
}


private
{
    enum DataSegmentTracking
    {
        ExecutableOnly,
        LoadTimeLibrariesOnly,
        Dynamic
    }

    version( Win32 )
    {
        extern (C)
        {
            extern int _data_start__;
            extern int _bss_end__;
        }

        alias _data_start__ Data_Start;
        alias _bss_end__    Data_End;
    }
    else version( GC_Use_Data_Fixed )
    {
        extern (C)
        {
            extern int _data;
            extern int __data_start;
            extern int _end;
            extern int _data_start__;
            extern int _data_end__;
            extern int _bss_start__;
            extern int _bss_end__;
            extern int __fini_array_end;
        }

        /* %% Move all this to configure script to test if it actually works?
           --enable-gc-data-fixed=Mode,s1,e1,s2,e2
           .. the Mode can be a version instead of enum trick
        */

        version( aix )
        {
            alias _data Data_Start;
            alias _end  Data_End;

            enum FM
            {
                MinMax = 0,
                One    = 1,
                Two    = 0
            }
        }
        else version( cygwin )
        {
            alias _data_start__ Data_Start;
            alias _data_end__   Data_End;
            alias _bss_start__  Data_Start_2;
            alias _bss_end__    Data_End_2;

            enum FM
            {
                MinMax = 1,
                One    = 0,
                Two    = 0
            }
        }
        else version( freebsd )
        {
            // use '_etext' if '__fini_array_end' doesn't work
            /* There is a bunch of read-only data after .data and before .bss, but
               no linker symbols to find it.  Would have to set up a fault handler
               and scan... */

            alias __fini_array_end  Data_Start;
            alias _end              Data_End;

            enum FM
            {
                MinMax = 0,
                One    = 1,
                Two    = 0
            }
        }
        else version( linux )
        {
            alias __data_start  Data_Start;
            alias _end          Data_End;

            /* possible better way:
               [__data_start,_DYNAMIC) and [_edata/edata or __bss_start,_end/end)
               This doesn't really save much.. a better linker script is needed.
            */

            enum FM
            {
                MinMax = 0,
                One    = 1,
                Two    = 0
            }
        }
        else version( skyos )
        {
            alias _data_start__ Data_Start;
            alias _bss_end__    Data_End;

            enum FM
            {
                MinMax = 0,
                One    = 1,
                Two    = 0
            }
        }
    }
    else version( GC_Use_Data_Dyld )
    {
        extern (C) void _d_gcc_dyld_start(DataSegmentTracking mode);
    }
    else version( GC_Use_Data_Proc_Maps )
    {
        private import tango.stdc.stdlib;

        struct DataSeg
        {
            void* beg;
            void* end;
        }

        DataSeg* dataSegs;
    }

    alias void delegate( void*, void* ) scanFn;

    void* dataStart,  dataEnd;
    void* dataStart2, dataEnd2;
}


/**
 *
 */
extern (C) void cr_scanStaticData( scanFn scan )
{
    scan( dataStart,  dataEnd );
    scan( dataStart2, dataEnd2 );
}


void initStaticDataPtrs()
{
    // Can't assume the input addresses are word-aligned
    static void* adjust_up( void* p )
    {
        const int S = (void*).sizeof;
        return p + ((S - (cast(uint)p & (S-1))) & (S-1)); // cast ok even if 64-bit
    }

    static void * adjust_down( void* p )
    {
        const int S = (void*).sizeof;
        return p - (cast(uint) p & (S-1));
    }

    version( Win32 )
    {
        dataStart = adjust_up( &Data_Start );
        dataEnd   = adjust_down( &Data_End );
    }
    else version( GC_Use_Data_Dyld )
    {
        // TODO: fix this function
        _d_gcc_dyld_start( DataSegmentTracking.Dynamic );
    }
    else version( GC_Use_Data_Fixed )
    {
        static if( FM.One )
        {
            dataStart = adjust_up( &Data_Start );
            dataEnd   = adjust_down( &Data_End );
        }
        else static if( FM.Two )
        {
            dataStart  = adjust_up( &Data_Start );
            dataEnd    = adjust_down( &Data_End );

            dataStart2 = adjust_up( &Data_Start_2 );
            dataEnd2   = adjust_down( &Data_End_2 );
        }
        else static if( FM.MinMax )
        {
            dataStart = adjust_up( &Data_Start < &Data_Start_2 ? &Data_Start : &Data_Start_2 );
            dataEnd   = adjust_down( &Data_End > &Data_End_2 ? &Data_End : &Data_End_2 );
        }
    }
    else version( GC_Use_Data_Proc_Maps )
    {
        // TODO: fix this to store list of data regions
        // TODO: Exclude zero-mapped regions

        int   fd = open("/proc/self/maps", O_RDONLY);
        int   count; // %% need to configure ret for read..
        char  buf[2024];
        char* p;
        char* e;
        char* s;
        void* start;
        void* end;

        p = buf;
        if (fd != -1)
        {
            while ( (count = read(fd, p, buf.sizeof - (p - buf.ptr))) > 0 )
            {
                e = p + count;
                p = buf;
                while (true)
                {
                    s = p;
                    while (p < e && *p != '\n')
                        p++;
                    if (p < e)
                    {
                        // parse the entry in [s, p)
                        version( GNU_BitsPerPointer32 )
                        {
                            enum Ofs
                            {
                                Write_Prot = 19,
                                Start_Addr = 0,
                                End_Addr   = 9,
                                Addr_Len   = 8,
                            }
                        }
                        else version( GNU_BitsPerPointer64 )
                        {
                            enum Ofs
                            {
                                Write_Prot = 35,
                                Start_Addr = 0,
                                End_Addr   = 9,
                                Addr_Len   = 17,
                            }
                        }
                        else
                        {
                            static assert( false );
                        }

                        // %% this is wrong for 64-bit:
                        // uint   strtoul(char *,char **,int);

                        if( s[Ofs.Write_Prot] == 'w' )
                        {
                            s[Ofs.Start_Addr + Ofs.Addr_Len] = '\0';
                            s[Ofs.End_Addr + Ofs.Addr_Len] = '\0';
                            start = cast(void*) strtoul(s + Ofs.Start_Addr, null, 16);
                            end   = cast(void*) strtoul(s + Ofs.End_Addr, null, 16);

                            // 1. Exclude anything overlapping [dataStart, dataEnd)
                            // 2. Exclude stack
                            if ( ( !dataEnd ||
                                   !( dataStart >= start && dataEnd <= end ) ) &&
                                 !( &buf >= start && & buf < end ) )
                            {
                                // we already have static data from this region.  anything else
                                // is heap (%% check)
                                debug (ProcMaps) printf("Adding map range %p 0%p\n", start, end);
                                // TODO: add region here
                                static assert( false, "GC_Use_Data_Proc_Maps not supported." );
                                //addRange(start, end);
                            }
                        }
                        p++;
                    }
                    else
                    {
                        count = p - s;
                        memmove(buf, s, count);
                        p = buf.ptr + count;
                        break;
                    }
                }
            }
            close(fd);
        }
    }
    else
    {
        static assert( false, "Operating system not supported." );
    }
}
