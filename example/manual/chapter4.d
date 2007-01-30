import tango.text.convert.Format,
       tango.text.convert.Sprint,
       tango.text.convert.UnicodeBom,
       tango.io.Stdout;

import Integer   = tango.text.convert.Integer,
       Unicode   = tango.text.convert.Utf,
       Float     = tango.text.convert.Float,
       TimeStamp = tango.text.convert.TimeStamp;

void main () {
    char [] i = "+2100";
    char [] r = "2006.21";

    /* String to Number conversions */
    int integer = Integer.parse(i);
    int alternate = Integer.parse(i);
    double double_ = Float.parse(r);
    Stdout.format("Integer [ {0}:{1} ], Double [ {3} ]",integer,alternate, double_).newline;

    /* Number to String conversions */
    char [64] intBuffer;
    char [64] floatBuffer;
    char [64] realBuffer;

    char [] intString = Integer.format(intBuffer,32.0 );
    char [] floatString = Float.format(floatBuffer,45.0 );

    Stdout.format("Integer [ {0} ], Float [ {1} ]",intString,floatString ).newline;

    /* HTTP date conversions , accepts strings in RFC1123 format*/
    char [] date = "Sun, 06 Nov 1994 08:49:37 GMT";
    ulong secondsSinceEpoch = TimeStamp.parse(date);
    char [256] dateBuffer;
    char [] dateString = TimeStamp.format(dateBuffer,secondsSinceEpoch);

    Stdout.format("secondsSinceEpoch [ {0}] , dateString [ {1} ]",secondsSinceEpoch,dateString ).newline;

    /* String formatting , replaces vsprintf() style functions*/

    // sprint
    auto sprint = new Sprint!(char);
    auto stringWithNoPrecision = sprint.format("{0} {1} {2} - {3} ","All your base","are","belong to us",2100 );
    Stdout(stringWithNoPrecision).newline;

    /* converting to / from UTF8, UTF16, UTF32, both Big Endian and Little Endian */
    char [] str = "Mary had a little endian";
    wchar [] wstr = Unicode.toUtf16(str);
    dchar [] dstr = Unicode.toUtf32(str);
    char [] newStr = Unicode.toUtf8(wstr); // and back again
    newStr = Unicode.toUtf8(dstr); //and back again
    Stdout(newStr).newline;


    /* Converting content to unicode for writing files.  See alsio tango.io.UnicodeFile .*/

    char [] bubbleBoy = "What you've never seen anyone in a bubble before ?";

    // since were just encoding and not reading in
    // ( if we were reading in the encoding would be figured out by the BOM )
    // have to sepcify big or little endian

   // UnicodeBom!(char) bom = new UnicodeBom!(char)(Unicode.UTF_16BE);

    //void [] encoded = bom.encode(bubbleBoy );

    Stdout(cast(char[])bubbleBoy );


}





