/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: March 2004      
        
        author:         Kris
                        Anders F Bjorklund (Darwin patches)

*******************************************************************************/

module tango.text.Layout;

/*******************************************************************************

        Arranges text strings in order, using indices to specify where
        each particular argument should be positioned within the text. 
        This is handy for collating I18N components.

        ---
        // write ordered text to Stdout
        char[64] dst;

        Stdout (TextLayout (dst, "%2 %1", "one", "two"));
        ---

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

