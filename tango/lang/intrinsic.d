// Copyright (c) 1999-2003 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// www.digitalmars.com
//
// Documentation written by Sean Kelly <sean@f4.ca>

/**
 * This module contains functions that the compiler is intended to replace
 * with optimized assembler code at compile-time.  While the instructions
 * provided are based on instructions outlined in the IA-32 spec, it should
 * be easy to emulate such functionality on other architectures, provided
 * there is no directly equivalent function available.
 */
module tango.lang.intrinsic;


/**
 *
 */
int bsf( uint v );


/**
 *
 */
int bsr( uint v );


/**
 *
 */
int bt( uint* p, uint bitnum );


/**
 *
 */
int btc( uint* p, uint bitnum );


/**
 *
 */
int btr( uint* p, uint bitnum );


/**
 *
 */
int bts( uint* p, uint bitnum );


/**
 *
 */
uint bswap( uint v );


/**
 *
 */
ubyte  inp( uint );


/**
 *
 */
ushort inpw( uint );



/**
 *
 */
 uint   inpl( uint );


/**
 *
 */
ubyte  outp( uint, ubyte );


/**
 *
 */
ushort outpw( uint, ushort );


/**
 *
 */
uint   outpl( uint, uint );