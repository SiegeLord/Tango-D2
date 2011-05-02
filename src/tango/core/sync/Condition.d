/**
 * The condition module provides a primitive for synchronized condition
 * checking.
 *
 * Copyright: Copyright (C) 2005-2006 Sean Kelly.  All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Author:    Sean Kelly
 */
module tango.core.sync.Condition;


public import tango.core.Exception : SyncException;
public import tango.core.sync.Mutex;

version( Win32 )
{
    private import tango.core.sync.Semaphore;
    private import tango.sys.win32.UserGdi;
}
else version( Posix )
{
    private import tango.core.sync.Config;
    private import tango.stdc.errno;
    private import tango.stdc.posix.pthread;
    private import tango.stdc.posix.time;
}


////////////////////////////////////////////////////////////////////////////////
// Condition
//
// void wait();
// void notify();
// void notifyAll();
////////////////////////////////////////////////////////////////////////////////


/**
 * This class represents a condition variable as concieved by C.A.R. Hoare.  As
 * per Mesa type monitors however, "signal" has been replaced with "notify" to
 * indicate that control is not transferred to the waiter when a notification
 * is sent.
 */
class Condition
{
    ////////////////////////////////////////////////////////////////////////////
    // Initialization
    ////////////////////////////////////////////////////////////////////////////


    /**
     * Initializes a condition object which is associated with the supplied
     * mutex object.
     *
     * Params:
     *  m = The mutex with which this condition will be associated.
     *
     * Throws:
     *  SyncException on error.
     */
    this( Mutex m )
    {
        version( Win32 )
        {
            m_blockLock = CreateSemaphoreA( null, 1, 1, null );
            if( m_blockLock == m_blockLock.init )
                throw new SyncException( "Unable to initialize condition" );
            scope(failure) CloseHandle( m_blockLock );

            m_blockQueue = CreateSemaphoreA( null, 0, int.max, null );
            if( m_blockQueue == m_blockQueue.init )
                throw new SyncException( "Unable to initialize condition" );
            scope(failure) CloseHandle( m_blockQueue );

            InitializeCriticalSection( &m_unblockLock );
            m_assocMutex = m;
        }
        else version( Posix )
        {
            m_mutexAddr = m.handleAddr();

            int rc = pthread_cond_init( &m_hndl, null );
            if( rc )
                throw new SyncException( "Unable to initialize condition" );
        }
    }


    ~this()
    {
        version( Win32 )
        {
            BOOL rc = CloseHandle( m_blockLock );
            assert( rc, "Unable to destroy condition" );
            rc = CloseHandle( m_blockQueue );
            assert( rc, "Unable to destroy condition" );
            DeleteCriticalSection( &m_unblockLock );
        }
        else version( Posix )
        {
            int rc = pthread_cond_destroy( &m_hndl );
            assert( !rc, "Unable to destroy condition" );
        }
    }


    ////////////////////////////////////////////////////////////////////////////
    // General Actions
    ////////////////////////////////////////////////////////////////////////////


    /**
     * Wait until notified.
     *
     * Throws:
     *  SyncException on error.
     */
    void wait()
    {
        version( Win32 )
        {
            timedWait( INFINITE );
        }
        else version( Posix )
        {
            int rc = pthread_cond_wait( &m_hndl, m_mutexAddr );
            if( rc )
                throw new SyncException( "Unable to wait for condition" );
        }
    }


    /**
     * Suspends the calling thread until a notification occurs or until the
     * supplied time period has elapsed.  The supplied period may be up to a
     * maximum of (uint.max - 1) milliseconds.
     *
     * Params:
     *  period = The time to wait, in seconds (fractional values are accepted).
     *
     * In:
     *  period must be less than (uint.max - 1) milliseconds.
     *
     * Returns:
     *  true if notified before the timeout and false if not.
     *
     * Throws:
     *  SyncException on error.
     */
    bool wait( double period )
    in
    {
        // NOTE: The fractional value added to period is to correct fp error.
        assert( period * 1000 + 0.1 < uint.max - 1 );
    }
    body
    {
        version( Win32 )
        {
            return timedWait( cast(uint)(period * 1000 + 0.1) );
        }
        else version( Posix )
        {
            timespec t;

            getTimespec( t );
            adjTimespec( t, period );
            int rc = pthread_cond_timedwait( &m_hndl, m_mutexAddr, &t );
            if( !rc )
                return true;
            if( rc == ETIMEDOUT )
                return false;
            throw new SyncException( "Unable to wait for condition" );
        }
    }

