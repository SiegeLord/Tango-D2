/* GDC -- D front-end for GCC
   Copyright (C) 2004 David Friedman
   
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
 
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
 
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

/* GNU/GCC unwind interface declarations for D.  This must match
   unwind-generic.h */

module rt.compiler.gdc.gcc.unwind;

private import rt.compiler.gdc.gcc.builtins;
private import tango.stdc.stdlib; // for abort

/* This is derived from the C++ ABI for IA-64.  Where we diverge
   for cross-architecture compatibility are noted with "@@@".  */

extern (C):

/* Level 1: Base ABI  */

/* @@@ The IA-64 ABI uses uint64 throughout.  Most places this is
   inefficient for 32-bit and smaller machines.  */

// %% These were typedefs, then made alias -- there are some
// extra casts now

alias __builtin_machine_uint _Unwind_Word;
alias __builtin_machine_int  _Unwind_Sword;
alias __builtin_pointer_uint _Unwind_Internal_Ptr;

version (IA64) {
    version (HPUX) {
        alias __builtin_machine_uint _Unwind_Ptr;
    } else {
        alias __builtin_pointer_uint _Unwind_Ptr;
    }
} else {
    alias __builtin_pointer_uint _Unwind_Ptr;
}


/* @@@ The IA-64 ABI uses a 64-bit word to identify the producer and
   consumer of an exception.  We'll go along with this for now even on
   32-bit machines.  We'll need to provide some other option for
   16-bit machines and for machines with > 8 bits per byte.  */
alias ulong _Unwind_Exception_Class;

/* The unwind interface uses reason codes in several contexts to
   identify the reasons for failures or other actions.  */
enum
{
  _URC_NO_REASON = 0,
  _URC_FOREIGN_EXCEPTION_CAUGHT = 1,
  _URC_FATAL_PHASE2_ERROR = 2,
  _URC_FATAL_PHASE1_ERROR = 3,
  _URC_NORMAL_STOP = 4,
  _URC_END_OF_STACK = 5,
  _URC_HANDLER_FOUND = 6,
  _URC_INSTALL_CONTEXT = 7,
  _URC_CONTINUE_UNWIND = 8
}
alias uint _Unwind_Reason_Code;


/* The unwind interface uses a pointer to an exception header object
   as its representation of an exception being thrown. In general, the
   full representation of an exception object is language- and
   implementation-specific, but it will be prefixed by a header
   understood by the unwind interface.  */

extern(C) typedef void (*_Unwind_Exception_Cleanup_Fn) (_Unwind_Reason_Code,
                                              _Unwind_Exception *);

align struct _Unwind_Exception // D Note: this may not be "maxium alignment required by any type"?
{
  _Unwind_Exception_Class exception_class;
  _Unwind_Exception_Cleanup_Fn exception_cleanup;
  _Unwind_Word private_1;
  _Unwind_Word private_2;

  /* @@@ The IA-64 ABI says that this structure must be double-word aligned.
     Taking that literally does not make much sense generically.  Instead we
     provide the maximum alignment required by any type for the machine.  */
}


/* The ACTIONS argument to the personality routine is a bitwise OR of one
   or more of the following constants.  */
typedef int _Unwind_Action;

enum
{
    _UA_SEARCH_PHASE  = 1,
    _UA_CLEANUP_PHASE = 2,
    _UA_HANDLER_FRAME = 4,
    _UA_FORCE_UNWIND  = 8,
    _UA_END_OF_STACK  = 16
}

/* This is an opaque type used to refer to a system-specific data
   structure used by the system unwinder. This context is created and
   destroyed by the system, and passed to the personality routine
   during unwinding.  */
struct _Unwind_Context;

/* Raise an exception, passing along the given exception object.  */
_Unwind_Reason_Code _Unwind_RaiseException (_Unwind_Exception *);

/* Raise an exception for forced unwinding.  */

extern(C) typedef _Unwind_Reason_Code (*_Unwind_Stop_Fn)
     (int, _Unwind_Action, _Unwind_Exception_Class,
      _Unwind_Exception *, _Unwind_Context *, void *);

_Unwind_Reason_Code _Unwind_ForcedUnwind (_Unwind_Exception *,
                                                 _Unwind_Stop_Fn,
                                                 void *);

