/**
 * The array module provides string manipulation routines in a manner that
 * balances performance and flexibility.
 *
 * Copyright: Copyright (C) 2005-2006 Sean Kelly.  All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Sean Kelly
 */
module tango.core.Array;


private import tango.core.Traits;


version( DDoc )
{
    typedef int Elem;

    alias bool function( Elem )       PredT1E;
    alias bool function( Elem, Elem ) PredT2E;
}


private
{
    struct IsEqual( T )
    {
        bool opCall( T p1, T p2 )
        {
            return p1 == p2;
        }
    }


    struct IsLess( T )
    {
        bool opCall( T p1, T p2 )
        {
            return p1 < p2;
        }
    }


    template ElemTypeOf( T )
    {
        alias typeof(T[0]) ElemTypeOf;
    }
}


////////////////////////////////////////////////////////////////////////////////
// Find
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a linear search of buf from $(LB)0 .. buf.length$(RP),
     * returning the index of the first element matching pat, or size_t.max
     * if no match was found.  Comparisons will be performed using '=='.
     *
     * Params:
     *  buf = The array to search.
     *  pat = The pattern to search for.
     *
     * Returns:
     *  The index of the first match or size_t.max if no match was found.
     */
    size_t find( Elem[] buf, Elem pat );


    /**
     * Performs a linear search of buf from $(LB)0 .. buf.length$(RP),
     * returning the index of the first element matching pat, or size_t.max
     * if no match was found.  Comparisons will be performed using the
     * supplied predicate.
     *
     * Params:
     *  buf  = The array to search.
     *  pat  = The pattern to search for.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         equal to e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  The index of the first match or size_t.max if no match was found.
     */
    size_t find( Elem[] buf, Elem pat, PredT2E pred );


    /**
     * Performs a linear search of buf from $(LB)0 .. buf.length$(RP),
     * returning the index of the first element matching pat, or size_t.max
     * if no match was found.  Comparisons will be performed using '=='.
     *
     * Params:
     *  buf = The array to search.
     *  pat = The pattern to search for.
     *
     * Returns:
     *  The index of the first match or size_t.max if no match was found.
     */
    size_t find( Elem[] buf, Elem[] pat );


    /**
     * Performs a linear search of buf from $(LB)0 .. buf.length$(RP),
     * returning the index of the first element matching pat, or size_t.max
     * if no match was found.  Comparisons will be performed using the
     * supplied predicate.
     *
     * Params:
     *  buf  = The array to search.
     *  pat  = The pattern to search for.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         equal to e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  The index of the first match or size_t.max if no match was found.
     */
    size_t find( Elem[] buf, Elem[] pat, PredT2E pred );

}
else
{
    template find_( Elem, Pred = IsEqual!(Elem) )
    {
        static assert( isCallableType!(Pred) );


        size_t fn( Elem[] buf, Elem pat, Pred pred = Pred.init )
        {
            foreach( size_t pos, Elem cur; buf )
            {
                if( pred( cur, pat ) )
                    return pos;
            }
            return size_t.max;
        }


        size_t fn( Elem[] buf, Elem[] pat, Pred pred = Pred.init )
        {
            if( buf.length == 0 ||
                pat.length == 0 ||
                buf.length < pat.length )
            {
                return size_t.max;
            }

            size_t end = buf.length - pat.length + 1;

            for( size_t pos = 0; pos < end; ++pos )
            {
                if( pred( buf[pos], pat[0] ) )
                {
                    size_t mat = 0;

                    do
                    {
                        if( ++mat >= pat.length )
                            return pos - pat.length + 1;
                        if( ++pos >= buf.length )
                            return size_t.max;
                    } while( pred( buf[pos], pat[mat] ) );
                    pos -= mat;
                }
            }
            return size_t.max;
        }
    }


    template find( Buf, Pat )
    {
        size_t find( Buf buf, Pat pat )
        {
            return find_!(ElemTypeOf!(Buf)).fn( buf, pat );
        }
    }


    template find( Buf, Pat, Pred )
    {
        size_t find( Buf buf, Pat pat, Pred pred )
        {
            return find_!(ElemTypeOf!(Buf), Pred).fn( buf, pat, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        // find element
        assert( find( "", 'a' ) == size_t.max );
        assert( find( "abc", 'a' ) == 0 );
        assert( find( "abc", 'b' ) == 1 );
        assert( find( "abc", 'c' ) == 2 );
        assert( find( "abc", 'd' ) == size_t.max );

        // null parameters
        assert( find( "", "" ) == size_t.max );
        assert( find( "a", "" ) == size_t.max );
        assert( find( "", "a" ) == size_t.max );

        // exact match
        assert( find( "abc", "abc" ) == 0 );

        // simple substring match
        assert( find( "abc", "a" ) == 0 );
        assert( find( "abca", "a" ) == 0 );
        assert( find( "abc", "b" ) == 1 );
        assert( find( "abc", "c" ) == 2 );
        assert( find( "abc", "d" ) == size_t.max );

        // multi-char substring match
        assert( find( "abc", "ab" ) == 0 );
        assert( find( "abcab", "ab" ) == 0 );
        assert( find( "abc", "bc" ) == 1 );
        assert( find( "abc", "ac" ) == size_t.max );
        assert( find( "abrabracadabra", "abracadabra" ) == 3 );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Reverse Find
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a linear search of buf from $(LP)buf.length .. 0$(RB),
     * returning the index of the first element matching pat, or size_t.max
     * if no match was found.  Comparisons will be performed using '=='.
     *
     * Params:
     *  buf = The array to search.
     *  pat = The pattern to search for.
     *
     * Returns:
     *  The index of the first match or size_t.max if no match was found.
     */
    size_t rfind( Elem[] buf, Elem pat );


    /**
     * Performs a linear search of buf from $(LP)buf.length .. 0$(RB),
     * returning the index of the first element matching pat, or size_t.max
     * if no match was found.  Comparisons will be performed using the
     * supplied predicate.
     *
     * Params:
     *  buf  = The array to search.
     *  pat  = The pattern to search for.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         equal to e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  The index of the first match or size_t.max if no match was found.
     */
    size_t rfind( Elem[] buf, Elem pat, PredT2E pred );


    /**
     * Performs a linear search of buf from $(LP)buf.length .. 0$(RB),
     * returning the index of the first element matching pat, or size_t.max
     * if no match was found.  Comparisons will be performed using '=='.
     *
     * Params:
     *  buf = The array to search.
     *  pat = The pattern to search for.
     *
     * Returns:
     *  The index of the first match or size_t.max if no match was found.
     */
    size_t rfind( Elem[] buf, Elem[] pat );


    /**
     * Performs a linear search of buf from $(LP)buf.length .. 0$(RB),
     * returning the index of the first element matching pat, or size_t.max
     * if no match was found.  Comparisons will be performed using the
     * supplied predicate.
     *
     * Params:
     *  buf  = The array to search.
     *  pat  = The pattern to search for.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         equal to e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  The index of the first match or size_t.max if no match was found.
     */
    size_t rfind( Elem[] buf, Elem[] pat, PredT2E pred );
}
else
{
    template rfind_( Elem, Pred = IsEqual!(Elem) )
    {
        static assert( isCallableType!(Pred) );


        size_t fn( Elem[] buf, Elem pat, Pred pred = Pred.init )
        {
            if( buf.length == 0 )
                return size_t.max;

            size_t pos = buf.length;

            do
            {
                if( pred( buf[--pos], pat ) )
                    return pos;
            } while( pos > 0 );
            return size_t.max;
        }


        size_t fn( Elem[] buf, Elem[] pat, Pred pred = Pred.init )
        {
            if( buf.length == 0 ||
                pat.length == 0 ||
                buf.length < pat.length )
            {
                return size_t.max;
            }

            size_t pos = buf.length - pat.length + 1;

            do
            {
                if( pred( buf[--pos], pat[0] ) )
                {
                    size_t mat = 0;

                    do
                    {
                        if( ++mat >= pat.length )
                            return pos - pat.length + 1;
                        if( ++pos >= buf.length )
                            return size_t.max;
                    } while( pred( buf[pos], pat[mat] ) );
                    pos -= mat;
                }
            } while( pos > 0 );
            return size_t.max;
        }
    }


    template rfind( Buf, Pat )
    {
        size_t rfind( Buf buf, Pat pat )
        {
            return rfind_!(ElemTypeOf!(Buf)).fn( buf, pat );
        }
    }


    template rfind( Buf, Pat, Pred )
    {
        size_t rfind( Buf buf, Pat pat, Pred pred )
        {
            return rfind_!(ElemTypeOf!(Buf), Pred).fn( buf, pat, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        // rfind element
        assert( rfind( "", 'a' ) == size_t.max );
        assert( rfind( "abc", 'a' ) == 0 );
        assert( rfind( "abc", 'b' ) == 1 );
        assert( rfind( "abc", 'c' ) == 2 );
        assert( rfind( "abc", 'd' ) == size_t.max );

        // null parameters
        assert( rfind( "", "" ) == size_t.max );
        assert( rfind( "a", "" ) == size_t.max );
        assert( rfind( "", "a" ) == size_t.max );

        // exact match
        assert( rfind( "abc", "abc" ) == 0 );

        // simple substring match
        assert( rfind( "abc", "a" ) == 0 );
        assert( rfind( "abca", "a" ) == 3 );
        assert( rfind( "abc", "b" ) == 1 );
        assert( rfind( "abc", "c" ) == 2 );
        assert( rfind( "abc", "d" ) == size_t.max );

        // multi-char substring match
        assert( rfind( "abc", "ab" ) == 0 );
        assert( rfind( "abcab", "ab" ) == 3 );
        assert( rfind( "abc", "bc" ) == 1 );
        assert( rfind( "abc", "ac" ) == size_t.max );
        assert( rfind( "abracadabrabra", "abracadabra" ) == 0 );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// KMP Find
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a linear search of buf from $(LB)0 .. buf.length$(RP),
     * returning the index of the first element matching pat, or size_t.max
     * if no match was found.  Comparisons will be performed using '=='.
     * This function is equivalent to its 'find' counterpart.
     *
     * Params:
     *  buf = The array to search.
     *  pat = The pattern to search for.
     *
     * Returns:
     *  The index of the first match or size_t.max if no match was found.
     */
    size_t kfind( Elem[] buf, Elem pat );


    /**
     * Performs a linear search of buf from $(LB)0 .. buf.length$(RP),
     * returning the index of the first element matching pat, or size_t.max
     * if no match was found.  Comparisons will be performed using the
     * supplied predicate.
     *
     * This function uses the KMP algorithm and offers O(M+N) performance but
     * must allocate a temporary buffer of size pat.sizeof to do so.  As the
     * cost of dynamic allocations is potentially quite high, the standard
     * find operation may be preferable.
     *
     * Implementor's Note: If stack allocation could be used, this algorithm
     * would be far more appealing.  Consider using alloca or restricting
     * pattern length and employing a fixed internal buffer.
     *
     * Params:
     *  buf  = The array to search.
     *  pat  = The pattern to search for.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         equal to e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  The index of the first match or size_t.max if no match was found.
     */
    size_t kfind( Elem[] buf, Elem pat, PredT2E pred );


    /**
     * Performs a linear search of buf from $(LB)0 .. buf.length$(RP),
     * returning the index of the first element matching pat, or size_t.max
     * if no match was found.  Comparisons will be performed using '=='.
     * This function is equivalent to its 'find' counterpart.
     *
     * Params:
     *  buf = The array to search.
     *  pat = The pattern to search for.
     *
     * Returns:
     *  The index of the first match or size_t.max if no match was found.
     */
    size_t kfind( Elem[] buf, Elem[] pat );


    /**
     * Performs a linear search of buf from $(LB)0 .. buf.length$(RP),
     * returning the index of the first element matching pat, or size_t.max
     * if no match was found.  Comparisons will be performed using the
     * supplied predicate.
     *
     * This function uses the KMP algorithm and offers O(M+N) performance but
     * must allocate a temporary buffer of size pat.sizeof to do so.  As the
     * cost of dynamic allocations is potentially quite high, the standard
     * find operation may be preferable.
     *
     * Implementor's Note: If stack allocation could be used, this algorithm
     * would be far more appealing.  Consider using alloca or restricting
     * pattern length and employing a fixed internal buffer.
     *
     * Params:
     *  buf  = The array to search.
     *  pat  = The pattern to search for.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         equal to e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  The index of the first match or size_t.max if no match was found.
     */
    size_t kfind( Elem[] buf, Elem[] pat, PredT2E pred );
}
else
{
    template kfind_( Elem, Pred = IsEqual!(Elem) )
    {
        static assert( isCallableType!(Pred) );


        size_t fn( Elem[] buf, Elem pat, Pred pred = Pred.init )
        {
            foreach( size_t pos, Elem cur; buf )
            {
                if( pred( cur, pat ) )
                    return pos;
            }
            return size_t.max;
        }


        size_t fn( Elem[] buf, Elem[] pat, Pred pred = Pred.init )
        {
            if( buf.length == 0 ||
                pat.length == 0 ||
                buf.length < pat.length )
            {
                return size_t.max;
            }

            size_t[]    func;
            scope( exit ) delete func; // force cleanup

            func.length = pat.length + 1;
            func[0]     = 0;

            //
            // building prefix-function
            //
            for( size_t m = 0, i = 1 ; i < pat.length ; ++i )
            {
                while( ( m > 0 ) && !pred( pat[m], pat[i] ) )
                    m = func[m - 1];
                if( pred( pat[m], pat[i] ) )
                    ++m;
                func[i] = m;
            }

            //
            // searching
            //
            for( size_t m = 0, i = 0; i < buf.length; ++i )
            {
                while( ( m > 0 ) && !pred( pat[m], buf[i] ) )
                    m = func[m - 1];
                if( pred( pat[m], buf[i] ) )
                {
                    ++m;
                    if( m == pat.length )
                    {
                        return i - pat.length + 1;
            	    }
                }
            }

            return size_t.max;
        }
    }


    template kfind( Buf, Pat )
    {
        size_t kfind( Buf buf, Pat pat )
        {
            return kfind_!(ElemTypeOf!(Buf)).fn( buf, pat );
        }
    }


    template kfind( Buf, Pat, Pred )
    {
        size_t kfind( Buf buf, Pat pat, Pred pred )
        {
            return kfind_!(ElemTypeOf!(Buf), Pred).fn( buf, pat, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        // find element
        assert( kfind( "", 'a' ) == size_t.max );
        assert( kfind( "abc", 'a' ) == 0 );
        assert( kfind( "abc", 'b' ) == 1 );
        assert( kfind( "abc", 'c' ) == 2 );
        assert( kfind( "abc", 'd' ) == size_t.max );

        // null parameters
        assert( kfind( "", "" ) == size_t.max );
        assert( kfind( "a", "" ) == size_t.max );
        assert( kfind( "", "a" ) == size_t.max );

        // exact match
        assert( kfind( "abc", "abc" ) == 0 );

        // simple substring match
        assert( kfind( "abc", "a" ) == 0 );
        assert( kfind( "abca", "a" ) == 0 );
        assert( kfind( "abc", "b" ) == 1 );
        assert( kfind( "abc", "c" ) == 2 );
        assert( kfind( "abc", "d" ) == size_t.max );

        // multi-char substring match
        assert( kfind( "abc", "ab" ) == 0 );
        assert( kfind( "abcab", "ab" ) == 0 );
        assert( kfind( "abc", "bc" ) == 1 );
        assert( kfind( "abc", "ac" ) == size_t.max );
        assert( kfind( "abrabracadabra", "abracadabra" ) == 3 );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// KMP Reverse Find
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a linear search of buf from $(LP)buf.length .. 0$(RB),
     * returning the index of the first element matching pat, or size_t.max
     * if no match was found.  Comparisons will be performed using '=='.
     * This function is equivalent to its 'rfind' counterpart.
     *
     * Params:
     *  buf = The array to search.
     *  pat = The pattern to search for.
     *
     * Returns:
     *  The index of the first match or size_t.max if no match was found.
     */
    size_t krfind( Elem[] buf, Elem pat );


    /**
     * Performs a linear search of buf from $(LP)buf.length .. 0$(RB),
     * returning the index of the first element matching pat, or size_t.max
     * if no match was found.  Comparisons will be performed using the
     * supplied predicate.
     *
     * This function uses the KMP algorithm and offers O(M+N) performance but
     * must allocate a temporary buffer of size pat.sizeof to do so.  As the
     * cost of dynamic allocations is potentially quite high, the standard
     * find operation may be preferable.
     *
     * Implementor's Note: If stack allocation could be used, this algorithm
     * would be far more appealing.  Consider using alloca or restricting
     * pattern length and employing a fixed internal buffer.
     *
     * Params:
     *  buf  = The array to search.
     *  pat  = The pattern to search for.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         equal to e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  The index of the first match or size_t.max if no match was found.
     */
    size_t krfind( Elem[] buf, Elem pat, PredT2E pred );


    /**
     * Performs a linear search of buf from $(LP)buf.length .. 0$(RB),
     * returning the index of the first element matching pat, or size_t.max
     * if no match was found.  Comparisons will be performed using '=='.
     * This function is equivalent to its 'rfind' counterpart.
     *
     * Params:
     *  buf = The array to search.
     *  pat = The pattern to search for.
     *
     * Returns:
     *  The index of the first match or size_t.max if no match was found.
     */
    size_t krfind( Elem[] buf, Elem[] pat );


    /**
     * Performs a linear search of buf from $(LP)buf.length .. 0$(RB),
     * returning the index of the first element matching pat, or size_t.max
     * if no match was found.  Comparisons will be performed using the
     * supplied predicate.
     *
     * This function uses the KMP algorithm and offers O(M+N) performance but
     * must allocate a temporary buffer of size pat.sizeof to do so.  As the
     * cost of dynamic allocations is potentially quite high, the standard
     * find operation may be preferable.
     *
     * Implementor's Note: If stack allocation could be used, this algorithm
     * would be far more appealing.  Consider using alloca or restricting
     * pattern length and employing a fixed internal buffer.
     *
     * Params:
     *  buf  = The array to search.
     *  pat  = The pattern to search for.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         equal to e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  The index of the first match or size_t.max if no match was found.
     */
    size_t krfind( Elem[] buf, Elem[] pat, PredT2E pred );
}
else
{
    template krfind_( Elem, Pred = IsEqual!(Elem) )
    {
        static assert( isCallableType!(Pred) );


        size_t fn( Elem[] buf, Elem pat, Pred pred = Pred.init )
        {
            if( buf.length == 0 )
                return size_t.max;

            size_t pos = buf.length;

            do
            {
                if( pred( buf[--pos], pat ) )
                    return pos;
            } while( pos > 0 );
            return size_t.max;
        }


        size_t fn( Elem[] buf, Elem[] pat, Pred pred = Pred.init )
        {
            if( buf.length == 0 ||
                pat.length == 0 ||
                buf.length < pat.length )
            {
                return size_t.max;
            }

            size_t[]    func;
            scope( exit ) delete func; // force cleanup

            func.length      = pat.length + 1;
            func[length - 1] = 0;

            //
            // building prefix-function
            //
            for( size_t m = 0, i = pat.length - 1; i > 0; --i )
            {
                while( ( m > 0 ) && !pred( pat[length - m - 1], pat[i - 1] ) )
                    m = func[length - m];
                if( pred( pat[length - m - 1], pat[i - 1] ) )
                    ++m;
                func[i - 1] = m;
            }

            //
            // searching
            //
            size_t  m = 0;
            size_t  i = buf.length;
            do
            {
                --i;
                while( ( m > 0 ) && !pred( pat[length - m - 1], buf[i] ) )
                    m = func[length - m - 1];
                if( pred( pat[length - m - 1], buf[i] ) )
                {
                    ++m;
                    if ( m == pat.length )
                    {
                        return i;
                    }
                }
            } while( i > 0 );

            return size_t.max;
        }
    }


    template krfind( Buf, Pat )
    {
        size_t krfind( Buf buf, Pat pat )
        {
            return krfind_!(ElemTypeOf!(Buf)).fn( buf, pat );
        }
    }


    template krfind( Buf, Pat, Pred )
    {
        size_t krfind( Buf buf, Pat pat, Pred pred )
        {
            return krfind_!(ElemTypeOf!(Buf), Pred).fn( buf, pat, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        // rfind element
        assert( krfind( "", 'a' ) == size_t.max );
        assert( krfind( "abc", 'a' ) == 0 );
        assert( krfind( "abc", 'b' ) == 1 );
        assert( krfind( "abc", 'c' ) == 2 );
        assert( krfind( "abc", 'd' ) == size_t.max );

        // null parameters
        assert( krfind( "", "" ) == size_t.max );
        assert( krfind( "a", "" ) == size_t.max );
        assert( krfind( "", "a" ) == size_t.max );

        // exact match
        assert( krfind( "abc", "abc" ) == 0 );

        // simple substring match
        assert( krfind( "abc", "a" ) == 0 );
        assert( krfind( "abca", "a" ) == 3 );
        assert( krfind( "abc", "b" ) == 1 );
        assert( krfind( "abc", "c" ) == 2 );
        assert( krfind( "abc", "d" ) == size_t.max );

        // multi-char substring match
        assert( krfind( "abc", "ab" ) == 0 );
        assert( krfind( "abcab", "ab" ) == 3 );
        assert( krfind( "abc", "bc" ) == 1 );
        assert( krfind( "abc", "ac" ) == size_t.max );
        assert( krfind( "abracadabrabra", "abracadabra" ) == 0 );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Find-If
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a linear search of buf from $(LB)0 .. buf.length$(RP),
     * returning the index of the first element where pred returns true.
     *
     * Params:
     *  buf  = The array to search.
     *  pred = The evaluation predicate, which should return true if the
     *         element is a valid match and false if not.  This predicate
     *         may be any callable type.
     *
     * Returns:
     *  The index of the first match or size_t.max if no match was found.
     */
    size_t findIf( Elem[] buf, PredT1E pred );
}
else
{
    template findIf_( Elem, Pred )
    {
        static assert( isCallableType!(Pred) );


        size_t fn( Elem[] buf, Pred pred )
        {
            foreach( size_t pos, Elem cur; buf )
            {
                if( pred( cur ) )
                    return pos;
            }
            return size_t.max;
        }
    }


    template findIf( Buf, Pred )
    {
        size_t findIf( Buf buf, Pred pred )
        {
            return findIf_!(ElemTypeOf!(Buf), Pred).fn( buf, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        int[5] buf;

        buf[0] = 1;
        buf[1] = 2;
        buf[2] = 4;
        buf[3] = 2;
        buf[4] = 6;

        assert( findIf( buf, ( int x ) { return x == 0; } ) == size_t.max );
        assert( findIf( buf, ( int x ) { return x == 1; } ) == 0 );
        assert( findIf( buf, ( int x ) { return x == 2; } ) == 1 );
        assert( findIf( buf, ( int x ) { return x == 3; } ) == size_t.max );
        assert( findIf( buf, ( int x ) { return x == 6; } ) == 4 );
        assert( findIf( buf, ( int x ) { return x == 7; } ) == size_t.max );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Reverse Find-If
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a linear search of buf from $(LB)buf.length .. 0$(RP),
     * returning the index of the first element where pred returns true.
     *
     * Params:
     *  buf  = The array to search.
     *  pred = The evaluation predicate, which should return true if the
     *         element is a valid match and false if not.  This predicate
     *         may be any callable type.
     *
     * Returns:
     *  The index of the first match or size_t.max if no match was found.
     */
    size_t rfindIf( Elem[] buf, PredT1E pred );
}
else
{
    template rfindIf_( Elem, Pred )
    {
        static assert( isCallableType!(Pred) );


        size_t fn( Elem[] buf, Pred pred )
        {
            if( buf.length == 0 )
                return size_t.max;

            size_t pos = buf.length;

            do
            {
                if( pred( buf[--pos] ) )
                    return pos;
            } while( pos > 0 );
            return size_t.max;
        }
    }


    template rfindIf( Buf, Pred )
    {
        size_t rfindIf( Buf buf, Pred pred )
        {
            return rfindIf_!(ElemTypeOf!(Buf), Pred).fn( buf, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        int[5] buf;

        buf[0] = 1;
        buf[1] = 2;
        buf[2] = 4;
        buf[3] = 2;
        buf[4] = 6;

        assert( rfindIf( buf, ( int x ) { return x == 0; } ) == size_t.max );
        assert( rfindIf( buf, ( int x ) { return x == 1; } ) == 0 );
        assert( rfindIf( buf, ( int x ) { return x == 2; } ) == 3 );
        assert( rfindIf( buf, ( int x ) { return x == 3; } ) == size_t.max );
        assert( rfindIf( buf, ( int x ) { return x == 6; } ) == 4 );
        assert( rfindIf( buf, ( int x ) { return x == 7; } ) == size_t.max );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Find
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a linear scan of buf from $(LB)0 .. buf.length$(RP), returning
     * a count of the number of elements matching pat.  Comparisons will be
     * performed using '=='.
     *
     * Params:
     *  buf = The array to scan.
     *  pat = The pattern to match.
     *
     * Returns:
     *  The index of the first match or size_t.max if no match was found.
     */
    size_t count( Elem[] buf, Elem pat );


    /**
     * Performs a linear scan of buf from $(LB)0 .. buf.length$(RP), returning
     * a count of the number of elements matching pat.  Comparisons will be
     * performed using the supplied predicate.
     *
     * Params:
     *  buf  = The array to scan.
     *  pat  = The pattern to match.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         equal to e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  The index of the first match or size_t.max if no match was found.
     */
    size_t count( Elem[] buf, Elem pat, PredT2E pred );

}
else
{
    template count_( Elem, Pred = IsEqual!(Elem) )
    {
        static assert( isCallableType!(Pred) );


        size_t fn( Elem[] buf, Elem pat, Pred pred = Pred.init )
        {
            size_t cnt = 0;

            foreach( size_t pos, Elem cur; buf )
            {
                if( pred( cur, pat ) )
                    ++cnt;
            }
            return cnt;
        }
    }


    template count( Buf, Pat )
    {
        size_t count( Buf buf, Pat pat )
        {
            return count_!(ElemTypeOf!(Buf)).fn( buf, pat );
        }
    }


    template count( Buf, Pat, Pred )
    {
        size_t count( Buf buf, Pat pat, Pred pred )
        {
            return count_!(ElemTypeOf!(Buf), Pred).fn( buf, pat, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        int[5] buf;

        buf[0] = 7;
        buf[1] = 2;
        buf[2] = 2;
        buf[3] = 2;
        buf[4] = 9;

        assert( count( buf, 0 ) == 0 );
        assert( count( buf, 7 ) == 1 );
        assert( count( buf, 2 ) == 3 );
        assert( count( buf, 9 ) == 1 );
        assert( count( buf, 4 ) == 0 );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Lower Bound
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a binary search of buf, returning the index of the first
     * element equivalent to pat.  If pat is less than all elements in
     * buf then 0 will be returned.  If pat is greater than the largest
     * element in buf then buf.length will be returned.  Comparisons will
     * be performed using '<'.
     *
     * Params:
     *  buf = The sorted array to search.
     *  pat = The pattern to search for.
     *
     * Returns:
     *  The index of the first match or size_t.max if no match was found.
     */
    size_t lbound( Elem[] buf, Elem pat );


    /**
     * Performs a binary search of buf, returning the index of the first
     * element equivalent to pat.  If pat is less than all elements in
     * buf then 0 will be returned.  If pat is greater than the largest
     * element in buf then buf.length will be returned.  Comparisons will
     * be performed using the supplied predicate.
     *
     * Params:
     *  buf = The sorted array to search.
     *  pat = The pattern to search for.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         less than e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  The index of the first match or size_t.max if no match was found.
     */
    size_t lbound( Elem[] buf, Elem pat, PredT2E pred );
}
else
{
    template lbound_( Elem, Pred = IsLess!(Elem) )
    {
        static assert( isCallableType!(Pred) );


        size_t fn( Elem[] buf, Elem pat, Pred pred = Pred.init )
        {
            size_t  beg   = 0,
                    end   = buf.length,
                    mid   = end / 2;

            while( beg + 1 < end )
            {
                if( pred( buf[mid], pat ) )
                    beg = mid + 1;
                else
                    end = mid;
                mid = beg + ( end - beg ) / 2;
            }
            return mid;
        }
    }


    template lbound( Buf, Pat )
    {
        size_t lbound( Buf buf, Pat pat )
        {
            return lbound_!(ElemTypeOf!(Buf)).fn( buf, pat );
        }
    }


    template lbound( Buf, Pat, Pred )
    {
        size_t lbound( Buf buf, Pat pat, Pred pred )
        {
            return lbound_!(ElemTypeOf!(Buf), Pred).fn( buf, pat, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        int[5] buf;

        buf[0] = 1;
        buf[1] = 2;
        buf[2] = 4;
        buf[3] = 5;
        buf[4] = 6;

        assert( lbound( buf, 0 ) == 0 );
        assert( lbound( buf, 7 ) == 5 );
        assert( lbound( buf, 3 ) == 2 );
        assert( lbound( buf, 4 ) == 2 );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Upper Bound
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a binary search of buf, returning the index of the first
     * element equivalent to pat.  If pat is less than all elements in
     * buf then 0 will be returned.  If pat is greater than or equivalent
     * to the largest element in buf then buf.length will be returned.
     * Comparisons will be performed using '<'.
     *
     * Params:
     *  buf = The sorted array to search.
     *  pat = The pattern to search for.
     *
     * Returns:
     *  The index of the first match or size_t.max if no match was found.
     */
    size_t ubound( Elem[] buf, Elem pat );


    /**
     * Performs a binary search of buf, returning the index of the first
     * element equivalent to pat.  If pat is less than all elements in
     * buf then 0 will be returned.  If pat is greater than or equivalent
     * to the largest element in buf then buf.length will be returned.
     * Comparisons will be performed using the supplied predicate.
     *
     * Params:
     *  buf = The sorted array to search.
     *  pat = The pattern to search for.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         less than e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  The index of the first match or size_t.max if no match was found.
     */
    size_t ubound( Elem[] buf, Elem pat, PredT2E pred );
}
else
{
    template ubound_( Elem, Pred = IsLess!(Elem) )
    {
        static assert( isCallableType!(Pred) );


        size_t fn( Elem[] buf, Elem pat, Pred pred = Pred.init )
        {
            size_t  beg   = 0,
                    end   = buf.length,
                    mid   = end / 2;

            while( beg + 1 < end )
            {
                if( !pred( pat, buf[mid] ) )
                    beg = mid + 1;
                else
                    end = mid;
                mid = beg + ( end - beg ) / 2;
            }
            return mid;
        }
    }


    template ubound( Buf, Pat )
    {
        size_t ubound( Buf buf, Pat pat )
        {
            return ubound_!(ElemTypeOf!(Buf)).fn( buf, pat );
        }
    }


    template ubound( Buf, Pat, Pred )
    {
        size_t ubound( Buf buf, Pat pat, Pred pred )
        {
            return ubound_!(ElemTypeOf!(Buf), Pred).fn( buf, pat, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        int[5] buf;

        buf[0] = 1;
        buf[1] = 2;
        buf[2] = 4;
        buf[3] = 5;
        buf[4] = 6;

        assert( ubound( buf, 0 ) == 0 );
        assert( ubound( buf, 7 ) == 5 );
        assert( ubound( buf, 3 ) == 2 );
        assert( ubound( buf, 4 ) == 3 );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Binay Search
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a binary search of buf, returning true if an element equivalent
     * to pat is found.  Comparisons will be performed using '<'.
     *
     * Params:
     *  buf = The sorted array to search.
     *  pat = The pattern to search for.
     *
     * Returns:
     *  True if an element equivalent to pat is found, false if not.
     */
    size_t bsearch( Elem[] buf, Elem pat );


    /**
     * Performs a binary search of buf, returning true if an element equivalent
     * to pat is found.  Comparisons will be performed using the supplied
     * predicate.
     *
     * Params:
     *  buf = The sorted array to search.
     *  pat = The pattern to search for.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         less than e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  True if an element equivalent to pat is found, false if not.
     */
    size_t bsearch( Elem[] buf, Elem pat, PredT2E pred );
}
else
{
    template bsearch_( Elem, Pred = IsLess!(Elem) )
    {
        static assert( isCallableType!(Pred) );


        size_t fn( Elem[] buf, Elem pat, Pred pred = Pred.init )
        {
            size_t pos = lbound( buf, pat, pred );
            return pos < buf.length && !( pat < buf[pos] );
        }
    }


    template bsearch( Buf, Pat )
    {
        size_t bsearch( Buf buf, Pat pat )
        {
            return bsearch_!(ElemTypeOf!(Buf)).fn( buf, pat );
        }
    }


    template bsearch( Buf, Pat, Pred )
    {
        size_t bsearch( Buf buf, Pat pat, Pred pred )
        {
            return bsearch_!(ElemTypeOf!(Buf), Pred).fn( buf, pat, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        int[5] buf;

        buf[0] = 1;
        buf[1] = 2;
        buf[2] = 4;
        buf[3] = 5;
        buf[4] = 6;

        assert( !bsearch( buf, 0 ) );
        assert(  bsearch( buf, 1 ) );
        assert(  bsearch( buf, 2 ) );
        assert( !bsearch( buf, 3 ) );
        assert(  bsearch( buf, 4 ) );
        assert(  bsearch( buf, 5 ) );
        assert(  bsearch( buf, 6 ) );
        assert( !bsearch( buf, 7 ) );
      }
    }
}