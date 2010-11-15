/**
 * This module contains functions and structures required for
 * exception handling.
 */
module rt.eh;

import ldc.cstdarg;
import rt.compiler.util.console;

// debug = EH_personality;

// current EH implementation works on x86
// if it has a working unwind runtime
version(X86) {
    version(linux) version=X86_UNWIND;
    version(darwin) version=X86_UNWIND;
    version(solaris) version=X86_UNWIND;
    version(freebsd) version=X86_UNWIND;
}
version(X86_64) {
    version(linux) version=X86_UNWIND;
    version(darwin) version=X86_UNWIND;
    version(solaris) version=X86_UNWIND;
    version(freebsd) version=X86_UNWIND;
}

//version = HP_LIBUNWIND;

private extern(C) void abort();
private extern(C) int printf(char*, ...);
private extern(C) int vprintf(char*, va_list va);

// D runtime functions
extern(C) {
    int _d_isbaseof(ClassInfo oc, ClassInfo c);
}

// libunwind headers
extern(C)
{
    enum _Unwind_Reason_Code : int
    {
        NO_REASON = 0,
        FOREIGN_EXCEPTION_CAUGHT = 1,
        FATAL_PHASE2_ERROR = 2,
        FATAL_PHASE1_ERROR = 3,
        NORMAL_STOP = 4,
        END_OF_STACK = 5,
        HANDLER_FOUND = 6,
        INSTALL_CONTEXT = 7,
        CONTINUE_UNWIND = 8
    }

    enum _Unwind_Action : int
    {
        SEARCH_PHASE = 1,
        CLEANUP_PHASE = 2,
        HANDLER_PHASE = 3,
        FORCE_UNWIND = 4
    }

    alias void* _Unwind_Context_Ptr;

    alias void function(_Unwind_Reason_Code, _Unwind_Exception*) _Unwind_Exception_Cleanup_Fn;

    struct _Unwind_Exception
    {
        ulong exception_class;
        _Unwind_Exception_Cleanup_Fn exception_cleanup;
        ptrdiff_t private_1;
        ptrdiff_t private_2;
    }

// interface to HP's libunwind from http://www.nongnu.org/libunwind/
version(HP_LIBUNWIND)
{
    // Haven't checked whether and how it has _Unwind_Get{Text,Data}RelBase
    pragma (msg, "HP_LIBUNWIND interface is out of date and untested");

    void __libunwind_Unwind_Resume(_Unwind_Exception *);
    _Unwind_Reason_Code __libunwind_Unwind_RaiseException(_Unwind_Exception *);
    ptrdiff_t __libunwind_Unwind_GetLanguageSpecificData(_Unwind_Context_Ptr
            context);
    ptrdiff_t __libunwind_Unwind_GetIP(_Unwind_Context_Ptr context);
    ptrdiff_t __libunwind_Unwind_SetIP(_Unwind_Context_Ptr context,
            ptrdiff_t new_value);
    ptrdiff_t __libunwind_Unwind_SetGR(_Unwind_Context_Ptr context, int index,
            ptrdiff_t new_value);
    ptrdiff_t __libunwind_Unwind_GetRegionStart(_Unwind_Context_Ptr context);

    alias __libunwind_Unwind_Resume _Unwind_Resume;
    alias __libunwind_Unwind_RaiseException _Unwind_RaiseException;
    alias __libunwind_Unwind_GetLanguageSpecificData
        _Unwind_GetLanguageSpecificData;
    alias __libunwind_Unwind_GetIP _Unwind_GetIP;
    alias __libunwind_Unwind_SetIP _Unwind_SetIP;
    alias __libunwind_Unwind_SetGR _Unwind_SetGR;
    alias __libunwind_Unwind_GetRegionStart _Unwind_GetRegionStart;
}
else version(X86_UNWIND)
{
    void _Unwind_Resume(_Unwind_Exception*);
    _Unwind_Reason_Code _Unwind_RaiseException(_Unwind_Exception*);
    ptrdiff_t _Unwind_GetLanguageSpecificData(_Unwind_Context_Ptr context);
    ptrdiff_t _Unwind_GetIP(_Unwind_Context_Ptr context);
    ptrdiff_t _Unwind_SetIP(_Unwind_Context_Ptr context, ptrdiff_t new_value);
    ptrdiff_t _Unwind_SetGR(_Unwind_Context_Ptr context, int index,
            ptrdiff_t new_value);
    ptrdiff_t _Unwind_GetRegionStart(_Unwind_Context_Ptr context);

    size_t _Unwind_GetTextRelBase(_Unwind_Context_Ptr);
    size_t _Unwind_GetDataRelBase(_Unwind_Context_Ptr);
}
else
{
    // runtime calls these directly
    void _Unwind_Resume(_Unwind_Exception*)
    {
        console("_Unwind_Resume is not implemented on this platform.\n");
    }
    _Unwind_Reason_Code _Unwind_RaiseException(_Unwind_Exception*)
    {
        console("_Unwind_RaiseException is not implemented on this platform.\n");
        return _Unwind_Reason_Code.FATAL_PHASE1_ERROR;
    }
}

}