    /**
     * Notifies one waiter.
     *
     * Throws:
     *  SyncException on error.
     */
    void notify()
    {
        version( Win32 )
        {
            notify( false );
        }
        else version( Posix )
        {
            int rc = pthread_cond_signal( &m_hndl );
            if( rc )
                throw new SyncException( "Unable to notify condition" );
        }
    }


    /**
     * Notifies all waiters.
     *
     * Throws:
     *  SyncException on error.
     */
    void notifyAll()
    {
        version( Win32 )
        {
            notify( true );
        }
        else version( Posix )
        {
            int rc = pthread_cond_broadcast( &m_hndl );
            if( rc )
                throw new SyncException( "Unable to notify condition" );
        }
    }


private:
    version( Win32 )
    {
        bool timedWait( DWORD timeout )
        {
            int   numSignalsLeft;
            int   numWaitersGone;
            DWORD rc;

            rc = WaitForSingleObject( m_blockLock, INFINITE );
            assert( rc == WAIT_OBJECT_0 );

            m_numWaitersBlocked++;

            rc = ReleaseSemaphore( m_blockLock, 1, null );
            assert( rc );

            m_assocMutex.unlock();
            scope(failure) m_assocMutex.lock();

            rc = WaitForSingleObject( m_blockQueue, timeout );
            assert( rc == WAIT_OBJECT_0 || rc == WAIT_TIMEOUT );
            bool timedOut = (rc == WAIT_TIMEOUT);

            EnterCriticalSection( &m_unblockLock );
            scope(failure) LeaveCriticalSection( &m_unblockLock );

            if( (numSignalsLeft = m_numWaitersToUnblock) != 0 )
            {
                if ( timedOut )
                {
                    // timeout (or canceled)
                    if( m_numWaitersBlocked != 0 )
                    {
                        m_numWaitersBlocked--;
                        // do not unblock next waiter below (already unblocked)
                        numSignalsLeft = 0;
                    }
                    else
                    {
                        // spurious wakeup pending!!
                        m_numWaitersGone = 1;
                    }
                }
                if( --m_numWaitersToUnblock == 0 )
                {
                    if( m_numWaitersBlocked != 0 )
                    {
                        // open the gate
                        rc = ReleaseSemaphore( m_blockLock, 1, null );
                        assert( rc );
                        // do not open the gate below again
                        numSignalsLeft = 0;
                    }
                    else if( (numWaitersGone = m_numWaitersGone) != 0 )
                    {
                        m_numWaitersGone = 0;
                    }
                }
            }
            else if( ++m_numWaitersGone == int.max / 2 )
            {
                // timeout/canceled or spurious event :-)
                rc = WaitForSingleObject( m_blockLock, INFINITE );
                assert( rc == WAIT_OBJECT_0 );
                // something is going on here - test of timeouts?
                m_numWaitersBlocked -= m_numWaitersGone;
                rc = ReleaseSemaphore( m_blockLock, 1, null );
                assert( rc == WAIT_OBJECT_0 );
                m_numWaitersGone = 0;
            }

            LeaveCriticalSection( &m_unblockLock );

            if( numSignalsLeft == 1 )
            {
                // better now than spurious later (same as ResetEvent)
                for( ; numWaitersGone > 0; --numWaitersGone )
                {
                    rc = WaitForSingleObject( m_blockQueue, INFINITE );
                    assert( rc == WAIT_OBJECT_0 );
                }
                // open the gate
                rc = ReleaseSemaphore( m_blockLock, 1, null );
                assert( rc );
            }
            else if( numSignalsLeft != 0 )
            {
                // unblock next waiter
                rc = ReleaseSemaphore( m_blockQueue, 1, null );
                assert( rc );
            }
            m_assocMutex.lock();
            return !timedOut;
        }


        void notify( bool all )
        {
            DWORD rc;

            EnterCriticalSection( &m_unblockLock );
            scope(failure) LeaveCriticalSection( &m_unblockLock );

            if( m_numWaitersToUnblock != 0 )
            {
                if( m_numWaitersBlocked == 0 )
                {
                    LeaveCriticalSection( &m_unblockLock );
                    return;
                }
                if( all )
                {
                    m_numWaitersToUnblock += m_numWaitersBlocked;
                    m_numWaitersBlocked = 0;
                }
                else
                {
                    m_numWaitersToUnblock++;
                    m_numWaitersBlocked--;
                }
                LeaveCriticalSection( &m_unblockLock );
            }
            else if( m_numWaitersBlocked > m_numWaitersGone )
            {
                rc = WaitForSingleObject( m_blockLock, INFINITE );
                assert( rc == WAIT_OBJECT_0 );
                if( 0 != m_numWaitersGone )
                {
                    m_numWaitersBlocked -= m_numWaitersGone;
                    m_numWaitersGone = 0;
                }
                if( all )
                {
                    m_numWaitersToUnblock = m_numWaitersBlocked;
                    m_numWaitersBlocked = 0;
                }
                else
                {
                    m_numWaitersToUnblock = 1;
                    m_numWaitersBlocked--;
                }
                LeaveCriticalSection( &m_unblockLock );
                rc = ReleaseSemaphore( m_blockQueue, 1, null );
                assert( rc );
            }
            else
            {
                LeaveCriticalSection( &m_unblockLock );
            }
        }


        // NOTE: This implementation uses Algorithm 8c as described here:
        //       http://groups.google.com/group/comp.programming.threads/
        //              browse_frm/thread/1692bdec8040ba40/e7a5f9d40e86503a
        HANDLE              m_blockLock;    // auto-reset event (now semaphore)
        HANDLE              m_blockQueue;   // auto-reset event (now semaphore)
        Mutex               m_assocMutex;   // external mutex/CS
        CRITICAL_SECTION    m_unblockLock;  // internal mutex/CS
        int                 m_numWaitersGone        = 0;
        int                 m_numWaitersBlocked     = 0;
        int                 m_numWaitersToUnblock   = 0;
    }
    else version( Posix )
    {
        pthread_cond_t      m_hndl;
        pthread_mutex_t*    m_mutexAddr;
    }
}


