
// Copyright (C) 2001-2004 by Digital Mars, www.digitalmars.com
// All Rights Reserved
// Written by Walter Bright

/*
 *  Modified by Sean Kelly <sean@f4.ca> for use with the Ares project.
 */

private import tango.stdc.posix.sys.mman;

/+
extern (C)
{
    // from <sys/mman.h>
    void* mmap(void* addr, uint len, int prot, int flags, int fd, uint offset);
    int munmap(void* addr, uint len);
    const void* MAP_FAILED = cast(void*)-1;

    // from <bits/mman.h>
    enum { PROT_NONE = 0, PROT_READ = 1, PROT_WRITE = 2, PROT_EXEC = 4 }
    enum { MAP_SHARED = 1, MAP_PRIVATE = 2, MAP_TYPE = 0x0F,
	   MAP_FIXED = 0x10, MAP_FILE = 0, MAP_ANON = 0x20 }
}
+/

extern (C)
{
    /* From <dlfcn.h>
     * See http://www.opengroup.org/onlinepubs/007908799/xsh/dlsym.html
     */

    const int RTLD_NOW = 0x00002;	// Correct for Red Hat 8

    void* dlopen(char* file, int mode);
    int   dlclose(void* handle);
    void* dlsym(void* handle, char* name);
    char* dlerror();
}

/***********************************
 * Map memory.
 */

void *os_mem_map(uint nbytes)
{   void *p;

    //errno = 0;
    p = mmap(null, nbytes, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
    return (p == MAP_FAILED) ? null : p;
}

/***********************************
 * Commit memory.
 * Returns:
 *	0	success
 *	!=0	failure
 */

int os_mem_commit(void *base, uint offset, uint nbytes)
{
    return 0;
}


/***********************************
 * Decommit memory.
 * Returns:
 *	0	success
 *	!=0	failure
 */

int os_mem_decommit(void *base, uint offset, uint nbytes)
{
    return 0;
}

/***********************************
 * Unmap memory allocated with os_mem_map().
 * Returns:
 *	0	success
 *	!=0	failure
 */

int os_mem_unmap(void *base, uint nbytes)
{
    return munmap(base, nbytes);
}