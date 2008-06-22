/*******************************************************************************

        copyright:      Copyright (c) 2008 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: April 2008      
        
        author:         Kris

*******************************************************************************/

module tango.util.container.more.Stack;

private import tango.core.Exception : ArrayBoundsException;

/******************************************************************************

        A stack of the given value-type V, with maximum depth Size. Note
        that, being a struct, this is a stack-based Stack

******************************************************************************/

struct Stack (V, int Size) 
{
        private V[Size]         stack;
        private uint            depth;

        alias rotateLeft       opShlAssign;
        alias rotateRight      opShrAssign;
        alias push             opCatAssign;
        alias slice            opSlice;
        alias nth              opIndex;
          
        /***********************************************************************

                Clear the stack

        ***********************************************************************/

        void clear ()
        {
                depth = 0;
        }

        /***********************************************************************
                
                Return depth of the stack

        ***********************************************************************/

        uint size ()
        {
                return depth;
        }

        /***********************************************************************
                
                Returns a (shallow) clone of this stack, on the stack

        ***********************************************************************/

        Stack clone ()
        {       
                Stack s = void;
                s.stack[] = stack;
                s.depth = depth;
                return s;
        }

        /***********************************************************************
                
                Push and return a (shallow) copy of the topmost element

        ***********************************************************************/

        V dup ()
        {
                auto v = top;
                push (v);       
                return v;
        }

        /**********************************************************************

                Push a value onto the stack.

                Throws an exception when the stack is full

        **********************************************************************/

        void push (V value)
        {
                if (depth < stack.length)
                    stack[depth++] = value;
                else
                   error (__LINE__);
        }

        /**********************************************************************

                Push a series of values onto the stack.

                Throws an exception when the stack is full

        **********************************************************************/

        void pushMore (V[] value...)
        {
                foreach (v; value)
                         push (v);
        }

        /**********************************************************************

                Remove and return the most recent addition to the stack.

                Throws an exception when the stack is empty

        **********************************************************************/

        V pop ()
        {
                if (depth)
                    return stack[--depth];

                return error (__LINE__);
        }

        /**********************************************************************

                Return the most recent addition to the stack.

                Throws an exception when the stack is empty

        **********************************************************************/

        V top ()
        {
                if (depth)
                    return stack[depth-1];

                return error (__LINE__);
        }

        /**********************************************************************

                Swaps the top two entries, and return the top

                Throws an exception when the stack has insufficient entries

        **********************************************************************/

        V swap ()
        {
                auto p = stack.ptr + depth;
                if ((p -= 2) >= stack.ptr)
                   {
                   auto v = p[0];
                   p[0] = p[1];
                   return p[1] = v; 
                   }

                return error (__LINE__);                
        }

        /**********************************************************************

                Index stack entries, where a zero index represents the
                newest stack entry (the top).

                Throws an exception when the given index is out of range

        **********************************************************************/

        V nth (uint i)
        {
                if (i < depth)
                    return stack [depth-i-1];

                return error (__LINE__);
        }

        /**********************************************************************

                Rotate the given number of stack entries 

                Throws an exception when the number is out of range

        **********************************************************************/

        void rotateLeft (uint d)
        {
                if (d <= depth)
                   {
                   auto p = &stack[depth-d];
                   auto t = *p;
                   while (--d)
                          *p++ = *(p+1);
                   *p = t;
                   }
                else
                   error (__LINE__);
        }

        /**********************************************************************

                Rotate the given number of stack entries 

                Throws an exception when the number is out of range

        **********************************************************************/

        void rotateRight (uint d)
        {
                if (d <= depth)
                   {
                   auto p = &stack[depth-1];
                   auto t = *p;
                   while (--d)
                          *p-- = *(p-1);
                   *p = t;
                   }
                else
                   error (__LINE__);
        }

        /**********************************************************************

                Return the stack as an array of values, where the first
                array entry represents the oldest value. 
                
                Doing a foreach() on the returned array will traverse in
                the opposite direction of foreach() upon a stack
                 
        **********************************************************************/

        V[] slice ()
        {
                return stack [0 .. depth];
        }

        /**********************************************************************

                Throw an exception

        **********************************************************************/

        private V error (size_t line)
        {
                throw new ArrayBoundsException (__FILE__, line);
        }

        /***********************************************************************

                Iterate from the most recent to the oldest stack entries

        ***********************************************************************/

        int opApply (int delegate(ref V value) dg)
        {
                        int result;

                        for (int i=depth; i--;)
                            {
                            auto value = stack [i];
                            if ((result = dg(value)) != 0)
                                 break;
                            }
                        return result;
        }
}


/*******************************************************************************

*******************************************************************************/

debug (Stack)
{
        import tango.io.Stdout;

        void main()
        {
                Stack!(int, 10) s;

                Stdout.formatln ("push four");
                s.push (1);
                s.push (2);
                s.push (3);
                s.push (4);
                foreach (v; s)
                         Stdout.formatln ("{}", v);
                s <<= 4;
                s >>= 4;
                foreach (v; s)
                         Stdout.formatln ("{}", v);

                s = s.clone;
                Stdout.formatln ("pop one: {}", s.pop);
                foreach (v; s)
                         Stdout.formatln ("{}", v);
                Stdout.formatln ("top: {}", s.top);

                Stdout.formatln ("pop three");
                s.pop;
                s.pop;
                s.pop;
                foreach (v; s)
                         Stdout.formatln ("> {}", v);
        }
}
        
