/**
 * Copyright: Copyright (c) 2010 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Feb 20, 2010
 * License: BSD style: $(LICENSE)
 */
module rt.compiler.dmd.darwin.loader;

version (darwin):

struct mach_header
{
	uint magic;
	int cputype;
	int cpusubtype;
	uint filetype;
	uint ncmds;
	uint sizeofcmds;
	uint flags;
}

struct mach_header_64
{
	uint magic;
	int cputype;
	int cpusubtype;
	uint filetype;
	uint ncmds;
	uint sizeofcmds;
	uint flags;
	uint reserved;
}

enum : uint
{
	MH_MAGIC = 0xfeedface,
	MH_CIGAM = 0xcefaedfe,
	MH_MAGIC_64 = 0xfeedfacf,
	MH_CIGAM_64 = 0xcffaedfe,
}

struct section
{
	char[16] sectname;
	char[16] segname;
	uint addr;
	uint size;
	uint offset;
	uint align_;
	uint reloff;
	uint nreloc;
	uint flags;
	uint reserved1;
	uint reserved2;
}

struct section_64
{
	char[16] sectname;
	char[16] segname;
	long addr;
	long size;
	uint offset;
	uint align_;
	uint reloff;
	uint nreloc;
	uint flags;
	uint reserved1;
	uint reserved2;
	uint reserved3;
}
