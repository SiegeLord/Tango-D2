/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: December 2005      
        
        author:         Kris

*******************************************************************************/

module tango.net.http.HttpTriplet;

/******************************************************************************

        Class to represent an HTTP response- or request-line 

******************************************************************************/

class HttpTriplet 
{
        protected char[]        line;
        protected char[]        failed;
        protected char[][3]     tokens;

        /**********************************************************************

                test the validity of these tokens

        **********************************************************************/

        abstract bool test ();

        /**********************************************************************

                Parse the the given line into its constituent components.

        **********************************************************************/

        bool parse (char[] line)
        {
                int i;
                int mark;

                this.line = line;
                foreach (int index, char c; line)
                         if (c is ' ')
                             if (i < 2)
                                {
                                tokens[i] = line[mark .. index];
                                mark = index+1;
                                ++i;
                                }
                             else
                                break;

                tokens[2] = line [mark .. line.length];
                return test;
        }

        /**********************************************************************

                return a reference to the original string

        **********************************************************************/

        override immutable(char[]) toString()
        {
                return line.idup;
        }

        /**********************************************************************

                return error string after a failed parse()

        **********************************************************************/

        final char[] error ()
        {
                return failed;
        }
}