/* Helper to invoke the exception_cleanup routine.  */
void _Unwind_DeleteException (_Unwind_Exception *);

/* Resume propagation of an existing exception.  This is used after
   e.g. executing cleanup code, and not to implement rethrowing.  */
void _Unwind_Resume (_Unwind_Exception *);

/* @@@ Resume propagation of an FORCE_UNWIND exception, or to rethrow
   a normal exception that was handled.  */
_Unwind_Reason_Code _Unwind_Resume_or_Rethrow (_Unwind_Exception *);

/* @@@ Use unwind data to perform a stack backtrace.  The trace callback
   is called for every stack frame in the call chain, but no cleanup
   actions are performed.  */
extern(C) typedef _Unwind_Reason_Code (*_Unwind_Trace_Fn)
     (_Unwind_Context *, void *);

_Unwind_Reason_Code _Unwind_Backtrace (_Unwind_Trace_Fn, void *);

/* These functions are used for communicating information about the unwind
   context (i.e. the unwind descriptors and the user register state) between
   the unwind library and the personality routine and landing pad.  Only
   selected registers maybe manipulated.  */

_Unwind_Word _Unwind_GetGR (_Unwind_Context *, int);
void _Unwind_SetGR (_Unwind_Context *, int, _Unwind_Word);

_Unwind_Ptr _Unwind_GetIP (_Unwind_Context *);
void _Unwind_SetIP (_Unwind_Context *, _Unwind_Ptr);

/* @@@ Retrieve the CFA of the given context.  */
_Unwind_Word _Unwind_GetCFA (_Unwind_Context *);

void *_Unwind_GetLanguageSpecificData (_Unwind_Context *);

_Unwind_Ptr _Unwind_GetRegionStart (_Unwind_Context *);


/* The personality routine is the function in the C++ (or other language)
   runtime library which serves as an interface between the system unwind
   library and language-specific exception handling semantics.  It is
   specific to the code fragment described by an unwind info block, and
   it is always referenced via the pointer in the unwind info block, and
   hence it has no ABI-specified name.

   Note that this implies that two different C++ implementations can
   use different names, and have different contents in the language
   specific data area.  Moreover, that the language specific data
   area contains no version info because name of the function invoked
   provides more effective versioning by detecting at link time the
   lack of code to handle the different data format.  */

extern(C) typedef _Unwind_Reason_Code (*_Unwind_Personality_Fn)
     (int, _Unwind_Action, _Unwind_Exception_Class,
      _Unwind_Exception *, _Unwind_Context *);

/* @@@ The following alternate entry points are for setjmp/longjmp
   based unwinding.  */

struct SjLj_Function_Context;
extern void _Unwind_SjLj_Register (SjLj_Function_Context *);
extern void _Unwind_SjLj_Unregister (SjLj_Function_Context *);

_Unwind_Reason_Code _Unwind_SjLj_RaiseException
     (_Unwind_Exception *);
_Unwind_Reason_Code _Unwind_SjLj_ForcedUnwind
     (_Unwind_Exception *, _Unwind_Stop_Fn, void *);
void _Unwind_SjLj_Resume (_Unwind_Exception *);
_Unwind_Reason_Code _Unwind_SjLj_Resume_or_Rethrow (_Unwind_Exception *);

/* @@@ The following provide access to the base addresses for text
   and data-relative addressing in the LDSA.  In order to stay link
   compatible with the standard ABI for IA-64, we inline these.  */

version (IA64) {
_Unwind_Ptr
_Unwind_GetDataRelBase (_Unwind_Context *_C)
{
  /* The GP is stored in R1.  */
  return _Unwind_GetGR (_C, 1);
}

_Unwind_Ptr
_Unwind_GetTextRelBase (_Unwind_Context *)
{
  abort ();
  return 0;
}

/* @@@ Retrieve the Backing Store Pointer of the given context.  */
_Unwind_Word _Unwind_GetBSP (_Unwind_Context *);
} else {
_Unwind_Ptr _Unwind_GetDataRelBase (_Unwind_Context *);
_Unwind_Ptr _Unwind_GetTextRelBase (_Unwind_Context *);
}

/* @@@ Given an address, return the entry point of the function that
   contains it.  */
extern void * _Unwind_FindEnclosingFunction (void *pc);
