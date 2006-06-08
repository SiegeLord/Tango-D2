/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: see doc/license.txt for details
      
        version:        Initial release: May 2004
        
        author:         Kris

*******************************************************************************/

module tango.log.FileAppender;

private import  tango.log.Appender;

version (Isolated)
{
private import std.stream;

/*******************************************************************************

        Append log messages to a file. This basic version has no rollover 
        support, so it just keeps on adding to the file. There's also a
        RollingFileAppender that may suit your needs.

*******************************************************************************/

public class FileAppender : Appender
{
        private static uint     mask;
        private File            file;

        /***********************************************************************
                
                Get a unique fingerprint for this class

        ***********************************************************************/

        static this()
        {
                mask = nextMask();
        }

        /***********************************************************************

        ***********************************************************************/

        protected this ()
        {
        }

        /***********************************************************************
                
                Create a basic FileAppender to a file with the specified 
                path.

        ***********************************************************************/

        this (char[] fp)
        {
                setFile (new File (fp, FileMode.OutNew));
        }

        /***********************************************************************
                
                Create a basic FileAppender to a file with the specified 
                path, and with the given Layout

        ***********************************************************************/

        this (char[] fp, Layout layout)
        {
                this (fp);
                setLayout (layout);
        }

        /***********************************************************************
                
                Return the file 

        ***********************************************************************/

        File getFile ()
        {
                return file;
        }

        /***********************************************************************
                
                Set the file

        ***********************************************************************/

        protected void setFile (File file)
        {
                this.file = file;
        }

        /***********************************************************************
                
                Return the fingerprint for this class

        ***********************************************************************/

        uint getMask ()
        {
                return mask;
        }

        /***********************************************************************
                
                Return the name of this class

        ***********************************************************************/

        char[] getName ()
        {
                return this.classinfo.name;
        }
                
        /***********************************************************************
                
                Append an event to the output.
                 
        ***********************************************************************/

        synchronized void append (Event event)
        {
                Layout layout = getLayout;
                file.writeString (layout.header  (event));
                file.writeString (layout.content (event));
                file.writeString (layout.footer  (event));
                file.writeLine (null);
                file.flush ();
        }

        /***********************************************************************
                
                Close the file associated with this Appender

        ***********************************************************************/

        synchronized void close ()
        {
                if (file)
                   {
                   file.close();
                   file = null;
                   }
        }
}
}

else

{
private import  tango.io.Buffer,
                tango.io.FileConst,
                tango.io.FileConduit;

private import  tango.io.model.IConduit;

/*******************************************************************************

        Append log messages to a file. This basic version has no rollover 
        support, so it just keeps on adding to the file. There's also a
        RollingFileAppender that may suit your needs.

*******************************************************************************/

public class FileAppender : Appender
{
        private static uint     mask;
        private Buffer          buffer;
        private IConduit        conduit;

        /***********************************************************************
                
                Get a unique fingerprint for this class

        ***********************************************************************/

        static this()
        {
                mask = nextMask();
        }

        /***********************************************************************

        ***********************************************************************/

        protected this ()
        {
        }

        /***********************************************************************
                
                Create a basic FileAppender to a file with the specified 
                path.

        ***********************************************************************/

        this (FilePath fp)
        {
                setConduit (new FileConduit (fp, FileStyle.WriteAppending));
        }

        /***********************************************************************
                
                Create a basic FileAppender to a file with the specified 
                path, and with the given Layout

        ***********************************************************************/

        this (FilePath fp, Layout layout)
        {
                this (fp);
                setLayout (layout);
        }

        /***********************************************************************
                
                Return the conduit

        ***********************************************************************/

        IConduit getConduit ()
        {
                return conduit;
        }

        /***********************************************************************
                
                Set the conduit

        ***********************************************************************/

        protected Buffer setConduit (IConduit conduit)
        {
                // create a new buffer upon this conduit
                this.conduit = conduit;
                return (buffer = new Buffer(conduit));
        }

        /***********************************************************************
                
                Return the fingerprint for this class

        ***********************************************************************/

        uint getMask ()
        {
                return mask;
        }

        /***********************************************************************
                
                Return the name of this class

        ***********************************************************************/

        char[] getName ()
        {
                return this.classinfo.name;
        }
                
        /***********************************************************************
                
                Append an event to the output.
                 
        ***********************************************************************/

        synchronized void append (Event event)
        {
                Layout layout = getLayout;
                buffer.append (layout.header  (event));
                buffer.append (layout.content (event));
                buffer.append (layout.footer  (event))
                      .append (FileConst.NewlineString)
                      .flush  ();
        }

        /***********************************************************************
                
                Close the file associated with this Appender

        ***********************************************************************/

        synchronized void close ()
        {
                if (conduit)
                   {
                   conduit.close();
                   conduit = null;
                   }
        }
}
}

