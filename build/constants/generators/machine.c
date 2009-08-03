#ifdef __APPLE__
#include <mach/machine.h>
#else
#define MACHINE_SKIP_ALL
#endif
// other mach based OS would also have this
t
xxx start xxx
/+ sed -e 's/(cpu_threadtype_t)//g' -e 's/(cpu_subtype_t)//g' -e 's/(cpu_type_t)//g' +/
module tango.stdc.constants.autoconf.machine;

#ifndef MACHINE_SKIP_ALL
alias int cpu_type_t;
alias int cpu_subtype_t;
alias int cpu_threadtype_t;

enum{
    __XYX__CPU_STATE_MAX     = CPU_STATE_MAX,

    __XYX__CPU_STATE_USER    = CPU_STATE_USER  ,
    __XYX__CPU_STATE_SYSTEM  = CPU_STATE_SYSTEM,
    __XYX__CPU_STATE_IDLE    = CPU_STATE_IDLE  ,
    __XYX__CPU_STATE_NICE    = CPU_STATE_NICE  ,



/*
 * Capability bits used in the definition of cpu_type.
 */
    __XYX__CPU_ARCH_MASK  = CPU_ARCH_MASK ,      /* mask for architecture bits */
    __XYX__CPU_ARCH_ABI64 = CPU_ARCH_ABI64,      /* 64 bit ABI */

/*
 *  Machine types known by all.
 */
 
    __XYX__CPU_TYPE_ANY = CPU_TYPE_ANY,

    __XYX__CPU_TYPE_VAX     =  CPU_TYPE_VAX     ,
    __XYX__CPU_TYPE_MC680x0 =  CPU_TYPE_MC680x0 ,
    __XYX__CPU_TYPE_X86     =  CPU_TYPE_X86     ,
    __XYX__CPU_TYPE_I386    =  CPU_TYPE_I386    ,   /* compatibility */
    __XYX__CPU_TYPE_X86_64  =  CPU_TYPE_X86_64  ,

/* skip CPU_TYPE_MIPS       ((cpu_type_t) 8)    */

    __XYX__CPU_TYPE_MC98000 =  CPU_TYPE_MC98000,
    __XYX__CPU_TYPE_HPPA    =  CPU_TYPE_HPPA   ,
    __XYX__CPU_TYPE_ARM     =  CPU_TYPE_ARM    ,
    __XYX__CPU_TYPE_MC88000 =  CPU_TYPE_MC88000,
    __XYX__CPU_TYPE_SPARC   =  CPU_TYPE_SPARC  ,
    __XYX__CPU_TYPE_I860    =  CPU_TYPE_I860   ,

/* skip CPU_TYPE_ALPHA      ((cpu_type_t) 16)   */

    __XYX__CPU_TYPE_POWERPC   = CPU_TYPE_POWERPC   ,
    __XYX__CPU_TYPE_POWERPC64 = CPU_TYPE_POWERPC64 ,

/*
 *  Machine subtypes (these are defined here, instead of in a machine
 *  dependent directory, so that any program can get all definitions
 *  regardless of where is it compiled).
 */

/*
 * Capability bits used in the definition of cpu_subtype.
 */
    __XYX__CPU_SUBTYPE_MASK  = CPU_SUBTYPE_MASK ,  /* mask for feature flags */
    __XYX__CPU_SUBTYPE_LIB64 = CPU_SUBTYPE_LIB64,  /* 64 bit libraries */


/*
 *  Object files that are hand-crafted to run on any
 *  implementation of an architecture are tagged with
 *  CPU_SUBTYPE_MULTIPLE.  This functions essentially the same as
 *  the "ALL" subtype of an architecture except that it allows us
 *  to easily find object files that may need to be modified
 *  whenever a new implementation of an architecture comes out.
 *
 *  It is the responsibility of the implementor to make sure the
 *  software handles unsupported implementations elegantly.
 */
    __XYX__CPU_SUBTYPE_MULTIPLE      =  CPU_SUBTYPE_MULTIPLE      ,
    __XYX__CPU_SUBTYPE_LITTLE_ENDIAN =  CPU_SUBTYPE_LITTLE_ENDIAN ,
    __XYX__CPU_SUBTYPE_BIG_ENDIAN    =  CPU_SUBTYPE_BIG_ENDIAN    ,

/*
 *     Machine threadtypes.
 *     This is none - not defined - for most machine types/subtypes.
 */
    __XYX__CPU_THREADTYPE_NONE = CPU_THREADTYPE_NONE,

/*
 *  VAX subtypes (these do *not* necessary conform to the actual cpu
 *  ID assigned by DEC available via the SID register).
 */

