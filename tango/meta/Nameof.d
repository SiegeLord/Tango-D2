/**
 *  Convert any D symbol or type to a human-readable string, at compile time.
 *
 *   Given any D symbol (class, template, function, module name, global, static or local variable)
 *   or any D type, convert it to a compile-time string literal,
 *   optionally containing the fully qualified and decorated name.
 *
 *   Limitations (as of DMD 0.173):
 *   1. The name mangling for symbols declared inside extern(Windows), extern(C) and extern(Pascal)
 *      functions is inherently ambiguous, so such inner symbols are not always correctly displayed.
 *   2. Every symbol converted in this way creates an usued enum in the obj file. (It is
 *      discardarded at link time).
 *
 * License:   BSD style: $(LICENSE)
 * Authors:   Don Clugston
 * Copyright: Copyright (C) 2005-2006 Don Clugston
 */
module tango.meta.Nameof;
private import tango.meta.Demangle;

private {
    // --------------------------------------------
    // Here's the magic...
    template Mang(alias F)
    {
        // Make a unique type for each identifier; but don't actually
        // use the identifier for anything.
        // This works because any class, struct or enum always needs to be fully qualified.
        enum mange { ignore }
        // If you take the .mangleof an alias parameter, you are only
        // told that it is an alias.
        // So, we put the type as a function parameter.
        alias void function(mange ) mangF;
        // We get the .mangleof for this function pointer. We do this
        // from inside this same template, so that we avoid
        // compilications with alias parameters from inner functions.
        const char [] mangledname = typeof(mangF).mangleof;
    }

// If the identifier is "MyIdentifier" and this module is "QualModule"
// The return value will be:
//  "PF"   -- because it's a pointer to a function
//   "E"     -- because the first parameter is an enum
//    "10QualModule"  -- the name of this module
//      "45" -- the number of characters in the remainder of the mangled name.
//         Note that this could be more than 2 characters, but will be at least "10".
//      "__T"    -- because it's a class inside a template
//       "4Mang" -- the name of the template "Mang"
//       "T" MyIdentifer -- Here's our prize!
//       "Z"  -- marks the end of the template parameters for "Mang"
//    "5mange" -- this is the enum "mange"
//  "Z"  -- the return value of the function is coming
//  "v"  -- the function returns void

// The only unknown parts above are:
// (1) the name of this source file
// (it could move or be renamed). So we do a simple case:
//  "C"   -- it's a class
//   "10QualModule" -- the name of this module
//   "15establishMangle" -- the name of the class
// and (2) the number of characters in the remainder of the name

    class establishMangle {}
    // Get length of this (fully qualified) module name
    const int modulemanglelength = establishMangle.mangleof.length - "C15establishMangle".length;

    // Get the number of chars at the start relating to the pointer
    const int pointerstartlength = "PFC".length + modulemanglelength + "__T4Mang".length;
    // And the number of chars at the end
    const int pointerendlength = "Z5mangeZv".length;
}

// --------------------------------------------------------------
// Now, some functions which massage the mangled name to give something more useful.


/**
 * Like .mangleof, except that it works for an alias template parameter instead of a type.
 */
template manglednameof(alias A)
{
    static if (Mang!(A).mangledname.length - pointerstartlength <= 100 + 1) {
        // the length of the template argument requires 2 characters
        const char [] manglednameof  =
             Mang!(A).mangledname[ pointerstartlength + 2 .. $ - pointerendlength];
    } else
        const char [] manglednameof  =
             Mang!(A).mangledname[ pointerstartlength + 3 .. $ - pointerendlength];
}

/**
 * The symbol as it was declared, but including full type qualification.
 *
 * example: "int mymodule.myclass.myfunc(uint, class otherclass)"
 */
template prettynameof(alias A)
{
  const char [] prettynameof = prettyTemplateArg!(manglednameof!(A), MangledNameType.PrettyName);
}

/** Convert any D type to a human-readable string literal
 *
 * example: "int function(double, char[])"
 */
template prettytypeof(A)
{
  const char [] prettytypeof = demangleType!(A.mangleof, MangledNameType.PrettyName);
}

/**
 * Returns the qualified name of the symbol A.
 *
 * This will be a sequence of identifiers, seperated by dots.
 * eg "mymodule.myclass.myfunc"
 * This is the same as prettynameof(), except that it doesn't include any type information.
 */
