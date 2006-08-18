/**
 * The exception module defines all system-level exceptions and provides a
 * mechanism to alter system-level error handling.
 *
 * Copyright: Copyright (C) 2005-2006 Sean Kelly.  All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Sean Kelly
 */
module tango.core.Exception;


private
{
    alias void function( char[] file, uint line, char[] msg = null ) assertHandlerType;
    alias bool function( Object obj ) collectHandlerType;

    assertHandlerType   assertHandler   = null;
    collectHandlerType  collectHandler  = null;
}


////////////////////////////////////////////////////////////////////////////////
// Exceptions
////////////////////////////////////////////////////////////////////////////////


/**
 * Thrown on an array bounds error.
 */
class ArrayBoundsException : Exception
{
    this( char[] file, size_t line )
    {
        super( "Array index out of bounds", file, line );
    }
}


/**
 * Thrown on an assert error.
 */
class AssertException : Exception
{
    this( char[] file, size_t line )
    {
        super( "Assertion failure", file, line );
    }

    this( char[] msg, char[] file, size_t line )
    {
        super( msg, file, line );
    }
}


/**
 * Thrown on finalize error.
 */
class FinalizeException : Exception
{
    ClassInfo   info;

    this( ClassInfo c, Exception e = null )
    {
        super( "Finalization error", e );
        info = c;
    }

    char[] toUtf8()
    {
        return "An exception was thrown while finalizing an instance of class " ~ info.name;
    }
}


/**
 * Thrown on an out of memory error.
 */
class OutOfMemoryException : Exception
{
    this( char[] file, size_t line )
    {
        super( "Memory allocation failed", file, line );
    }

    char[] toUtf8()
    {
        return msg ? super.toUtf8() : "Memory allocation failed";
    }
}


/**
 * Thrown on a switch error.
 */
class SwitchException : Exception
{
    this( char[] file, size_t line )
    {
        super( "No appropriate switch clause found", file, line );
    }
}


/**
 * Thrown on a unicode conversion error.
 */
class UnicodeException : Exception
{
    size_t idx;

    this( char[] msg, size_t idx )
    {
        super( msg );
        this.idx = idx;
    }
}


////////////////////////////////////////////////////////////////////////////////
// Overrides
////////////////////////////////////////////////////////////////////////////////


/**
 * Overrides the default assert hander with a user-supplied version.
 *
 * Params:
 *  h = The new assert handler.  Set to null to use the default handler.
 */
void setAssertHandler( assertHandlerType h )
{
    assertHandler = h;
}


/**
 * Overrides the default collect hander with a user-supplied version.
 *
 * Params:
 *  h = The new collect handler.  Set to null to use the default handler.
 */
void setCollectHandler( collectHandlerType h )
{
    collectHandler = h;
}


////////////////////////////////////////////////////////////////////////////////
// Overridable Callbacks
////////////////////////////////////////////////////////////////////////////////


/**
 * A callback for assert errors in D.  The user-supplied assert handler will
 * be called if one has been supplied, otherwise an AssertException will be
 * thrown.
 *
 * Params:
 *  file = The name of the file that signaled this error.
 *  line = The line number on which this error occurred.
 */
extern (C) void onAssertError( char[] file, uint line )
{
    if( assertHandler is null )
        throw new AssertException( file, line );
    assertHandler( file, line );
}


/**
 * A callback for assert errors in D.  The user-supplied assert handler will
 * be called if one has been supplied, otherwise an AssertException will be
 * thrown.
 *
 * Params:
 *  file = The name of the file that signaled this error.
 *  line = The line number on which this error occurred.
 *  msg  = An error message supplied by the user.
 */
extern (C) void onAssertErrorMsg( char[] file, uint line, char[] msg )
{
    if( assertHandler is null )
        throw new AssertException( msg, file, line );
    assertHandler( file, line, msg );
}


/**
 * This function will be called when resource objects (ie. objects with a dtor)
 * are finalized by the garbage collector.  The user-supplied collect handler
 * will be called if one has been supplied, otherwise no action will be taken.
 *
 * Params:
 *  obj = The object being collected.
 *
 * Returns:
 *  true if the runtime should call this object's dtor and false if not.
 *  Default behavior is to return true.
 */
extern (C) bool onCollectResource( Object obj )
{
    if( collectHandler is null )
        return true;
    return collectHandler( obj );
}


////////////////////////////////////////////////////////////////////////////////
// Internal Error Callbacks
////////////////////////////////////////////////////////////////////////////////


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
extern (C) void onArrayBoundsError( char[] file, size_t line )
{
    throw new ArrayBoundsException( file, line );
}


/**
 * A callback for finalize errors in D.  A FinalizeException will be thrown.
 *
 * Params:
 *  e = The exception thrown during finalization.
 *
 * Throws:
 *  FinalizeException.
 */
extern (C) void onFinalizeError( ClassInfo info, Exception ex )
{
    throw new FinalizeException( info, ex );
}


/**
 * A callback for out of memory errors in D.  An OutOfMemoryException will be
 * thrown.
 *
 * Throws:
 *  OutOfMemoryException.
 */
extern (C) void onOutOfMemoryError()
{
    // NOTE: Since an out of memory condition exists, no allocation must occur
    //       while generating this object.
    throw cast(OutOfMemoryException) cast(void*) OutOfMemoryException.classinfo.init;
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
extern (C) void onSwitchError( char[] file, size_t line )
{
    throw new SwitchException( file, line );
}


/**
 * A callback for unicode errors in D.  A UnicodeException will be thrown.
 *
 * Params:
 *  msg = Information about the error.
 *  idx = String index where this error was detected.
 *
 * Throws:
 *  UnicodeException.
 */
extern (C) void onUnicodeError( char[] msg, size_t idx )
{
    throw new UnicodeException( msg, idx );
}