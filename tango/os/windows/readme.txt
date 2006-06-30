+--------------------------------------+
| Translation of the Win32 API headers |
+--------------------------------------+


This is a project to create a well-crafted translation of the Windows 32-bit API headers in the D programming language.

The project started off as an improvement of Y. Tomino's translation, but is now officially a derivative of the public domain MinGW Windows headers.  However, it is useful to have to hand a copy of Tomino's work (or some other D translation of the Win32 headers) in order to test-compile the modules while the work is in progress.

An up-to-date version of this project can be downloaded from
http://pr.stewartsplace.org.uk/d/win32.zip
Email me with updates/comments/suggestions/bug reports: smjg@iname.com


Instructions
------------
1. Module naming

The name of each module shall be win32.qwert, where qwert.h is the name of the original header file.  This is for compatibility with the Tomino translation, but may change in the future.


2. Constant #defines to enum blocks

Convert #defines that define integral constants into enum blocks that group the constants logically.  If you can determine the appropriate type of the constants, then specify it as the base type of the enum.

If the enum block so defined contains consecutive values, they do not need to be explicitly specified, as D will automatically assign consecutive values to them.

Indent the constants within an enum block with one tab character.  In each enum block, align the equals signs in a column, using spaces rather than tabs.

Example:

enum : uint {
	WM_DDE_FIRST     = 0x03E0,
	WM_DDE_INITIATE  = WM_DDE_FIRST,
	WM_DDE_TERMINATE,
	WM_DDE_ADVISE,
	WM_DDE_UNADVISE,
	WM_DDE_ACK,
	WM_DDE_DATA,
	WM_DDE_REQUEST,
	WM_DDE_POKE,
	WM_DDE_EXECUTE,
	WM_DDE_LAST      = WM_DDE_EXECUTE
}


Sometimes in the original headers, a logical group of constants is interrupted with other declarations (e.g. constants related to specific Windows messages).  Move these interruptions to below the whole group.

Group constants of non-integer types (e.g. magic values of handles or string pointers) using a const declaration.  Example:

const HKEY
	HKEY_CLASSES_ROOT     = cast(HKEY) 0x80000000,
	HKEY_CURRENT_USER     = cast(HKEY) 0x80000001,
	HKEY_LOCAL_MACHINE    = cast(HKEY) 0x80000002,
	HKEY_USERS            = cast(HKEY) 0x80000003,
	HKEY_PERFORMANCE_DATA = cast(HKEY) 0x80000004,
	HKEY_CURRENT_CONFIG   = cast(HKEY) 0x80000005,
	HKEY_DYN_DATA         = cast(HKEY) 0x80000006;


3. Struct naming

Remove struct tag names.  Instead, define every struct with its first typedef'd name.  Make any other names aliases of this.

Indent a struct's members by one tab character.  Align the member names in a column using spaces.

Example:

struct VALENTW {
	LPWSTR ve_valuename;
	DWORD  ve_valuelen;
	DWORD  ve_valueptr;
	DWORD  ve_type;
}
alias VALENTW* PVALENTW;

Some structs have their own size in bytes as the first member, generally called cbSize, dwSize or lStructSize.  Use a member initialiser here.

A few structs use bit fields.  Because D doesn't have bit fields, they must be simulated using property getters/setters.  See dde.d for an example.  Use bool for one-bit members; otherwise use the smallest integer type that will accommodate the required number of bits.

Some structs end with a one-element array, designed to be followed immediately in memory by more elements of the same type.  Name such struct members with a leading underscore, and use a property getter to return just the pointer in order to prevent bounds checking.


4. COM interfaces

Translate DECLARE_INTERFACE constructions into D interfaces.  See unknwn.d for an example.  The macros used to access interface functions become unnecessary and may therefore be removed.


5. Consolidate aliases

Declare type aliases as aliases, not typedefs.  The only exception is

    typedef void* HANDLE;

since handles aren't interchangeable with pointers.  Define all specific handle types to be aliases of HANDLE.