template qualifiednameof(alias A)
{
  const char [] qualifiednameof = prettyTemplateArg!(manglednameof!(A), MangledNameType.QualifiedName);
}

/**
 * Returns the unqualified name, as a single text string.
 *
 * eg. "myfunc"
 */
template symbolnameof(alias A)
{
  const char [] symbolnameof = prettyTemplateArg!(manglednameof!(A), MangledNameType.SymbolName);
}

//----------------------------------------------
//                Unit Tests
//----------------------------------------------

debug(UnitTest) {

// remove the ".d" from the end
const char [] THISFILE = "tango.meta.Nameof";


private {
// Declare some structs, classes, enums, functions, and templates.

template ClassTemplate(A)
{
   class ClassTemplate {}
}

struct OuterClass  {
class SomeClass {}
}

alias double delegate (int, OuterClass) SomeDelegate;

template IntTemplate(int F)
{
  class IntTemplate { }
}

template MyInt(int F)
{
    const int MyIntX = F;
}


enum SomeEnum { ABC = 2 }
SomeEnum SomeInt;


static assert( prettytypeof!(real) == "real");
static assert( prettytypeof!(OuterClass.SomeClass) == "class " ~ THISFILE ~".OuterClass.SomeClass");

// Test that it works with module names (for example, this module)
static assert( qualifiednameof!(tango.meta.Nameof) == "tango.meta.Nameof");
static assert( symbolnameof!(tango.meta.Nameof) == "Nameof");

static assert( prettynameof!(SomeInt) == "enum " ~ THISFILE ~ ".SomeEnum " ~ THISFILE ~ ".SomeInt");
static assert( qualifiednameof!(OuterClass) == THISFILE ~".OuterClass");
static assert( symbolnameof!(SomeInt) == "SomeInt");
static assert( prettynameof!(ClassTemplate!(OuterClass.SomeClass))
    == "class "~ THISFILE ~ ".ClassTemplate!(class "~ THISFILE ~ ".OuterClass.SomeClass).ClassTemplate");
static assert( symbolnameof!(ClassTemplate!(OuterClass.SomeClass))  == "ClassTemplate");

// Extern(D) declarations have full type information.
extern int pig();
extern int pog;
static assert( prettynameof!(pig) == "int " ~ THISFILE ~ ".pig()");
static assert( prettynameof!(pog) == "int " ~ THISFILE ~ ".pog");
static assert( symbolnameof!(pig) == "pig");

// Extern(Windows) declarations contain no type information.
extern (Windows) {
    extern int dog();
    extern int dig;
}

static assert( prettynameof!(dog) == "dog");
static assert( prettynameof!(dig) == "dig");

// There are some nasty corner cases involving classes that are inside functions.
// Corner case #1: class inside nested function inside template

extern (Windows) {
template aardvark(X) {
    int aardvark(short goon) {
        class ant {}
        static assert(prettynameof!(ant)== "class extern (Windows) " ~ THISFILE ~ ".aardvark!(struct "
            ~ THISFILE ~ ".OuterClass).aardvark(short).ant");
        static assert(qualifiednameof!(ant)== THISFILE ~ ".aardvark.aardvark.ant");
        static assert( symbolnameof!(ant) == "ant");
        return 3;
        }
    }
}

// This is just to ensure that the static assert actually gets executed.
const test_aardvark = is (aardvark!(OuterClass) == function);

// Corner case #2: template inside function. This is currently possible only with mixins.
template fox(B, ushort C) {
    class fox {}
}

}

creal wolf(uint a) {

        mixin fox!(cfloat, 21);
        static assert(prettynameof!(fox)== "class " ~ THISFILE ~ ".wolf(uint).fox!(cfloat, int = 21).fox");
        static assert(qualifiednameof!(fox)== THISFILE ~ ".wolf.fox.fox");
        static assert(symbolnameof!(fox)== "fox");
        ushort innerfunc(...)
        {
            wchar innervar;
            static assert(prettynameof!(innervar)== "wchar " ~ THISFILE ~ ".wolf(uint).innerfunc(...).innervar");
            static assert(symbolnameof!(innervar)== "innervar");
            static assert(qualifiednameof!(innervar)== THISFILE ~ ".wolf.innerfunc.innervar");
            return 0;
        }
        return 0+0i;
}

}