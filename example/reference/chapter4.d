import tango.text.convert.Atoi,
       tango.text.convert.Double,
       tango.text.convert.DGDouble,
       tango.text.convert.Format,
       tango.text.convert.Integer,
       tango.text.convert.Rfc1123,
       tango.text.convert.Sprint,
       tango.text.convert.Unicode,
       tango.text.convert.UnicodeBom,
       tango.text.convert.Type,
       tango.io.Stdout;

void main () {
    char [] i = "+2100";
    char [] r = "2006.21";
    char [] d = "2006.314159";

    /* String to Number conversions */
    int integer = Atoi.parse(i);
    int alternate = Integer.parse(i);
    double double_ = Double.parse(r);
    real real_ = DGDouble.parse(d); // for extended accuracy
    Stdout.format("Integer [ {0}:{1} ], DGDouble [ {2} ], Double [ {3} ]",integer,alternate,real_ , double_).newline;

    /* Number to String conversions */
    char [64] intBuffer;
    char [64] floatBuffer;
    char [64] realBuffer;

    char [] intString = Integer.format(intBuffer,32 );
    char [] floatString = Double.format(floatBuffer,45 );
    char [] realString = DGDouble.format(realBuffer,32.65798,3 );

    Stdout.format("Integer [ {0} ], Double [ {1} ], DGDouble [ {2} ] ",intString,floatString,realString ).newline;

    /* HTTP date conversions , accepts strings in RFC1123 format*/
    char [] date = "Sun, 06 Nov 1994 08:49:37 GMT";
    ulong secondsSinceEpoch = Rfc1123.parse(date);
    char [256] dateBuffer;
    char [] dateString = Rfc1123.format(dateBuffer,secondsSinceEpoch);

    Stdout.format("secondsSinceEpoch [ {0}] , dateString [ {1} ]",secondsSinceEpoch,dateString ).newline;

    /* String formatting , replaces vsprintf() style functions*/

    // struct based sprint with no precision specifiers, all stack based
    char [256] stackSprintString;
    SprintStruct stackSprint;
    stackSprint.ctor(stackSprintString);
    char [] stringWithNoPrecision = stackSprint("{0} {1} {2} - {3} ","All your base","are","belong to us",2100 );
    Stdout(stringWithNoPrecision).newline;
    // class based sprint with precision specifiers, we use Double.format

    //Sprint sprint = new Sprint(256, &Double.format);
    //char [] stringWithPrecision = sprint ( "{0} is {1} times {2:f.3}","Julio",32, 5.68732 );
    //Stdout(stringWithPrecision).newline;


    /* converting to / from UTF8, UTF16, UTF32, both Big Endian and Little Endian */
    char [] str = "Marry had a little endian";
    wchar [] wstr = Unicode.toUtf16(str);
    dchar [] dstr = Unicode.toUtf32(str);
    char [] newStr = Unicode.toUtf8(wstr); // and back again
    newStr = Unicode.toUtf8(dstr); //and back again
    Stdout(newStr).newline;

    // or the alternate way
    Unicode.Into!(char) into; //  char is what converting into
    char [] catchAllConverter = cast(char[])into.convert(
            /* what you want to convert*/
            cast(void[])wstr,
            /* the type the your converting _from_ */
            Type.Utf16
            );
    Stdout(catchAllConverter).newline;


    /* Converting content to unicode for writing files.  See alsio tango.io.UnicodeFile .*/

    char [] bubbleBoy = "What you've never seen anyone in a bubble  before ?";

    // since were just encoding and not reading in
    // ( if we were reading in the encoding would be figured out by the BOM )
    // have to sepcify big or little endian

    UnicodeBomT!(char) bom = new UnicodeBomT!(char)(Unicode.UTF_16BE);

    void [] encoded = bom.encode(bubbleBoy );

    Stdout(cast(char[])bubbleBoy );


}





