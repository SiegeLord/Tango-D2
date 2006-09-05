
// Copyright (C) 2001-2002 by Digital Mars
// All Rights Reserved
// www.digitalmars.com
// Written by Walter Bright

/*
 *  Modified by Sean Kelly <sean@f4.ca> for use with the Ares project.
 */

import tango.sys.windows.minwin;

alias int pthread_t;

/***********************************
 * Map memory.
 */

void *os_mem_map(uint nbytes)
{
    return VirtualAlloc(null, nbytes, MEM_RESERVE, PAGE_READWRITE);
}

/***********************************
 * Commit memory.
 * Returns:
 *      0       success
 *      !=0     failure
 */

int os_mem_commit(void *base, uint offset, uint nbytes)
{
    void *p;

    p = VirtualAlloc(base + offset, nbytes, MEM_COMMIT, PAGE_READWRITE);
    return (p == null);
}


/***********************************
 * Decommit memory.
 * Returns:
 *      0       success
 *      !=0     failure
 */

int os_mem_decommit(void *base, uint offset, uint nbytes)
{
    return VirtualFree(base + offset, nbytes, MEM_DECOMMIT) == 0;
}

/***********************************
 * Unmap memory allocated with os_mem_map().
 * Memory must have already been decommitted.
 * Returns:
 *      0       success
 *      !=0     failure
 */

int os_mem_unmap(void *base, uint nbytes)
{
    return VirtualFree(base, 0, MEM_RELEASE) == 0;
}


/********************************************
 */

pthread_t pthread_self()
{
    //printf("pthread_self() = %x\n", GetCurrentThreadId());
    return cast(pthread_t) GetCurrentThreadId();
}