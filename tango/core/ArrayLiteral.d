/**
 * Module to create stack allocated array literals
 *
 * Copyright: Copyright (C) 2011 Pavel Sountsov.  All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Pavel Sountsov
 */
module tango.core.ArrayLiteral;

import tango.core.Traits;

/**
 * Creates a static array composed of passed elements. Note that the array is allocated on the stack, so care
 * should be taken not to let slices of it escape from functions.
 * Returns:
 *  Newly created static array.
 */
auto ArrayLiteral(ElemTypes...)(ElemTypes elems)
{
    alias CommonType!(ElemTypes) ElemT;
    ElemT[ElemTypes.length] ret;

    foreach(idx, elem; elems)
    {
        alias ElemTypes[idx] OtherElemT;
        static assert(!isStaticArrayType!(OtherElemT), "Element can't be a static array. Slice it first.");
        static assert(is(OtherElemT : ElemT), "Incompatible types: "~ElemT.stringof~" and "~OtherElemT.stringof~".");
        ret[idx] = elem;
    }

    return ret;
}

private template CommonType(ElemTypes...)
{
    static if(ElemTypes.length > 1)
        alias typeof(true ? ElemTypes[0] : CommonType!(ElemTypes[1..$])) CommonType;
    else static if(ElemTypes.length == 1)
        alias ElemTypes[0] CommonType;
    else
        alias void CommonType;
}

debug( UnitTest )
{
    unittest
    {
        alias ArrayLiteral AL;

        assert(AL(1, 2, 3) == [1, 2, 3]);
        assert(AL(1, 2, 3.3) == [1, 2, 3.3]);
        assert(AL(1.0L, 2.0f, 3) == [1.0L, 2.0f, 3]);
        assert(AL(AL(1.0L, 2)[], AL(3.0L)[]) == [[1.0L, 2], [3.0L]]);

        static assert(is(typeof(AL()[]) == typeof([])));
        static assert(is(typeof(AL(1, 2.0f, 3.3L)[]) == typeof([1, 2.0f, 3.3L])));
        static assert(is(typeof(AL(AL(1.0L, 2)[], AL(3.0L)[])[]) == typeof([[1.0L, 2], [3.0L]])));
    }
}
