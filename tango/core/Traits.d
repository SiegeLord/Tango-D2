/**
 * The traits module defines tools useful for obtaining detailed compile-time
 * information about a type.  Please note that the mixed naming scheme used in
 * this module is intentional.  Templates which evaluate to a type follow the
 * naming convention used for types, and templates which evaluate to a value
 * follow the naming convention used for functions.
 *
 * Copyright: Copyright (C) 2005-2006 Sean Kelly.  All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Sean Kelly, Fawzi Mohamed, Abscissa
 */
module tango.core.Traits;

/**
 * Strips the qualifiers from a type
 */

template BaseTypeOf( T )
{
    static if (is(T S : shared(S)))
        alias S BaseTypeOf;
    else static if (is(T S : shared(const(S))))
        alias S BaseTypeOf;
    else static if (is(T S : const(S)))
        alias S BaseTypeOf;
    else
        alias T BaseTypeOf;
}

/**
 * Computes the effective type that inout would have if you have it two parameters of difference constness
 */

template InoutTypeOf(T, M)
{
    static assert(is(BaseTypeOf!(T) == BaseTypeOf!(M)));
    static if (is(immutable(BaseTypeOf!(T)) == T) && is(immutable(BaseTypeOf!(T)) == M))
        alias immutable(BaseTypeOf!(T)) InoutTypeOf;
    else static if ((is(BaseTypeOf!(T) == T) && is(BaseTypeOf!(T) == M)))
        alias BaseTypeOf!(T) InoutTypeOf;
    else
        alias const(BaseTypeOf!(T)) InoutTypeOf;
}

/**
 * Evaluates to true if T is char[], wchar[], or dchar[].
 */
template isStringType( T )
{
    const bool isStringType = is( T : const(char)[] )  ||
                              is( T : const(wchar)[] ) ||
                              is( T : const(dchar)[] );
}

/**
 * Evaluates to true if T is char, wchar, or dchar.
 */
template isCharType( T )
{
    const bool isCharType = is( BaseTypeOf!(T) == char )  ||
                            is( BaseTypeOf!(T) == wchar ) ||
                            is( BaseTypeOf!(T) == dchar );
}


/**
 * Evaluates to true if T is a signed integer type.
 */
template isSignedIntegerType( T )
{
    const bool isSignedIntegerType = is( BaseTypeOf!(T) == byte )  ||
                                     is( BaseTypeOf!(T) == short ) ||
                                     is( BaseTypeOf!(T) == int )   ||
                                     is( BaseTypeOf!(T) == long )/+||
                                     is( T == cent  )+/;
}


/**
 * Evaluates to true if T is an unsigned integer type.
 */
template isUnsignedIntegerType( T )
{
    const bool isUnsignedIntegerType = is( BaseTypeOf!(T) == ubyte )  ||
                                       is( BaseTypeOf!(T) == ushort ) ||
                                       is( BaseTypeOf!(T) == uint )   ||
                                       is( BaseTypeOf!(T) == ulong )/+||
                                       is( T == ucent  )+/;
}


/**
 * Evaluates to true if T is a signed or unsigned integer type.
 */
template isIntegerType( T )
{
    const bool isIntegerType = isSignedIntegerType!(T) ||
                               isUnsignedIntegerType!(T);
}


/**
 * Evaluates to true if T is a real floating-point type.
 */
template isRealType( T )
{
    const bool isRealType = is( BaseTypeOf!(T) == float )  ||
                            is( BaseTypeOf!(T) == double ) ||
                            is( BaseTypeOf!(T) == real );
}


/**
 * Evaluates to true if T is a complex floating-point type.
 */
template isComplexType( T )
{
    const bool isComplexType = is( BaseTypeOf!(T) == cfloat )  ||
                               is( BaseTypeOf!(T) == cdouble ) ||
                               is( BaseTypeOf!(T) == creal );
}


/**
 * Evaluates to true if T is an imaginary floating-point type.
 */
template isImaginaryType( T )
{
    const bool isImaginaryType = is( T == ifloat )  ||
                                 is( T == idouble ) ||
                                 is( T == ireal );
}


/**
 * Evaluates to true if T is any floating-point type: real, complex, or
 * imaginary.
 */
template isFloatingPointType( T )
{
    const bool isFloatingPointType = isRealType!(T)    ||
                                     isComplexType!(T) ||
                                     isImaginaryType!(T);
}

