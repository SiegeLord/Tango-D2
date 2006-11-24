/*******************************************************************************

        copyright:      Copyright (c) 2004 . All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: Oct 2004

        authors:

*******************************************************************************/

module tango.text.convert.UniOther;

private extern (C) void onUnicodeError( char[] msg, size_t idx );

/***********************************************************************

 ***********************************************************************/

package static final void error (char[] msg, size_t idx = 0)
{
        onUnicodeError (msg, idx);
}

/***********************************************************************

        Get a Utf32 dchar from a Utf8 Array char[].

        Decodes and returns character starting at input[aIndex]. 
        aIndex is advanced past the decoded character. 

        If the character is not well formed, 
        an UtfException is thrown and idx remains unchanged.

***********************************************************************/

static final dchar decode (char[] input, inout uint aIndex )
{
        uint idx = aIndex;
        dchar b = cast(dchar) input[ idx++ ];

        void err()
        {
                error ("Unicode.decode( char, uint ) : invalid utf8 input", idx-1 );
        }

        void check( bool aCondition )
        {
                if( !aCondition ){
                        err();
                }
        }

        // Get one more byte and shift it into the result. Increment idx.
        void oneMore()
        {
                dchar t = input[ idx++ ];
                check((t & 0xC0 ) == 0x80 );
                b = (b << 6) | ( t & 0x3f);
        }

        if (( b & 0x80 ) == 0x00 )
        {
                // do nothing, we are complete
        }
        else if (( b & 0xE0 ) == 0xC0 )
        {
                b &= 0x1f;
                oneMore();
        }
        else if (( b & 0xF0 ) == 0xE0 )
        {
                b &= 0x0f;
                oneMore();
                oneMore();
        }
        else if (( b & 0xF8 ) == 0xF0 )
        {
                b &= 0x07;
                oneMore();
                oneMore();
                oneMore();
        }
        else
        {
                err();
        }

        // did we exceed the valid range
        check (b < 0x110000);
        // did we read past the end of the input?
        check ( idx <= input.length );

        // populate the eaten bytes
        aIndex = idx;

        // return the produced output
        return b;
}

/***********************************************************************

        Get a Utf32 dchar from a Utf16 Array wchar[].

        Decodes and returns character starting at input[aIndex]. 
        aIndex is advanced past the decoded character. 

        If the character is not well formed, 
        an UtfException is thrown and idx remains unchanged.

***********************************************************************/

static final dchar decode (wchar[] input, inout uint aIndex )
{
        uint idx = aIndex;
        dchar d = cast(dchar) input[ idx++ ];

        void err()
        {
                error ("Unicode.decode( wchar, uint ) : invalid utf16 input", idx-1 );
        }

        void check( bool aCondition )
        {
                if( !aCondition ){
                        err();
                }
        }

        // simple conversion ~ see http://www.unicode.org/faq/utf_bom.html#35
        if (d >= 0xd800 && d <= 0xdfff){
                // did we read past the end of the input?
                check ( idx <= input.length );
                d = ((d - 0xd7c0) << 10) + (input[ idx ] - 0xdc00);
                idx++;
        }


        // did we exceed the valid range
        check (d < 0x110000);

        // did we read past the end of the input?
        check ( idx <= input.length );

        // populate the eaten bytes
        aIndex = idx;

        // return the produced output
        return d;
}

/***********************************************************************

        Get a Utf32 dchar from a Utf32 Array dchar[].

        Decodes and returns character starting at input[aIndex]. 
        aIndex is advanced past the decoded character. 

        If the character is not well formed, 
        an UtfException is thrown and idx remains unchanged.

***********************************************************************/

static final dchar decode (dchar[] input, inout uint aIndex )
{
        return input[ aIndex++ ];
}

/***********************************************************************

        Encode a Utf32 dchar to Utf8 and append it to the array aOutput

        If the character is not well formed, 
        an UtfException is thrown and idx remains unchanged.

***********************************************************************/

