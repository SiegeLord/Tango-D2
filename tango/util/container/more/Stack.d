/*******************************************************************************

        copyright:      Copyright (c) 2008 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: April 2008      
        
        author:         Kris

*******************************************************************************/

module tango.util.container.more.Stack;

private import tango.core.Exception : ArrayBoundsException;

/******************************************************************************

        A stack of the given value-type V, with maximum depth Size

******************************************************************************/

struct Stack (V, int Size) 
{
        private V[Size]         stack;
        private uint            depth;

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
                
                Returns a (shallow) clone of this stack

        ***********************************************************************/

        Stack dup ()
        {       
                Stack s = void;
                s.stack[] = stack;
                s.depth = depth;
                return s;
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

                Push an array of values onto the stack.

                Throws an exception when the stack is full

        **********************************************************************/

        void push (V[] value)
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
                if (depth is 0)
                    error (__LINE__);
                return stack[--depth];
        }

        /**********************************************************************

                Swaps the top two entries, and return the top

                Throws an exception when the stack has insufficient entries

        **********************************************************************/

        V swap ()
        {
                if (depth < 2)
                    error (__LINE__);
                auto v = stack[depth-2];
                stack[depth-2] = stack[depth-1];
                stack[depth-1] = v;
                return v;
        }

        /**********************************************************************

                Return the most recent addition to the stack.

                Throws an exception when the stack is empty

        **********************************************************************/

        V top ()
        {
                if (depth is 0)
                    error (__LINE__);
                return stack[depth-1];
        }

        /**********************************************************************

                Index stack entries.

                Throws an exception when the given index is out of range

        **********************************************************************/

        V opIndex (int i)
        {
                if (i >= depth)
                    error (__LINE__);
                return stack[i];
        }

        /**********************************************************************

                Return the stack as an array of values, where the first
                array entry represents the oldest value. 
                
                Doing a foreach() on the returned array will traverse in
                the opposite direction of foreach() upon a stack
                 
        **********************************************************************/

        V[] opSlice ()
        {
                return stack [0 .. depth];
        }

        /**********************************************************************

                Throw an exception

        **********************************************************************/

        private void error (size_t line)
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

                s = s.dup;
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
        
