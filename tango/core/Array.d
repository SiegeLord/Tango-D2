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


////////////////////////////////////////////////////////////////////////////////
// Find
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a linear search of buf from [0 .. buf.length&#41;, returning the
     * index of the first element matching pat, or size_t.max if no match was
     * found.  Comparisons will be performed using '=='.
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
     * Performs a linear search of buf from [0 .. buf.length&#41;, returning the
     * index of the first element matching pat, or size_t.max if no match was
     * found.  Comparisons will be performed using the supplied predicate.
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
     * Performs a linear search of buf from [0 .. buf.length&#41;, returning the
     * index of the first element matching pat, or size_t.max if no match was
     * found.  Comparisons will be performed using '=='.
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
     * Performs a linear search of buf from [0 .. buf.length&#41;, returning the
     * index of the first element matching pat, or size_t.max if no match was
     * found.  Comparisons will be performed using the supplied predicate.
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
    template find_( Elem, Pred )
    {
        static assert( isCallableType!(Pred) );


        size_t fn( Elem[] buf, Elem pat )
        {
            foreach( size_t pos, Elem cur; buf )
            {
                if( cur == pat )
                    return pos;
            }
            return size_t.max;
        }


        size_t fn( Elem[] buf, Elem pat, Pred pred )
        {
            foreach( size_t pos, Elem cur; buf )
            {
                if( pred( cur, pat ) )
                    return pos;
            }
            return size_t.max;
        }


        size_t fn( Elem[] buf, Elem[] pat )
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
                if( buf[pos] == pat[0] )
                {
                    size_t mat = 0;

                    do
                    {
                        if( ++mat >= pat.length )
                            return pos - pat.length + 1;
                        if( ++pos >= buf.length )
                            return size_t.max;
                    } while( buf[pos] == pat[mat] );
                    pos -= mat;
                }
            }
            return size_t.max;
        }


        size_t fn( Elem[] buf, Elem[] pat, Pred pred )
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


    template find( Elem, Pred = bool function( Elem, Elem ) )
    {
        alias find_!(Elem, Pred).fn find;
    }


    debug( UnitTest )
    {
      unittest
      {
        // find element
        assert( find!(char)( "", 'a' ) == size_t.max );
        assert( find!(char)( "abc", 'a' ) == 0 );
        assert( find!(char)( "abc", 'b' ) == 1 );
        assert( find!(char)( "abc", 'c' ) == 2 );
        assert( find!(char)( "abc", 'd' ) == size_t.max );

        // null parameters
        assert( find!(char)( "", "" ) == size_t.max );
        assert( find!(char)( "a", "" ) == size_t.max );
        assert( find!(char)( "", "a" ) == size_t.max );

        // exact match
        assert( find!(char)( "abc", "abc" ) == 0 );

        // simple substring match
        assert( find!(char)( "abc", "a" ) == 0 );
        assert( find!(char)( "abca", "a" ) == 0 );
        assert( find!(char)( "abc", "b" ) == 1 );
        assert( find!(char)( "abc", "c" ) == 2 );
        assert( find!(char)( "abc", "d" ) == size_t.max );

        // multi-char substring match
        assert( find!(char)( "abc", "ab" ) == 0 );
        assert( find!(char)( "abcab", "ab" ) == 0 );
        assert( find!(char)( "abc", "bc" ) == 1 );
        assert( find!(char)( "abc", "ac" ) == size_t.max );
        assert( find!(char)( "abrabracadabra", "abracadabra" ) == 3 );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Reverse Find
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a linear search of buf from &#40;buf.length .. 0], returning the
     * index of the first element matching pat, or size_t.max if no match was
     * found.  Comparisons will be performed using '=='.
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
     * Performs a linear search of buf from &#40;buf.length .. 0], returning the
     * index of the first element matching pat, or size_t.max if no match was
     * found.  Comparisons will be performed using the supplied predicate.
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
     * Performs a linear search of buf from &#40;buf.length .. 0], returning the
     * index of the first element matching pat, or size_t.max if no match was
     * found.  Comparisons will be performed using '=='.
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
     * Performs a linear search of buf from &#40;buf.length .. 0], returning the
     * index of the first element matching pat, or size_t.max if no match was
     * found.  Comparisons will be performed using the supplied predicate.
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
    template rfind_( Elem, Pred )
    {
        static assert( isCallableType!(Pred) );


        size_t fn( Elem[] buf, Elem pat )
        {
            if( buf.length == 0 )
                return size_t.max;

            size_t pos = buf.length;

            do
            {
                if( buf[--pos] == pat )
                    return pos;
            } while( pos > 0 );
            return size_t.max;
        }


        size_t fn( Elem[] buf, Elem pat, Pred pred )
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


        size_t fn( Elem[] buf, Elem[] pat )
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
                if( buf[--pos] == pat[0] )
                {
                    size_t mat = 0;

                    do
                    {
                        if( ++mat >= pat.length )
                            return pos - pat.length + 1;
                        if( ++pos >= buf.length )
                            return size_t.max;
                    } while( buf[pos] == pat[mat] );
                    pos -= mat;
                }
            } while( pos > 0 );
            return size_t.max;
        }


        size_t fn( Elem[] buf, Elem[] pat, Pred pred )
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


    template rfind( Elem, Pred = bool function( Elem, Elem ) )
    {
        alias rfind_!(Elem, Pred).fn rfind;
    }


    debug( UnitTest )
    {
      unittest
      {
        // rfind element
        assert( rfind!(char)( "", 'a' ) == size_t.max );
        assert( rfind!(char)( "abc", 'a' ) == 0 );
        assert( rfind!(char)( "abc", 'b' ) == 1 );
        assert( rfind!(char)( "abc", 'c' ) == 2 );
        assert( rfind!(char)( "abc", 'd' ) == size_t.max );

        // null parameters
        assert( rfind!(char)( "", "" ) == size_t.max );
        assert( rfind!(char)( "a", "" ) == size_t.max );
        assert( rfind!(char)( "", "a" ) == size_t.max );

        // exact match
        assert( rfind!(char)( "abc", "abc" ) == 0 );

        // simple substring match
        assert( rfind!(char)( "abc", "a" ) == 0 );
        assert( rfind!(char)( "abca", "a" ) == 3 );
        assert( rfind!(char)( "abc", "b" ) == 1 );
        assert( rfind!(char)( "abc", "c" ) == 2 );
        assert( rfind!(char)( "abc", "d" ) == size_t.max );

        // multi-char substring match
        assert( rfind!(char)( "abc", "ab" ) == 0 );
        assert( rfind!(char)( "abcab", "ab" ) == 3 );
        assert( rfind!(char)( "abc", "bc" ) == 1 );
        assert( rfind!(char)( "abc", "ac" ) == size_t.max );
        assert( rfind!(char)( "abracadabrabra", "abracadabra" ) == 0 );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// KMP Find
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a linear search of buf from [0 .. buf.length&#41;, returning the
     * index of the first element matching pat, or size_t.max if no match was
     * found.  Comparisons will be performed using '=='.  This function is
     * equivalent to its 'find' counterpart.
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
     * Performs a linear search of buf from [0 .. buf.length&#41;, returning the
     * index of the first element matching pat, or size_t.max if no match was
     * found.  Comparisons will be performed using the supplied predicate.
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
     * Performs a linear search of buf from [0 .. buf.length&#41;, returning the
     * index of the first element matching pat, or size_t.max if no match was
     * found.  Comparisons will be performed using '=='.  This function is
     * equivalent to its 'find' counterpart.
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
     * Performs a linear search of buf from [0 .. buf.length&#41;, returning the
     * index of the first element matching pat, or size_t.max if no match was
     * found.  Comparisons will be performed using the supplied predicate.
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
    template kfind_( Elem, Pred )
    {
        static assert( isCallableType!(Pred) );


        size_t fn( Elem[] buf, Elem pat )
        {
            foreach( size_t pos, Elem cur; buf )
            {
                if( cur == pat )
                    return pos;
            }
            return size_t.max;
        }


        size_t fn( Elem[] buf, Elem pat, Pred pred )
        {
            foreach( size_t pos, Elem cur; buf )
            {
                if( pred( cur, pat ) )
                    return pos;
            }
            return size_t.max;
        }


        size_t fn( Elem[] buf, Elem[] pat )
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
                while( ( m > 0 ) && ( pat[m] != pat[i] ) )
                    m = func[m - 1];
                if( pat[m] == pat[i] )
                    ++m;
                func[i] = m;
            }

            //
            // searching
            //
            for( size_t m = 0, i = 0; i < buf.length; ++i )
            {
                while( ( m > 0 ) && ( pat[m] != buf[i] ) )
                    m = func[m - 1];
                if( pat[m] == buf[i] )
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


        size_t fn( Elem[] buf, Elem[] pat, Pred pred )
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


    template kfind( Elem, Pred = bool function( Elem, Elem ) )
    {
        alias kfind_!(Elem, Pred).fn kfind;
    }


    debug( UnitTest )
    {
      unittest
      {
        // find element
        assert( kfind!(char)( "", 'a' ) == size_t.max );
        assert( kfind!(char)( "abc", 'a' ) == 0 );
        assert( kfind!(char)( "abc", 'b' ) == 1 );
        assert( kfind!(char)( "abc", 'c' ) == 2 );
        assert( kfind!(char)( "abc", 'd' ) == size_t.max );

        // null parameters
        assert( kfind!(char)( "", "" ) == size_t.max );
        assert( kfind!(char)( "a", "" ) == size_t.max );
        assert( kfind!(char)( "", "a" ) == size_t.max );

        // exact match
        assert( kfind!(char)( "abc", "abc" ) == 0 );

        // simple substring match
        assert( kfind!(char)( "abc", "a" ) == 0 );
        assert( kfind!(char)( "abca", "a" ) == 0 );
        assert( kfind!(char)( "abc", "b" ) == 1 );
        assert( kfind!(char)( "abc", "c" ) == 2 );
        assert( kfind!(char)( "abc", "d" ) == size_t.max );

        // multi-char substring match
        assert( kfind!(char)( "abc", "ab" ) == 0 );
        assert( kfind!(char)( "abcab", "ab" ) == 0 );
        assert( kfind!(char)( "abc", "bc" ) == 1 );
        assert( kfind!(char)( "abc", "ac" ) == size_t.max );
        assert( kfind!(char)( "abrabracadabra", "abracadabra" ) == 3 );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// KMP Reverse Find
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a linear search of buf from &#40;buf.length .. 0], returning the
     * index of the first element matching pat, or size_t.max if no match was
     * found.  Comparisons will be performed using '=='.  This function is
     * equivalent to its 'rfind' counterpart.
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
     * Performs a linear search of buf from &#40;buf.length .. 0], returning the
     * index of the first element matching pat, or size_t.max if no match was
     * found.  Comparisons will be performed using the supplied predicate.
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
     * Performs a linear search of buf from &#40;buf.length .. 0], returning the
     * index of the first element matching pat, or size_t.max if no match was
     * found.  Comparisons will be performed using '=='.  This function is
     * equivalent to its 'rfind' counterpart.
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
     * Performs a linear search of buf from &#40;buf.length .. 0], returning the
     * index of the first element matching pat, or size_t.max if no match was
     * found.  Comparisons will be performed using the supplied predicate.
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
    template krfind_( Elem, Pred )
    {
        static assert( isCallableType!(Pred) );


        size_t fn( Elem[] buf, Elem pat )
        {
            if( buf.length == 0 )
                return size_t.max;

            size_t pos = buf.length;

            do
            {
                if( buf[--pos] == pat )
                    return pos;
            } while( pos > 0 );
            return size_t.max;
        }


        size_t fn( Elem[] buf, Elem pat, Pred pred )
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


        size_t fn( Elem[] buf, Elem[] pat )
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
                while( ( m > 0 ) && ( pat[length - m - 1] != pat[i - 1] ) )
                    m = func[length - m];
                if( pat[length - m - 1] == pat[i - 1] )
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
                while( ( m > 0 ) && ( pat[length - m - 1] != buf[i] ) )
                    m = func[length - m - 1];
                if( ( pat[length - m - 1] == buf[i] ) )
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


        size_t fn( Elem[] buf, Elem[] pat, Pred pred )
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


    template krfind( Elem, Pred = bool function( Elem, Elem ) )
    {
        alias krfind_!(Elem, Pred).fn krfind;
    }


    debug( UnitTest )
    {
      unittest
      {
        // rfind element
        assert( krfind!(char)( "", 'a' ) == size_t.max );
        assert( krfind!(char)( "abc", 'a' ) == 0 );
        assert( krfind!(char)( "abc", 'b' ) == 1 );
        assert( krfind!(char)( "abc", 'c' ) == 2 );
        assert( krfind!(char)( "abc", 'd' ) == size_t.max );

        // null parameters
        assert( krfind!(char)( "", "" ) == size_t.max );
        assert( krfind!(char)( "a", "" ) == size_t.max );
        assert( krfind!(char)( "", "a" ) == size_t.max );

        // exact match
        assert( krfind!(char)( "abc", "abc" ) == 0 );

        // simple substring match
        assert( krfind!(char)( "abc", "a" ) == 0 );
        assert( krfind!(char)( "abca", "a" ) == 3 );
        assert( krfind!(char)( "abc", "b" ) == 1 );
        assert( krfind!(char)( "abc", "c" ) == 2 );
        assert( krfind!(char)( "abc", "d" ) == size_t.max );

        // multi-char substring match
        assert( krfind!(char)( "abc", "ab" ) == 0 );
        assert( krfind!(char)( "abcab", "ab" ) == 3 );
        assert( krfind!(char)( "abc", "bc" ) == 1 );
        assert( krfind!(char)( "abc", "ac" ) == size_t.max );
        assert( krfind!(char)( "abracadabrabra", "abracadabra" ) == 0 );
      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Find-If
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a linear search of buf from [0 .. buf.length&#41;, returning the
     * index of the first element where pred returns true.
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


    template findIf( Elem, Pred = bool function( Elem ) )
    {
        alias findIf_!(Elem, Pred).fn findIf;
    }


    debug( UnitTest )
    {
      unittest
      {

      }
    }
}


////////////////////////////////////////////////////////////////////////////////
// Reverse Find-If
////////////////////////////////////////////////////////////////////////////////


version( DDoc )
{
    /**
     * Performs a linear search of buf from &#40;buf.length .. 0], returning the
     * index of the first element where pred returns true.
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


    template rfindIf( Elem, Pred = bool function( Elem ) )
    {
        alias rfindIf_!(Elem, Pred).fn rfindIf;
    }


    debug( UnitTest )
    {
      unittest
      {

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
    template lbound_( Elem, Pred )
    {
        static assert( isCallableType!(Pred) );


        size_t fn( Elem[] buf, Elem pat )
        {
            size_t  beg   = 0,
                    end   = buf.length,
                    mid   = end / 2;

            while( beg + 1 < end )
            {
                if( buf[mid] < pat )
                    beg = mid + 1;
                else
                    end = mid;
                mid = beg + ( end - beg ) / 2;
            }
            return mid;
        }


        size_t fn( Elem[] buf, Elem pat, Pred pred )
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


    template lbound( Elem, Pred = bool function( Elem, Elem ) )
    {
        alias lbound_!(Elem, Pred).fn lbound;
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

        assert( lbound!(int)( buf, 0 ) == 0 );
        assert( lbound!(int)( buf, 7 ) == 5 );
        assert( lbound!(int)( buf, 3 ) == 2 );
        assert( lbound!(int)( buf, 4 ) == 2 );
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
    template ubound_( Elem, Pred )
    {
        static assert( isCallableType!(Pred) );


        size_t fn( Elem[] buf, Elem pat )
        {
            size_t  beg   = 0,
                    end   = buf.length,
                    mid   = end / 2;

            while( beg + 1 < end )
            {
                if( !( pat < buf[mid] ) )
                    beg = mid + 1;
                else
                    end = mid;
                mid = beg + ( end - beg ) / 2;
            }
            return mid;
        }


        size_t fn( Elem[] buf, Elem pat, Pred pred )
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


    template ubound( Elem, Pred = bool function( Elem, Elem ) )
    {
        alias ubound_!(Elem, Pred).fn ubound;
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

        assert( ubound!(int)( buf, 0 ) == 0 );
        assert( ubound!(int)( buf, 7 ) == 5 );
        assert( ubound!(int)( buf, 3 ) == 2 );
        assert( ubound!(int)( buf, 4 ) == 3 );
      }
    }
}