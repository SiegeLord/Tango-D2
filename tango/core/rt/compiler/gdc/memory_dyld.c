// Could config test HAVE_PRIVATE_EXTERN, but this should be okay
#ifndef __private_extern__
#define __private_extern__ extern
#include <mach-o/dyld.h>
#undef __private_extern__
#else
#include <mach-o/dyld.h>
#endif

#include <mach-o/getsect.h>
#include <stdlib.h>

enum DataSegmentTracking {
    ExecutableOnly,
    LoadTimeLibrariesOnly,
    Dynamic
};

const static struct {
        const char *seg;
        const char *sect;
} GC_dyld_sections[] = {
        { SEG_DATA, SECT_DATA },
        { SEG_DATA, SECT_BSS },
        { SEG_DATA, SECT_COMMON }
};

void _d_gcc_gc_add_range( void* beg, void* end );
void _d_gcc_gc_remove_range( void* beg );

/* This should never be called by a thread holding the lock */
static void
on_dyld_add_image(const struct mach_header* hdr, intptr_t slide) {
    unsigned i;
    void *start, *end;
    const struct section *sec;

    for (i = 0;
         i < sizeof(GC_dyld_sections) / sizeof(GC_dyld_sections[0]);
         i++) {

        sec = getsectbynamefromheader(hdr, GC_dyld_sections[i].seg,
            GC_dyld_sections[i].sect);
        if (sec == NULL || sec->size == 0)
            continue;
        start = (void*)( sec->addr + slide );
        end = (void*)( start + sec->size );

        _d_gcc_gc_add_range((void*) start, (void*) end);
    }
}

/* This should never be called by a thread holding the lock */
static void
on_dyld_remove_image(const struct mach_header* hdr, intptr_t slide) {
    unsigned i;
    void *start, *end;
    const struct section *sec;

    for(i = 0;
        i < sizeof(GC_dyld_sections) / sizeof(GC_dyld_sections[0]);
        i++) {

        sec = getsectbynamefromheader(hdr,
            GC_dyld_sections[i].seg, GC_dyld_sections[i].sect);
        if (sec == NULL || sec->size == 0)
            continue;
        start = (void*)( sec->addr + slide );
        end = (void*)( start + sec->size );

        _d_gcc_gc_remove_range(start);
    }
}

void _d_gcc_dyld_start(enum DataSegmentTracking mode)
{
    static int started = 0;

    if (! started) {
        started = 1;
        _dyld_register_func_for_add_image(on_dyld_add_image);
        _dyld_register_func_for_remove_image(on_dyld_remove_image);
    }

    // (for LoadTimeLibrariesOnly:) Can't unregister callbacks
}
