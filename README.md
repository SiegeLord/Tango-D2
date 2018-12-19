Tango for D2
========

[![Build Status](https://travis-ci.org/SiegeLord/Tango-D2.svg?branch=travis_test)](https://travis-ci.org/SiegeLord/Tango-D2)

Last tested DMDFE: 2.083

This is an effort to port [Tango](http://www.dsource.org/projects/tango/) to the [D2 programming language](http://www.dlang.org).

This port roughly follows the guidelines outlined in the `porting_guidelines` file. If you want to help out, please follow that procedure.

What works so far
--------

Modules that have not been yet ported are located in the `unported` folder. All those located in the tango folder are ported, in the sense that they pass the import+unittest test (sometimes imperfectly on 64 bits due to DMD bugs). Right now this means that essentially all the user modules (with the exception for tango.math.BigNum, which is aliased to std.bigint until further notice) and a large majority of tango.core modules are ported. Examples in the doc/examples folder should also work.

I do the porting on Linux, so that is the most tested platform. It generally should also compile on Windows, but might not pass all the unit-tests, since DMD does weird things with unittests on Windows. All other platforms probably don't compile at all.

Documentation can be found here: http://siegelord.github.com/Tango-D2/

See Bugs.md for a list of D compiler bugs that affect Tango and possible workabouts for them.

Breaking changes from D1
--------

Since one of the important use cases of this port is porting programs from D1 to D2, breaking changes in functionality have been avoided as much as possible. Sometimes, however, this would introduce hidden heap usage or unsafe operation. Those things are even more detestable, especially for Tango's future, than breaking backwards compatibility. Cases where changes were introduced are documented here.

- tango.sys.Process
    - args no longer returns the program name as the first element. Get it from programName property instead.

Installation
--------

### From packages

jordisayol maintains a APT repository with a reasonably recent version of Tango-D2 available there. Worth a try if you're using a Debian based OS. To use it, follow the directions on this website: https://code.google.com/p/d-apt/wiki/APT_Repository .

### From source

It is possible to use the binary bob building tool (located in `build/bin/*/bob`) like so:

64-bit Linux

    cd PathToTango
    ./build/bin/linux64/bob -vu .

Windows

    cd PathToTango
    build\bin\win32\bob.exe -vu .

LDC2 is the primary testing compiler, but DMD seems to compile the library as well.

There is also an experimental Makefile building system. You can invoke it like so (modify the parameters you pass to make to suit preference):

    cd PathToTango
    make -f build/Makefile static-lib -j4 DC=ldc2
    make -f build/Makefile install-static-lib install-modules DC=ldc2

Notable version statements
-------

Define the following version statements to customize your build of the library:

* NoPhobos - Removes the Phobos2 dependencies from tango (tango.math.BigInt is the only dependency right now)
* TangoDemangler - Use Tango's old demangler instead of Druntime's

License
-------

See LICENSE.txt

Contact
--------

Find me on IRC on #d.tango @ irc.freenode.net or by email.