////////////////////////////////////////////////////////////////////////////////
// Unit Tests
////////////////////////////////////////////////////////////////////////////////


debug( UnitTest )
{
    private import tango.core.Thread;
    private import tango.core.sync.Mutex;
    private import tango.core.sync.Semaphore;


    void testNotify()
    {
        auto mutex      = new Mutex;
        auto condReady  = new Condition( mutex );
        auto semDone    = new Semaphore;
        auto synLoop    = new Object;
        int  numWaiters = 10;
        int  numTries   = 10;
        int  numReady   = 0;
        int  numTotal   = 0;
        int  numDone    = 0;
        int  numPost    = 0;

        void waiter()
        {
            for( int i = 0; i < numTries; ++i )
            {
                synchronized( mutex )
                {
                    while( numReady < 1 )
                    {
                        condReady.wait();
                    }
                    --numReady;
                    ++numTotal;
                }

                synchronized( synLoop )
                {
                    ++numDone;
                }
                semDone.wait();
            }
        }

        auto group = new ThreadGroup;

        for( int i = 0; i < numWaiters; ++i )
            group.create( &waiter );

        for( int i = 0; i < numTries; ++i )
        {
            for( int j = 0; j < numWaiters; ++j )
            {
                synchronized( mutex )
                {
                    ++numReady;
                    condReady.notify();
                }
            }
            while( true )
            {
                synchronized( synLoop )
                {
                    if( numDone >= numWaiters )
                        break;
                }
                Thread.yield();
            }
            for( int j = 0; j < numWaiters; ++j )
            {
                semDone.notify();
            }
        }

        group.joinAll();
        assert( numTotal == numWaiters * numTries );
    }


    void testNotifyAll()
    {
        auto mutex      = new Mutex;
        auto condReady  = new Condition( mutex );
        int  numWaiters = 10;
        int  numReady   = 0;
        int  numDone    = 0;
        bool alert      = false;

        void waiter()
        {
            synchronized( mutex )
            {
                ++numReady;
                while( !alert )
                    condReady.wait();
                ++numDone;
            }
        }

        auto group = new ThreadGroup;

        for( int i = 0; i < numWaiters; ++i )
            group.create( &waiter );

        while( true )
        {
            synchronized( mutex )
            {
                if( numReady >= numWaiters )
                {
                    alert = true;
                    condReady.notifyAll();
                    break;
                }
            }
            Thread.yield();
        }
        group.joinAll();
        assert( numReady == numWaiters && numDone == numWaiters );
    }


    void testWaitTimeout()
    {
        auto mutex      = new Mutex;
        auto condReady  = new Condition( mutex );
        bool waiting    = false;
        bool alertedOne = true;
        bool alertedTwo = true;

        void waiter()
        {
            synchronized( mutex )
            {
                waiting    = true;
                alertedOne = condReady.wait( 1 );
                alertedTwo = condReady.wait( 1 );
            }
        }

        auto thread = new Thread( &waiter );
        thread.start();

        while( true )
        {
            synchronized( mutex )
            {
                if( waiting )
                {
                    condReady.notify();
                    break;
                }
            }
            Thread.yield();
        }
        thread.join();
        assert( waiting && alertedOne && !alertedTwo );
    }


    unittest
    {
        testNotify();
        testNotifyAll();
        testWaitTimeout();
    }
}
