/**
 * The traits module defines tools useful for obtaining detailed type
 * information at compile-time.
 *
 * Copyright: Copyright (C) 2005-2006 Sean Kelly.  All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Sean Kelly
 */
module tango.core.Traits;


/**
 *
 */
template isCharType( T )
{
    const bool isCharType = is( T == char )  ||
                            is( T == wchar ) ||
                            is( T == dchar );
}


/**
 *
 */
template isIntegerType( T )
{
    const bool isIntegerType = is( T == byte )  || is( T == ubyte )  ||
                               is( T == short ) || is( T == ushort ) ||
                               is( T == int )   || is( T == uint )   ||
                               is( T == long )  || is( T == ulong )/+||
                               is( T == cent )  || is( T == ucent )+/;
}


/**
 *
 */
template isDecimalType( T )
{
    const bool isDecimalType = is( T == float )  || is( T == cfloat )  || is( T == ifloat )  ||
                               is( T == double ) || is( T == cdouble ) || is( T == idouble ) ||
                               is( T == real )   || is( T == creal )   || is( T == ireal );
}


/**
 *
 */
template isPointerType( T )
{
    const bool isPointerType = is( typeof(*T) );
}


/**
 *
 */
template isReferenceType( T )
{

    const bool isReferenceType = isPointerType!(T)  ||
                               is( T == class )     ||
                               is( T == interface ) ||
                               is( T == delegate );
}


/**
 *
 */
template isCallableType( T )
{
    const bool isCallableType = is( T == function )             ||
                                is( typeof(*T) == function )    ||
                                is( T == delegate )             ||
                                is( typeof(T.opCall) == function );
}