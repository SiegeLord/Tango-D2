/**
 * The exception module defines all system-level exceptions and provides a
 * mechanism to alter system-level error handling.
 *
 * Copyright: Copyright (C) 2005-2006 Sean Kelly, Kris Bell.  All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Sean Kelly, Kris Bell
 */
module tango.core.Exception;

public import core.exception;


/**
 * Basically all of tangos exceptions derive from one of the following exceptions.
 * Most of them aren't specified here, because they transport a lot of specific
 * information of the objects from which they are thrown.
 * 
 * But for information, here is a list of the hirarchy. 
 * 
 * - Exception (druntime)
 *   - IOException
 *     - SocketException
 *       - TcpServerException
 *       - LocalServerException
 *       - UdpServerException
 *     -
 * 
 * ---
 * // example code
 * try
 * {
 *      // put your code here
 * }
 * catch(Exception ex)
 * {
 *      Stdout(ex.toString());
 * }
 * ---
 */


////////////////////////////////////////////////////////////////////////////////
/*
 *  ---> need to clean up
- Exception
  - OutOfMemoryException
  - SwitchException
  - AssertException
  - ArrayBoundsException
  - FinalizeException

  - PlatformException
    - ProcessException
    - ThreadPoolException  
    - SyncException
    - IOException
      - SocketException
      - VfsException
      - ClusterException

  - NoSuchElementException
    - CorruptedIteratorException

  - IllegalArgumentException
    - IllegalElementException

  - TextException
    - XmlException
    - RegexException
    - LocaleException
    - UnicodeException

  - PayloadException
*/
////////////////////////////////////////////////////////////////////////////////

/**
 * The basic exception thrown by the tango.io package. One should try to ensure
 * that all Tango exceptions related to IO are derived from this one.
 */
class IOException : Exception
{
    this( immutable(char)[] msg )
    {
        super( msg );
    }
    
    this(immutable(char)[] msg, immutable(char)[] file, size_t line)
    {
        super(msg, file, line);
    }
}

/**
 * Thrown on an out of memory error.
 */
class OutOfMemoryException : Exception
{
    this( immutable(char)[] file, size_t line )
    {
        super( "Memory allocation failed", file, line );
    }

    override immutable(char)[] toString()
    {
        return msg ? super.toString() : "Memory allocation failed";
    }
}


/**
 * Base class for operating system or library exceptions.
 */
class PlatformException : Exception
{
    this( immutable(char)[] msg )
    {
        super( msg );
    }
}

/**
 * Thrown on an assert error.
 */
class AssertException : Exception
{
    this( immutable(char)[] file, size_t line )
    {
        super( "Assertion failure", file, line );
    }

    this( immutable(char)[] msg, immutable(char)[] file, size_t line )
    {
        super( msg, file, line );
    }
}


/**
 * Thrown on an array bounds error.
 */
class ArrayBoundsException : Exception
{
    this( immutable(char)[] file, size_t line )
    {
        super( "Array index out of bounds", file, line );
    }
}


/**
 * Thrown on finalize error.
 */
class FinalizeException : Exception
{
    ClassInfo   info;

    this( ClassInfo c, Exception e )
    {
        super( "Finalization error", e );
        info = c;
    }

    override immutable(char)[] toString()
    {
        auto other = super.next ? super.next.toString : "unknown";
        return "An exception was thrown while finalizing an instance of class " ~ info.name ~ " :: "~other;
    }
}


/**
 * Thrown on a switch error.
 */
class SwitchException : Exception
{
    this( immutable(char)[] file, size_t line )
    {
        super( "No appropriate switch clause found", file, line );
    }
}


/**
 * Represents a text processing error.
 */
class TextException : Exception
{
    this( immutable(char)[] msg )
    {
        super( msg );
    }
}

/**
 * Thrown on a unicode conversion error.
 */
class UnicodeException : TextException
{
    size_t idx;

    this( immutable(char)[] msg, size_t idx )
    {
        super( msg );
        this.idx = idx;
    }
}

/**
 * Base class for ThreadPoolException
 */
class ThreadPoolException : Exception
{
    this( immutable(char)[] msg )
    {
        super( msg );
    }
}


/**
 * Base class for synchronization exceptions.
 */
class SyncException : PlatformException
{
    this( immutable(char)[] msg )
    {
        super( msg );
    }
}

/**
 * The basic exception thrown by the tango.io.vfs package.
 */
class VfsException : IOException
{
    this( immutable(char)[] msg )
    {
        super( msg );
    }
}

/**
 * The basic exception thrown by the tango.io.cluster package.
 */
class ClusterException : IOException
{
    this( immutable(char)[] msg )
    {
        super( msg );
    }
}

/**
 * Base class for exception thrown by an InternetHost.
 */
class HostException : IOException
{
    this( immutable(char)[] msg )
    {
        super( msg );
    }
}

/**
 * Thrown on a process error.
 */
class ProcessException : PlatformException
{
    this( immutable(char)[] msg )
    {
        super( msg );
    }
}


/**
 * Base class for regluar expression exceptions.
 */
class RegexException : TextException
{
    this( immutable(char)[] msg )
    {
        super( msg );
    }
}


/**
 * Base class for locale exceptions.
 */
class LocaleException : TextException
{
    this( immutable(char)[] msg )
    {
        super( msg );
    }
}


/**
 * Base class for XML exceptions.
 */
class XmlException : TextException
{
    this( immutable(char)[] msg )
    {
        super( msg );
    }
}


/**
 * RegistryException is thrown when the NetworkRegistry encounters a
 * problem during proxy registration, or when it sees an unregistered
 * guid.
 */
class RegistryException : Exception
{
    this( immutable(char)[] msg )
    {
        super( msg );
    }
}

/**
 * Thrown when an illegal argument is encountered.
 */
class IllegalArgumentException : Exception
{
    this( immutable(char)[] msg )
    {
        super( msg );
    }
}


/**
 *
 * IllegalElementException is thrown by Collection methods
 * that add (or replace) elements (and/or keys) when their
 * arguments are null or do not pass screeners.
 *
 */
class IllegalElementException : IllegalArgumentException
{
    this( immutable(char)[] msg )
    {
        super( msg );
    }
}


/**
 * Thrown on past-the-end errors by iterators and containers.
 */
class NoSuchElementException : Exception
{
    this( immutable(char)[] msg )
    {
        super( msg );
    }
}


/**
 * Thrown when a corrupt iterator is detected.
 */
class CorruptedIteratorException : NoSuchElementException
{
    this( immutable(char)[] msg )
    {
        super( msg );
    }
}

/*******************************************************************************

        Internal Error Callbacks

*******************************************************************************/

/**
 * A callback for array bounds errors in D.  An ArrayBoundsException will be
 * thrown.
 *
 * Params:
 *  file = The name of the file that signaled this error.
 *  line = The line number on which this error occurred.
 *
 * Throws:
 *  ArrayBoundsException.
 */
extern (C) void onArrayBoundsError( immutable(char)[] file, size_t line )
{
    throw new ArrayBoundsException( file, line );
}

/**
 * A callback for switch errors in D.  A SwitchException will be thrown.
 *
 * Params:
 *  file = The name of the file that signaled this error.
 *  line = The line number on which this error occurred.
 *
 * Throws:
 *  SwitchException.
 */
extern (C) void onSwitchError( immutable(char)[] file, size_t line )
{
    throw new SwitchException( file, line );
}
