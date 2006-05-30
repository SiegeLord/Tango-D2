/*******************************************************************************

        @file ConduitStyle.d
        
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


*******************************************************************************/

module tango.io.ConduitStyle;

pragma (msg, "ConduitStyle module deprecated -- please remove the import. Related constants are now in IConduit");


/+
/*******************************************************************************

        Defines how a Conduit should be opened. This is typically subsumed
        by a subclass.        

*******************************************************************************/

class ConduitStyle
{
        /***********************************************************************
        
                Declare the basic styles for a Conduit

        ***********************************************************************/
        
        enum Access             {
                                Read      = 0x01,
                                Write     = 0x02,
                                ReadWrite = 0x03,
                                };

        private Access          m_access;
        
        /***********************************************************************
        
                Expose common instances of ConduitStyle

        ***********************************************************************/

        static ConduitStyle     Read,
                                Write,
                                ReadWrite;

        /***********************************************************************
        
                Setup common instances of ConduitStyle

        ***********************************************************************/

        static this ()
        {
                Read      = new ConduitStyle (Access.Read);
                Write     = new ConduitStyle (Access.Write);
                ReadWrite = new ConduitStyle (Access.ReadWrite);
        }
      
        /***********************************************************************
        
                Construct a ConduitStyle with the given access

        ***********************************************************************/

        this (Access access)
        {
                m_access = access;
        }

        /***********************************************************************
        
                Return the access attribute of this ConduitStyle

        ***********************************************************************/

        Access access()
        {
                return m_access;
        }
}
+/
