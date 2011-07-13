/**
 * The thread module provides support for thread creation and management.
 *
 * If AtomicSuspendCount is used for speed reasons all signals are sent together.
 * When debugging gdb funnels all signals through one single handler, and if
 * the signals arrive quickly enough they will be coalesced in a single signal,
 * (discarding the second) thus it is possible to loose signals, which blocks
 * the program. Thus when debugging it is better to use the slower SuspendOneAtTime
 * version.
 *
 * Copyright: Copyright (C) 2005-2006 Sean Kelly, Fawzi.  All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Sean Kelly, Fawzi Mohamed
 */
module tango.core.Thread;

private import core.thread;

////////////////////////////////////////////////////////////////////////////////
// Thread
////////////////////////////////////////////////////////////////////////////////


/**
 * This class encapsulates all threading functionality for the D
 * programming language.  As thread manipulation is a required facility
 * for garbage collection, all user threads should derive from this
 * class, and instances of this class should never be explicitly deleted.
 * A new thread may be created using either derivation or composition, as
 * in the following example.
 *
 * Example:
 * -----------------------------------------------------------------------------
 * class DerivedThread : Thread
 * {
 *     this()
 *     {
 *         super( &run );
 *     }
 *
 * private :
 *     void run()
 *     {
 *         printf( "Derived thread running.\n" );
 *     }
 * }
 *
 * void threadFunc()
 * {
 *     printf( "Composed thread running.\n" );
 * }
 *
 * // create instances of each type
 * Thread derived = new DerivedThread();
 * Thread composed = new Thread( &threadFunc );
 *
 * // start both threads
 * derived.start();
 * composed.start();
 * -----------------------------------------------------------------------------
 */
class Thread : core.thread.Thread
{
	///////////////////////////////////////////////////////////////////////////
    // Initialization
    ///////////////////////////////////////////////////////////////////////////

    /**
     * Initializes a thread object which is associated with a static
     * D function.
     *
     * Params:
     * fn = The thread function.
     * sz = The stack size for this thread.
     *
     * In:
     * fn must not be null.
     */
    this( void function() fn, size_t sz = 0 ) {
			super(fn, sz);
	}
	
    /**
     * Initializes a thread object which is associated with a dynamic
     * D function.
     *
     * Params:
     * dg = The thread function.
     * sz = The stack size for this thread.
     *
     * In:
     * dg must not be null.
     */
    this( void delegate() dg, size_t sz = 0 ) {
			super(dg, sz);
	}
	
    /**
     * Suspends the calling thread for at least the supplied time, up to a
     * maximum of (uint.max - 1) milliseconds.
     *
     * Params:
     *  period = The minimum duration the calling thread should be suspended,
     *           in seconds.  Sub-second durations are specified as fractional
     *           values.
     *
     * In:
     *  period must be less than (uint.max - 1) milliseconds.
     *
     * Example:
     * -------------------------------------------------------------------------
     * Thread.sleep( 0.05 ); // sleep for 50 milliseconds
     * Thread.sleep( 5 );    // sleep for 5 seconds
     * -------------------------------------------------------------------------
     */
    static void sleep( double period ) {
			long lperiod = cast(long)(period * 10_000_000);
			Thread.sleep(lperiod);
	}
	
    /+
    /**
     * Suspends the calling thread for at least the supplied time, up to a
     * maximum of (uint.max - 1) milliseconds.
     *
     * Params:
     *  period = The minimum duration the calling thread should be suspended.
     *
     * In:
     *  period must be less than (uint.max - 1) milliseconds.
     *
     * Example:
     * -------------------------------------------------------------------------
     * Thread.sleep( TimeSpan.milliseconds( 50 ) ); // sleep for 50 milliseconds
     * Thread.sleep( TimeSpan.seconds( 5 ) );       // sleep for 5 seconds
     * -------------------------------------------------------------------------
     */
    static void sleep( TimeSpan period )
    in
    {
        assert( period.milliseconds < uint.max - 1 );
    }
    body
    {
        version( Win32 )
        {
            Sleep( cast(uint)( period.milliseconds ) );
        }
        else version( Posix )
        {
            timespec tin  = void;
            timespec tout = void;

            if( tin.tv_sec.max < period.seconds )
            {
                tin.tv_sec  = tin.tv_sec.max;
                tin.tv_nsec = 0;
            }
            else
            {
                tin.tv_sec  = cast(typeof(tin.tv_sec))  period.seconds;
                tin.tv_nsec = cast(typeof(tin.tv_nsec)) period.nanoseconds % 1_000_000_000;
            }

            while( true )
            {
                if( !nanosleep( &tin, &tout ) )
                    return;
                if( getErrno() != EINTR )
                    throw new ThreadException( "Unable to sleep for specified duration" );
                tin = tout;
            }
        }
    }


    /**
     * Suspends the calling thread for at least the supplied time, up to a
     * maximum of (uint.max - 1) milliseconds.
     *
     * Params:
     *  period = The minimum duration the calling thread should be suspended,
     *           in seconds.  Sub-second durations are specified as fractional
     *           values.  Please note that because period is a floating-point
     *           number, some accuracy may be lost for certain intervals.  For
     *           this reason, the TimeSpan overload is preferred in instances
     *           where an exact interval is required.
     *
     * In:
     *  period must be less than (uint.max - 1) milliseconds.
     *
     * Example:
     * -------------------------------------------------------------------------
     * Thread.sleep( 0.05 ); // sleep for 50 milliseconds
     * Thread.sleep( 5 );    // sleep for 5 seconds
     * -------------------------------------------------------------------------
     */
    static void sleep( double period )
    {
      sleep( TimeSpan.interval( period ) );
    }
    +/
}

/**
 * This class provides a cooperative concurrency mechanism integrated with the
 * threading and garbage collection functionality.  Calling a fiber may be
 * considered a blocking operation that returns when the fiber yields (via
 * Fiber.yield()).  Execution occurs within the context of the calling thread
 * so synchronization is not necessary to guarantee memory visibility so long
 * as the same thread calls the fiber each time.  Please note that there is no
 * requirement that a fiber be bound to one specific thread.  Rather, fibers
 * may be freely passed between threads so long as they are not currently
 * executing.  Like threads, a new fiber thread may be created using either
 * derivation or composition, as in the following example.
 *
 * Example:
 * ----------------------------------------------------------------------
 * class DerivedFiber : Fiber
 * {
 *     this()
 *     {
 *         super( &run );
 *     }
 *
 * private :
 *     void run()
 *     {
 *         printf( "Derived fiber running.\n" );
 *     }
 * }
 *
 * void fiberFunc()
 * {
 *     printf( "Composed fiber running.\n" );
 *     Fiber.yield();
 *     printf( "Composed fiber running.\n" );
 * }
 *
 * // create instances of each type
 * Fiber derived = new DerivedFiber();
 * Fiber composed = new Fiber( &fiberFunc );
 *
 * // call both fibers once
 * derived.call();
 * composed.call();
 * printf( "Execution returned to calling context.\n" );
 * composed.call();
 *
 * // since each fiber has run to completion, each should have state TERM
 * assert( derived.state == Fiber.State.TERM );
 * assert( composed.state == Fiber.State.TERM );
 * ----------------------------------------------------------------------
 *
 * Authors: Based on a design by Mikola Lysenko.
 */

class Fiber : core.thread.Fiber
{
   
}
