/*
 *  Copyright (C) 2005-2006 Sean Kelly
 *
 *  This software is provided 'as-is', without any express or implied
 *  warranty. In no event will the authors be held liable for any damages
 *  arising from the use of this software.
 *
 *  Permission is granted to anyone to use this software for any purpose,
 *  including commercial applications, and to alter it and redistribute it
 *  freely, in both source and binary form, subject to the following
 *  restrictions:
 *
 *  o  The origin of this software must not be misrepresented; you must not
 *     claim that you wrote the original software. If you use this software
 *     in a product, an acknowledgment in the product documentation would be
 *     appreciated but is not required.
 *  o  Altered source versions must be plainly marked as such, and must not
 *     be misrepresented as being the original software.
 *  o  This notice may not be removed or altered from any source
 *     distribution.
 */

/**
 * The exception module defines all system-level exceptions and provides a
 * mechanism to alter system-lever error handling.
 *
 * Design Issues:
 *
 * The Exception base class is required to live in the global object module,
 * as it is used by the system for exception propogation.
 *
 * Future Directions:
 *
 * It may be useful to provide a means of determining whether an exception
 * is currently in flight.  This would require cooperation with the thread
 * module to implement.
 */
module tango.core.exception;


private
{
    import tango.stdc.stddef;
}


private
{
    alias void function( char[] file, uint line ) assertHandlerType;
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
}


/**
 * Thrown on finalize error.
 */
class FinalizeException : Exception
{
    ClassInfo   info;

    this( ClassInfo c, Exception e = null )
    {
        // NOTE: It is really not ideal to allocate memory here for
        //       the concatenation.  A better approach would be to
        //       include a reference to the ClassInfo object and
        //       construct the message via a specialized toString().
        super( "Finalization error", e );
        info = c;
    }

    char[] toString()
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
 *  h = The new assert handler.
 */
void setAssertHandler( assertHandlerType h )
{
    assertHandler = h;
}


/**
 * Overrides the default assert hander with a user-supplied version.
 *
 * Params:
 *  h = The new assert handler.
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
extern (C) void onAssertError( char[] file, uint line );


/**
 * This function will be called when resource objects (ie. objects with a dtor)
 * are finalized by the garbage collector.  The user-supplied collect handler
 * will be called if one has been supplied, otherwise no action will be taken.
 *
 * Params:
 *  obj = The object being collected.
 *
 * Returns:
 *  true if the runtime should call this object's dtors and false if not.
 *  Default behavior is to return true.
 */
extern (C) bool onCollectResource( Object obj );


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
extern (C) void onArrayBoundsError( char[] file, size_t line );


/**
 * A callback for finalize errors in D.  A FinalizeException will be thrown.
 *
 * Params:
 *  e = The exception thrown during finalization.
 *
 * Throws:
 *  FinalizeException.
 */
extern (C) void onFinalizeError( ClassInfo info, Exception ex );


/**
 * A callback for out of memory errors in D.  An OutOfMemoryException will be
 * thrown.
 *
 * Throws:
 *  OutOfMemoryException.
 */
extern (C) void onOutOfMemoryError();


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
extern (C) void onSwitchError( char[] file, size_t line );


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
extern (C) void onUnicodeError( char[] msg, size_t idx );