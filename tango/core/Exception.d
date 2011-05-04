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

version = SocketSpecifics;              // TODO: remove this before v1.0

////////////////////////////////////////////////////////////////////////////////
/*
- Exception
  - OutOfMemoryException
  - SwitchException
  - AssertException
  - ArrayBoundsException
  - FinalizeException

  - PlatformException
    - ProcessException
    - ThreadException
      - FiberException
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
 * The basic exception thrown by the tango.io package. One should try to ensure
 * that all Tango exceptions related to IO are derived from this one.
 */
class IOException : PlatformException
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
 * Base class for socket exceptions.
 */
class SocketException : IOException
{
    this( immutable(char)[] msg )
    {
        super( msg );
    }
}


version (SocketSpecifics)
{
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
 * Base class for exceptiond thrown by an Address.
 */
class AddressException : IOException
{
    this( immutable(char)[] msg )
    {
        super( msg );
    }
}


/**
 * Thrown when a socket failed to accept an incoming connection.
 */
class SocketAcceptException : SocketException
{
    this( immutable(char)[] msg )
    {
        super( msg );
    }
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