static final void encode( inout char[] aOutput, dchar aChar )
{
        if ( aChar < 0x80)
        {
                aOutput ~= aChar;
        }
        else if (aChar < 0x0800)
        {
                aOutput ~= 0xc0 | ((aChar >> 6) & 0x3f);
                aOutput ~= 0x80 | (aChar & 0x3f);
        }
        else if (aChar < 0x10000)
        {
                aOutput ~= 0xe0 | ((aChar >> 12) & 0x3f);
                aOutput ~= 0x80 | ((aChar >> 6)  & 0x3f);
                aOutput ~= 0x80 | (aChar & 0x3f);
        }
        else if (aChar < 0x110000)
        {
                aOutput ~= 0xf0 | ((aChar >> 18) & 0x3f);
                aOutput ~= 0x80 | ((aChar >> 12) & 0x3f);
                aOutput ~= 0x80 | ((aChar >> 6)  & 0x3f);
                aOutput ~= 0x80 | (aChar & 0x3f);
        }
        else
        {
                error ("Unicode.encode( char[], dchar ) : invalid dchar" );
        }
}

/***********************************************************************

        Encode a Utf32 dchar to Utf16 and append it to the array aOutput

        If the character is not well formed, 
        an UtfException is thrown and idx remains unchanged.

***********************************************************************/

static final void encode( inout wchar[] aOutput, dchar aChar )
{
        if (aChar < 0x10000)
        {
                aOutput ~= aChar;
        }
        else if (aChar < 0x110000)
        {
                aOutput ~= 0xd800 | (((aChar - 0x10000) >> 10) & 0x3ff);
                aOutput ~= 0xdc00 | ((aChar - 0x10000) & 0x3ff);
        }
        else
        {
                error ("Unicode.encode( wchar[], dchar ) : invalid dchar" );
        }
}

/***********************************************************************

        Append a Utf32 dchar to the array aOutput

        If the character is not well formed, 
        an UtfException is thrown and idx remains unchanged.

***********************************************************************/

static final void encode( inout dchar[] aOutput, dchar aChar )
{
        if (aChar < 0x110000)
        {
                aOutput ~= aChar;
        }
        else
        {
                error ("Unicode.encode( dchar[], dchar ) : invalid dchar" );
        }
}

/***********************************************************************

        Returns the index of the aSource of the Column.
        If a newline occurs befor the searched column, -1 is return.

***********************************************************************/

static final int indexOfColumn( T )( T[] aSource, int aColumnToSearch, int aTabSize = 8 ) in {
        assert( aTabSize > 0 );
        assert( aColumnToSearch >= 0 );
}
out( result ){
        assert( result < aSource.length );
}
body {
        uint idx = 0;
        int col = 0;
        while( col <= aColumnToSearch ){
            uint oldidx = idx;
                dchar d = decode( aSource, idx );
                switch( d ){
                case '\t':
                        col += aTabSize;
                        col -= ( col % aTabSize );
                        break;
                case '\r':
                case '\n':
                case PS:
                case LS:
                        // error
                        return -1;
                default:
                        col ++;
                        break;
                }
        }
        // idx is already incremented => minus one.
        return idx-1;
}

/***********************************************************************

        Returns the column count of aSource. If aSource contains more than
        one line, the maximum column width is returned.

***********************************************************************/

static final int getColumnCount(T)( T[] aSource, int aTabSize = 8 ) in {
        assert( aTabSize > 0 );
}
body {
        uint idx = 0;
        int col = 0;
        int res = 0;
        while( idx < aSource.length ){
                dchar d = decode( aSource, idx );
                switch( d ){
                case '\t':
                        col += aTabSize;
                        col -= ( col % aTabSize );
                        break;
                case '\r':
                case '\n':
                case PS:
                case LS:
                        if( col > res ){
                                res = col;
                        }
                        col = 0;
                        break;
                default:
                        col++;
                        break;
                }
        }
        if( col > res ){
                res = col;
        }
        return res;
}

