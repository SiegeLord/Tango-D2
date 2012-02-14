Tango for D2
========
This is an effort to port [Tango](http://www.dsource.org/projects/tango/) to the [D2 programming language](http://www.dlang.org).

This port roughly follows the guidelines outlined in the `porting_guidelines` file. If you want to help out, please follow that procedure.

I see this as a rough first pass at porting this library... making it more D2-like will be the second pass.

What works so far
--------

Modules that have not been yet ported are located in the `unported` folder. All those located in the tango folder are ported, in the sense that they pass the import+unittest test (sometimes imperfectly on 64 bits due to DMD bugs). Right now this means that essentially all the user modules (with the exception for tango.math.BigNum, which is aliased to std.bigint until further notice) and a large majority of tango.core modules are ported. Examples in the doc/examples folder should also work.

I do the porting on Linux, so that is the most tested platform. It generally should also compile on Windows, but might not pass all the unit-tests, since DMD does weird things with unittests on Windows. All other platforms probably don't compile at all.

How to use it
--------

It is possible to use the binary bob building tool (located in `build/bin/*/bob`) like so:

64-bit Linux

    cd PathToTango
    ./build/bin/linux64/bob -vu .

Windows

    cd PathToTango
    build\bin\win32\bob.exe -vu .

DMD is the primary testing compiler, but LDC2 seems to compile the library as well.

License
-------

See LICENSE.txt

Contact
--------

You can message me on Github, or find me on IRC on #d and #d.tango @ irc.freenode.net
