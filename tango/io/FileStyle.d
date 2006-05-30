/*******************************************************************************

        @file FileStyle.d
        
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

module tango.io.FileStyle;

pragma (msg, "FileStyle module deprecated -- please remove the import. Related constants are now in FileConduit");

/+
private import  tango.io.ConduitStyle;

/*******************************************************************************

        Defines how a file should be opened. You can use the predefined 
        instances, or create specializations for your own needs.

*******************************************************************************/

class FileStyle : ConduitStyle
{
        /***********************************************************************
        
                Instantiate some common styles

        ***********************************************************************/

        static FileStyle        ReadExisting,
                                WriteTruncate,
                                WriteAppending,
                                ReadWriteCreate,
                                ReadWriteExisting;

        /***********************************************************************
        
        ***********************************************************************/

        enum Open               {
                                Exists=0,               // must exist
                                Create,                 // create always
                                Truncate,               // must exist
                                Append,                 // create if necessary
                                };

        /***********************************************************************
        
        ***********************************************************************/

        enum Share              {
                                Read=0,                 // shared reading
                                Write,                  // shared writing
                                ReadWrite,              // both
                                };

        /***********************************************************************
        
        ***********************************************************************/

        enum Cache              {
                                None      = 0x00,       // don't optimize
                                Random    = 0x01,       // optimize for random
                                Stream    = 0x02,       // optimize for stream
                                WriteThru = 0x04,       // backing-cache flag
                                };

        /***********************************************************************
        
        ***********************************************************************/

        private Open            m_open;
        private Share           m_share;
        private Cache           m_cache;
        
        /***********************************************************************
        
                Construct a set of typical FileStyle instances.

        ***********************************************************************/

        static this ()
        {
                ReadExisting = new FileStyle (Access.Read, Open.Exists);
                WriteTruncate = new FileStyle (Access.Write, Open.Truncate);
                WriteAppending = new FileStyle (Access.Write, Open.Append);
                ReadWriteCreate = new FileStyle (Access.ReadWrite, Open.Create); 
                ReadWriteExisting = new FileStyle (Access.ReadWrite, Open.Exists); 
        }
      
        /***********************************************************************
        
                Construct a FileStyle with the given properties. Defaults 
                are set to indicate the file should exist, will be opened
                for read-only sharing, and should not be cache optimized 
                in any special manner by the OS.

        ***********************************************************************/

        this (Access access, 
              Open  open  = Open.Exists, 
              Share share = Share.Read, 
              Cache cache = Cache.None)
        {
                super(access);
                m_open = open;
                m_share = share;
                m_cache = cache;
        }

        /***********************************************************************
                
                Return the style of opening

        ***********************************************************************/

        Open open()
        {
                return m_open;
        }

        /***********************************************************************
        
                Return the style of sharing

        ***********************************************************************/

        Share share()
        {
                return m_share;
        }

        /***********************************************************************
        
                Return the style of caching

        ***********************************************************************/

        Cache cache()
        {
                return m_cache;
        }
}
+/