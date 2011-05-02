/**
 * Copyright: Copyright (c) 2010 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Mar 16, 2010
 * License: BSD style: $(LICENSE)
 */
module rt.compiler.dmd.darwin.getsect;

version (darwin):

import rt.compiler.dmd.darwin.loader;

extern (C):

section* getsectbynamefromheader (in mach_header* mhp, in char* segname, in char* sectname);
section_64* getsectbynamefromheader_64 (mach_header_64* mhp, in char* segname, in char* sectname);
