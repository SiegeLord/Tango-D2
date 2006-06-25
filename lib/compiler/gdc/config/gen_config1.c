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

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <dirent.h>
#include <sys/types.h>
#include <sys/time.h>
#include <time.h>
#include <limits.h>
#include <assert.h>

#include "config.h"

#define sympfx ""

const char * D_type_for(unsigned size, int is_signed) {
    switch (size) {
    case 1: return is_signed ? "byte" : "ubyte";
    case 2: return is_signed ? "short" : "ushort";
    case 4: return is_signed ? "int" : "uint";
    case 8: return is_signed ? "long" : "ulong";
    default:
	assert(0);
	return NULL;
    }     
}

#define CONFIG_INT_TYPE(typename) \
{ \
     char zerobuf[sizeof(typename)]; \
     char neg1buf[sizeof(typename)]; \
     memset(zerobuf, 0x0, sizeof(typename)); \
     memset(neg1buf, 0xff, sizeof(typename)); \
     printf("alias %s %s;\n", \
	 D_type_for(sizeof(typename),*(typename *)neg1buf < *(typename *)zerobuf), \
	 "C"#typename); \
}

void errorExit(const char * msg)
{
    fprintf(stderr, "error: %s\n", msg);
    exit(1);
}

int main() {
    struct dirent de;
    unsigned offset;
   
    offset = (char*) & de.d_name - (char*) & de;
    printf("\n");
    printf("// from <dirent.h>\n");
    printf("const size_t dirent_d_name_offset = %u;\n", offset);
    printf("const size_t dirent_d_name_size = %u;\n", sizeof(de.d_name));
    printf("const size_t dirent_remaining_size = %u;\n", sizeof(de) - (offset + sizeof(de.d_name)));
    printf("const size_t DIR_struct_size = %u;\n",
#if HAVE_SIZEOF_DIR
	sizeof(DIR)
#else
	0
#endif
	   );
    printf("\n");

    printf("// from <stdlib.h>\n");
#ifdef RAND_MAX
    printf("const int RAND_MAX = %d;\n", RAND_MAX);
#endif
    printf("\n");

    printf("// from <stdio.h>\n");
    printf("const size_t FILE_struct_size = %u;\n",
#if HAVE_SIZEOF_FILE
	sizeof(FILE)
#else
	0
#endif
	   );
#if HAVE_SNPRINTF
    //printf(""); // not sure if this is needed for can just use builtins
#endif
    
    printf("const int " sympfx"EOF = %d;\n", EOF);
    printf("const int " sympfx"FOPEN_MAX = %d;\n", FOPEN_MAX); // HAVE_FOPEN_MAX?
    printf("const int " sympfx"FILENAME_MAX = %d;\n", FILENAME_MAX);
    printf("const int " sympfx"TMP_MAX = %d;\n", TMP_MAX); // "?
    printf("const int " sympfx"L_tmpnam = %d;\n", L_tmpnam);
    // extra, needed for std.file.getcwd
    printf("const int " sympfx"PATH_MAX = %d;\n", PATH_MAX);
    printf("\n");
    
    printf("// from <sys/types.h>\n");
    CONFIG_INT_TYPE(off_t);
    CONFIG_INT_TYPE(size_t);
    CONFIG_INT_TYPE(time_t);
    printf("\n");

    printf("// from <time.h>\n");
    printf("const uint " sympfx"CLOCKS_PER_SEC = %u;\n", CLOCKS_PER_SEC);
    
    return 0;
}