    __XYX__CPU_SUBTYPE_VAX_ALL = CPU_SUBTYPE_VAX_ALL ,
    __XYX__CPU_SUBTYPE_VAX780  = CPU_SUBTYPE_VAX780  ,
    __XYX__CPU_SUBTYPE_VAX785  = CPU_SUBTYPE_VAX785  ,
    __XYX__CPU_SUBTYPE_VAX750  = CPU_SUBTYPE_VAX750  ,
    __XYX__CPU_SUBTYPE_VAX730  = CPU_SUBTYPE_VAX730  ,
    __XYX__CPU_SUBTYPE_UVAXI   = CPU_SUBTYPE_UVAXI   ,
    __XYX__CPU_SUBTYPE_UVAXII  = CPU_SUBTYPE_UVAXII  ,
    __XYX__CPU_SUBTYPE_VAX8200 = CPU_SUBTYPE_VAX8200 ,
    __XYX__CPU_SUBTYPE_VAX8500 = CPU_SUBTYPE_VAX8500 ,
    __XYX__CPU_SUBTYPE_VAX8600 = CPU_SUBTYPE_VAX8600 ,
    __XYX__CPU_SUBTYPE_VAX8650 = CPU_SUBTYPE_VAX8650 ,
    __XYX__CPU_SUBTYPE_VAX8800 = CPU_SUBTYPE_VAX8800 ,
    __XYX__CPU_SUBTYPE_UVAXIII = CPU_SUBTYPE_UVAXIII ,

/*
 *  680x0 subtypes
 *
 * The subtype definitions here are unusual for historical reasons.
 * NeXT used to consider 68030 code as generic 68000 code.  For
 * backwards compatability:
 * 
 *  CPU_SUBTYPE_MC68030 symbol has been preserved for source code
 *  compatability.
 *
 *  CPU_SUBTYPE_MC680x0_ALL has been defined to be the same
 *  subtype as CPU_SUBTYPE_MC68030 for binary comatability.
 *
 *  CPU_SUBTYPE_MC68030_ONLY has been added to allow new object
 *  files to be tagged as containing 68030-specific instructions.
 */

    __XYX__CPU_SUBTYPE_MC680x0_ALL  = CPU_SUBTYPE_MC680x0_ALL  ,
    __XYX__CPU_SUBTYPE_MC68030      = CPU_SUBTYPE_MC68030      ,/* compat */
    __XYX__CPU_SUBTYPE_MC68040      = CPU_SUBTYPE_MC68040      ,
    __XYX__CPU_SUBTYPE_MC68030_ONLY = CPU_SUBTYPE_MC68030_ONLY ,

/*
 *  I386 subtypes
 */

    __XYX__CPU_SUBTYPE_I386_ALL       = CPU_SUBTYPE_I386_ALL       ,
    __XYX__CPU_SUBTYPE_386            = CPU_SUBTYPE_386            ,
    __XYX__CPU_SUBTYPE_486            = CPU_SUBTYPE_486            ,
    __XYX__CPU_SUBTYPE_486SX          = CPU_SUBTYPE_486SX          ,
    __XYX__CPU_SUBTYPE_586            = CPU_SUBTYPE_586            ,
    __XYX__CPU_SUBTYPE_PENT           = CPU_SUBTYPE_PENT           ,
    __XYX__CPU_SUBTYPE_PENTPRO        = CPU_SUBTYPE_PENTPRO        ,
    __XYX__CPU_SUBTYPE_PENTII_M3      = CPU_SUBTYPE_PENTII_M3      ,
    __XYX__CPU_SUBTYPE_PENTII_M5      = CPU_SUBTYPE_PENTII_M5      ,
    __XYX__CPU_SUBTYPE_CELERON        = CPU_SUBTYPE_CELERON        ,
    __XYX__CPU_SUBTYPE_CELERON_MOBILE = CPU_SUBTYPE_CELERON_MOBILE ,
    __XYX__CPU_SUBTYPE_PENTIUM_3      = CPU_SUBTYPE_PENTIUM_3      ,
    __XYX__CPU_SUBTYPE_PENTIUM_3_M    = CPU_SUBTYPE_PENTIUM_3_M    ,
    __XYX__CPU_SUBTYPE_PENTIUM_3_XEON = CPU_SUBTYPE_PENTIUM_3_XEON ,
    __XYX__CPU_SUBTYPE_PENTIUM_M      = CPU_SUBTYPE_PENTIUM_M      ,
    __XYX__CPU_SUBTYPE_PENTIUM_4      = CPU_SUBTYPE_PENTIUM_4      ,
    __XYX__CPU_SUBTYPE_PENTIUM_4_M    = CPU_SUBTYPE_PENTIUM_4_M    ,
    __XYX__CPU_SUBTYPE_ITANIUM        = CPU_SUBTYPE_ITANIUM        ,
    __XYX__CPU_SUBTYPE_ITANIUM_2      = CPU_SUBTYPE_ITANIUM_2      ,
    __XYX__CPU_SUBTYPE_XEON           = CPU_SUBTYPE_XEON           ,
    __XYX__CPU_SUBTYPE_XEON_MP        = CPU_SUBTYPE_XEON_MP        ,
}