// error and exit
extern(C) private void fatalerror(char[] format)
{
  printf("Fatal error in EH code: %.*s\n", format.length, format.ptr);
  abort();
}


// DWARF EH encoding enum
// See e.g. http://refspecs.freestandards.org/LSB_3.1.1/LSB-Core-generic/LSB-Core-generic/dwarfext.html
private enum : ubyte {
  DW_EH_PE_omit    = 0xff, // value is not present

  // value format
  DW_EH_PE_absptr  = 0x00, // literal pointer
  DW_EH_PE_uleb128 = 0x01,
  DW_EH_PE_udata2  = 0x02, // unsigned 2-byte
  DW_EH_PE_udata4  = 0x03,
  DW_EH_PE_udata8  = 0x04,
  DW_EH_PE_sleb128 = 0x09,
  DW_EH_PE_sdata2  = 0x0a,
  DW_EH_PE_sdata4  = 0x0b,
  DW_EH_PE_sdata8  = 0x0c,

  // value meaning
  DW_EH_PE_pcrel    = 0x10, // relative to program counter
  DW_EH_PE_textrel  = 0x20, // relative to .text
  DW_EH_PE_datarel  = 0x30, // relative to .got or .eh_frame_hdr
  DW_EH_PE_funcrel  = 0x40, // relative to beginning of function
  DW_EH_PE_aligned  = 0x50, // is an aligned void*

  // value is a pointer to the actual value
  // this is a mask on top of one of the above
  DW_EH_PE_indirect = 0x80
}

// Helpers for reading DWARF data

// Given an encoding and a context, return the base to which the encoding is
// relative
private size_t base_of_encoded(_Unwind_Context_Ptr context, ubyte encoding)
{
  if (encoding == DW_EH_PE_omit)
    return 0;

  switch (encoding & 0x70) // ignore DW_EH_PE_indirect
  {
    case DW_EH_PE_absptr, DW_EH_PE_pcrel, DW_EH_PE_aligned:
      return 0;

    case DW_EH_PE_textrel: return _Unwind_GetTextRelBase(context);
    case DW_EH_PE_datarel: return _Unwind_GetDataRelBase(context);
    case DW_EH_PE_funcrel: return _Unwind_GetRegionStart(context);

    default: fatalerror("Unrecognized base for DWARF value");
  }
  assert(0);
}

// Only defined for fixed-size encodings
private size_t size_of_encoded(ubyte encoding)
{
  if (encoding == DW_EH_PE_omit)
    return 0;

  switch (encoding & 0x07) // ignore leb128
  {
    case DW_EH_PE_absptr: return (void*).sizeof;
    case DW_EH_PE_udata2: return 2;
    case DW_EH_PE_udata4: return 4;
    case DW_EH_PE_udata8: return 8;

    default: fatalerror("Unrecognized fixed-size DWARF value encoding");
  }
  assert(0);
}

// Actual value readers below: read a value from the given ubyte* into the
// output parameter and return the pointer incremented past the value.

// Like read_encoded_with_base but gets the base from the given context
private ubyte* read_encoded(_Unwind_Context_Ptr context, ubyte encoding, ubyte* p, out size_t val)
{
  return read_encoded_with_base(encoding, base_of_encoded(context, encoding), p, val);
}

