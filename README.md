Tango for D2
========
This is a half-hearted effort to port [Tango](http://www.dsource.org/projects/tango/) to the [D2 programming language](http://www.dlang.org). I am doing this quickly, and in a haphazard fashion. I primarily care that it compiles, and passes the unittests (or my own quick tests). I am sure the parts I ported don't work 100%.

This port roughly follows the guidelines outlined in the `porting_guidelines` file. If you want to help out, please follow that procedure.

I see this as a rough first pass at porting this library... making it more D2-like will be the second pass.

What works so far
--------

Modules that have not been yet ported are located in the `unported` folder. All those located in the tango folder are ported, in the sense that they pass the import+unittest test (sometimes imperfectly on 64 bits due to DMD bugs). See also the `ported_modules` list which enumerates the ported modules.

I do the porting on Linux, so that is the most tested platform. It generally should also compile on Windows, but might not pass all the unit-tests, since DMD does weird things with unittests on Windows. All other platforms probably don't compile at all.

Some notables
--------

 * tango.io.Stdout and the imported modules (notably tango.io.Console, tango.text.convert.Layout and tango.core.Thread (maybe))
 * tango.text.xml.Document and the imported modules
 * tango.io.device.File
 * tango.core.Array
 * tango.core.Traits
 * tango.math
 * tango.util.container

What will work next
--------

Who knows... I'm porting stuff rather randomly.

What won't work for awhile:

Anything that's hard to port... like intrinsics/anything that's Tango's runtime specific

How to use it
--------

It is possible to use the binary bob building tool (located in `build/bin/*/bob`) like so:

    cd PathToTango
    ./build/bin/linux64/bob -vu .

Contact
--------

You can message me on Github, or find me on IRC on #d and #d.tango @ irc.freenode.net