/// true if T is an atomic type
template isAtomicType(T)
{
    static if( is( T == bool )
            || is( T == char )
            || is( T == wchar )
            || is( T == dchar )
            || is( T == byte )
            || is( T == short )
            || is( T == int )
            || is( T == long )
            || is( T == ubyte )
            || is( T == ushort )
            || is( T == uint )
            || is( T == ulong )
            || is( T == float )
            || is( T == double )
            || is( T == real )
            || is( T == ifloat )
            || is( T == idouble )
            || is( T == ireal ) )
        const isAtomicType = true;
    else
        const isAtomicType = false;
}

/**
 * complex type for the given type
 */
template ComplexTypeOf(T){
    static if(is(T==float)||is(T==ifloat)||is(T==cfloat)){
        alias cfloat ComplexTypeOf;
    } else static if(is(T==double)|| is(T==idouble)|| is(T==cdouble)){
        alias cdouble ComplexTypeOf;
    } else static if(is(T==real)|| is(T==ireal)|| is(T==creal)){
        alias creal ComplexTypeOf;
    } else static assert(0,"unsupported type in ComplexTypeOf "~T.stringof);
}

/**
 * real type for the given type
 */
template RealTypeOf(T){
    static if(is(T==float)|| is(T==ifloat)|| is(T==cfloat)){
        alias float RealTypeOf;
    } else static if(is(T==double)|| is(T==idouble)|| is(T==cdouble)){
        alias double RealTypeOf;
    } else static if(is(T==real)|| is(T==ireal)|| is(T==creal)){
        alias real RealTypeOf;
    } else static assert(0,"unsupported type in RealTypeOf "~T.stringof);
}

/**
 * imaginary type for the given type
 */
template ImaginaryTypeOf(T){
    static if(is(T==float)|| is(T==ifloat)|| is(T==cfloat)){
        alias ifloat ImaginaryTypeOf;
    } else static if(is(T==double)|| is(T==idouble)|| is(T==cdouble)){
        alias idouble ImaginaryTypeOf;
    } else static if(is(T==real)|| is(T==ireal)|| is(T==creal)){
        alias ireal ImaginaryTypeOf;
    } else static assert(0,"unsupported type in ImaginaryTypeOf "~T.stringof);
}

/// type with maximum precision
template MaxPrecTypeOf(T){
    static if (isComplexType!(T)){
        alias creal MaxPrecTypeOf;
    } else static if (isImaginaryType!(T)){
        alias ireal MaxPrecTypeOf;
    } else {
        alias real MaxPrecTypeOf;
    }
}


/**
 * Evaluates to true if T is a pointer type.
 */
template isPointerType(T)
{
        const isPointerType = false;
}

template isPointerType(T : T*)
{
        const isPointerType = true;
}

debug( UnitTest )
{
    unittest
    {
        static assert( is(BaseTypeOf!(const(int))==int) );
        static assert( is(BaseTypeOf!(immutable(int))==int) );
        static assert( is(BaseTypeOf!(shared(int))==int) );
        static assert( is(BaseTypeOf!(inout(int))==int) );
        static assert( isPointerType!(void*) );
        static assert( !isPointerType!(char[]) );
        static assert( isPointerType!(char[]*) );
        static assert( !isPointerType!(char*[]) );
        static assert( isPointerType!(real*) );
        static assert( !isPointerType!(uint) );
        static assert( is(MaxPrecTypeOf!(float)==real));
        static assert( is(MaxPrecTypeOf!(cfloat)==creal));
        static assert( is(MaxPrecTypeOf!(ifloat)==ireal));

        class Ham
        {
            void* a;
        }

        static assert( !isPointerType!(Ham) );

        union Eggs
        {
            void* a;
            uint  b;
        }

        static assert( !isPointerType!(Eggs) );
        static assert( isPointerType!(Eggs*) );

        struct Bacon {}

        static assert( !isPointerType!(Bacon) );

    }
}

/**
 * Evaluates to true if T is a a pointer, class, interface, or delegate.
 */
template isReferenceType( T )
{

    const bool isReferenceType = isPointerType!(T)  ||
                               is( T == class )     ||
                               is( T == interface ) ||
                               is( T == delegate );
}


/**
 * Evaluates to true if T is a dynamic array type.
 */
