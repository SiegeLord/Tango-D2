Modules in constants should contain only enums or version statements.
The modules should be present on all platforms (importing them should never fail).

These modules are automatically created by precompiling the ones in the lib/consts/generators with the command dppAll.sh which calls dpp.sh to preompile each file.

On windows just the files in the win directory will be used.

the building directory contains some helpful things to help generating .dpp files.

A .c is simply a file that gets precompiled, and then the part before xxx start xxx is discarded along with all occurrences of __XYX__.

http://opengroup.org/onlinepubs/007908799/headix.html