/++
  Author: Aziz Köksal
  License: GPL3
+/

string lang_code = "en";

string[] messages = [
  // Lexer messages:
  "illegal character found: '{0}'",
//   "invalid Unicode character.",
  "invalid UTF-8 sequence: '{0}'",
  // ''
  "unterminated character literal.",
  "empty character literal.",
  // #line
  "expected 'line' after '#'.",
  "integer expected after #line",
//   `expected filespec string (e.g. "path\to\file".)`,
  "unterminated filespec string.",
  "expected a terminating newline after special token.",
  // ""
  "unterminated string literal.",
  // x""
  "non-hex character '{0}' found in hex string.",
  "odd number of hex digits in hex string.",
  "unterminated hex string.",
  // /* */ /+ +/
  "unterminated block comment (/* */).",
  "unterminated nested comment (/+ +/).",
  // `` r""
  "unterminated raw string.",
  "unterminated back quote string.",
  // \x \u \U
  "found undefined escape sequence '{0}'.",
  "found invalid Unicode escape sequence '{0}'.",
  "insufficient number of hex digits in escape sequence: '{0}'",
  // \&[a-zA-Z][a-zA-Z0-9]+;
  "undefined HTML entity '{0}'",
  "unterminated HTML entity '{0}'.",
  "HTML entities must begin with a letter.",
  // integer overflows
  "decimal number overflows sign bit.",
  "overflow in decimal number.",
  "overflow in hexadecimal number.",
  "overflow in binary number.",
  "overflow in octal number.",
  "overflow in float number.",
  "digits 8 and 9 are not allowed in octal numbers.",
  "invalid hex number; at least one hex digit expected.",
  "invalid binary number; at least one binary digit expected.",
  "the exponent of a hexadecimal float number is required.",
  "hexadecimal float exponents must start with a digit.",
  "exponents must start with a digit.",

  // Parser messages
  "expected '{0}', but found '{1}'.",
  "'{0}' is redundant.",
  "template tuple parameters can only be last.",
  "the functions 'in' contract was already parsed.",
  "the functions 'out' contract was already parsed.",
  "no linkage type was specified.",
  "unrecognized linkage type '{0}'; valid types are C, C++, D, Windows, Pascal und System.",
  "expected one or more base classes, not '{0}'.",
  "base classes are not allowed in forward declarations.",

  // Help messages:
  `dil v{0}
Copyright (c) 2007-2008 by Aziz Köksal. Licensed under the GPL3.

Subcommands:
{1}
Type 'dil help <subcommand>' for more help on a particular subcommand.

Compiled with {2} v{3} on {4}.`,

  `Generate an XML or HTML document from a D source file.
Usage:
  dil gen file.d [Options]

Options:
  --syntax         : generate tags for the syntax tree
  --xml            : use XML format (default)
  --html           : use HTML format

Example:
  dil gen Parser.d --html --syntax > Parser.html`,

  `Parse a module and extract information from the resulting module dependency graph.
Usage:
  dil igraph file.d Format [Options]

  The directory of file.d is implicitly added to the list of import paths.

Format:
  --dot            : generate a dot document
  Further options for --dot:
  -gbp             : Group modules by package names
  -gbf             : Group modules by full package name
  -hle             : highlight cyclic edges in the graph
  -hlv             : highlight modules in cyclic relationship

  --paths          : print a list of paths to the modules imported by file.d
  --list           : print a list of the module names imported by file.d
  Options common to --paths and --list:
  -lN              : print N levels.
  -m               : mark modules in cyclic relationships with a star.

Options:
  -Ipath           : add 'path' to the list of import paths where modules are
                     looked for
  -rREGEXP         : exclude modules whose names match the regular expression
                     REGEXP
  -i               : include unlocatable modules

Example:
  dil igraph src/main.d`,
];