template isDynamicArrayType( T )
{
    const bool isDynamicArrayType = is( typeof(T.init[0])[] == T );
}

/**
 * Evaluates to true if T is a static array type.
 */
template isStaticArrayType( T : T[U], size_t U )
{
    const bool isStaticArrayType = true;
}

template isStaticArrayType( T )
{
    const bool isStaticArrayType = false;
}

/// true for array types
template isArrayType(T)
{
    static if (is( T U : U[] ))
        const bool isArrayType=true;
    else
        const bool isArrayType=false;
}

debug( UnitTest )
{
    unittest
    {
        static assert( isStaticArrayType!(char[5][2]) );
        static assert( !isDynamicArrayType!(char[5][2]) );
        static assert( isArrayType!(char[5][2]) );

        static assert( isStaticArrayType!(char[15]) );
        static assert( !isStaticArrayType!(char[]) );

        static assert( isDynamicArrayType!(char[]) );
        static assert( !isDynamicArrayType!(char[15]) );

        static assert( isArrayType!(char[15]) );
        static assert( isArrayType!(char[]) );
        static assert( !isArrayType!(char) );
    }
}

/**
 * Evaluates to true if T is an associative array type.
 */
template isAssocArrayType( T )
{
    const bool isAssocArrayType = is( typeof(T.init.values[0])[typeof(T.init.keys[0])] == T );
}


/**
 * Evaluates to true if T is a function, function pointer, delegate, or
 * callable object.
 */
template isCallableType( T )
{
    const bool isCallableType = is( T == function )             ||
                                is( typeof(*T) == function )    ||
                                is( T == delegate )             ||
                                is( typeof(T.opCall) == function );
}


/**
 * Evaluates to the return type of Fn.  Fn is required to be a callable type.
 */
template ReturnTypeOf( Fn )
{
    static if( is( Fn Ret == return ) )
        alias Ret ReturnTypeOf;
    else
        static assert( false, "Argument has no return type." );
}

/** 
 * Returns the type that a T would evaluate to in an expression.
 * Expr is not required to be a callable type
 */ 
template ExprTypeOf( Expr )
{
    static if(isCallableType!( Expr ))
        alias ReturnTypeOf!( Expr ) ExprTypeOf;
    else
        alias Expr ExprTypeOf;
}


/**
 * Evaluates to the return type of fn.  fn is required to be callable.
 */
template ReturnTypeOf( alias fn )
{
//    static if( is( typeof(fn) Base == typedef ) )
//        alias ReturnTypeOf!(Base) ReturnTypeOf;
//    else
        alias ReturnTypeOf!(typeof(fn)) ReturnTypeOf;
}


/**
 * Evaluates to a tuple representing the parameters of Fn.  Fn is required to
 * be a callable type.
 */
template ParameterTupleOf( Fn )
{
    static if( is( Fn Params == function ) )
        alias Params ParameterTupleOf;
    else static if( is( Fn Params == delegate ) )
        alias ParameterTupleOf!(Params) ParameterTupleOf;
    else static if( is( Fn Params == Params* ) )
        alias ParameterTupleOf!(Params) ParameterTupleOf;
    else
        static assert( false, "Argument has no parameters." );
}


/**
 * Evaluates to a tuple representing the parameters of fn.  n is required to
 * be callable.
 */
template ParameterTupleOf( alias fn )
{
//    static if( is( typeof(fn) Base == typedef ) )
//        alias ParameterTupleOf!(Base) ParameterTupleOf;
//    else
        alias ParameterTupleOf!(typeof(fn)) ParameterTupleOf;
}


/**
 * Evaluates to a tuple representing the ancestors of T.  T is required to be
 * a class or interface type.
 */
template BaseTypeTupleOf( T )
{
    static if( is( T Base == super ) )
        alias Base BaseTypeTupleOf;
    else
        static assert( false, "Argument is not a class or interface." );
}

/**
 * Strips the []'s off of a type.
 */
template BaseTypeOfArrays(T)
{
    static if( is( T S : S[]) ) {
        alias BaseTypeOfArrays!(S)  BaseTypeOfArrays;
    }
    else {
        alias T BaseTypeOfArrays;
    }
}

/**
 * strips one [] off a type
 */
template ElementTypeOfArray(T:T[])
{
    alias T ElementTypeOfArray;
}

