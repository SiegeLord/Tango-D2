Tango D2 Port
========

This is a half-hearted effort to port [Tango](http://www.dsource.org/projects/tango/) to the [D2 programming language](http://www.dlang.org). I am doing this quickly, and in a haphazard fashion. I primarily care that it compiles, and passes the unittests (or my own quick tests). I am sure the parts I ported don't work 100%.

This port roughly follows the guidelines outlined in the `porting_guidelines` file. If you want to help out, please follow that procedure.

I see this as a rough first pass at porting this library... making it more D2-like will be the second pass.

What can you expect?
--------

There is some basic stuff that is quite useable in the current version. More modules may work, but only the listed ones pass the import + unittest test.

 * tango.io.Stdout
 * tango.io.Console
 * tango.io.File
 * tango.core.Array
 * tango.core.Thread
 * tango.core.Traits
 * tango.text.xml.Document
 * tango.text.convert.Layout
 * tango.util.container.*
 * tango.math.*
 * ... and some parts of the others ...
    
What you cannot expect!
--------

Anything that's hard to port... like intrinsics/anything that's Tango's runtime specific. But who knows... I'm porting stuff rather randomly.

Building the Libary
--------

You can just checkout the libary and start building it. There is a Makefile for GNU/Linux to build the libary. I assume that you're using dmd to compile it! Just type the following commands to your console.

    $ cd /usr/include/d/dmd
    $ git clone git://github.com/mtachrono/tango.git tango
    $ cd tango
    $ make -f posix.mak
    $ make install -f posix.mak
 
your build is generated into generated/$(BUILD)/$(MODEL)/libtango2.lib
and installed into /usr/lib$(MODEL)/libtango2.lib
    
example: generated/release/32/libtango2.lib -> /usr/lib32/libtango2.lib
example: generated/debug/64/libtango2.lib -> /usr/lib64/libtango2.lib

Makefile Targets
--------

If you want to build the libary  and additional parts you need to enter the following commands

 * make -f posix.mak                # same as 'make release -f posix.mak'

 * make release -f posix.mak        # build release (default) [adds -O -release -nofloat]
 * make debug -f posix.mak          # build debug [adds -g -debug]

 * make install -f posix.mak        # And of course you can install the libary to /usr/lib32 or /usr/lib64 (see MODEL)

 * make unittest -f posix.mak       # build debug and release unittest [adds -g -debug -debug=UnitTest -unittest ]
                                    # and starts testing each module in 32 and 64 bit mode.
                                   
 * make doc -f posix.mak            # You can also generate the docs. They'll be puttet to doc/html.

 * make clean -f posix.mak          # If you need to rebuild the libary, you can tidy up your folder with this command.

Makefile switches
--------

You can pass additional switches for make You can use multiple switches in conjunction with each other.

 * make -f posix.mak MODEL=64                           # 64-Bit Version
 * make -f posix.mak MODEL=32                           # 32-Bit Version (default)
 * make -f posix.mak DMD=/usr/local/dmd                 # use this dmd compiler
 * make -f posix.mak CFLAGS=... DFLAGS=... LFLAGS=...   # set your own .c, .d, and linker flags
    
Setting up your Environment
--------

If you want to build your applications with tango, you need to take care to link against the tango libary. You can tell dmd to automatically link to tangolib by modifing /etc/dmd.conf. Basically you need to add the following line.

-I/usr/include/d/dmd/tango -L-ltango2

Here is my complete /etc/dmd.conf

[Environment]
DFLAGS= -I/usr/include/d/dmd/phobos -I/usr/include/d/dmd/tango -I/usr/include/d/dmd/druntime/import -L-L/usr/lib32 -L-L/usr/lib64 -L--export-dynamic -L-lrt -L-ltango2

Guided Installation
--------

 * Online Installation Reference:  http://dsource.org/projects/tango/wiki/TopicInstallTango
 * License is available at http://dsource.org/projects/tango/wiki/LibraryLicense

Contact
--------

 * You can message me on github, or find me on IRC on #d and #d.tango @ irc.freenode.net
