/**
 * D header file for POSIX.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */
module tango.stdc.posix.semaphore;

private import tango.stdc.posix.config;
private import tango.stdc.posix.time;
version( solaris ) {
	private import tango.stdc.stdint;
}


extern (C):

//
// Required
//
/*
sem_t
SEM_FAILED

int sem_close(sem_t*);
int sem_destroy(sem_t*);
int sem_getvalue(sem_t*, int*);
int sem_init(sem_t*, int, uint);
sem_t* sem_open(in char*, int, ...);
int sem_post(sem_t*);
int sem_trywait(sem_t*);
int sem_unlink(in char*);
int sem_wait(sem_t*);
*/

version( linux )
{
    private alias int __atomic_lock_t;

    private struct _pthread_fastlock
    {
      c_long            __status;
      __atomic_lock_t   __spinlock;
    }

    struct sem_t
    {
      _pthread_fastlock __sem_lock;
      int               __sem_value;
      void*             __sem_waiting;
    }

    const SEM_FAILED    = cast(sem_t*) null;
}
else version( darwin )
{
    alias int sem_t;

    const SEM_FAILED    = cast(sem_t*) null;
    // mach_port based semaphores (the working anonymous semaphores)
    alias uint mach_port_t;
    alias mach_port_t semaphore_t;
    alias mach_port_t thread_t;
    alias mach_port_t task_t;
    alias int kern_return_t;
    enum KERN_RETURN: kern_return_t{
        SUCCESS=0,
        ABORTED=14,
        OPERATION_TIMED_OUT=49
    }
    kern_return_t   semaphore_signal        (semaphore_t semaphore);
    kern_return_t   semaphore_signal_all    (semaphore_t semaphore);
    kern_return_t   semaphore_signal_thread (semaphore_t semaphore,
                                             thread_t thread);
    
    kern_return_t   semaphore_wait          (semaphore_t semaphore);
    kern_return_t   semaphore_timedwait     (semaphore_t semaphore, 
                     timespec wait_time);
    
    kern_return_t   semaphore_wait_signal   (semaphore_t wait_semaphore,
                                             semaphore_t signal_semaphore);
    
    kern_return_t semaphore_timedwait_signal(semaphore_t wait_semaphore,
                                                     semaphore_t signal_semaphore,
                                                     timespec wait_time);
    kern_return_t semaphore_destroy(task_t task,
                              semaphore_t semaphore);
    kern_return_t semaphore_create(task_t task,
                           semaphore_t *semaphore,
                           int policy,
                           int value);
   alias int sync_policy_t;
   
   task_t mach_task_self();// returns the task port of the current  thread
   /*
    *   These options define the wait ordering of the synchronizers
    */
   enum MACH_SYNC_POLICY{
       SYNC_POLICY_FIFO=0x0,
       SYNC_POLICY_FIXED_PRIORITY=0x1,
       SYNC_POLICY_REVERSED=0x2,
       SYNC_POLICY_ORDER_MASK=0x3,
       SYNC_POLICY_LIFO=(SYNC_POLICY_FIFO|SYNC_POLICY_REVERSED),
       SYNC_POLICY_MAX=0x7
   }

}
else version( FreeBSD )
{
    const uint SEM_MAGIC = 0x09fa4012;
    const SEM_USER = 0;

    alias void* sem_t;

    const SEM_FAILED = cast(sem_t*) null;
}
else version( solaris )
{
	struct sem_t
	{
		/* this structure must be the same as sema_t in <synch.h> */
		uint32_t	sem_count;	/* semaphore count */
		uint16_t	sem_type;
		uint16_t	sem_magic;
		upad64_t[3]	sem_pad1;	/* reserved for a mutex_t */
		upad64_t[2]	sem_pad2;	/* reserved for a cond_t */
	}
}

int sem_close(sem_t*);
int sem_destroy(sem_t*);
int sem_getvalue(sem_t*, int*);
int sem_init(sem_t*, int, uint);
sem_t* sem_open(in char*, int, ...);
int sem_post(sem_t*);
int sem_trywait(sem_t*);
int sem_unlink(in char*);
int sem_wait(sem_t*);

//
// Timeouts (TMO)
//
/*
int sem_timedwait(sem_t*, in timespec*);
*/

version( linux )
{
    int sem_timedwait(sem_t*, in timespec*);
}
else version( darwin )
{
    // int sem_timedwait(sem_t*, in timespec*); // not defined, use mach semaphores instead
}
else version( FreeBSD )
{
    int sem_timedwait(sem_t*, in timespec*);
}
else version( solaris )
{
    int sem_timedwait(sem_t*, in timespec*);
}