/**
 * Count the []'s on an array type
 */
template rankOfArray(T) {
    static if(is(T S : S[])) {
        const uint rankOfArray = 1 + rankOfArray!(S);
    } else {
        const uint rankOfArray = 0;
    }
}

/// type of the keys of an AA
template KeyTypeOfAA(T){
    alias typeof(T.init.keys[0]) KeyTypeOfAA;
}

/// type of the values of an AA
template ValTypeOfAA(T){
    alias typeof(T.init.values[0]) ValTypeOfAA;
}

/// returns the size of a static array
template staticArraySize(T)
{
    static assert(isStaticArrayType!(T),"staticArraySize needs a static array as type");
    static assert(rankOfArray!(T)==1,"implemented only for 1d arrays...");
    const size_t staticArraySize=(T).sizeof / ElementTypeOfArray!(T).sizeof;
}

/// is T is static array returns a dynamic array, otherwise returns T
template DynamicArrayType(T)
{
    static if( isStaticArrayType!(T) )
        alias typeof(T.dup) DynamicArrayType;
    else
        alias T DynamicArrayType;
}

debug( UnitTest )
{
    static assert( is(BaseTypeOfArrays!(real[][])==real) );
    static assert( is(BaseTypeOfArrays!(real[2][3])==real) );
    static assert( is(ElementTypeOfArray!(real[])==real) );
    static assert( is(ElementTypeOfArray!(real[][])==real[]) );
    static assert( is(ElementTypeOfArray!(real[2][])==real[2]) );
    static assert( is(ElementTypeOfArray!(real[2][2])==real[2]) );
    static assert( rankOfArray!(real[][])==2 );
    static assert( rankOfArray!(real[2][])==2 );
    static assert( is(ValTypeOfAA!(char[int])==char));
    static assert( is(KeyTypeOfAA!(char[int])==int));
    static assert( is(ValTypeOfAA!(char[][int])==char[]));
    static assert( is(KeyTypeOfAA!(char[][int[]])==const(int)[]));
    static assert( isAssocArrayType!(char[][int[]]));
    static assert( !isAssocArrayType!(char[]));
    static assert( is(DynamicArrayType!(char[2])==DynamicArrayType!(char[])));
    static assert( is(DynamicArrayType!(char[2])==char[]));
    static assert( staticArraySize!(char[2])==2);
}

/** This template finds the const type of T if T implicitly can be converted into a const type and can be hold in variable HolderOf without making a explicit copy or dup.
    This template can be used on an argument of template functions if the argument is kept constant. 
    The called argument can be const,immutable or variable.
	Ex.
    class TClass(T) {
	HolderOf! T value;
	void func(ConstOf!T x) {
	value=x;
	}
    }
    ...
    The function "func" can be called with.
    auto C=new Tclass!(char[]);
    char[] str;
    const(char[]) const_str="Const";
    immutable(char[]) immutable_str="Immutable";
    C.func(str);
    C.func(const_str); 
    C.func(immutable_str);
*/

template ConstOf(T) {
  static if (is(T U:const(U)[])) {
	alias const(U)[] ConstOf; 
  } else static if (is(T U:const(U))) {
    alias const(U) ConstOf;
  } else {
    alias T ConstOf;
  }
}

// template ConstOf(T) {
//   static if (is(T : Object))
//     alias T ConstOf; 
//   else static if (is(T U==immutable(U)[] ))
// 		 alias const(U)[] ConstOf; 
//   else static if (is(T U:U[]))
// 		 alias ConstOf!(U)[] ConstOf;
//   else static if (is(T U:const(U)))
// 		 alias const(U) ConstOf;
// 	else static assert(0, "No constant type of "~T.stringof);
// }

/** This template is used in conjunction with the ConstOf template.
    HolderOf can hold the value of the ConstOf type with out making a explicit copy.
    Ex.
    ConstOf!T conts_var;
    HolderOf!T holder_var=const_var;
*/

