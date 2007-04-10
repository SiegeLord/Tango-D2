/*******************************************************************************
  copyright:   Copyright (c) 2006 Juan Jose Comellas. All rights reserved
  license:     BSD style: $(LICENSE)
  author:      Juan Jose Comellas <juanjo@comellas.com.ar>
*******************************************************************************/

module tango.util.locks.LockException;


/**
 * LockException is thrown when there is a problem with any locking primitive
 * that cannot allocate enough resources (file descriptors, memory, etc.)
 */
public class LockException: Exception
{
    /**
     * Construct a lock exception with the provided text string
     *
     * Params:
     * msg      = text with a description of the error that caused the
     *            exception to be thrown.
     * file     = name of the source file where the exception was thrown; you
     *            would normally use __FILE__ for this parameter.
     * line     = line number of the source file where the exception was
     *            thrown; you would normally use __LINE__ for this parameter.
     */
    public this(char[] msg, char[] file, uint line)
    {
        super(msg, file, line);
    }
}

/**
 * AlreadyLockedException is thrown when the mutex could not be acquired
 * because it was currently locked.
 */
public class AlreadyLockedException: LockException
{
    /**
     * Construct an AlreadyLockedException with the provided text string.
     *
     * Params:
     * file     = name of the source file where the exception was thrown; you
     *            would normally use __FILE__ for this parameter.
     * line     = line number of the source file where the exception was
     *            thrown; you would normally use __LINE__ for this parameter.
     */
    public this(char[] file, uint line)
    {
        super("The mutex could not be destroyed because it was still locked", file, line);
    }
}

/**
 * DeadlockException is thrown when the mutex is already locked by the calling
 * thread (only for error checking mutexes on POSIX platforms).
 */
public class DeadlockException: LockException
{
    /**
     * Construct a DeadlockException with the provided text string.
     *
     * Params:
     * file     = name of the source file where the exception was thrown; you
     *            would normally use __FILE__ for this parameter.
     * line     = line number of the source file where the exception was
     *            thrown; you would normally use __LINE__ for this parameter.
     */
    public this(char[] file, uint line)
    {
        super("Deadlock detected", file, line);
    }
}

/**
 * OutOfLocksException is thrown when the maximum number of locks has been
 * exceded.
 */
public class OutOfLocksException: LockException
{
    /**
     * Construct a OutOfLocksException with the provided text string.
     *
     * Params:
     * file     = name of the source file where the exception was thrown; you
     *            would normally use __FILE__ for this parameter.
     * line     = line number of the source file where the exception was
     *            thrown; you would normally use __LINE__ for this parameter.
     */
    public this(char[] file, uint line)
    {
        super("Maximum amount of locks reached for mutex", file, line);
    }
}

/**
 * InvalidMutexException is thrown when the mutex has not been properly
 * initialized.
 */
public class InvalidMutexException: LockException
{
    /**
     * Construct an InvalidMutexException with the provided text string.
     *
     * Params:
     * file     = name of the source file where the exception was thrown; you
     *            would normally use __FILE__ for this parameter.
     * line     = line number of the source file where the exception was
     *            thrown; you would normally use __LINE__ for this parameter.
     */
    public this(char[] file, uint line)
    {
        super("The mutex is not valid", file, line);
    }
}

/**
 * InvalidBarrierException is thrown when the barrier has not been properly
 * initialized.
 */
public class InvalidBarrierException: LockException
{
    /**
     * Construct an InvalidBarrierException with the provided text string.
     *
     * Params:
     * file     = name of the source file where the exception was thrown; you
     *            would normally use __FILE__ for this parameter.
     * line     = line number of the source file where the exception was
     *            thrown; you would normally use __LINE__ for this parameter.
     */
    public this(char[] file, uint line)
    {
        super("The barrier is not valid", file, line);
    }
}

/**
 * InvalidConditionException is thrown when the condition has not been properly
 * initialized.
 */
