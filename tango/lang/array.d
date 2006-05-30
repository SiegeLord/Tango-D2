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
 * The string module provides string manipulation routines in a manner that
 * balances performance and flexibility.
 *
 * Design Issues:
 *
 * While these functions will operate with wide character types, little attempt
 * has yet been made to provide any explicit Unicode support.  So case-insensitive
 * routines are not available and equality is done via binary comparisons.
 *
 * Future Directions:
 *
 * This module is the first attempt at developing function interface guidelines
 * for Ares.  All functions will likely be templates and will be designed with
 * implicit tempalte instantiation and template overloading as required features.
 * The goal here is to provide a useful set of string routines for everyday use
 * and to use this experience for developing more generalized algorithms later on.
 */
module tango.lang.array;


private import tango.lang.traits;


/**
 * Temporary until a predicate module can be created.
 */
template equalTo( Elem )
{
    /**
     *
     */
    bool equalTo( Elem a, Elem  b )
    {
        return a == b;
    }
}


/**
 *
 */
 /+
template find( Elem )
{
    /**
     *
     */
    size_t find( Elem[] str, Elem chr )
    {
        return find( str, chr, &equalTo!(Elem) );
    }
}


/**
 *
 */
 template find( Elem, Pred )
{
    static assert( isCallableType!(Pred) );

    /**
     *
     */
    size_t find( Elem[] str, Elem chr, Pred pred )
    {
        for( size_t pos = 0; pos < str.length; ++pos )
        {
            if( pred( str[pos], chr ) )
                return pos;
        }
        return size_t.max;
    }
}


unittest
{
    assert( find!(char)( "", 'a' ) == size_t.max );
    assert( find!(char)( "abc", 'a' ) == 0 );
    assert( find!(char)( "abc", 'b' ) == 1 );
    assert( find!(char)( "abc", 'c' ) == 2 );
    assert( find!(char)( "abc", 'd' ) == size_t.max );
}
+/


/**
 *
 */
template find( Elem )
{
    /**
     *
     */
    size_t find( Elem[] str, Elem[] pat )
    {
        alias bool function( Elem, Elem ) pf;
        return find!(Elem, pf)( str, pat, &equalTo!(Elem) );
    }
}


/**
 *
 */
template find( Elem, Pred )
{
    static assert( isCallableType!(Pred) );

  version( none )
  {
    /**
     *
     */
    size_t find( Elem[] str, Elem[] pat, Pred pred )
    {
        if( str.length == 0 ||
            pat.length == 0 ||
            str.length < pat.length )
        {
            return size_t.max;
        }

        size_t end = str.length - pat.length + 1;

        for( size_t pos = 0; pos < end; ++pos )
        {
            if( pred( str[pos], pat[0] ) )
            {
                size_t mat = 0;

                do
                {
                    if( ++mat >= pat.length )
                        return pos - pat.length + 1;
                    if( ++pos >= str.length )
                        return size_t.max;
                } while( pred( str[pos], pat[mat] ) );
                pos -= mat;
            }
        }
        return size_t.max;
    }
  }
  else
  {
    /**
     *
     */
    size_t find( Elem[] str, Elem[] pat, Pred pred )
    {
        if( str.length == 0 ||
            pat.length == 0 ||
            str.length < pat.length )
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
        for( size_t m = 0, i = 0; i < str.length; ++i )
        {
            while( ( m > 0 ) && !pred( pat[m], str[i] ) )
                m = func[m - 1];
            if( pred( pat[m], str[i] ) )
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
}


unittest
{
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


/**
 *
 */
 /+
template rfind( Elem )
{
    /**
     *
     */
    size_t rfind( Elem[] str, Elem chr )
    {
        return rfind( str, chr, &equalTo!(Elem) );
    }
}


/**
 *
 */
template rfind( Elem, Pred )
{
    static assert( isCallableType!(Pred) );

    /**
     *
     */
    size_t rfind( Elem[] str, Elem chr, Pred pred )
    {
        if( str.length == 0 )
            return size_t.max;

        size_t pos = str.length;

        do
        {
            if( pred( str[--pos], chr ) )
                return pos;
        } while( pos > 0 );
        return size_t.max;
    }
}


unittest
{
    assert( rfind!(char)( "", 'a' ) == size_t.max );
    assert( rfind!(char)( "abc", 'a' ) == 0 );
    assert( rfind!(char)( "abc", 'b' ) == 1 );
    assert( rfind!(char)( "abc", 'c' ) == 2 );
    assert( rfind!(char)( "abc", 'd' ) == size_t.max );
}
+/


/**
 *
 */
template rfind( Elem )
{
    /**
     *
     */
    size_t rfind( Elem[] str, Elem[] pat )
    {
        alias bool function( Elem, Elem ) pf;
        return rfind!(Elem, pf)( str, pat, &equalTo!(Elem) );
    }
}


/**
 *
 */
template rfind( Elem, Pred )
{
    static assert( isCallableType!(Pred) );

  version( none )
  {
    /**
     *
     */
    size_t rfind( Elem[] str, Elem[] pat, Pred pred )
    {
        if( str.length == 0 ||
            pat.length == 0 ||
            str.length < pat.length )
        {
            return size_t.max;
        }

        size_t pos = str.length - pat.length + 1;
        do
        {
            if( pred( str[--pos], pat[0] ) )
            {
                size_t mat = 0;
                do
                {
                    if( ++mat >= pat.length )
                        return pos - pat.length + 1;
                    if( ++pos >= str.length )
                        return size_t.max;
                } while( pred( str[pos], pat[mat] ) );
                pos -= mat;
            }
        } while( pos > 0 );
        return size_t.max;
    }
  }
  else
  {
    /**
     *
     */
    size_t rfind( Elem[] str, Elem[] pat, Pred pred )
    {
        if( str.length == 0 ||
            pat.length == 0 ||
            str.length < pat.length )
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
        size_t  i = str.length;
        do
        {
            --i;
            while( ( m > 0 ) && !pred( pat[length - m - 1], str[i] ) )
                m = func[length - m - 1];
            if( pred( pat[length - m - 1], str[i] ) )
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
}


unittest
{
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