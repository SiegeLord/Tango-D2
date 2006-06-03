/**
 * These functions are built-in intrinsics to the compiler.
 *
 * Intrinsic functions are functions built in to the compiler, usually to take
 * advantage of specific CPU features that are inefficient to handle via
 * external functions.  The compiler's optimizer and code generator are fully
 * integrated in with intrinsic functions, bringing to bear their full power on
 * them. This can result in some surprising speedups.
 *
 * Authors:   Walter Bright
 * Copyright: Public Domain
 * License:   See about.d
 */
module tango.core.intrinsic;

public import std.intrinsic;

