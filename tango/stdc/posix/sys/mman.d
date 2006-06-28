/**
 * D header file for POSIX.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */
module tango.stdc.posix.sys.mman;

public import tango.stdc.stddef; // for size_t
public import tango.stdc.posix.sys.types; // for off_t, mode_t

extern (C):

//
// Advisory Information (ADV)
//
/*
int posix_madvise(void*, size_t, int);
*/

//
// Advisory Information and either Memory Mapped Files or Shared Memory Objects (MC1)
//
/*
POSIX_MADV_NORMAL
POSIX_MADV_SEQUENTIAL
POSIX_MADV_RANDOM
POSIX_MADV_WILLNEED
POSIX_MADV_DONTNEED
*/

version( darwin )
{
    const auto POSIX_MADV_NORMAL        = 0;
    const auto POSIX_MADV_RANDOM        = 1;
    const auto POSIX_MADV_SEQUENTIAL    = 2;
    const auto POSIX_MADV_WILLNEED      = 3;
    const auto POSIX_MADV_DONTNEED      = 4;
}

//
// Memory Mapped Files, Shared Memory Objects, or Memory Protection (MC2)
//
/*
PROT_READ
PROT_WRITE
PROT_EXEC
PROT_NONE
*/

version( linux )
{
    const auto PROT_NONE    = 0x0;
    const auto PROT_READ    = 0x1;
    const auto PROT_WRITE   = 0x2;
    const auto PROT_EXEC    = 0x4;
}
else version( darwin )
{
    const auto PROT_NONE    = 0x00;
    const auto PROT_READ    = 0x01;
    const auto PROT_WRITE   = 0x02;
    const auto PROT_EXEC    = 0x04;
}

//
// Memory Mapped Files, Shared Memory Objects, or Typed Memory Objects (MC3)
//
/*
void* mmap(void*, size_t, int, int, int, off_t);
int munmap(void*, size_t);
*/

version( linux )
{
    void* mmap(void*, size_t, int, int, int, off_t);
    int   munmap(void*, size_t);
}
else version( darwin )
{
    void* mmap(void*, size_t, int, int, int, off_t);
    int   munmap(void*, size_t);
}

//
// Memory Mapped Files (MF)
//
/*
MAP_SHARED (MF|SHM)
MAP_PRIVATE (MF|SHM)
MAP_FIXED  (MF|SHM)
MAP_FAILED (MF|SHM)

MS_ASYNC (MF|SIO)
MS_SYNC (MF|SIO)
MS_INVALIDATE (MF|SIO)

int msync(void*, size_t, int); (MF|SIO)
*/

version( linux )
{
    const auto MAP_SHARED   = 0x01;
    const auto MAP_PRIVATE  = 0x02;
    const auto MAP_FIXED    = 0x10;
    const auto MAP_ANON     = 0x20; // NOTE: this is a nonstandard extension

    const auto MAP_FAILED  = cast(void*) -1;

    enum
    {
        MS_ASYNC      = 1,
        MS_SYNC       = 4,
        MS_INVALIDATE = 2
    }

    int msync(void*, size_t, int);
}
else version( darwin )
{
    const auto MAP_SHARED   = 0x0001;
    const auto MAP_PRIVATE  = 0x0002;
    const auto MAP_FIXED    = 0x0010;

    const auto MAP_FAILED = cast(void*)-1;

    const auto MS_ASYNC         = 0x0001;
    const auto MS_INVALIDATE    = 0x0002;
    const auto MS_SYNC          = 0x0010;
}

//
// Process Memory Locking (ML)
//
/*
MCL_CURRENT
MCL_FUTURE

int mlockall(int);
int munlockall();
*/

version( darwin )
{
    const auto MCL_CURRENT = 0x0001;
    const auto MCL_FUTURE  = 0x0002;

    int mlockall(int);
    int munlockall();
}

//
// Range Memory Locking (MLR)
//
/*
int mlock(void*, size_t);
int munlock(void*, size_t);
*/

version( darwin )
{
    int mlock(void*, size_t);
    int munlock(void*, size_t);
}

//
// Memory Protection (MPR)
//
/*
int mprotect(void*, size_t, int);
*/

version( darwin )
{
    int mprotect(void*, size_t, int);
}

//
// Shared Memory Objects (SHM)
//
/*
int shm_open(char*, int, mode_t);
int shm_unlink(char*);
*/

version( linux )
{

}
else version( darwin )
{
    int shm_open(char*, int, mode_t);
    int shm_unlink(char*);
}

//
// Typed Memory Objects (TYM)
//
/*
POSIX_TYPED_MEM_ALLOCATE
POSIX_TYPED_MEM_ALLOCATE_CONTIG
POSIX_TYPED_MEM_MAP_ALLOCATABLE

struct posix_typed_mem_info
{
    size_t posix_tmi_length;
}

int posix_mem_offset(void*, size_t, off_t *, size_t *, int *);
int posix_typed_mem_get_info(int, struct posix_typed_mem_info *);
int posix_typed_mem_open(char*, int, int);
*/