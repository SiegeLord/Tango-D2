/**
 * D header file for POSIX.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */
module tango.stdc.posix.sys.wait;

private import tango.stdc.posix.config;
public import tango.stdc.posix.sys.types; // for id_t, pid_t
public import tango.stdc.posix.signal;    // for siginfo_t (XSI)
//public import tango.stdc.posix.resource; // for rusage (XSI)

extern (C):

//
// Required
//
/*
WNOHANG
WUNTRACED

WEXITSTATUS
WIFCONTINUED
WIFEXITED
WIFSIGNALED
WIFSTOPPED
WSTOPSIG
WTERMSIG

pid_t wait(int*);
pid_t waitpid(pid_t, int*, int);
*/

version( linux )
{
    const WNOHANG       = 1;
    const WUNTRACED     = 2;

    private
    {
        const __W_CONTINUED = 0xFFFF;

        extern (D) int __WTERMSIG( int status ) { return status & 0x7F; }
    }

    //
    // NOTE: These macros assume __USE_BSD is not defined in the relevant
    //       C headers as the parameter definition there is different and
    //       much more complicated.
    //
    extern (D) int  WEXITSTATUS( int status )  { return ( status & 0xFF00 ) >> 8;   }
    extern (D) int  WIFCONTINUED( int status ) { return status == __W_CONTINUED;    }
    extern (D) bool WIFEXITED( int status )    { return __WTERMSIG( status ) == 0;  }
    extern (D) bool WIFSIGNALED( int status )
    {
        return ( cast(byte) ( ( status & 0x7F ) + 1 ) >> 1 ) > 0;
    }
    extern (D) bool WIFSTOPPED( int status )   { return ( status & 0xFF ) == 0x7F;  }
    extern (D) int  WSTOPSIG( int status )     { return WEXITSTATUS( status );      }
    extern (D) int  WTERMSIG( int status )     { return status & 0x7F;              }
}
else version( darwin )
{
    const WNOHANG       = 1;
    const WUNTRACED     = 2;

    private
    {
        const _WSTOPPED = 0177;
    }

    extern (D) int _WSTATUS(int status)         { return (status & 0177);           }
    extern (D) int  WEXITSTATUS( int status )   { return (status >> 8);             }
    extern (D) int  WIFCONTINUED( int status )  { return status == 0x13;            }
    extern (D) bool WIFEXITED( int status )     { return _WSTATUS(status) == 0;     }
    extern (D) bool WIFSIGNALED( int status )
    {
        return _WSTATUS( status ) != _WSTOPPED && _WSTATUS( status ) != 0;
    }
    extern (D) bool WIFSTOPPED( int status )   { return _WSTATUS( status ) == _WSTOPPED; }
    extern (D) int  WSTOPSIG( int status )     { return status >> 8;                     }
    extern (D) int  WTERMSIG( int status )     { return _WSTATUS( status );              }
}
else version( freebsd )
{
    const WNOHANG       = 1;
    const WUNTRACED     = 2;
	const WCONTINUED	= 4;

    private
    {
        const _WSTOPPED = 0177;
    }

    extern (D) int _WSTATUS(int status)         { return (status & 0177);           }
    extern (D) int  WEXITSTATUS( int status )   { return (status >> 8);             }
    extern (D) int  WIFCONTINUED( int status )  { return status == 0x13;            }
    extern (D) bool WIFEXITED( int status )     { return _WSTATUS(status) == 0;     }
    extern (D) bool WIFSIGNALED( int status )
    {
        return _WSTATUS( status ) != _WSTOPPED && _WSTATUS( status ) != 0;
    }
    extern (D) bool WIFSTOPPED( int status )   { return _WSTATUS( status ) == _WSTOPPED; }
    extern (D) int  WSTOPSIG( int status )     { return status >> 8;                     }
    extern (D) int  WTERMSIG( int status )     { return _WSTATUS( status );              }
}
else version( solaris )
{	
	const WCONTFLG		= 0177777;
	
    const WNOHANG       = 0100;
    const WUNTRACED     = 0004;
	const WCONTINUED	= 0010;
	
	extern (D) int  WWORD( int status )			{ return (status & 0177777);			}
    extern (D) int  WEXITSTATUS( int status )   { return (status >> 8) & 0xFF;			}
    extern (D) int  WIFCONTINUED( int status )  { return WWORD(status) == WCONTFLG;		}
    extern (D) bool WIFEXITED( int status )     { return (status & 0xFF) == 0;			}
    extern (D) bool WIFSIGNALED( int status )	{ return (status & 0xFF) > 0 && (status & 0xFF00) == 0; }
    extern (D) bool WIFSTOPPED( int status )	{ return (status & 0xFF) == 0177 && (status & 0xFF00) != 0; }
    extern (D) int  WSTOPSIG( int status )		{ return (status >> 8) & 0xFF;			}
    extern (D) int  WTERMSIG( int status )		{ return status & 0x7F;					}
}
else
{
    static assert( false );
}

pid_t wait(int*);
pid_t waitpid(pid_t, int*, int);

//
// XOpen (XSI)
//
/*
WEXITED
WSTOPPED
WCONTINUED
WNOHANG
WNOWAIT

enum idtype_t
{
    P_ALL,
    P_PID,
    P_PGID
}

int waitid(idtype_t, id_t, siginfo_t*, int);
*/