#ifdef CPU_SUBTYPE_INTEL_FAMILY
uint extractSubtypeIntelFamily(uint x){
    return CPU_SUBTYPE_INTEL_FAMILY(x);
}
#endif

#ifdef CPU_SUBTYPE_INTEL_MODEL
uint extractCpuSubtypeIntelModel(uint x){
    return CPU_SUBTYPE_INTEL_MODEL(x);
}
#endif

enum{
    __XYX__CPU_SUBTYPE_INTEL_FAMILY_MAX = CPU_SUBTYPE_INTEL_FAMILY_MAX,

    __XYX__CPU_SUBTYPE_INTEL_MODEL_ALL = CPU_SUBTYPE_INTEL_MODEL_ALL,

/*
 *  X86 subtypes.
 */

    __XYX__CPU_SUBTYPE_X86_ALL    = CPU_SUBTYPE_X86_ALL    ,
    __XYX__CPU_SUBTYPE_X86_64_ALL = CPU_SUBTYPE_X86_64_ALL ,
    __XYX__CPU_SUBTYPE_X86_ARCH1  = CPU_SUBTYPE_X86_ARCH1  ,


    __XYX__CPU_THREADTYPE_INTEL_HTT = CPU_THREADTYPE_INTEL_HTT ,

/*
 *  Mips subtypes.
 */

    __XYX__CPU_SUBTYPE_MIPS_ALL    = CPU_SUBTYPE_MIPS_ALL    , 
    __XYX__CPU_SUBTYPE_MIPS_R2300  = CPU_SUBTYPE_MIPS_R2300  , 
    __XYX__CPU_SUBTYPE_MIPS_R2600  = CPU_SUBTYPE_MIPS_R2600  , 
    __XYX__CPU_SUBTYPE_MIPS_R2800  = CPU_SUBTYPE_MIPS_R2800  , 
    __XYX__CPU_SUBTYPE_MIPS_R2000a = CPU_SUBTYPE_MIPS_R2000a , /* pmax */
    __XYX__CPU_SUBTYPE_MIPS_R2000  = CPU_SUBTYPE_MIPS_R2000  , 
    __XYX__CPU_SUBTYPE_MIPS_R3000a = CPU_SUBTYPE_MIPS_R3000a , /* 3max */
    __XYX__CPU_SUBTYPE_MIPS_R3000  = CPU_SUBTYPE_MIPS_R3000  , 

/*
 *  MC98000 (PowerPC) subtypes
 */
    __XYX__CPU_SUBTYPE_MC98000_ALL = CPU_SUBTYPE_MC98000_ALL ,
    __XYX__CPU_SUBTYPE_MC98601     = CPU_SUBTYPE_MC98601     ,

/*
 *  HPPA subtypes for Hewlett-Packard HP-PA family of
 *  risc processors. Port by NeXT to 700 series. 
 */

