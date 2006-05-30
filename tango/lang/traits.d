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
 *
 * Design Issues:
 *
 * Future Directions:
 *
 */
module tango.lang.traits;


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
                               is( T == function )  || isFunctionType!( T ) ||
                               is( T == delegate );
}


/**
 *
 */
template isCallableType( T )
{
    const bool isCallableType = is( T == function ) || isFunctionType!( T ) ||
                                is( T == delegate ) ||
                                is( typeof(T.opCall) == function );
}


//
// NOTE: This template is a hack to replace is(T==function) since it's broken.
//
private template isFunctionType( T )
{
    const bool isFunctionType = mangleString!(T).length > 2 &&
                                mangleString!(T)[0] == 'P'  &&
                                mangleString!(T)[1] == 'F';
}


//
// NOTE: Yet another workaround for a compiler bug.
//
private template mangleString( T )
{
    const char[] mangleString = T.mangleof;
}