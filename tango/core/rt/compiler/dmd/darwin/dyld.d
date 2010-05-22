/**
 * Copyright: Copyright (c) 2010 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Feb 20, 2010
 * License: BSD style: $(LICENSE)
 */
module rt.compiler.dmd.darwin.dyld;

version (darwin):

import rt.compiler.dmd.darwin.loader;

extern (C):

uint _dyld_image_count ();
mach_header* _dyld_get_image_header (uint image_index);
