/**
 * The tuple module defines a template struct used for arbitrary data grouping.
 *
 * Copyright: Copyright (C) 2005-2006 Sean Kelly.  All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Sean Kelly, Tom S.
 */
module tango.core.Tuple;


version( DDoc )
{
    /**
     * This struct may contain up to ten arbitrary elements, which will be
     * stored in consecutive order.
     */
    struct Tuple( T1, T2, T3, T4, T5, T6, T7, T8, T9, T10 )
    {
        /**
         * The number of elements contained in this tuple.
         */
        const size_t length;

        /**
         * An alias to the specified element, indexed from zero.
         *
         * Params:
         *  n = The index of the desired element.
         */
        template val( size_t n )
        {
            alias T1 val;
        }
    }
}
else
{
    private
    {
        template TupleMix( T1, T2 )
        {
            const bool lastNode = is( Tail == void );

            static if( lastNode )
                const size_t length = 1;
            else
                const size_t length = tail.length + 1;

            template val( size_t n )
            {
                static if( n >= length )
                    static assert( n < length, "Tuple index out of bounds." );
                else static if( n == 0 )
                    alias head val;
                else
                    alias tail.val!( n - 1 ) val;
            }

        private:
            alias T1 Head;
            alias T2 Tail;

            Head                                            head;
            static if( !lastNode )
                mixin .TupleMix!( Tail.Head, Tail.Tail )    tail;
        }


        struct TupleObj( T1, T2 = void )
        {
            mixin TupleMix!( T1, T2 );
        }
    }


    template Tuple( T1 = void, T2 = void, T3 = void, T4 = void, T5  = void,
                    T6 = void, T7 = void, T8 = void, T9 = void, T10 = void )
    {
        static if( is( T1 == void ) )
            alias void Tuple;
        else
            alias TupleObj!( T1, .Tuple!( T2, T3, T4, T5, T6, T7, T8, T9, T10 ) ) Tuple;
    }
}