template HolderOf(T) {
  pragma(msg, "------- "~T.stringof~" -------");
  static if (is(T U==immutable(U[]))) {
	// pragma(msg, "inside is(T U==immutable(U)[])  U="~U.stringof~" MutableOf!U="~MutableOf!(U).stringof);
	alias const(MutableOf!U)[] HolderOf;
  } else static if(is(T U:U[])) {
	// pragma(msg, "inside T="~T.stringof~"  is(T U:U[])"~U.stringof);
    static if (is(U S==const(S))) {
	  // pragma(msg, "inside is(U S==const(S)) U="~U.stringof~" S="~S.stringof);
      alias U[] HolderOf;
	} else static if (is(U S==immutable(S))) {
	  // pragma(msg, "inside is(U S==immutable(S)) U="~U.stringof~" S="~S.stringof)
		  ;
      alias const(S)[] HolderOf;
	} else 
		  alias HolderOf!(U)[] HolderOf;
  } else static if (is(T U==const(U))) {
	  // pragma(msg, "inside is(T U==const(U)) U="~U.stringof);
	  static if (isAtomicType!(MutableOf!T)) {
        alias U HolderOf;
	  } else {
		alias T HolderOf;
	  }
  } else static if (is(T U==immutable(U))) {
	  static if (isAtomicType!(MutableOf!T)) {
        alias U HolderOf;
	  } else {
		alias const(U) HolderOf;
	  }
  } else {
	  alias T HolderOf;
	}
}

/** Converts a type to a mutable type 
 */
template MutableOf(T) {
  static if(is(T U:const(U)[]))
    alias MutableOf!(U)[] MutableOf;
  else static if(is(T U:const(U)))
    alias U MutableOf;
  else 
    alias T MutableOf;
}


