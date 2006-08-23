/**
 * The array module provides array manipulation routines in a manner that
 * balances performance and flexibility.  Operations are provides for sorting,
 * and for processing both sorted and unsorted arrays.
 *
 * Copyright: Copyright (C) 2005-2006 Sean Kelly.  All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Sean Kelly
 */
module tango.core.Array;


private import tango.core.Traits;


version( DDoc )
{
    typedef int Num;
    typedef int Elem;

    typedef bool function( Elem )       Pred1E;
    typedef bool function( Elem, Elem ) Pred2E;
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
     * returning the index of the first element matching pat, or buf.length
     * if no match was found.  Comparisons will be performed using the
     * supplied predicate or '==' if none is supplied.
     *
     * Params:
     *  buf  = The array to search.
     *  pat  = The pattern to search for.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         equal to e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  The index of the first match or buf.length if no match was found.
     */
    size_t find( Elem[] buf, Elem pat, Pred2E pred = Pred2E.init );


    /**
     * Performs a linear search of buf from $(LB)0 .. buf.length$(RP),
     * returning the index of the first element matching pat, or buf.length
     * if no match was found.  Comparisons will be performed using the
     * supplied predicate or '==' if none is supplied.
     *
     * Params:
     *  buf  = The array to search.
     *  pat  = The pattern to search for.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         equal to e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  The index of the first match or buf.length if no match was found.
     */
    size_t find( Elem[] buf, Elem[] pat, Pred2E pred = Pred2E.init );

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
            return buf.length;
        }


        size_t fn( Elem[] buf, Elem[] pat, Pred pred = Pred.init )
        {
            if( buf.length == 0 ||
                pat.length == 0 ||
                buf.length < pat.length )
            {
                return buf.length;
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
                            return buf.length;
                    } while( pred( buf[pos], pat[mat] ) );
                    pos -= mat;
                }
            }
            return buf.length;
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
        assert( find( "", 'a' ) == 0 );
        assert( find( "abc", 'a' ) == 0 );
        assert( find( "abc", 'b' ) == 1 );
        assert( find( "abc", 'c' ) == 2 );
        assert( find( "abc", 'd' ) == 3 );

        // null parameters
        assert( find( "", "" ) == 0 );
        assert( find( "a", "" ) == 1 );
        assert( find( "", "a" ) == 0 );

        // exact match
        assert( find( "abc", "abc" ) == 0 );

        // simple substring match
        assert( find( "abc", "a" ) == 0 );
        assert( find( "abca", "a" ) == 0 );
        assert( find( "abc", "b" ) == 1 );
        assert( find( "abc", "c" ) == 2 );
        assert( find( "abc", "d" ) == 3 );

        // multi-char substring match
        assert( find( "abc", "ab" ) == 0 );
        assert( find( "abcab", "ab" ) == 0 );
        assert( find( "abc", "bc" ) == 1 );
        assert( find( "abc", "ac" ) == 3 );
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
     * returning the index of the first element matching pat, or buf.length
     * if no match was found.  Comparisons will be performed using the
     * supplied predicate or '==' if none is supplied.
     *
     * Params:
     *  buf  = The array to search.
     *  pat  = The pattern to search for.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         equal to e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  The index of the first match or buf.length if no match was found.
     */
    size_t rfind( Elem[] buf, Elem pat, Pred2E pred = Pred2E.init );


    /**
     * Performs a linear search of buf from $(LP)buf.length .. 0$(RB),
     * returning the index of the first element matching pat, or buf.length
     * if no match was found.  Comparisons will be performed using the
     * supplied predicate or '==' if none is supplied.
     *
     * Params:
     *  buf  = The array to search.
     *  pat  = The pattern to search for.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         equal to e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  The index of the first match or buf.length if no match was found.
     */
    size_t rfind( Elem[] buf, Elem[] pat, Pred2E pred = Pred2E.init );
}
else
{
    template rfind_( Elem, Pred = IsEqual!(Elem) )
    {
        static assert( isCallableType!(Pred) );


        size_t fn( Elem[] buf, Elem pat, Pred pred = Pred.init )
        {
            if( buf.length == 0 )
                return buf.length;

            size_t pos = buf.length;

            do
            {
                if( pred( buf[--pos], pat ) )
                    return pos;
            } while( pos > 0 );
            return buf.length;
        }


        size_t fn( Elem[] buf, Elem[] pat, Pred pred = Pred.init )
        {
            if( buf.length == 0 ||
                pat.length == 0 ||
                buf.length < pat.length )
            {
                return buf.length;
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
                            return buf.length;
                    } while( pred( buf[pos], pat[mat] ) );
                    pos -= mat;
                }
            } while( pos > 0 );
            return buf.length;
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
        assert( rfind( "", 'a' ) == 0 );
        assert( rfind( "abc", 'a' ) == 0 );
        assert( rfind( "abc", 'b' ) == 1 );
        assert( rfind( "abc", 'c' ) == 2 );
        assert( rfind( "abc", 'd' ) == 3 );

        // null parameters
        assert( rfind( "", "" ) == 0 );
        assert( rfind( "a", "" ) == 1 );
        assert( rfind( "", "a" ) == 0 );

        // exact match
        assert( rfind( "abc", "abc" ) == 0 );

        // simple substring match
        assert( rfind( "abc", "a" ) == 0 );
        assert( rfind( "abca", "a" ) == 3 );
        assert( rfind( "abc", "b" ) == 1 );
        assert( rfind( "abc", "c" ) == 2 );
        assert( rfind( "abc", "d" ) == 3 );

        // multi-char substring match
        assert( rfind( "abc", "ab" ) == 0 );
        assert( rfind( "abcab", "ab" ) == 3 );
        assert( rfind( "abc", "bc" ) == 1 );
        assert( rfind( "abc", "ac" ) == 3 );
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
     * returning the index of the first element matching pat, or buf.length
     * if no match was found.  Comparisons will be performed using the
     * supplied predicate or '==' if none is supplied.
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
     *  The index of the first match or buf.length if no match was found.
     */
    size_t kfind( Elem[] buf, Elem pat, Pred2E pred = Pred2E.init );


    /**
     * Performs a linear search of buf from $(LB)0 .. buf.length$(RP),
     * returning the index of the first element matching pat, or buf.length
     * if no match was found.  Comparisons will be performed using the
     * supplied predicate or '==' if none is supplied.
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
     *  The index of the first match or buf.length if no match was found.
     */
    size_t kfind( Elem[] buf, Elem[] pat, Pred2E pred = Pred2E.init );
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
            return buf.length;
        }


        size_t fn( Elem[] buf, Elem[] pat, Pred pred = Pred.init )
        {
            if( buf.length == 0 ||
                pat.length == 0 ||
                buf.length < pat.length )
            {
                return buf.length;
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

            return buf.length;
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
        assert( kfind( "", 'a' ) == 0 );
        assert( kfind( "abc", 'a' ) == 0 );
        assert( kfind( "abc", 'b' ) == 1 );
        assert( kfind( "abc", 'c' ) == 2 );
        assert( kfind( "abc", 'd' ) == 3 );

        // null parameters
        assert( kfind( "", "" ) == 0 );
        assert( kfind( "a", "" ) == 1 );
        assert( kfind( "", "a" ) == 0 );

        // exact match
        assert( kfind( "abc", "abc" ) == 0 );

        // simple substring match
        assert( kfind( "abc", "a" ) == 0 );
        assert( kfind( "abca", "a" ) == 0 );
        assert( kfind( "abc", "b" ) == 1 );
        assert( kfind( "abc", "c" ) == 2 );
        assert( kfind( "abc", "d" ) == 3 );

        // multi-char substring match
        assert( kfind( "abc", "ab" ) == 0 );
        assert( kfind( "abcab", "ab" ) == 0 );
        assert( kfind( "abc", "bc" ) == 1 );
        assert( kfind( "abc", "ac" ) == 3 );
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
     * returning the index of the first element matching pat, or buf.length
     * if no match was found.  Comparisons will be performed using the
     * supplied predicate or '==' if none is supplied.
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
     *  The index of the first match or buf.length if no match was found.
     */
    size_t krfind( Elem[] buf, Elem pat, Pred2E pred = Pred2E.init );


    /**
     * Performs a linear search of buf from $(LP)buf.length .. 0$(RB),
     * returning the index of the first element matching pat, or buf.length
     * if no match was found.  Comparisons will be performed using the
     * supplied predicate or '==' if none is supplied.
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
     *  The index of the first match or buf.length if no match was found.
     */
    size_t krfind( Elem[] buf, Elem[] pat, Pred2E pred = Pred2E.init );
}
else
{
    template krfind_( Elem, Pred = IsEqual!(Elem) )
    {
        static assert( isCallableType!(Pred) );


        size_t fn( Elem[] buf, Elem pat, Pred pred = Pred.init )
        {
            if( buf.length == 0 )
                return buf.length;

            size_t pos = buf.length;

            do
            {
                if( pred( buf[--pos], pat ) )
                    return pos;
            } while( pos > 0 );
            return buf.length;
        }


        size_t fn( Elem[] buf, Elem[] pat, Pred pred = Pred.init )
        {
            if( buf.length == 0 ||
                pat.length == 0 ||
                buf.length < pat.length )
            {
                return buf.length;
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

            return buf.length;
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
        assert( krfind( "", 'a' ) == 0 );
        assert( krfind( "abc", 'a' ) == 0 );
        assert( krfind( "abc", 'b' ) == 1 );
        assert( krfind( "abc", 'c' ) == 2 );
        assert( krfind( "abc", 'd' ) == 3 );

        // null parameters
        assert( krfind( "", "" ) == 0 );
        assert( krfind( "a", "" ) == 1 );
        assert( krfind( "", "a" ) == 0 );

        // exact match
        assert( krfind( "abc", "abc" ) == 0 );

        // simple substring match
        assert( krfind( "abc", "a" ) == 0 );
        assert( krfind( "abca", "a" ) == 3 );
        assert( krfind( "abc", "b" ) == 1 );
        assert( krfind( "abc", "c" ) == 2 );
        assert( krfind( "abc", "d" ) == 3 );

        // multi-char substring match
        assert( krfind( "abc", "ab" ) == 0 );
        assert( krfind( "abcab", "ab" ) == 3 );
        assert( krfind( "abc", "bc" ) == 1 );
        assert( krfind( "abc", "ac" ) == 3 );
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
     *  The index of the first match or buf.length if no match was found.
     */
    size_t findIf( Elem[] buf, Pred1E pred );
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
            return buf.length;
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
        assert( findIf( "bcecg", ( int x ) { return x == 'a'; } ) == 5 );
        assert( findIf( "bcecg", ( int x ) { return x == 'b'; } ) == 0 );
        assert( findIf( "bcecg", ( int x ) { return x == 'c'; } ) == 1 );
        assert( findIf( "bcecg", ( int x ) { return x == 'd'; } ) == 5 );
        assert( findIf( "bcecg", ( int x ) { return x == 'g'; } ) == 4 );
        assert( findIf( "bcecg", ( int x ) { return x == 'h'; } ) == 5 );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Reverse Find-If
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a linear search of buf from $(LP)buf.length .. 0$(RB),
     * returning the index of the first element where pred returns true.
     *
     * Params:
     *  buf  = The array to search.
     *  pred = The evaluation predicate, which should return true if the
     *         element is a valid match and false if not.  This predicate
     *         may be any callable type.
     *
     * Returns:
     *  The index of the first match or buf.length if no match was found.
     */
    size_t rfindIf( Elem[] buf, Pred1E pred );
}
else
{
    template rfindIf_( Elem, Pred )
    {
        static assert( isCallableType!(Pred) );


        size_t fn( Elem[] buf, Pred pred )
        {
            if( buf.length == 0 )
                return buf.length;

            size_t pos = buf.length;

            do
            {
                if( pred( buf[--pos] ) )
                    return pos;
            } while( pos > 0 );
            return buf.length;
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
        assert( rfindIf( "bcecg", ( int x ) { return x == 'a'; } ) == 5 );
        assert( rfindIf( "bcecg", ( int x ) { return x == 'b'; } ) == 0 );
        assert( rfindIf( "bcecg", ( int x ) { return x == 'c'; } ) == 3 );
        assert( rfindIf( "bcecg", ( int x ) { return x == 'd'; } ) == 5 );
        assert( rfindIf( "bcecg", ( int x ) { return x == 'g'; } ) == 4 );
        assert( rfindIf( "bcecg", ( int x ) { return x == 'h'; } ) == 5 );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Find Adjacent
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a linear search of buf from $(LB)0 .. buf.length$(RP),
     * returning the index of the first element that compares equal to the
     * element immediately following it.  Comparisons will be performed using
     * the supplied predicate or '==' if none is supplied.
     *
     * Params:
     *  buf  = The array to scan.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         equal to e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  The index of the first match or buf.length if no match was found.
     */
    size_t findAdj( Elem[] buf, Elem pat, Pred2E pred = Pred2E.init );

}
else
{
    template findAdj_( Elem, Pred = IsEqual!(Elem) )
    {
        static assert( isCallableType!(Pred) );


        size_t fn( Elem[] buf, Pred pred = Pred.init )
        {
            if( buf.length < 2 )
                return buf.length;

            Elem sav = buf[0];

            foreach( size_t pos, Elem cur; buf[1 .. $] )
            {
                if( pred( cur, sav ) )
                    return pos;
                sav = cur;
            }
            return buf.length;
        }
    }


    template findAdj( Buf )
    {
        size_t findAdj( Buf buf )
        {
            return findAdj_!(ElemTypeOf!(Buf)).fn( buf );
        }
    }


    template findAdj( Buf, Pred )
    {
        size_t findAdj( Buf buf, Pred pred )
        {
            return findAdj_!(ElemTypeOf!(Buf), Pred).fn( buf, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        assert( findAdj( "aabcdef" ) == 0 );
        assert( findAdj( "abcddef" ) == 3 );
        assert( findAdj( "abcdeff" ) == 5 );
        assert( findAdj( "abcdefg" ) == 7 );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Count
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a linear scan of buf from $(LB)0 .. buf.length$(RP), returning
     * a count of the number of elements matching pat.  Comparisons will be
     * performed using the supplied predicate or '==' if none is supplied.
     *
     * Params:
     *  buf  = The array to scan.
     *  pat  = The pattern to match.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         equal to e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  The index of the first match or buf.length if no match was found.
     */
    size_t count( Elem[] buf, Elem pat, Pred2E pred = Pred2E.init );

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
        assert( count( "gbbbi", 'a' ) == 0 );
        assert( count( "gbbbi", 'g' ) == 1 );
        assert( count( "gbbbi", 'b' ) == 3 );
        assert( count( "gbbbi", 'i' ) == 1 );
        assert( count( "gbbbi", 'd' ) == 0 );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Select
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Partitions the array with num - 1 as a pivot such that the first num
     * elements will be less than or equal to the remaining elements in the
     * array.  Comparisons will be performed using the supplied predicate or
     * '<' if none is supplied.  The algorithm is not required to be stable.
     *
     * Params:
     *  buf  = The array to partition.  This parameter is not marked 'inout'
     *         to allow temporary slices to be sorted.  As buf is not resized
     *         in any way, omitting the 'inout' qualifier has no effect on
     *         the result of this operation, even though it may be viewed
     *         as a side-effect.
     *  num  = The number of elements which are considered significant in
     *         this array, where num - 1 is the pivot around which partial
     *         sorting will occur.  For example, if num is buf.length / 2
     *         then select will effectively partition the array around its
     *         median value, with the elements in the first half of the array
     *         evaluating as less than or equal to the elements in the second
     *         half.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         less than e2 and false if not.  This predicate may be any
     *         callable type.
     */
    void select( Elem[] buf, Num num, Pred2E pred = Pred2E.init );
}
else
{
    template select_( Elem, Pred = IsLess!(Elem) )
    {
        static assert( isCallableType!(Pred ) );


        // NOTE: buf is not 'inout' so subranges can be partitioned.  This
        //       should work for D arrays, since the Array type contains a
        //       pointer to the referenced data.
        void fn( Elem[] buf, size_t num, Pred pred = Pred.init )
        in
        {
            // NOTE: The original algorithm relies on the use of signed index
            //       values, and modifying it to use unsigned values is non-
            //       trivial.  For now, signed values will be used, and buf
            //       simply must be <= ptrdiff_t.max elements in size.
            assert( buf.length <= ptrdiff_t.max );
        }
        body
        {
            bool equiv( Elem p1, Elem p2 )
            {
                return !pred( p1, p2 ) && !pred( p2, p1 );
            }

            // NOTE: Indexes are passed instead of references because DMD does
            //       not inline the reference-based version.
            void exch( ptrdiff_t p1, ptrdiff_t p2 )
            {
                Elem t  = buf[p1];
                buf[p1] = buf[p2];
                buf[p2] = t;
            }

            if( buf.length < 2 )
                return;

            ptrdiff_t   l = 0,
                        r = buf.length - 1,
                        k = num;

            while( r > l )
            {
                ptrdiff_t   i = l - 1,
                            j = r;
                Elem        v = buf[r];
                while( true )
                {
                    while( i < r && pred( buf[++i], v ) )
                        {}
                    while( j > l && pred( v, buf[--j] ) )
                        {}
                    if( i >= j )
                        break;
                    exch( i, j );
                }
                exch( i, r );
                if( i >= k )
                    r = i - 1;
                if( i <= k )
                    l = i + 1;
            }
        }
    }


    template select( Buf, Num )
    {
        void select( Buf buf, Num num )
        {
            return select_!(ElemTypeOf!(Buf)).fn( buf, num );
        }
    }


    template select( Buf, Num, Pred )
    {
        void select( Buf buf, Num num, Pred pred )
        {
            return select_!(ElemTypeOf!(Buf), Pred).fn( buf, num, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        char[] buf = "efedcaabca";
        size_t num = buf.length / 2;

        select( buf, num );
        foreach( char cur; buf[0 .. num - 1] )
            assert( cur <= buf[num - 1] );
        foreach( char cur; buf[num - 1 .. $] )
            assert( cur >= buf[num - 1] );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Sort
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Sorts a range using the supplied predicate or '<' if none is supplied.
     * The algorithm is not required to be stable.  The current implementation
     * is based on quicksort, but uses a three-way partitioning scheme to
     * improve performance for ranges containing duplicate values (Bentley and
     * McIlroy, 1993).
     *
     * Params:
     *  buf  = The array to sort.  This parameter is not marked 'inout' to
     *         allow temporary slices to be sorted.  As buf is not resized
     *         in any way, omitting the 'inout' qualifier has no effect on
     *         the result of this operation, even though it may be viewed
     *         as a side-effect.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         less than e2 and false if not.  This predicate may be any
     *         callable type.
     */
    void sort( Elem[] buf, Pred2E pred = Pred2E.init );
}
else
{
    template sort_( Elem, Pred = IsLess!(Elem) )
    {
        static assert( isCallableType!(Pred ) );


        // NOTE: buf is not 'inout' so subranges can be sorted.  This should
        //       work for D arrays, since the Array type contains a pointer
        //       to the referenced data.
        void fn( Elem[] buf, Pred pred = Pred.init )
        in
        {
            // NOTE: The original algorithm relies on the use of signed index
            //       values, and modifying it to use unsigned values is non-
            //       trivial.  For now, signed values will be used, and buf
            //       simply must be <= ptrdiff_t.max elements in size.
            assert( buf.length <= ptrdiff_t.max );
        }
        body
        {
            bool equiv( Elem p1, Elem p2 )
            {
                return !pred( p1, p2 ) && !pred( p2, p1 );
            }

            // NOTE: Indexes are passed instead of references because DMD does
            //       not inline the reference-based version.
            void exch( ptrdiff_t p1, ptrdiff_t p2 )
            {
                Elem t  = buf[p1];
                buf[p1] = buf[p2];
                buf[p2] = t;
            }

            void quicksort( ptrdiff_t l, ptrdiff_t r )
            {
                if( r <= l )
                    return;

                // The general goal is to partition the range into three
                // parts, one each for keys smaller than, equal to, and
                // larger than the partitioning element:
                //
                // |--less than v--|--equal to v--|--greater than v--|
                // l               j              i                  r
                //
                // During partitioning, we maintain:
                //
                // |--equal--|--less--|--[###]--|--greater--|--equal--[v]
                // l         p        i         j           q          r

                Elem        v = buf[r];
                ptrdiff_t   i = l - 1,
                            j = r,
                            p = l - 1,
                            q = r,
                            k;

                while( true )
                {
                    while( i < r && pred( buf[++i], v ) )
                        {}
                    while( j > l && pred( v, buf[--j] ) )
                        {}
                    if( i >= j )
                        break;
                    exch( i, j );
                    if( equiv( buf[i], v ) )
                        exch( ++p, i );
                    if( equiv( v, buf[j] ) )
                        exch( --q, j );
                }
                exch( i, r );
                j = i - 1;
                i = i + 1;
                for( k = l; k <= p; k++, j-- )
                    exch( k, j );
                for( k = r - 1; k >= q; k--, i++ )
                    exch( k, i );
                quicksort( l, j );
                quicksort( i, r );
            }

            if( buf.length > 1 )
            {
                quicksort( 0, buf.length - 1 );
            }
        }
    }


    template sort( Buf )
    {
        void sort( Buf buf )
        {
            return sort_!(ElemTypeOf!(Buf)).fn( buf );
        }
    }


    template sort( Buf, Pred )
    {
        void sort( Buf buf, Pred pred )
        {
            return sort_!(ElemTypeOf!(Buf), Pred).fn( buf, pred );
        }
    }


    debug( UnitTest )
    {
      unittest
      {
        char[] buf = "edacb";

        sort( buf );
        foreach( i, v; buf )
        {
            assert( v == 'a' + i );
        }
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
     * be performed using the supplied predicate or '<' if none is supplied.
     *
     * Params:
     *  buf = The sorted array to search.
     *  pat = The pattern to search for.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         less than e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  The index of the first match or buf.length if no match was found.
     */
    size_t lbound( Elem[] buf, Elem pat, Pred2E pred = Pred2E.init );
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
        assert( lbound( "bcefg", 'a' ) == 0 );
        assert( lbound( "bcefg", 'h' ) == 5 );
        assert( lbound( "bcefg", 'd' ) == 2 );
        assert( lbound( "bcefg", 'e' ) == 2 );
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
     * Comparisons will be performed using the supplied predicate or '<'
     * if none is supplied.
     *
     * Params:
     *  buf = The sorted array to search.
     *  pat = The pattern to search for.
     *  pred = The evaluation predicate, which should return true if e1 is
     *         less than e2 and false if not.  This predicate may be any
     *         callable type.
     *
     * Returns:
     *  The index of the first match or buf.length if no match was found.
     */
    size_t ubound( Elem[] buf, Elem pat, Pred2E pred = Pred2E.init );
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
        assert( ubound( "bcefg", 'a' ) == 0 );
        assert( ubound( "bcefg", 'h' ) == 5 );
        assert( ubound( "bcefg", 'd' ) == 2 );
        assert( ubound( "bcefg", 'e' ) == 3 );
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
     * to pat is found.  Comparisons will be performed using the supplied
     * predicate or '<' if none is supplied.
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
    size_t bsearch( Elem[] buf, Elem pat, Pred2E pred = Pred2E.init );
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
        assert( !bsearch( "bcefg", 'a' ) );
        assert(  bsearch( "bcefg", 'b' ) );
        assert(  bsearch( "bcefg", 'c' ) );
        assert( !bsearch( "bcefg", 'd' ) );
        assert(  bsearch( "bcefg", 'e' ) );
        assert(  bsearch( "bcefg", 'f' ) );
        assert(  bsearch( "bcefg", 'g' ) );
        assert( !bsearch( "bcefg", 'h' ) );
      }
    }
}