Where multiple aliases for the same type appear in the same module (or logical section thereof), consolidate them into a single alias declaration.  For structs, these should be placed immediately below the struct definition.


6. Declare functions as extern (Windows)

Remove attributes such as WINAPI from function prototypes, replacing them with extern (Windows).  Where several functions are declared together, use an extern (Windows) attribute block.

This doesn't apply to macros converted to functions (see below).


7. Consolidate ANSI/Unicode selection into version blocks

Where #ifdef UNICODE is used to select A/W versions of functions and other identifiers, replace with version (Unicode).  Use only aliases, rather than enums or const declarations, within these version blocks.  These should be defined in one place at the end of each module, or at the end of some logical section within the module.  Consolidate any aliases of these aliases into the alias declarations within these version blocks.

As an exception, reduce string constants to a single declaration of type TCHAR[], bypassing the need to put such a constant in a version block.


8. Translate conditional compilation based on Windows version support

Every module that uses this conditional compilation must privately import win32.w32api, which defines the constants used to set the minimum version of Windows an application supports.

Unlike with the C headers, the programmer is expected to specify both the minimum Windows 9x version and the minimum Windows NT version, so both _WIN32_WINDOWS and _WIN32_WINNT are defined in any project.  Conditional compilation must therefore, in general, involve checking the values of both constants either directly or indirectly.  The WINVER and _WIN32_WINNT_ONLY constants are also defined for syntactic sugar.

Rather than relying on the conditionals in the MinGW headers, it is a good idea to look on http://msdn.microsoft.com/ to see which Windows versions support each entity that is CC'd.


9. Other conditional compilation

Use the built-in version (Win32) and version (Win64) to deal with _WIN64 conditional blocks.

For other #ifdefs designed to be specified by the programmer, leave the directive in, commented out.  This is pending decision on which to include and which to leave out, and how to name them.


10. Convert function-like macros to functions

Use the appropriate parameter and return types.  If necessary, consult the API docs to find out what these are.  (Watch out for parameters that are documented as LPSTR but should actually be LPTSTR!)

For type-generic macros, use a template.

Don't just leave the macro expansion verbatim; make some effort to make it look more like a function definition by:
* removing pointless parentheses and casts
* using line breaks and indentation as you might normally when writing a function


11. Remove leftover preprocessor directives

Remove any preprocessor directives, such as #if..#elseif..#endif and any #defines, that have been deemed unnecessary.


12. Whitespace conventions

Declare pointers D-style, i.e. a space after the '*', no space before.

Function definitions, struct/enum definitions, etc. should be separated by a blank line.  Exceptions: One-line functions (such as bitfield setters/getters) may be placed together without intervening blank lines.  Alias declarations of a struct or enum follow its definition without a blank line, and have a blank line below them.

Always indent the contents of a { ... } block of any kind by one tab character below the level of that in which it is contained.


13. Section heading comments (optional)

Comments may be used to create logical section headings within a module.  They shall look like this:

// Property sheet
// --------------


14. Deprecate functions (optional)

If you discover when reading the documentation for a function, structure, etc. that it is intended only for compatibility with 16-bit Windows versions, you may mark it as deprecated.  Group deprecated function prototypes within a block under a deprecated attribute block.  Be sure to deprecate the ANSI/Unicode aliases as well.

Although bothering with this is optional for the time being, it is preferred that if you do it at all, then you check the whole module for deprecated structures and functions.


15. Always check that the translated module compiles

After translating, compile the module to check for errors.

Sometimes there will be errors due to undefined types or other identifiers.  These compiled in C because of the nature of C preprocessor macros, but fail in D where they are treated symbolically.  To deal with this, use a private import.

It is a good idea to try compiling under all meaningful configurations of Windows versions:

* none specified (equivalent to Windows 95/NT 4)
* -version=Windows98
* -version=WindowsME
* -version=WindowsNTonly
* -version=Windows2000
* -version=Windows98 -version=Windows2000
* -version=WindowsME -version=Windows2000
* -version=WindowsNTonly -version=Windows2000
* -version=WindowsXP
* -version=Windows2003