private ubyte* read_encoded_with_base(ubyte encoding, size_t base, ubyte* p, out size_t val)
{
  if (encoding == DW_EH_PE_aligned)
  {
    auto a = cast(size_t)p;
    a = (a + (void*).sizeof - 1) & -(void*).sizeof;
    val = *cast(size_t*)a;
    return cast(ubyte*)(a + (void*).sizeof);
  }

  union U
  {
    size_t ptr;
    ushort udata2;
    uint   udata4;
    ulong  udata8;
    short  sdata2;
    int    sdata4;
    long   sdata8;
  }

  auto u = cast(U*)p;

  size_t result;

  switch (encoding & 0x0f)
  {
    case DW_EH_PE_absptr:
      result = u.ptr;
      p += (void*).sizeof;
      break;

    case DW_EH_PE_uleb128:
    {
      p = get_uleb128(p, result);
      break;
    }
    case DW_EH_PE_sleb128:
    {
      ptrdiff_t sleb128;
      p = get_sleb128(p, sleb128);
      result = cast(size_t)sleb128;
      break;
    }

    case DW_EH_PE_udata2: result = cast(size_t)u.udata2; p += 2; break;
    case DW_EH_PE_udata4: result = cast(size_t)u.udata4; p += 4; break;
    case DW_EH_PE_udata8: result = cast(size_t)u.udata8; p += 8; break;
    case DW_EH_PE_sdata2: result = cast(size_t)u.sdata2; p += 2; break;
    case DW_EH_PE_sdata4: result = cast(size_t)u.sdata4; p += 4; break;
    case DW_EH_PE_sdata8: result = cast(size_t)u.sdata8; p += 8; break;

    default: fatalerror("Unrecognized DWARF value encoding format");
  }
  if (result)
  {
    if ((encoding & 0x70) == DW_EH_PE_pcrel)
      result += cast(size_t)u;
    else
      result += base;

    if (encoding & DW_EH_PE_indirect)
      result = *cast(size_t*)result;
  }
  val = result;
  return p;
}

private ubyte* get_uleb128(ubyte* addr, ref size_t res)
{
  res = 0;
  size_t bitsize = 0;

  // read as long as high bit is set
  while(*addr & 0x80) {
    res |= (*addr & 0x7f) << bitsize;
    bitsize += 7;
    addr += 1;
    if(bitsize >= size_t.sizeof*8)
       fatalerror("tried to read uleb128 that exceeded size of size_t");
  }
  // read last
  if(bitsize != 0 && *addr >= 1 << size_t.sizeof*8 - bitsize)
    fatalerror("Fatal error in EH code: tried to read uleb128 that exceeded size of size_t");
  res |= (*addr) << bitsize;

  return addr + 1;
}

private ubyte* get_sleb128(ubyte* addr, ref ptrdiff_t res)
{
  res = 0;
  size_t bitsize = 0;

  // read as long as high bit is set
  while(*addr & 0x80) {
    res |= (*addr & 0x7f) << bitsize;
    bitsize += 7;
    addr += 1;
    if(bitsize >= size_t.sizeof*8)
       fatalerror("tried to read sleb128 that exceeded size of size_t");
  }
  // read last
  if(bitsize != 0 && *addr >= 1 << size_t.sizeof*8 - bitsize)
    fatalerror("tried to read sleb128 that exceeded size of size_t");
  res |= (*addr) << bitsize;

  // take care of sign
  if(bitsize < size_t.sizeof*8 && ((*addr) & 0x40))
    res |= cast(ptrdiff_t)(-1) ^ ((1 << (bitsize+7)) - 1);

  return addr + 1;
}


// exception struct used by the runtime.
// _d_throw allocates a new instance and passes the address of its
// _Unwind_Exception member to the unwind call. The personality
// routine is then able to get the whole struct by looking at the data
// surrounding the unwind info.
struct _d_exception
{
  Object exception_object;
  _Unwind_Exception unwind_info;
}

// the 8-byte string identifying the type of exception
// the first 4 are for vendor, the second 4 for language
//TODO: This may be the wrong way around
const char[8] _d_exception_class = "LLDCD1\0\0";


