/*
 *  Copyright (C) 2004-2005 by Digital Mars, www.digitalmars.com
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

module rt.compiler.dmd.typeinfo.ti_Acfloat;

private import rt.compiler.dmd.typeinfo.ti_cfloat;
private import rt.compiler.util.hash;

// cfloat[]

class TypeInfo_Aq : TypeInfo_Array
{
    override char[] toString() { return "cfloat[]"; }

    override hash_t getHash(in void* p) {
        cfloat[] s = *cast(cfloat[]*)p;
        size_t len = s.length;
        cfloat *str = s.ptr;
        return rt_hash_str(str,len*cfloat.sizeof,0);
    }

    override equals_t equals(in void* p1, in void* p2)
    {
        cfloat[] s1 = *cast(cfloat[]*)p1;
        cfloat[] s2 = *cast(cfloat[]*)p2;
        size_t len = s1.length;

        if (len != s2.length)
            return false;
        for (size_t u = 0; u < len; u++)
        {
            if (!TypeInfo_q._equals(s1[u], s2[u]))
                return false;
        }
        return true;
    }

    override int compare(in void* p1, in void* p2)
    {
        cfloat[] s1 = *cast(cfloat[]*)p1;
        cfloat[] s2 = *cast(cfloat[]*)p2;
        size_t len = s1.length;

        if (s2.length < len)
            len = s2.length;
        for (size_t u = 0; u < len; u++)
        {
            int c = TypeInfo_q._compare(s1[u], s2[u]);
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
        return (cfloat[]).sizeof;
    }

    override uint flags()
    {
        return 1;
    }

    override TypeInfo next()
    {
        return typeid(cfloat);
    }
}
