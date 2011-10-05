/*******************************************************************************

        Illustrates the basic console formatting. This is different than
        the use of tango.io.Console, in that Stdout supports a variety of
        printf-style formatting, and has unicode-conversion support

*******************************************************************************/

private import tango.io.Stdout;

void main()
{
    // simple print
    Stdout ("hello, sweetheart \u263a").newline;                // hello, sweetheart ☺
    
    // print different variable types
    int a = -20;
    uint b = 1;
    long c = 10000;
    double d = 3.6;
    Stdout(a, b, c, d).newline;                                 // -20, 1, 10000, 3.60
    
    // print arrays
    int[] aa = [0x2, 0x62, 0x7, 0x21];
    double[] ab = [0.65, 7.202, 3.2125, 5.0/3];
    Stdout(aa).newline;                                         // [2, 98, 7, 33]
    Stdout(ab).newline;                                         // [0.65, 7.20, 3.21, 1.67]
    
    // format print
    int cars = 10;
    int goals = 45;
    string name = "Jonny";
    Stdout.formatln("There are {} cars on the road.", cars);    // There are 10 cars on the road.
    Stdout.formatln("{} has {} goals!", name, goals);           // Jonny has 45 goals!
    Stdout.formatln("{1} goals by {0}.", name, goals);          // 45 goals by Jonny.
    Stdout.formatln("{} + {1} = {} - {1} = {0}", 7, 8, 7+8);    // 7 + 8 = 15 - 8 = 7
    
    // alignment
    Stdout.formatln("'{,30}'", "right");                        // '                         right'
    Stdout.formatln("'{,-30}'", "left");                        // 'left                          '
    
    // class, toString
    class A
    {
        override immutable(char)[] toString()
        {
            return "I'm the A class!";
        }
    }
    
    Stdout(new A).newline;                                      // I'm the A class!
}
