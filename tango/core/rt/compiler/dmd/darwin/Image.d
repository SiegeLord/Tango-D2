/**
 * Copyright: Copyright (c) 2010 Jacob Carlborg. All rights reserved.
 * Authors: Jacob Carlborg
 * Version: Initial created: Feb 23, 2010
 * License: BSD style: $(LICENSE)
 */
module rt.compiler.dmd.darwin.Image;

version (darwin):

import rt.compiler.dmd.darwin.dyld;
import rt.compiler.dmd.darwin.loader;
import rt.compiler.dmd.darwin.getsect;

struct Image
{
	private mach_header* header_;
	private uint index_;
	
	static Image opCall (uint index)
	{
		Image image;
		image.header_ = _dyld_get_image_header(index);
		image.index_ = index;
		
		return image;
	}
	
	static uint numberOfImages ()
	{
		return _dyld_image_count;
	}
	
	static int opApply (int delegate(ref Image) dg)
	{
		int result;
		
		for (size_t i = 0; i < numberOfImages; i++)
		{
			result = dg(Image(i));
			
			if (result)
				break;
		}
		
		return result;
	}
	
	static int opApplyReverse (int delegate(ref Image) dg)
	{
		int result;
		
		for (int i = numberOfImages - 1; i >= 0; i--)
		{
			result = dg(Image(i));
			
			if (result)
				break;
		}
		
		return result;
	}
	
	mach_header* header ()
	{
		return header_;
	}
	
	mach_header_64* header64 ()
	{
		return cast(mach_header_64*) header_;
	}
	
	CPU cpu ()
	{
		return CPU(header_);
	}
}

struct CPU
{
	private mach_header* header;
	
	static CPU opCall (mach_header* header)
	{
		CPU cpu;
		cpu.header = header;
		
		return cpu;
	}
	
	bool is32bit ()
	{		
		return (header.magic & MH_MAGIC) != 0;
	}

	bool is64bit ()
	{
		return (header.magic & MH_MAGIC_64) != 0;
	}
}

T[] getSectionData (T, char[] segmentName, char[] sectionName) ()
{
    T[] array;
    
    const c_segmentName = segmentName.ptr;
    const c_sectionName = sectionName.ptr;    
    
    void* start;
    void* end;
    
    foreach_reverse (image ; Image)
    {            
        if (image.cpu.is32bit)
        {
            auto header = image.header;
            section* sect = getsectbynamefromheader(header, c_segmentName, c_sectionName);
            
            if (sect is null || sect.size == 0)
                continue;

            start = cast(void*) (cast(byte*) header + sect.offset);
    	    end = cast(void*) (cast(byte*) start + sect.size);
        }
        
        else
        {
            auto header = image.header64;
            section_64* sect = getsectbynamefromheader_64(header, c_segmentName, c_sectionName);
            
            if (sect is null || sect.size == 0)
                continue;

            start = cast(void*) (cast(byte*) header + sect.offset);
    	    end = cast(void*) (cast(byte*) start + sect.size);
        }
	    
	    size_t len = cast(T*)end - cast(T*)start;
		array ~= (cast(T*)start)[0 .. len];
    }
    
    return array;
}