debug( UnitTest ){
    import tango.io.Stdout;
    unittest{
        uint idx;
        dchar d;
        char[] ac;
        wchar[] aw;


        // Test for Utf8 <-> Utf32
        idx = 0;
        d = Unicode.decode( " "c, idx );
        assert( d == 0x20 );

        idx = 0;
        d = Unicode.decode( "\u03A0"c, idx );
        assert( d == 0x03A0 );

        idx = 0;
        d = Unicode.decode( "\u0E10"c, idx );
        assert( d == 0x0E10 );

        idx = 0;
        d = Unicode.decode( "\U00101234"c, idx );
        assert( d == 0x0101234 );

        ac = null;
        d = "\U00000020"d [0];
        Unicode.encode( ac, d );
        assert( ac == " " );

        ac = null;
        d = "\U000003A0"d [0];
        Unicode.encode( ac, d );
        assert( ac == "\u03A0"c );

        ac = null;
        d = "\U00000E10"d [0];
        Unicode.encode( ac, d );
        assert( ac == "\u0E10"c );

        ac = null;
        d = "\U00101234"d [0];
        Unicode.encode( ac, d );
        assert( ac == "\U00101234"c );

        // Test for Utf16 <-> Utf32
        idx = 0;
        d = Unicode.decode( " "w, idx );
        assert( d == 0x20 );

        idx = 0;
        d = Unicode.decode( "\u03A0"w, idx );
        assert( d == 0x03A0 );

        idx = 0;
        d = Unicode.decode( "\u0E10"w, idx );
        assert( d == 0x0E10 );

        idx = 0;
        d = Unicode.decode( "\U00101234"w, idx );
        assert( d == 0x0101234 );

        aw = null;
        d = "\U00000020"d [0];
        Unicode.encode( aw, d );
        assert( aw == " " );

        aw = null;
        d = "\U000003A0"d [0];
        Unicode.encode( aw, d );
        assert( aw == "\u03A0"w );

        aw = null;
        d = "\U00000E10"d [0];
        Unicode.encode( aw, d );
        assert( aw == "\u0E10"w );

        aw = null;
        d = "\U00101234"d [0];
        Unicode.encode( aw, d );
        assert( aw == "\U00101234"w );


        assert( getColumnCount( ""c ) == 0 );
        assert( getColumnCount( "xx"c ) == 2 );
        assert( getColumnCount( "xx\tx"c ) == 9 );
        assert( getColumnCount( "xxx\tx"c ) == 9 );
        // show up longes line
        assert( getColumnCount( "x\nxx\tx"c ) == 9 );
        assert( getColumnCount( "xxx\tx\nyy"c ) == 9 );
        assert( getColumnCount( "\u0123"c ) == 1 );
        assert( getColumnCount( "\u0123"w ) == 1 );


        //Stdout.formatln( "{0}", indexOfColumn( "12345"c, 3 ));
        assert( indexOfColumn( "12345"c, 3 ) == 3 );
        assert( indexOfColumn( "12\t12345"c,  0 ) == 0 );
        assert( indexOfColumn( "12\t12345"c,  1 ) == 1 );
        assert( indexOfColumn( "12\t12345"c,  2 ) == 2 );
        // result still two, because of tab
        assert( indexOfColumn( "12\t12345"c,  3 ) == 2 );
        assert( indexOfColumn( "12\t12345"c,  4 ) == 2 );
        assert( indexOfColumn( "12\t12345"c,  5 ) == 2 );
        assert( indexOfColumn( "12\t12345"c,  6 ) == 2 );
        assert( indexOfColumn( "12\t12345"c,  7 ) == 2 );
        // next char after tab
        assert( indexOfColumn( "12\t12345"c,  8 ) == 3 );
        assert( indexOfColumn( "12\t12345"c,  9 ) == 4 );
        assert( indexOfColumn( "12\t12345"c, 10 ) == 5 );

        // index stretched by 1, because of 2 byte utf8 char
        assert( indexOfColumn( "\u03A02345"c, 3 ) == 4 );
        // index stretched by 2, because of 3 byte utf8 char
        assert( indexOfColumn( "\u0EA02345"c, 3 ) == 5 );
        // index stretched by 3, because of 4 byte utf8 char
        assert( indexOfColumn( "\U001012342345"c, 3 ) == 6 );
        }
}
