/+ sed -e 's///g' -e 's///g' -e 's///g' +/
module tango.sys.darwin.consts.machine;
alias int cpu_type_t;
alias int cpu_subtype_t;
alias int cpu_threadtype_t;
enum{
    CPU_STATE_MAX = 4,
    CPU_STATE_USER = 0 ,
    CPU_STATE_SYSTEM = 1,
    CPU_STATE_IDLE = 2 ,
    CPU_STATE_NICE = 3 ,
/*
 * Capability bits used in the definition of cpu_type.
 */
    CPU_ARCH_MASK = 0xff000000 , /* mask for architecture bits */
    CPU_ARCH_ABI64 = 0x01000000, /* 64 bit ABI */
/*
 *  Machine types known by all.
 */
    CPU_TYPE_ANY = ( -1),
    CPU_TYPE_VAX = ( 1) ,
    CPU_TYPE_MC680x0 = ( 6) ,
    CPU_TYPE_X86 = ( 7) ,
    CPU_TYPE_I386 = ( 7) , /* compatibility */
    CPU_TYPE_X86_64 = (( 7) | 0x01000000) ,
/* skip CPU_TYPE_MIPS       ( 8)    */
    CPU_TYPE_MC98000 = ( 10),
    CPU_TYPE_HPPA = ( 11) ,
    CPU_TYPE_ARM = ( 12) ,
    CPU_TYPE_MC88000 = ( 13),
    CPU_TYPE_SPARC = ( 14) ,
    CPU_TYPE_I860 = ( 15) ,
/* skip CPU_TYPE_ALPHA      ( 16)   */
    CPU_TYPE_POWERPC = ( 18) ,
    CPU_TYPE_POWERPC64 = (( 18) | 0x01000000) ,
/*
 *  Machine subtypes (these are defined here, instead of in a machine
 *  dependent directory, so that any program can get all definitions
 *  regardless of where is it compiled).
 */
/*
 * Capability bits used in the definition of cpu_subtype.
 */
    CPU_SUBTYPE_MASK = 0xff000000 , /* mask for feature flags */
    CPU_SUBTYPE_LIB64 = 0x80000000, /* 64 bit libraries */
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
    CPU_SUBTYPE_MULTIPLE = ( -1) ,
    CPU_SUBTYPE_LITTLE_ENDIAN = ( 0) ,
    CPU_SUBTYPE_BIG_ENDIAN = ( 1) ,
/*
 *     Machine threadtypes.
 *     This is none - not defined - for most machine types/subtypes.
 */
    CPU_THREADTYPE_NONE = ( 0),
/*
 *  VAX subtypes (these do *not* necessary conform to the actual cpu
 *  ID assigned by DEC available via the SID register).
 */
    CPU_SUBTYPE_VAX_ALL = ( 0) ,
    CPU_SUBTYPE_VAX780 = ( 1) ,
    CPU_SUBTYPE_VAX785 = ( 2) ,
    CPU_SUBTYPE_VAX750 = ( 3) ,
    CPU_SUBTYPE_VAX730 = ( 4) ,
    CPU_SUBTYPE_UVAXI = ( 5) ,
    CPU_SUBTYPE_UVAXII = ( 6) ,
    CPU_SUBTYPE_VAX8200 = ( 7) ,
    CPU_SUBTYPE_VAX8500 = ( 8) ,
    CPU_SUBTYPE_VAX8600 = ( 9) ,
    CPU_SUBTYPE_VAX8650 = ( 10) ,
    CPU_SUBTYPE_VAX8800 = ( 11) ,
    CPU_SUBTYPE_UVAXIII = ( 12) ,
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
    CPU_SUBTYPE_MC680x0_ALL = ( 1) ,
    CPU_SUBTYPE_MC68030 = ( 1) ,/* compat */
    CPU_SUBTYPE_MC68040 = ( 2) ,
    CPU_SUBTYPE_MC68030_ONLY = ( 3) ,
/*
 *  I386 subtypes
 */
    CPU_SUBTYPE_I386_ALL = ( (3) + ((0) << 4)) ,
    CPU_SUBTYPE_386 = ( (3) + ((0) << 4)) ,
    CPU_SUBTYPE_486 = ( (4) + ((0) << 4)) ,
    CPU_SUBTYPE_486SX = ( (4) + ((8) << 4)) ,
    CPU_SUBTYPE_586 = ( (5) + ((0) << 4)) ,
    CPU_SUBTYPE_PENT = ( (5) + ((0) << 4)) ,
    CPU_SUBTYPE_PENTPRO = ( (6) + ((1) << 4)) ,
    CPU_SUBTYPE_PENTII_M3 = ( (6) + ((3) << 4)) ,
    CPU_SUBTYPE_PENTII_M5 = ( (6) + ((5) << 4)) ,
    CPU_SUBTYPE_CELERON = ( (7) + ((6) << 4)) ,
    CPU_SUBTYPE_CELERON_MOBILE = ( (7) + ((7) << 4)) ,
    CPU_SUBTYPE_PENTIUM_3 = ( (8) + ((0) << 4)) ,
    CPU_SUBTYPE_PENTIUM_3_M = ( (8) + ((1) << 4)) ,
    CPU_SUBTYPE_PENTIUM_3_XEON = ( (8) + ((2) << 4)) ,
    CPU_SUBTYPE_PENTIUM_M = ( (9) + ((0) << 4)) ,
    CPU_SUBTYPE_PENTIUM_4 = ( (10) + ((0) << 4)) ,
    CPU_SUBTYPE_PENTIUM_4_M = ( (10) + ((1) << 4)) ,
    CPU_SUBTYPE_ITANIUM = ( (11) + ((0) << 4)) ,
    CPU_SUBTYPE_ITANIUM_2 = ( (11) + ((1) << 4)) ,
    CPU_SUBTYPE_XEON = ( (12) + ((0) << 4)) ,
    CPU_SUBTYPE_XEON_MP = ( (12) + ((1) << 4)) ,
}
uint extractSubtypeFamily(uint x){
    return ((x) & 15);
}
uint extractCpuSubtypeModel(uint x){
    return ((x) >> 4);
}
enum{
    CPU_SUBTYPE_INTEL_FAMILY_MAX = 15,
    CPU_SUBTYPE_INTEL_MODEL_ALL = 0,
/*
 *  X86 subtypes.
 */
    CPU_SUBTYPE_X86_ALL = (3) ,
    CPU_SUBTYPE_X86_64_ALL = (3) ,
    CPU_SUBTYPE_X86_ARCH1 = (4) ,
    CPU_THREADTYPE_INTEL_HTT = ( 1) ,
/*
 *  Mips subtypes.
 */
    CPU_SUBTYPE_MIPS_ALL = ( 0) ,
    CPU_SUBTYPE_MIPS_R2300 = ( 1) ,
    CPU_SUBTYPE_MIPS_R2600 = ( 2) ,
    CPU_SUBTYPE_MIPS_R2800 = ( 3) ,
    CPU_SUBTYPE_MIPS_R2000a = ( 4) , /* pmax */
    CPU_SUBTYPE_MIPS_R2000 = ( 5) ,
    CPU_SUBTYPE_MIPS_R3000a = ( 6) , /* 3max */
    CPU_SUBTYPE_MIPS_R3000 = ( 7) ,
/*
 *  MC98000 (PowerPC) subtypes
 */
    CPU_SUBTYPE_MC98000_ALL = ( 0) ,
    CPU_SUBTYPE_MC98601 = ( 1) ,
/*
 *  HPPA subtypes for Hewlett-Packard HP-PA family of
 *  risc processors. Port by NeXT to 700 series. 
 */
    CPU_SUBTYPE_HPPA_ALL = ( 0) ,
    CPU_SUBTYPE_HPPA_7100 = ( 0) , /* compat */
    CPU_SUBTYPE_HPPA_7100LC = ( 1),
/*
 *  MC88000 subtypes.
 */
    CPU_SUBTYPE_MC88000_ALL = ( 0) ,
    CPU_SUBTYPE_MC88100 = ( 1) ,
    CPU_SUBTYPE_MC88110 = ( 2) ,
/*
 *  SPARC subtypes
 */
    CPU_SUBTYPE_SPARC_ALL = ( 0) ,
/*
 *  I860 subtypes
 */
    CPU_SUBTYPE_I860_ALL = ( 0),
    CPU_SUBTYPE_I860_860 = ( 1),
/*
 *  PowerPC subtypes
 */
    CPU_SUBTYPE_POWERPC_ALL = ( 0) ,
    CPU_SUBTYPE_POWERPC_601 = ( 1) ,
    CPU_SUBTYPE_POWERPC_602 = ( 2) ,
    CPU_SUBTYPE_POWERPC_603 = ( 3) ,
    CPU_SUBTYPE_POWERPC_603e = ( 4) ,
    CPU_SUBTYPE_POWERPC_603ev = ( 5) ,
    CPU_SUBTYPE_POWERPC_604 = ( 6) ,
    CPU_SUBTYPE_POWERPC_604e = ( 7) ,
    CPU_SUBTYPE_POWERPC_620 = ( 8) ,
    CPU_SUBTYPE_POWERPC_750 = ( 9) ,
    CPU_SUBTYPE_POWERPC_7400 = ( 10) ,
    CPU_SUBTYPE_POWERPC_7450 = ( 11) ,
    CPU_SUBTYPE_POWERPC_970 = ( 100) ,
/*
 *  ARM subtypes
 */
    CPU_SUBTYPE_ARM_ALL = ( 0),
    CPU_SUBTYPE_ARM_V4T = ( 5),
    CPU_SUBTYPE_ARM_V6 = ( 6) ,
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
    CPUFAMILY_UNKNOWN = 0 ,
    CPUFAMILY_POWERPC_G3 = 0xcee41549 ,
    CPUFAMILY_POWERPC_G4 = 0x77c184ae ,
    CPUFAMILY_POWERPC_G5 = 0xed76d8aa ,
    CPUFAMILY_INTEL_6_13 = 0xaa33392b ,
    CPUFAMILY_INTEL_6_14 = 0x73d67300 ,/* " Core Solo" and " Core Duo" (32-bit Pentium-M with SSE3) */
    CPUFAMILY_INTEL_6_15 = 0x426f69ef ,/* " Core 2 Duo" */
    CPUFAMILY_INTEL_6_23 = 0x78ea4fbc ,/* Penryn */
    CPUFAMILY_INTEL_6_26 = 0x6b5a4cd2 ,/* Nehalem */
    CPUFAMILY_ARM_9 = 0xe73283ae ,
    CPUFAMILY_ARM_11 = 0x8ff620d8 ,
    CPUFAMILY_INTEL_YONAH = 0x73d67300 ,
    CPUFAMILY_INTEL_MEROM = 0x426f69ef ,
    CPUFAMILY_INTEL_PENRYN = 0x78ea4fbc ,
    CPUFAMILY_INTEL_NEHALEM = 0x6b5a4cd2 ,
    CPUFAMILY_INTEL_CORE = 0x73d67300 ,
    CPUFAMILY_INTEL_CORE2 = 0x426f69ef ,
}
