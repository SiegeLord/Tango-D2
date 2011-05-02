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

/*
 *  Modified by Sean Kelly <sean@f4.ca> for use with Tango.
 */

module rt.compiler.dmd.rt.cast_;

extern (C):

/******************************************
 * Given a pointer:
 *      If it is an Object, return that Object.
 *      If it is an interface, return the Object implementing the interface.
 *      If it is null, return null.
 *      Else, undefined crash
 */

Object _d_toObject(void* p)
{   Object o;

    if (p)
    {
        o = cast(Object)p;
        ClassInfo oc = o.classinfo;
        Interface *pi = **cast(Interface ***)p;

        /* Interface.offset lines up with ClassInfo.name.ptr,
         * so we rely on pointers never being less than 64K,
         * and Objects never being greater.
         */
        if (pi.offset < 0x10000)
        {
            //printf("\tpi.offset = %d\n", pi.offset);
            o = cast(Object)(p - pi.offset);
        }
    }
    return o;
}


/*************************************
 * Attempts to cast Object o to class c.
 * Returns o if successful, null if not.
 */

Object _d_interface_cast(void* p, ClassInfo c)
{   Object o;

    //printf("_d_interface_cast(p = %p, c = '%.*s')\n", p, c.name);
    if (p)
    {
        Interface *pi = **cast(Interface ***)p;

        //printf("\tpi.offset = %d\n", pi.offset);
        o = cast(Object)(p - pi.offset);
        return _d_dynamic_cast(o, c);
    }
    return o;
}

Object _d_dynamic_cast(Object o, ClassInfo c)
{   ClassInfo oc;
    size_t offset = 0;

    //printf("_d_dynamic_cast(o = %p, c = '%.*s')\n", o, c.name);

    if (o)
    {
        oc = o.classinfo;
        if (_d_isbaseof2(oc, c, offset))
        {
            //printf("\toffset = %d\n", offset);
            o = cast(Object)(cast(void*)o + offset);
        }
        else
            o = null;
    }
    //printf("\tresult = %p\n", o);
    return o;
}

int _d_isbaseof2(ClassInfo oc, ClassInfo c, ref size_t offset)
{   int i;

    if (oc is c)
        return 1;
    do
    {
        if (oc.base is c)
            return 1;
        for (i = 0; i < oc.interfaces.length; i++)
        {
            ClassInfo ic;

            ic = oc.interfaces[i].classinfo;
            if (ic is c)
            {   offset = oc.interfaces[i].offset;
                return 1;
            }
        }
        for (i = 0; i < oc.interfaces.length; i++)
        {
            ClassInfo ic;

            ic = oc.interfaces[i].classinfo;
            if (_d_isbaseof2(ic, c, offset))
            {   offset = oc.interfaces[i].offset;
                return 1;
            }
        }
        oc = oc.base;
    } while (oc);
    return 0;
}

int _d_isbaseof(ClassInfo oc, ClassInfo c)
{   int i;

    if (oc is c)
        return 1;
    do
    {
        if (oc.base is c)
            return 1;
        for (i = 0; i < oc.interfaces.length; i++)
        {
            ClassInfo ic;

            ic = oc.interfaces[i].classinfo;
            if (ic is c || _d_isbaseof(ic, c))
                return 1;
        }
        oc = oc.base;
    } while (oc);
    return 0;
}

/*********************************
 * Find the vtbl[] associated with Interface ic.
 */

void *_d_interface_vtbl(ClassInfo ic, Object o)
{   int i;
    ClassInfo oc;

    //printf("__d_interface_vtbl(o = %p, ic = %p)\n", o, ic);

    assert(o);

    oc = o.classinfo;
    for (i = 0; i < oc.interfaces.length; i++)
    {
        ClassInfo oic;

        oic = oc.interfaces[i].classinfo;
        if (oic is ic)
        {
            return cast(void *)oc.interfaces[i].vtbl;
        }
    }
    assert(0);
}