    __XYX__CPU_SUBTYPE_HPPA_ALL    = CPU_SUBTYPE_HPPA_ALL   ,
    __XYX__CPU_SUBTYPE_HPPA_7100   = CPU_SUBTYPE_HPPA_7100  , /* compat */
    __XYX__CPU_SUBTYPE_HPPA_7100LC = CPU_SUBTYPE_HPPA_7100LC,

/*
 *  MC88000 subtypes.
 */
    __XYX__CPU_SUBTYPE_MC88000_ALL = CPU_SUBTYPE_MC88000_ALL ,
    __XYX__CPU_SUBTYPE_MC88100     = CPU_SUBTYPE_MC88100     ,
    __XYX__CPU_SUBTYPE_MC88110     = CPU_SUBTYPE_MC88110     ,

/*
 *  SPARC subtypes
 */
    __XYX__CPU_SUBTYPE_SPARC_ALL = CPU_SUBTYPE_SPARC_ALL ,

/*
 *  I860 subtypes
 */
    __XYX__CPU_SUBTYPE_I860_ALL = CPU_SUBTYPE_I860_ALL,
    __XYX__CPU_SUBTYPE_I860_860 = CPU_SUBTYPE_I860_860,

/*
 *  PowerPC subtypes
 */
    __XYX__CPU_SUBTYPE_POWERPC_ALL   = CPU_SUBTYPE_POWERPC_ALL   ,
    __XYX__CPU_SUBTYPE_POWERPC_601   = CPU_SUBTYPE_POWERPC_601   ,
    __XYX__CPU_SUBTYPE_POWERPC_602   = CPU_SUBTYPE_POWERPC_602   ,
    __XYX__CPU_SUBTYPE_POWERPC_603   = CPU_SUBTYPE_POWERPC_603   ,
    __XYX__CPU_SUBTYPE_POWERPC_603e  = CPU_SUBTYPE_POWERPC_603e  ,
    __XYX__CPU_SUBTYPE_POWERPC_603ev = CPU_SUBTYPE_POWERPC_603ev ,
    __XYX__CPU_SUBTYPE_POWERPC_604   = CPU_SUBTYPE_POWERPC_604   ,
    __XYX__CPU_SUBTYPE_POWERPC_604e  = CPU_SUBTYPE_POWERPC_604e  ,
    __XYX__CPU_SUBTYPE_POWERPC_620   = CPU_SUBTYPE_POWERPC_620   ,
    __XYX__CPU_SUBTYPE_POWERPC_750   = CPU_SUBTYPE_POWERPC_750   ,
    __XYX__CPU_SUBTYPE_POWERPC_7400  = CPU_SUBTYPE_POWERPC_7400  ,
    __XYX__CPU_SUBTYPE_POWERPC_7450  = CPU_SUBTYPE_POWERPC_7450  ,
    __XYX__CPU_SUBTYPE_POWERPC_970   = CPU_SUBTYPE_POWERPC_970   ,

/*
 *  ARM subtypes
 */
    __XYX__CPU_SUBTYPE_ARM_ALL = CPU_SUBTYPE_ARM_ALL,
    __XYX__CPU_SUBTYPE_ARM_V4T = CPU_SUBTYPE_ARM_V4T,
    __XYX__CPU_SUBTYPE_ARM_V6  = CPU_SUBTYPE_ARM_V6 ,

/*
 *  CPU families (sysctl hw.cpufamily)
 *
 * These are meant to identify the CPU's marketing name - an
 * application can map these to (possibly) localized strings.
 * NB: the encodings of the CPU families are intentionally arbitrary.
 * There is no ordering, and you should never try to deduce whether
 * or not some feature is available based on the family.
 * Use feature flags (eg, hw.optional.altivec) to test for optional
 * functionality.
 */
    __XYX__CPUFAMILY_UNKNOWN       = CPUFAMILY_UNKNOWN       ,
    __XYX__CPUFAMILY_POWERPC_G3    = CPUFAMILY_POWERPC_G3    ,
    __XYX__CPUFAMILY_POWERPC_G4    = CPUFAMILY_POWERPC_G4    ,
    __XYX__CPUFAMILY_POWERPC_G5    = CPUFAMILY_POWERPC_G5    ,
    __XYX__CPUFAMILY_INTEL_6_13    = CPUFAMILY_INTEL_6_13    ,
    __XYX__CPUFAMILY_INTEL_6_14    = CPUFAMILY_INTEL_6_14    ,/* "Intel Core Solo" and "Intel Core Duo" (32-bit Pentium-M with SSE3) */
    __XYX__CPUFAMILY_INTEL_6_15    = CPUFAMILY_INTEL_6_15    ,/* "Intel Core 2 Duo" */
    __XYX__CPUFAMILY_INTEL_6_23    = CPUFAMILY_INTEL_6_23    ,/* Penryn */
    __XYX__CPUFAMILY_INTEL_6_26    = CPUFAMILY_INTEL_6_26    ,/* Nehalem */
    __XYX__CPUFAMILY_ARM_9         = CPUFAMILY_ARM_9         ,
    __XYX__CPUFAMILY_ARM_11        = CPUFAMILY_ARM_11        ,

    __XYX__CPUFAMILY_INTEL_YONAH   = CPUFAMILY_INTEL_YONAH   , 
    __XYX__CPUFAMILY_INTEL_MEROM   = CPUFAMILY_INTEL_MEROM   , 
    __XYX__CPUFAMILY_INTEL_PENRYN  = CPUFAMILY_INTEL_PENRYN  , 
    __XYX__CPUFAMILY_INTEL_NEHALEM = CPUFAMILY_INTEL_NEHALEM , 

    __XYX__CPUFAMILY_INTEL_CORE    = CPUFAMILY_INTEL_CORE    , 
    __XYX__CPUFAMILY_INTEL_CORE2   = CPUFAMILY_INTEL_CORE2   , 
}

#endif  /* _MACH_MACHINE_H_ */
