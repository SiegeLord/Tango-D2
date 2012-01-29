/*******************************************************************************

        copyright:      Copyright (c) 2008 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: April 2008      
        
        author:         Kris

        Since:          0.99.7

*******************************************************************************/

module tango.util.container.more.Vector;

private import tango.core.Exception : RangeError;
private import tango.stdc.string : memmove;

/******************************************************************************

        A vector of the given value-type V, with maximum depth Size. Note
        that this does no memory allocation of its own when Size != 0, and
        does heap allocation when Size == 0. Thus you can have a fixed-size
        low-overhead instance, or a heap oriented instance.

******************************************************************************/

struct Vector (V, int Size = 0) 
{
        alias add       push;
        alias slice     opSlice;

        Vector* opOpAssign(immutable(char)[] s : "~")(V value)
        {
            return push(value);
        }

        static if (Size == 0)
                  {
                  private size_t depth;
                  private V[]  vector;
                  }
               else
                  {
                  private size_t     depth;
                  private V[Size]  vector;
                  }

        /***********************************************************************

                Clear the vector

        ***********************************************************************/

        Vector* clear ()
        {
                depth = 0;
                return &this;
        }

        /***********************************************************************
                
                Return depth of the vector

        ***********************************************************************/

        @property const size_t size ()
        {
                return depth;
        }

        /***********************************************************************
                
                Return remaining unused slots

        ***********************************************************************/

        const size_t unused ()
        {
                return vector.length - depth;
        }

        /***********************************************************************
                
                Returns a (shallow) clone of this vector

        ***********************************************************************/

        Vector clone ()
        {       
                Vector v;
                static if (Size == 0)
                           v.vector.length = vector.length;
                
                v.vector[0..depth] = vector[0..depth];
                v.depth = depth;
                return v;
        }

        /**********************************************************************

                Add a value to the vector.

                Throws an exception when the vector is full

        **********************************************************************/

        V* add (V value)
        {
                static if (Size == 0)
                          {
                          if (depth >= vector.length)
                              vector.length = vector.length + 64;
                          vector[depth++] = value;
                          }
                       else
                          {                         
                          if (depth < vector.length)
                              vector[depth++] = value;
                          else
                             error (__LINE__);
                          }
                return &vector[depth-1];
        }

        /**********************************************************************

                Add a value to the vector.

                Throws an exception when the vector is full

        **********************************************************************/

        V* add ()
        {
                static if (Size == 0)
                          {
                          if (depth >= vector.length)
                              vector.length = vector.length + 64;
                          }
                       else
                          if (depth >= vector.length)
                              error (__LINE__);

                auto p = &vector[depth++];
                *p = V.init;
                return p;
        }

        /**********************************************************************

                Add a series of values to the vector.

                Throws an exception when the vector is full

        **********************************************************************/

        Vector* append (V[] value...)
        {
                foreach (v; value)
                         add (v);
                return &this;
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

        V remove (size_t i)
        {
                if (i < depth)
                   {
                   if (i is depth-1)
                       return remove;
                   --depth;
                   auto v = vector [i];
                   memmove (vector.ptr+i, vector.ptr+i+1, V.sizeof * (depth-i));
                   return v;
                   }

                return error (__LINE__);
        }

        /**********************************************************************

                Index vector entries, as though it were an array

                Throws an exception when the given index is out of range

        **********************************************************************/

        V opIndex (size_t i)
        {
                if (i < depth)
                    return vector [i];

                return error (__LINE__);
        }

        /**********************************************************************

                Assign vector entries as though it were an array.

                Throws an exception when the given index is out of range

        **********************************************************************/

        V opIndexAssign (V value, size_t i)
        {
                if (i < depth)
                   {
                   vector[i] = value;
                   return value;
                   }

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
                throw new RangeError (__FILE__, line);
        }

        /***********************************************************************

                Iterate from the most recent to the oldest vector entries

        ***********************************************************************/

        int opApply (scope int delegate(ref V value) dg)
        {
                        int result;

                        for (int i=depth; i-- && result is 0;)
                             result = dg (vector [i]);
                        return result;
        }

        /***********************************************************************

                Iterate from the most recent to the oldest vector entries

        ***********************************************************************/

        int opApply (scope int delegate(ref V value, ref bool kill) dg)
        {
                        int result;

                        for (int i=depth; i-- && result is 0;)
                            {
                            auto kill = false;
                            result = dg (vector[i], kill);
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
                Vector!(int, 0) v;
                v.add (1);
                
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
        
