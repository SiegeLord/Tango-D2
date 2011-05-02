/*
 *  Copyright (C) 2004-2006 by Digital Mars, www.digitalmars.com
 *  Written by Walter Bright
 *
 *  This software is provided 'as-is', without any express or implied
 *  warranty. In no event will the authors be held liable for any damages
 *  arising from the use of this software.
 *
 *  Permission is granted to anyone to use this software for any purpose,
 *  including commercial applications, and to alter it and redistribute it
 *  freely, in both source and binary form, subject to the following
 *  restrictions:
 *
 *  o  The origin of this software must not be misrepresented; you must not
 *     claim that you wrote the original software. If you use this software
 *     in a product, an acknowledgment in the product documentation would be
 *     appreciated but is not required.
 *  o  Altered source versions must be plainly marked as such, and must not
 *     be misrepresented as being the original software.
 *  o  This notice may not be removed or altered from any source
 *     distribution.
 */

module rt.compiler.dmd.typeinfo.ti_Areal;

private import rt.compiler.dmd.typeinfo.ti_real;
private import rt.compiler.util.hash;

// real[]

class TypeInfo_Ae : TypeInfo_Array
{
    override char[] toString() { return "real[]"; }

    override hash_t getHash(in void* p)
    {   real[] s = *cast(real[]*)p;
        size_t len = s.length;
        auto str = s.ptr;
        return rt_hash_str(str,len*real.sizeof,0);
    }

    override equals_t equals(in void* p1, in void* p2)
    {
        real[] s1 = *cast(real[]*)p1;
        real[] s2 = *cast(real[]*)p2;
        size_t len = s1.length;

        if (len != s2.length)
            return false;
        for (size_t u = 0; u < len; u++)
        {
            if (!TypeInfo_e._equals(s1[u], s2[u]))
                return false;
        }
        return true;
    }

    override int compare(in void* p1, in void* p2)
    {
        real[] s1 = *cast(real[]*)p1;
        real[] s2 = *cast(real[]*)p2;
        size_t len = s1.length;

        if (s2.length < len)
            len = s2.length;
        for (size_t u = 0; u < len; u++)
        {
            int c = TypeInfo_e._compare(s1[u], s2[u]);
            if (c)
                return c;
        }
        if (s1.length < s2.length)
            return -1;
        else if (s1.length > s2.length)
            return 1;
        return 0;
    }

    override size_t tsize()
    {
        return (real[]).sizeof;
    }

    override uint flags()
    {
        return 1;
    }

    override TypeInfo next()
    {
        return typeid(real);
    }
}

// ireal[]

class TypeInfo_Aj : TypeInfo_Ae
{
    override char[] toString() { return "ireal[]"; }

    override TypeInfo next()
    {
        return typeid(ireal);
    }
}
