/*******************************************************************************

        @file HttpTriplet.d
        
        Copyright (c) 2004 Kris Bell
        
        This software is provided 'as-is', without any express or implied
        warranty. In no event will the authors be held liable for damages
        of any kind arising from the use of this software.
        
        Permission is hereby granted to anyone to use this software for any 
        purpose, including commercial applications, and to alter it and/or 
        redistribute it freely, subject to the following restrictions:
        
        1. The origin of this software must not be misrepresented; you must 
           not claim that you wrote the original software. If you use this 
           software in a product, an acknowledgment within documentation of 
           said product would be appreciated but is not required.

        2. Altered source versions must be plainly marked as such, and must 
           not be misrepresented as being the original software.

        3. This notice may not be removed or altered from any distribution
           of the source.

        4. Derivative works are permitted, but they must carry this notice
           in full and credit the original source.


                        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        
        @version        Initial version, December 2005      

        @author         Kris


*******************************************************************************/

module tango.net.http.HttpTriplet;

private import  tango.io.Exception;

private import  tango.io.protocol.model.IWriter;

/******************************************************************************

        Class to represent an HTTP response- or request-line 

******************************************************************************/

class HttpTriplet : IWritable
{
        protected char[]        line;
        protected char[][3]     tokens;

        /**********************************************************************

                test the validity of these tokens

        **********************************************************************/

        abstract void test ();

        /**********************************************************************

                Parse the the given line into its constituent components.

        **********************************************************************/

        void parse (char[] line)
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

                test ();
        }

        /**********************************************************************

                return a reference to the original string

        **********************************************************************/

        override char[] toString ()
        {
                return line;
        }

        /**********************************************************************

                Output the string via the given writer

        **********************************************************************/

        void write (IWriter writer)
        {
               writer(toString).cr();
        }

        /**********************************************************************

                throw an exception

        **********************************************************************/

        final void error (char[] msg)
        {
                throw new IOException (msg);
        }
}


