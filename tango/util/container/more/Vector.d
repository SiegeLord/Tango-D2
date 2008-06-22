/*******************************************************************************

        copyright:      Copyright (c) 2008 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: April 2008      
        
        author:         Kris

*******************************************************************************/

module tango.util.container.more.Vector;

private import tango.core.Exception : ArrayBoundsException;

private extern(C) void memmove (void*, void*, int);

/******************************************************************************

        A vector of the given value-type V, with maximum depth Size. Note
        that this is a value type, and does no memory allocation of its
        own 

******************************************************************************/

struct Vector (V, int Size) 
{
        private V[Size]         vector;
        private uint            depth;

        alias slice             opSlice;
        alias nth               opIndex;
          
        /***********************************************************************

                Clear the vector

        ***********************************************************************/

        void clear ()
        {
                depth = 0;
        }

        /***********************************************************************
                
                Return depth of the vector

        ***********************************************************************/

        uint size ()
        {
                return depth;
        }

        /***********************************************************************
                
                Returns a (shallow) clone of this vector

        ***********************************************************************/

        Vector clone ()
        {       
                Vector v = void;
                v.vector[] = vector;
                v.depth = depth;
                return v;
        }

        /**********************************************************************

                Add a value to the vector.

                Throws an exception when the vector is full

        **********************************************************************/

        void add (V value)
        {
                if (depth < vector.length)
                    vector[depth++] = value;
                else
                   error (__LINE__);
        }

        /**********************************************************************

                Add a series of values to the vector.

                Throws an exception when the vector is full

        **********************************************************************/

        void addMore (V[] value...)
        {
                foreach (v; value)
                         add (v);
        }

        /**********************************************************************

                Remove and return the most recent addition to the vector.

                Throws an exception when the vector is empty

        **********************************************************************/

        V remove ()
        {
                if (depth)
                    return vector[--depth];

                return error (__LINE__);
        }

        /**********************************************************************

                Index vector entries, where a zero index represents the
                oldest vector entry.

                Throws an exception when the given index is out of range

        **********************************************************************/

        V remove (uint i)
        {
                if (i < depth)
                   {
                   if (i is depth-1)
                       return remove;
                   --depth;
                   auto v = vector [i];
                   memmove (vector.ptr+i, vector.ptr+i+1, V.sizeof * depth-i);
                   return v;
                   }

                return error (__LINE__);
        }

        /**********************************************************************

                Index vector entries, where a zero index represents the
                oldest vector entry (the top).

                Throws an exception when the given index is out of range

        **********************************************************************/

        V nth (uint i)
        {
                if (i < depth)
                    return vector [i];

                return error (__LINE__);
        }

        /**********************************************************************

                Return the vector as an array of values, where the first
                array entry represents the oldest value. 
                
                Doing a foreach() on the returned array will traverse in
                the opposite direction of foreach() upon a vector
                 
        **********************************************************************/

        V[] slice ()
        {
                return vector [0 .. depth];
        }

        /**********************************************************************

                Throw an exception

        **********************************************************************/

        private V error (size_t line)
        {
                throw new ArrayBoundsException (__FILE__, line);
        }

        /***********************************************************************

                Iterate from the most recent to the oldest vector entries

        ***********************************************************************/

        int opApply (int delegate(ref V value) dg)
        {
                        int result;

                        for (int i=depth; i--;)
                            {
                            auto value = vector [i];
                            if ((result = dg(value)) != 0)
                                 break;
                            }
                        return result;
        }

        /***********************************************************************

                Iterate from the most recent to the oldest vector entries

        ***********************************************************************/

        int opApply (int delegate(ref V value, ref bool kill) dg)
        {
                        int result;

                        for (int i=depth; i--;)
                            {
                            auto kill = false;
                            auto value = vector [i];
                            if ((result = dg(value, kill)) != 0)
                                 break;
                            else
                               if (kill)
                                   remove (i);
                            }
                        return result;
        }
}


/*******************************************************************************

*******************************************************************************/

debug (Vector)
{
        import tango.io.Stdout;

        void main()
        {
                Vector!(int, 10) s;

                Stdout.formatln ("add four");
                s.add (1);
                s.add (2);
                s.add (3);
                s.add (4);
                foreach (v; s)
                         Stdout.formatln ("{}", v);

                s = s.clone;
                Stdout.formatln ("pop one: {}", s.remove);
                foreach (v; s)
                         Stdout.formatln ("{}", v);

                Stdout.formatln ("remove[1]: {}", s.remove(1));
                foreach (v; s)
                         Stdout.formatln ("{}", v);

                Stdout.formatln ("remove two");
                s.remove;
                s.remove;
                foreach (v; s)
                         Stdout.formatln ("> {}", v);

                s.add (1);
                s.add (2);
                s.add (3);
                s.add (4);
                foreach (v, ref k; s)
                         k = true;
                Stdout.formatln ("size {}", s.size);
                
        }
}
        