unittest {
  import tango.io.Stdout;
  class TemplateClass(T) {
	HolderOf!T value;

	bool equal(ConstOf!T val) const {
	  return val==value;
	}

	T set(T val) {
      return (value=val);
	}

  }

  struct TestStruct {
	int x,y;
	real z;
	this(const int x, const int y, const real z) {
	  this.x=x;this.y=y;this.z=z;
	}
  }

  class TestClass {
	int x,y;
	real z;
	this() {
	  z=1.0;
	}
	this(const int x, const int y, const real z) {
	  this.x=x;this.y=y;this.z=z;
	}
  }

  // Implicitly conversion 
  static assert(is(const(int) : int));
  static assert(is(immutable(int) : int));
  static assert(is(const(Object)==const Object));
  static assert(is(int[] :const(int)[]));
  static assert(is(immutable(int)[] :const(int)[]));
  static assert(is(const(int)[] :const(int)[]));
  static assert(is(const(int[]) :const(int)[]));
  static assert(is(immutable(int[]) :const(int)[]));
  static assert(is(immutable(int[]) :immutable(int)[]));
  static assert(is(immutable(int[])  : const(int)[]));
  static assert(is(immutable(int[][])  : const(int[])[]));
  static assert(is(immutable(int[][][])  : const(int[][])[]));

  // Atomics common  
  static assert(is(ConstOf!(int)==const(int)));
  static assert(is(ConstOf!(immutable int)==const(int)));
  static assert(is(ConstOf!(const(int))==const(int)));
  // Object common
  static assert(is(ConstOf!(Object)==const(Object)));
  static assert(is(ConstOf!(immutable(Object))==const(Object)));
  static assert(is(ConstOf!(const(Object))==const Object ));
  // Atomics Array common
  static assert(is(ConstOf!(int[]) == const(int)[]) );
  static assert(is(ConstOf!(const(int)[]) == const(int)[]) );
  static assert(is(ConstOf!(immutable(int)[]) == const(int)[]) );
  // Fixed Atomics Array common
  static assert(is(ConstOf!(const(int[])) == const(int)[]) );
  static assert(is(ConstOf!(immutable(int[])) == const(int)[]) );
  // Object Array common
  static assert(is(ConstOf!(Object[]) == const(Object)[]) );
  static assert(is(ConstOf!(const(Object)[]) == const(Object)[]) );
  static assert(is(ConstOf!(immutable(Object)[]) == const(Object)[]) );
  // Fixed Object Array common
  static assert(is(ConstOf!(const(int[])) == const(int)[]) );
  static assert(is(ConstOf!(immutable(int[])) == const(int)[]) );
  // Jaggles common
  static assert(is(ConstOf!(int[][]) == const(int[])[]));
  static assert(is(ConstOf!(const(int[])[]) == const(int[])[]));
  static assert(is(ConstOf!(const(int[][])) == const(int[])[]));
  static assert(is(ConstOf!(immutable(int[])[]) == const(immutable(int)[])[]));
  static assert(is(ConstOf!(immutable(int[][])) == const(immutable(int)[])[]));

  // Atomics Mutable
  static assert(is(MutableOf!(int)==int));
  static assert(is(MutableOf!(const(int))==int));
  static assert(is(MutableOf!(immutable(int))==int));
  // Object Mutable
  static assert(is(MutableOf!(Object)==Object));
  static assert(is(MutableOf!(const(Object))==Object));
  static assert(is(MutableOf!(immutable(Object))==Object));
  // Array Mutable
  static assert(is(MutableOf!(int[])==int[]));
  static assert(is(MutableOf!(const(int[]))==int[]));
  static assert(is(MutableOf!(immutable(int[]))==int[]));
  static assert(is(MutableOf!(const(int)[])==int[]));
  static assert(is(MutableOf!(immutable(int)[])==int[]));
  // Jaggle Mutable
  static assert(is(MutableOf!(int[][])==int[][]));
  static assert(is(MutableOf!(const(int[][]))==int[][]));
  static assert(is(MutableOf!(immutable(int[][]))==int[][]));
  static assert(is(MutableOf!(const(int[])[])==int[][]));
  static assert(is(MutableOf!(immutable(int[])[])==int[][]));
  static assert(is(MutableOf!(const(int[][][]))==int[][][]));
  static assert(is(MutableOf!(immutable(int[][][]))==int[][][]));
 
  // Atomic Holder
  static assert(is(HolderOf!(int)==int));
  static assert(is(HolderOf!(const(int))==int));
  static assert(is(HolderOf!(immutable(int))==int));
  static assert(is(int : HolderOf!(int)));
  static assert(is(const(int) : HolderOf!(const(int))));
  static assert(is(immutable(int) : HolderOf!(immutable(int))));
  // Object Holder
  static assert(is(HolderOf!(Object)==Object));
  static assert(is(HolderOf!(const(Object))==const(Object)));
  static assert(is(HolderOf!(immutable(Object))==const(Object)));
  static assert(is(Object : HolderOf!(Object)));
  static assert(is(const(Object) : HolderOf!(const(Object))));
  static assert(is(immutable(Object) : HolderOf!(immutable(Object))));
  // Atomic Array Holder
  static assert(is(HolderOf!(int[])==int[]));
  static assert(is(HolderOf!(const(int)[])== const(int)[]));
  static assert(is(HolderOf!(immutable(int)[])==const(int)[]));
  static assert(is(int[] : HolderOf!(int[])));
  static assert(is(const(int)[] : HolderOf!(const(int)[])));
  static assert(is(immutable(int)[] : HolderOf!(immutable(int)[])));
  // Atomic Fixed Array holder
  static assert(is(HolderOf!(const(int[]))== const(int)[]));
  static assert(is(HolderOf!(immutable(int[]))==const(int)[]));
  static assert(is(const(int[]) : HolderOf!(const(int[]))));
  static assert(is(immutable(int[]) : HolderOf!(immutable(int[]))));
  // Object Array holder 
  static assert(is(HolderOf!(Object[])==Object[]));
  static assert(is(HolderOf!(const(Object)[])==const(Object)[]));
  static assert(is(HolderOf!(immutable(Object)[])==const(Object)[]));
  static assert(is(Object[] : HolderOf!(Object[])));
  static assert(is(const(Object)[] : HolderOf!(const(Object)[])));
  static assert(is(immutable(Object)[] : HolderOf!(immutable(Object)[])));
  // Object Fixed Array holder
  static assert(is(HolderOf!(const(Object[]))== const(Object)[]));
  static assert(is(HolderOf!(immutable(Object[]))==const(Object)[]));
  static assert(is(const(Object[]) : HolderOf!(const(Object[]))));
  static assert(is(immutable(Object[]) : HolderOf!(immutable(Object[]))));
  // Jaggle Holder
  static assert(is(HolderOf!(int[][]) == int[][]));
  static assert(is(HolderOf!(const(int[])[]) == const(int[])[]));
  static assert(is(HolderOf!(immutable(int[])[]) == const(int[])[]));
  static assert(is(immutable(int[])[] : HolderOf!(immutable(int[])[])));
  static assert(is(HolderOf!(immutable(int[][])[]) == const(int[][])[]));
  static assert(is(immutable(int[][])[] : HolderOf!(immutable(int[][])[])));
  static assert(is(HolderOf!(immutable(int[][][])) == const(int[][])[]));
  static assert(is(immutable(int[][][]) : HolderOf!(immutable(int[][])[])));


  Stdout("Runtime test").nl;
  // Runtime test
  auto temp_int=new TemplateClass!(int);
  auto temp_struct=new TemplateClass!(TestStruct);
  auto temp_class=new TemplateClass!(TestClass);
  auto temp_string=new TemplateClass!(char[]);
  auto temp_class_array=new TemplateClass!(TestClass[]);
  Stdout("After test").nl;
  // Atomics
  auto y1=temp_int.set(10);
  assert(temp_int.equal(10));
  assert(temp_int.equal(y1));
  int x2=30;
  auto y2=temp_int.set(x2);
  assert(temp_int.equal(20));
  assert(temp_int.equal(x2));
  // Struct
  auto x3=TestStruct(20,40,1.0);
  auto y3=temp_struct.set(x3);
  assert(temp_struct.equal(y3));
  assert(temp_struct.equal(const(TestStruct)(20,40,1.0)));
  assert(temp_struct.equal(immutable(TestStruct)(20,40,1.0)));
  // const Struct
  auto x4=const(TestStruct)(30,40,2.2);
  auto y4=temp_struct.set(x4);
  assert(temp_struct.equal(y4));
  assert(temp_struct.equal(const(TestStruct)(20,40,1.0)));
  assert(temp_struct.equal(immutable(TestStruct)(20,40,1.0)));
  // Array
  char[] x5="Test".dup;
  auto y5=temp_string.set(x5);
  assert(temp_string.equal(y5));
  assert(temp_string.equal(cast(const(char)[])("Test")));
  assert(temp_string.equal("Test"));

  auto x6=new TestClass(20,40,1.0);
  auto y6=temp_class.equal(x6);
  auto x7=new TestClass[10];
  auto y7=temp_class_array.equal(x7);
  static assert(is(ConstOf!(char[])==const(char)[]));
  static assert(is(ConstOf!(immutable(char)[])==const(char)[]));
  static assert(is(ConstOf!(immutable(char)[])==const(char)[]));
  static assert(is(MutableOf!(char[])==char[]));
  static assert(is(MutableOf!(immutable(char)[])==char[]));
  static assert(is(MutableOf!(immutable(char)[])==char[]));
  Stdout("Eof Traits").nl;
}