//
// x86 unwind specific implementation of personality function
// and helpers
//
version(X86_UNWIND)
{

// Various stuff we need
struct Region
{
  ubyte* callsite_table;
  ubyte* action_table;

  // Note: classinfo_table points past the end of the table
  ubyte* classinfo_table;

  ptrdiff_t start;
  size_t lpStart_base; // landing pad base

  ubyte ttypeEnc;
  size_t ttype_base; // typeinfo base

  ubyte callSiteEnc;
}

// the personality routine gets called by the unwind handler and is responsible for
// reading the EH tables and deciding what to do
extern(C) _Unwind_Reason_Code _d_eh_personality(int ver, _Unwind_Action actions, ulong exception_class, _Unwind_Exception* exception_info, _Unwind_Context_Ptr context)
{
  // check ver: the C++ Itanium ABI only allows ver == 1
  if(ver != 1)
    return _Unwind_Reason_Code.FATAL_PHASE1_ERROR;

  // check exceptionClass
  //TODO: Treat foreign exceptions with more respect
  if((cast(char*)&exception_class)[0..8] != _d_exception_class)
    return _Unwind_Reason_Code.FATAL_PHASE1_ERROR;

  // find call site table, action table and classinfo table
  // Note: callsite and action tables do not contain static-length
  // data and will be parsed as needed

  Region region;

  _d_getLanguageSpecificTables(context, region);
  if (!region.callsite_table)
    return _Unwind_Reason_Code.CONTINUE_UNWIND;

  /*
    find landing pad and action table index belonging to ip by walking
    the callsite_table
  */
  ubyte* callsite_walker = region.callsite_table;

  // get the instruction pointer
  // will be used to find the right entry in the callsite_table
  // -1 because it will point past the last instruction
  ptrdiff_t ip = _Unwind_GetIP(context) - 1;

  // table entries
  size_t landing_pad;
  size_t action_offset;

  while(true) {
    // if we've gone through the list and found nothing...
    if(callsite_walker >= region.action_table)
      return _Unwind_Reason_Code.CONTINUE_UNWIND;

    size_t block_start, block_size;

    callsite_walker = read_encoded(null, region.callSiteEnc, callsite_walker, block_start);
    callsite_walker = read_encoded(null, region.callSiteEnc, callsite_walker, block_size);
    callsite_walker = read_encoded(null, region.callSiteEnc, callsite_walker, landing_pad);
    callsite_walker = get_uleb128(callsite_walker, action_offset);

    debug(EH_personality_verbose) printf("ip=%zx %d %d %zx\n", ip, block_start, block_size, landing_pad);

    // since the list is sorted, as soon as we're past the ip
    // there's no handler to be found
    if(ip < region.start + block_start)
      return _Unwind_Reason_Code.CONTINUE_UNWIND;

    if(landing_pad)
      landing_pad += region.lpStart_base;

    // if we've found our block, exit
    if(ip < region.start + block_start + block_size)
      break;
  }

  debug(EH_personality) printf("Found correct landing pad %zx and actionOffset %zx\n", landing_pad, action_offset);

  // now we need the exception's classinfo to find a handler
  // the exception_info is actually a member of a larger _d_exception struct
  // the runtime allocated. get that now
  _d_exception* exception_struct = cast(_d_exception*)(cast(ubyte*)exception_info - _d_exception.unwind_info.offsetof);

  // if there's no action offset and no landing pad, continue unwinding
  if(!action_offset && !landing_pad)
    return _Unwind_Reason_Code.CONTINUE_UNWIND;

  // if there's no action offset but a landing pad, this is a cleanup handler
  else if(!action_offset && landing_pad)
    return _d_eh_install_finally_context(actions, cast(ptrdiff_t)landing_pad, exception_struct, context);

  /*
   walk action table chain, comparing classinfos using _d_isbaseof
  */
  ubyte* action_walker = region.action_table + action_offset - 1;

  while(true) {
    ptrdiff_t ti_offset, next_action_offset;

    action_walker = get_sleb128(action_walker, ti_offset);
    // it is intentional that we not modify action_walker here
    // next_action_offset is from current action_walker position
    get_sleb128(action_walker, next_action_offset);

    // negative are 'filters' which we don't use
    if(ti_offset < 0)
      fatalerror("Filter actions are unsupported");

    // zero means cleanup, which we require to be the last action
    if(ti_offset == 0) {
      if(next_action_offset != 0)
        fatalerror("Cleanup action must be last in chain");
      return _d_eh_install_finally_context(actions, cast(ptrdiff_t)landing_pad, exception_struct, context);
    }

    // get classinfo for action and check if the one in the
    // exception structure is a base
    size_t typeinfo;
    auto filter = ti_offset * size_of_encoded(region.ttypeEnc);
    read_encoded_with_base(region.ttypeEnc, region.ttype_base, region.classinfo_table - filter, typeinfo);

    debug(EH_personality_verbose)
      printf("classinfo at %zx (enc %zx (size %zx) base %zx ptr %zx)\n", typeinfo, region.ttypeEnc, size_of_encoded(region.ttypeEnc), region.ttype_base, region.classinfo_table - filter);

    auto catch_ci = *cast(ClassInfo*)&typeinfo;

    debug(EH_personality) printf("Comparing catch %s to exception %s\n", catch_ci.name.ptr, exception_struct.exception_object.classinfo.name.ptr);
    if(_d_isbaseof(exception_struct.exception_object.classinfo, catch_ci))
      return _d_eh_install_catch_context(actions, ti_offset, cast(ptrdiff_t)landing_pad, exception_struct, context);

    // we've walked through all actions and found nothing...
    if(next_action_offset == 0)
      return _Unwind_Reason_Code.CONTINUE_UNWIND;
    else
      action_walker += next_action_offset;
  }

  fatalerror("reached unreachable");
  return _Unwind_Reason_Code.FATAL_PHASE1_ERROR;
}

// These are the register numbers for SetGR that
// llvm's eh.exception and eh.selector intrinsics
// will pick up.
// Hints for these can be found by looking at the
// EH_RETURN_DATA_REGNO macro in GCC, careful testing
// is required though.
version (X86_64)
{
  private int eh_exception_regno = 0;
  private int eh_selector_regno = 1;
} else {
  private int eh_exception_regno = 0;
  private int eh_selector_regno = 2;
}

private _Unwind_Reason_Code _d_eh_install_catch_context(_Unwind_Action actions, ptrdiff_t switchval, ptrdiff_t landing_pad, _d_exception* exception_struct, _Unwind_Context_Ptr context)
{
  debug(EH_personality) printf("Found catch clause!\n");

  if(actions & _Unwind_Action.SEARCH_PHASE)
    return _Unwind_Reason_Code.HANDLER_FOUND;

  else if(actions & _Unwind_Action.HANDLER_PHASE)
  {
    debug(EH_personality) printf("Setting switch value to: %d!\n", switchval);
    _Unwind_SetGR(context, eh_exception_regno, cast(ptrdiff_t)cast(void*)(exception_struct.exception_object));
    _Unwind_SetGR(context, eh_selector_regno, cast(ptrdiff_t)switchval);
    _Unwind_SetIP(context, landing_pad);
    return _Unwind_Reason_Code.INSTALL_CONTEXT;
  }

  fatalerror("reached unreachable");
  return _Unwind_Reason_Code.FATAL_PHASE2_ERROR;
}

private _Unwind_Reason_Code _d_eh_install_finally_context(_Unwind_Action actions, ptrdiff_t landing_pad, _d_exception* exception_struct, _Unwind_Context_Ptr context)
{
  // if we're merely in search phase, continue
  if(actions & _Unwind_Action.SEARCH_PHASE)
    return _Unwind_Reason_Code.CONTINUE_UNWIND;

  debug(EH_personality) printf("Calling cleanup routine...\n");

  _Unwind_SetGR(context, eh_exception_regno, cast(ptrdiff_t)exception_struct);
  _Unwind_SetGR(context, eh_selector_regno, 0);
  _Unwind_SetIP(context, landing_pad);
  return _Unwind_Reason_Code.INSTALL_CONTEXT;
}

private void _d_getLanguageSpecificTables(_Unwind_Context_Ptr context, out Region region)
{
  auto data = cast(ubyte*)_Unwind_GetLanguageSpecificData(context);
  if (!data)
    return;

  region.start = _Unwind_GetRegionStart(context);

  // Read the C++-style LSDA: this is implementation-defined by GCC but LLVM
  // outputs the same kind of table

  // Get @LPStart: landing pad offsets are relative to it
  auto lpStartEnc = *data++;
  if (lpStartEnc == DW_EH_PE_omit)
    region.lpStart_base = region.start;
  else
    data = read_encoded(context, lpStartEnc, data, region.lpStart_base);

  // Get @TType: the offset to the handler and typeinfo
  region.ttypeEnc = *data++;
  if (region.ttypeEnc == DW_EH_PE_omit)
    // Not sure about this one...
    fatalerror("@TType must not be omitted from DWARF header");

  size_t ciOffset;
  data = get_uleb128(data, ciOffset);
  region.classinfo_table = data + ciOffset;

  region.ttype_base = base_of_encoded(context, region.ttypeEnc);

  // Get encoding and length of the call site table, which precedes the action
  // table.
  region.callSiteEnc = *data++;
  if (region.callSiteEnc == DW_EH_PE_omit)
    fatalerror("Call site table encoding must not be omitted from DWARF header");

  size_t callSiteLength;
  region.callsite_table = get_uleb128(data, callSiteLength);
  region.action_table = region.callsite_table + callSiteLength;
}

} // end of x86 Linux specific implementation


extern(C) void _d_throw_exception(Object e)
{
    if (e !is null)
    {
        _d_exception* exc_struct = new _d_exception;
        exc_struct.unwind_info.exception_class = *cast(ulong*)_d_exception_class.ptr;
        exc_struct.exception_object = e;
        _Unwind_Reason_Code ret = _Unwind_RaiseException(&exc_struct.unwind_info);
        console("_Unwind_RaiseException failed with reason code: ")(ret)("\n");
    }
    abort();
}

extern(C) void _d_eh_resume_unwind(_d_exception* exception_struct)
{
  _Unwind_Resume(&exception_struct.unwind_info);
}
