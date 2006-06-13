/**
 *
 * Copyright: Copyright (C) 2005-2006 Sean Kelly.  All rights reserved.
 * License:   BSD style: see doc/license.txt for details.
 * Authors:   Sean Kelly
 *
 */
module tango.core.traits;


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
    const bool isPointerType = is( T : void* )      ||
                               is( T == class )     ||
                               is( T == interface ) ||
                               isFunctionPointerType!( T ) ||
                               is( T == delegate );
}


/**
 *
 */
template isCallableType( T )
{
    const bool isCallableType = is( T == function ) || isFunctionPointerType!( T ) ||
                                is( T == delegate ) ||
                                is( typeof(T.opCall) == function );
}


//
// NOTE: This template is a hack to use in place of "is(T==function)" since
//       it actually detects a function alias, not a function pointer.
//
private template isFunctionPointerType( T )
{
    const bool isFunctionPointerType = T.mangleof.length > 2 &&
                                       T.mangleof[0] == 'P'  &&
                                       T.mangleof[1] == 'F';
}