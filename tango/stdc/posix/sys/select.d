/**
 * D header file for POSIX.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */
module tango.stdc.posix.sys.select;

public import tango.stdc.posix.sys.types; // for time_t
public import tango.stdc.posix.signal;    // for sigset_t
public import tango.stdc.time;            // for timespec
public import tango.stdc.config;          // for c_long

extern (C):

//
// Required
//
/*
struct timeval
{
    time_t      tv_sec;
    suseconds_t tv_usec;
}

fd_set

void FD_CLR(int fd, fd_set* fdset);
int FD_ISSET(int fd, fd_set* fdset);
void FD_SET(int fd, fd_set* fdset);
void FD_ZERO(fd_set* fdset);

FD_SETSIZE

int  pselect(int, fd_set*, fd_set*, fd_set*, timespec*, sigset_t*);
int  select(int, fd_set*, fd_set*, fd_set*, timeval*);
*/

version( linux )
{
    struct timeval
    {
        time_t      tv_sec;
        suseconds_t tv_usec;
    }

    private
    {
        alias c_long __fd_mask;
        const auto   __NFDBITS = 8 * __fd_mask.sizeof;

        extern (D) int __FDELT( int d )
        {
            return d / __NFDBITS;
        }

        extern (D) int __FDMASK( int d )
        {
            return cast(__fd_mask) 1 << ( d % __NFDBITS );
        }
    }

    const auto FD_SETSIZE   = 1024;

    struct fd_set
    {
        __fd_mask[FD_SETSIZE / __NFDBITS] fds_bits;
    }

    extern (D) void FD_CLR( int fd, fd_set* fdset )
    {
        fdset.fds_bits[__FDELT( fd )] &= ~__FDMASK( fd );
    }

    extern (D) int  FD_ISSET( int fd, fd_set* fdset )
    {
        return fdset.fds_bits[__FDELT( fd )] & __FDMASK( fd );
    }

    extern (D) void FD_SET( int fd, fd_set* fdset )
    {
        fdset.fds_bits[__FDELT( fd )] |= __FDMASK( fd );
    }

    extern (D) void FD_ZERO( fd_set* fdset )
    {
        fdset.fds_bits[0 .. $] = 0;
    }

    /+
     + GNU ASM Implementation
     +
    # define __FD_ZERO(fdsp) \
      do {									      \
        int __d0, __d1;							      \
        __asm__ __volatile__ ("cld; rep; stosl"				      \
    			  : "=c" (__d0), "=D" (__d1)			      \
    			  : "a" (0), "0" (sizeof (fd_set)		      \
    					  / sizeof (__fd_mask)),	      \
    			    "1" (&__FDS_BITS (fdsp)[0])			      \
    			  : "memory");					      \
      } while (0)

    # define __FD_SET(fd, fdsp) \
      __asm__ __volatile__ ("btsl %1,%0"					      \
    			: "=m" (__FDS_BITS (fdsp)[__FDELT (fd)])	      \
    			: "r" (((int) (fd)) % __NFDBITS)		      \
    			: "cc","memory")
    # define __FD_CLR(fd, fdsp) \
      __asm__ __volatile__ ("btrl %1,%0"					      \
    			: "=m" (__FDS_BITS (fdsp)[__FDELT (fd)])	      \
    			: "r" (((int) (fd)) % __NFDBITS)		      \
    			: "cc","memory")
    # define __FD_ISSET(fd, fdsp) \
      (__extension__							      \
       ({register char __result;						      \
         __asm__ __volatile__ ("btl %1,%2 ; setcb %b0"			      \
    			   : "=q" (__result)				      \
    			   : "r" (((int) (fd)) % __NFDBITS),		      \
    			     "m" (__FDS_BITS (fdsp)[__FDELT (fd)])	      \
    			   : "cc");					      \
         __result; }))
     +/

    int pselect(int, fd_set*, fd_set*, fd_set*, timespec*, sigset_t*);
    int select(int, fd_set*, fd_set*, fd_set*, timeval*);
}