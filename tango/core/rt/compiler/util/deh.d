
module rt.compiler.util.deh;

private extern (C) void* gc_calloc(size_t sz, uint ba, PointerMap pm);

extern (C) void* gc_calloc_noscan(size_t sz)
{
	return gc_calloc(sz, 2 /* NO_SCAN */, PointerMap.init);
}