// ------- CTFE -------

/// compile time integer to string
char [] ctfe_i2a(int i){
    char[] digit="0123456789".dup;
    char[] res="".dup;
    if (i==0){
        return "0".dup;
    }
    bool neg=false;
    if (i<0){
        neg=true;
        i=-i;
    }
    while (i>0) {
        res=digit[i%10]~res;
        i/=10;
    }
    if (neg)
        return '-'~res;
    else
        return res;
}
/// ditto
char [] ctfe_i2a(long i){
    char[] digit="0123456789".dup;
    char[] res="".dup;
    if (i==0){
        return "0".dup;
    }
    bool neg=false;
    if (i<0){
        neg=true;
        i=-i;
    }
    while (i>0) {
        res=digit[cast(size_t)(i%10)]~res;
        i/=10;
    }
    if (neg)
        return '-'~res;
    else
        return res;
}
/// ditto
char [] ctfe_i2a(uint i){
    const(char)[] digit="0123456789";
    char[] res;
    if (i==0){
        return "0".dup;
    }
    bool neg=false;
    while (i>0) {
        res=digit[i%10]~res;
        i/=10;
    }
    return res;
}
/// ditto
char [] ctfe_i2a(ulong i){
    const(char)[] digit="0123456789";
    char[] res;
    if (i==0){
        return "0".dup;
    }
    bool neg=false;
    while (i>0) {
        res=digit[cast(size_t)(i%10)]~res;
        i/=10;
    }
    return res;
}

debug( UnitTest )
{
    unittest {
    static assert( ctfe_i2a(31)=="31" );
    static assert( ctfe_i2a(-31)=="-31" );
    static assert( ctfe_i2a(14u)=="14" );
    static assert( ctfe_i2a(14L)=="14" );
    static assert( ctfe_i2a(14UL)=="14" );
    }
}