public class InvalidConditionException: LockException
{
    /**
     * Construct an InvalidConditionException with the provided text string.
     *
     * Params:
     * file     = name of the source file where the exception was thrown; you
     *            would normally use __FILE__ for this parameter.
     * line     = line number of the source file where the exception was
     *            thrown; you would normally use __LINE__ for this parameter.
     */
    public this(char[] file, uint line)
    {
        super("The condition variable is not valid", file, line);
    }
}

/**
 * InvalidSemaphoreException is thrown when the semaphore has not been properly
 * initialized.
 */
public class InvalidSemaphoreException: LockException
{
    /**
     * Construct an InvalidSemaphoreException with the provided text string.
     *
     * Params:
     * file     = name of the source file where the exception was thrown; you
     *            would normally use __FILE__ for this parameter.
     * line     = line number of the source file where the exception was
     *            thrown; you would normally use __LINE__ for this parameter.
     */
    public this(char[] file, uint line)
    {
        super("The semaphore is not valid", file, line);
    }
}

/**
 * MutexOwnerException is thrown when the calling thread does not own the
 * mutex (only for error checking mutexes on POSIX platforms).
 */
public class MutexOwnerException: LockException
{
    /**
     * Construct an MutexOwnerException with the provided text string.
     *
     * Params:
     * file     = name of the source file where the exception was thrown; you
     *            would normally use __FILE__ for this parameter.
     * line     = line number of the source file where the exception was
     *            thrown; you would normally use __LINE__ for this parameter.
     */
    public this(char[] file, uint line)
    {
        super("The calling thread does not own the mutex", file, line);
    }
}

/**
 * SemaphoreOwnerException is thrown when the calling thread does not own the
 * semaphore.
 */
public class SemaphoreOwnerException: LockException
{
    /**
     * Construct an SemaphoreOwnerException with the provided text string.
     *
     * Params:
     * file     = name of the source file where the exception was thrown; you
     *            would normally use __FILE__ for this parameter.
     * line     = line number of the source file where the exception was
     *            thrown; you would normally use __LINE__ for this parameter.
     */
    public this(char[] file, uint line)
    {
        super("The calling thread does not own the semaphore", file, line);
    }
}

/**
 * AccessDeniedException is thrown when the caller has limited access rights
 * on Windows.
 */
public class AccessDeniedException: LockException
{
    /**
     * Construct an AccessDeniedException with the provided text string.
     *
     * Params:
     * file     = name of the source file where the exception was thrown; you
     *            would normally use __FILE__ for this parameter.
     * line     = line number of the source file where the exception was
     *            thrown; you would normally use __LINE__ for this parameter.
     */
    public this(char[] file, uint line)
    {
        super("The caller does not have access rights to this synchronization object", file, line);
    }
}

/**
 * MutexTimeoutException is thrown when a ScopedTimedLock cannot acquire its
 * underlying mutex in the specified timeout.
 */
public class MutexTimeoutException: LockException
{
    /**
     * Construct an MutexTimeoutException with the provided text string.
     *
     * Params:
     * file     = name of the source file where the exception was thrown; you
     *            would normally use __FILE__ for this parameter.
     * line     = line number of the source file where the exception was
     *            thrown; you would normally use __LINE__ for this parameter.
     */
    public this(char[] file, uint line)
    {
        super("Timeout acquiring mutex", file, line);
    }
}

/**
 * InterruptedSystemCallException is thrown when a system call is interrupted
 * by a signal.
 */
public class InterruptedSystemCallException: LockException
{
    /**
     * Construct an InterruptedSystemCallException with the provided text
     * string.
     *
     * Params:
     * file     = name of the source file where the exception was thrown; you
     *            would normally use __FILE__ for this parameter.
     * line     = line number of the source file where the exception was
     *            thrown; you would normally use __LINE__ for this parameter.
     */
    public this(char[] file, uint line)
    {
        super("A system call was interrupted by a signal", file, line);
    }
}
