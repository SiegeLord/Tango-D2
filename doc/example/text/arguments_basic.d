/**
 * This example shows how to use tango.text.arguments.
 * Put into public domain by mta`chrono
 */

private import  tango.io.Stdout,
                tango.text.Arguments;


// ./arguments_basic -a -b    --> true, true, false
// ./arguments_basic -b       --> false, true, false
// ./arguments_basic --abc    --> false, false, false
// ./arguments_basic --a      --> true, false, false
// ./arguments_basic -abc     --> true, false, false (sloppy=false) [default]
// ./arguments_basic -abc     --> true, true, true  (sloppy=true)

// ./arguments_basic --foo=bar--> [bar]
// ./arguments_basic --foo bar--> [bar]

int main(char[][] args)
{
    // parse arguments
    bool sloppy = false;
    auto arguments = new Arguments(args, sloppy);
    
    // fetch arguments.
    auto a = arguments("a");        // uses ( and )
    auto b = arguments["b"];        // uses [ and ]
    auto c = arguments.get("c");    // uses get method
    auto foo = arguments("foo");
    
    // debug output
    Stdout(a.set, b.set, c.set).newline;
    Stdout(foo.assigned).newline;

    // conditional case
    if (a.set && b.set)
        Stdout("a and b are evaluate true").newline;

    // ok
    return 0;
}
