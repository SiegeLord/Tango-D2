/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: see doc/license.txt for details

        version:        Initial release: March 2004      
        
        author:         Kris

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
