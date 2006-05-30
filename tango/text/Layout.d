/*******************************************************************************

        @file Layout.d
        
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


        @version        Initial version, March 2004      
        @author         Kris
                        Anders F Bjorklund (Darwin patches)


*******************************************************************************/

module tango.text.Layout;

/*******************************************************************************

        Arranges text strings in order, using indices to specify where
        each particular argument should be positioned within the text. 
        This is handy for collating I18N components.

        @code
        // write ordered text to Stdout
        char[64] dst;

        Stdout (TextLayout (dst, "%2 %1", "one", "two"));
        @endcode

        The index numbers range from one through nine. TextLayout defaults
        to char[], but you can instantiate the template for any other type.
        
*******************************************************************************/

struct TextLayoutT(T)
{       
        /**********************************************************************
              
        **********************************************************************/

        static T[] opCall (T[] output, T[][] layout ...)
        {
                int     pos,
                        args;
                bool    state;

                args = layout.length - 1;
                foreach (T c; layout[0])
                        {
                        if (state)
                           {
                           state = false;
                           if (c >= '1' || c <= '9')
                              {
                              uint index = c - '0';
                              if (index <= args)
                                 {
                                 T[] x = layout[index];

                                 int limit = pos + x.length;
                                 if (limit < output.length)
                                    {
                                    output[pos..limit] = x;
                                    pos = limit;
                                    continue;
                                    } 
                                 else
                                    error ("TextLayout : output buffer too small");
                                 }
                              else
                                 error ("TextLayout : invalid argument");
                              }
                           }
                        else
                           if (c == '%')
                              {
                              state = true;
                              continue;
                              }
                
                        if (pos < output.length)
                           {
                           output[pos] = c;
                           ++pos;
                           }
                        else     
                           error ("TextLayout : output buffer too small");
                        }

                return output [0..pos];
        }

        /**********************************************************************
              
        **********************************************************************/

        private static void error (char[] msg)
        {
                throw new Exception (msg);
        }
}


alias TextLayoutT!(char) TextLayout;

