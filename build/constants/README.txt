Modules in constants should contain only enums or similar.
The modules should be present on all platforms (importing them should never fail).

These modules are automatically created by precompiling the ones in the lib/constants/generators with the command dppAll.sh which calls dpp.sh to precompile each file.
The precompiled files are stored in tango/stdc/constants/autoconf, and you can use them with tango by using -version=autoconf

A .c is simply a file that gets precompiled, and then the part before "xxx start xxx" is discarded along with all occurrences of __XYX__.
The dppAll2.sh script leaves the part before "xxx start xxx", so that you have to remove it by hand.
This is useful because in that part there are the definition of types that C uses, and enum definitions.
You might have to take enums from that part and add them to the header by hand.
The definition of C types can be used to check that the definitions used by tango in stdc.* are correct.

A useful starting point with standard contents of header files is:
http://opengroup.org/onlinepubs/007908799/headix.html

Fawzi