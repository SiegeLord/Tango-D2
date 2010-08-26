/* GDC -- D front-end for GCC
   Copyright (C) 2004 David Friedman

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

module rt.compiler.gdc.gcc.threadsem;
private import tango.stdc.config;

version (GNU_Semaphore_POSIX)
{
    private import tango.stdc.posix.semaphore;
    struct Semaphore {
        sem_t sem;
        bool create() {  return sem_init(& sem, 0, 0) == 0; }
        void wait() { sem_wait(& sem); }
        void signal() { sem_post(& sem); }

    }
}
else version (GNU_Semaphore_Mach)
{
    // from std.c.mach.mach

    extern (C)
    {
        enum
        {
            SYNC_POLICY_FIFO            = 0x0,
            SYNC_POLICY_FIXED_PRIORITY  = 0x1,
            SYNC_POLICY_REVERSED        = 0x2,
            SYNC_POLICY_ORDER_MASK      = 0x3,
            SYNC_POLICY_LIFO            = (SYNC_POLICY_FIFO|SYNC_POLICY_REVERSED)
        }

        enum
        {
            KERN_SUCCESS                = 0
        }

        private alias uint  natural_t;      // uint on both 32- and 64-bit
        alias natural_t     semaphore_t;    // TODO: natural_t
        alias natural_t     task_t;         // TODO: natural_t
        alias natural_t     mach_port_t;    // TODO: natural_t
        alias int           kern_return_t;

        // this probably isn't stable
        mach_port_t         mach_task_self_;

        kern_return_t semaphore_create( task_t, semaphore_t*, int, int);
        kern_return_t semaphore_destroy( task_t, semaphore_t);
        kern_return_t semaphore_signal(semaphore_t);
        kern_return_t semaphore_wait(semaphore_t);
    }

    mach_port_t current_task() { return mach_task_self_; }

    struct Semaphore {
        semaphore_t sem;
        bool create() {
            return semaphore_create(current_task(), & sem,
                SYNC_POLICY_FIFO, 0) == KERN_SUCCESS; }
        void wait() { semaphore_wait(sem); }
        void signal() { semaphore_signal(sem); }
    }
}
else version (GNU_Sempahore_Pthreads)
{
    struct Semaphore {
        pthread_mutex_t lock;
        pthread_cond_t  cond;
        int count; // boehm-gc only calls lock once -- outside the loop
        bool create() {
            count = 0;
            return  pthread_mutex_init(& lock, null) == 0 &&
                pthread_cond_init(& cond, null) == 0;
        }
        void wait() {
            // boehm-gc only calls lock once -- outside the loop
            pthread_mutex_lock(& lock);
            if (--count < 0) {
                while (count < 0) { // shouldn't be needed
                    pthread_cond_wait(& cond, & lock);
                }
            }
            pthread_mutex_unlock(& lock);
        }
        void signal() {
            pthread_mutex_lock(& lock);
            if (++count >= 0) {
                pthread_cond_signal(& cond);
            }
            pthread_mutex_unlock(& lock);
        }
    }
}
else version (GNU_Semaphore_SysV)
{
    // TODO
}
