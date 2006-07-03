/**
 * D header file for C99.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: ISO/IEC 9899:1999 (E)
 */
module tango.stdc.signal;

version( Posix ) { unittest {} }

extern (C):

// this should be volatile
alias int sig_atomic_t;

private alias void function(int) sigfn_t;

version( Posix )
{
    const auto SIG_ERR  = cast(sigfn_t) -1;
    const auto SIG_DFL  = cast(sigfn_t) 0;
    const auto SIG_IGN  = cast(sigfn_t) 1;

    // standard C signals
    const auto SIGABRT  = 6;  // Abnormal termination
    const auto SIGFPE   = 8;  // Floating-point error
    const auto SIGILL   = 4;  // Illegal hardware instruction
    const auto SIGINT   = 2;  // Terminal interrupt character
    const auto SIGSEGV  = 11; // Invalid memory reference
    const auto SIGTERM  = 15; // Termination
}
else
{
    const auto SIG_ERR  = cast(sigfn_t) -1;
    const auto SIG_DFL  = cast(sigfn_t) 0;
    const auto SIG_IGN  = cast(sigfn_t) 1;

    // standard C signals
    const auto SIGABRT  = 22; // Abnormal termination
    const auto SIGFPE   = 8;  // Floating-point error
    const auto SIGILL   = 4;  // Illegal hardware instruction
    const auto SIGINT   = 2;  // Terminal interrupt character
    const auto SIGSEGV  = 11; // Invalid memory reference
    const auto SIGTERM  = 15; // Termination
}

sigfn_t signal(int sig, sigfn_t func);
int     raise(int sig);