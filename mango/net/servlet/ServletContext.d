/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module mango.net.servlet.ServletContext;

private import  tango.util.log.Log;

private import  tango.text.Text;

private import  tango.io.FileConduit;
              
private import  mango.net.servlet.Dictionary,
                mango.net.servlet.ServletException;

public  import  mango.net.servlet.model.IServletContext;

/******************************************************************************

        Provided equivalent functionality of the Java class by the same 
        name.

******************************************************************************/

class ServletContext : IServletContext
{
        private char[]                  name,
                                        basePath;
        private Logger                  logger;
        private MutableDictionary       attributes,
                                        configuration;

        private static ServletException irp;

        private static MutableDictionary mimeMap;

        private static const char[]     ServerIdentity = "mango.Servlet/Beta 9";
        

        // content to build contentType map for file extensions
        private struct MimeMap
        {
                char[]  ext,
                        mime;
        }

        // a set of file extension and their mime types 
        private static const MimeMap list[] = 
        [
        {".a",           "application/octet-stream"}, 
        {".ai",          "application/postscript"}, 
        {".aif",         "audio/x-aiff"}, 
        {".aifc",        "audio/x-aiff"}, 
        {".aiff",        "audio/x-aiff"}, 
        {".arc",         "application/octet-stream"}, 
        {".au",          "audio/basic"}, 
        {".avi",         "application/x-troff-msvideo"}, 
        {".bcpio",       "application/x-bcpio"}, 
        {".bin",         "application/octet-stream"}, 
        {".bmp",         "image/bmp"}, 
        {".c",           "text/plain"}, 
        {".c++",         "text/plain"}, 
        {".cc",          "text/plain"}, 
        {".cdf",         "application/x-netcdf"}, 
        {".cpio",        "application/x-cpio"}, 
        {".d",           "text/plain"}, 
        {".djv",         "image/x-djvu"}, 
        {".djvu",        "image/x-djvu"}, 
        {".dump",        "application/octet-stream"}, 
        {".dvi",         "application/x-dvi"}, 
        {".eps",         "application/postscript"}, 
        {".etx",         "text/x-setext"}, 
        {".exe",         "application/octet-stream"}, 
        {".gif",         "image/gif"}, 
        {".gtar",        "application/x-gtar"}, 
        {".gz",          "application/octet-stream"}, 
        {".h",           "text/plain"}, 
        {".hdf",         "application/x-hdf"}, 
        {".hqx",         "application/octet-stream"}, 
        {".htm",         "text/html"}, 
        {".html",        "text/html"}, 
        {".iw4",         "image/x-iw44"}, 
        {".iw44",        "image/x-iw44"}, 
        {".ief",         "image/ief"}, 
        {".java",        "text/plain"}, 
        {".jfif",        "image/jpeg"}, 
        {".jfif-tbnl",   "image/jpeg"}, 
        {".jpe",         "image/jpeg"}, 
        {".jpeg",        "image/jpeg"}, 
        {".jpg",         "image/jpeg"}, 
        {".latex",       "application/x-latex"}, 
        {".man",         "application/x-troff-man"}, 
        {".me",          "application/x-troff-me"}, 
        {".mime",        "message/rfc822"}, 
        {".mov",         "video/quicktime"}, 
        {".movie",       "video/x-sgi-movie"}, 
        {".mpe",         "video/mpeg"}, 
        {".mpeg",        "video/mpeg"}, 
        {".mpg",         "video/mpeg"}, 
        {".ms",          "application/x-troff-ms"}, 
        {".mv",          "video/x-sgi-movie"}, 
        {".nc",          "application/x-netcdf"}, 
        {".o",           "application/octet-stream"}, 
        {".oda",         "application/oda"}, 
        {".pbm",         "image/x-portable-bitmap"}, 
        {".pdf",         "application/pdf"}, 
        {".pgm",         "image/x-portable-graymap"}, 
        {".pl",          "text/plain"}, 
        {".png",         "image/png"}, 
        {".pnm",         "image/x-portable-anymap"}, 
        {".ppm",         "image/x-portable-pixmap"}, 
        {".ps",          "application/postscript"}, 
        {".qt",          "video/quicktime"}, 
        {".ras",         "image/x-cmu-rast"}, 
        {".rgb",         "image/x-rgb"}, 
        {".roff",        "application/x-troff"}, 
        {".rtf",         "application/rtf"}, 
        {".rtx",         "application/rtf"}, 
        {".saveme",      "application/octet-stream"}, 
        {".sh",          "application/x-shar"}, 
        {".shar",        "application/x-shar"}, 
        {".snd",         "audio/basic"}, 
        {".src",         "application/x-wais-source"}, 
        {".sv4cpio",     "application/x-sv4cpio"}, 
        {".sv4crc",      "application/x-sv4crc"}, 
        {".t",           "application/x-troff"}, 
        {".tar",         "application/x-tar"}, 
        {".tex",         "application/x-tex"}, 
        {".texi",        "application/x-texinfo"}, 
        {".texinfo",     "application/x-texinfo"}, 
        {".text",        "text/plain"}, 
        {".tif",         "image/tiff"}, 
        {".tiff",        "image/tiff"}, 
        {".tr",          "application/x-troff"}, 
        {".tsv",         "text/tab-separated-values"}, 
        {".txt",         "text/plain"}, 
        {".ustar",       "application/x-ustar"}, 
        {".uu",          "application/octet-stream"}, 
        {".wav",         "audio/x-wav"}, 
        {".wsrc",        "application/x-wais-source"}, 
        {".xbm",         "image/x-xbitmap"}, 
        {".xpm",         "image/x-xpixmap"}, 
        {".xwd",         "image/x-xwindowdump"}, 
        {".z",           "application/octet-stream"}, 
        {".zip",         "application/zip"}, 
        ];

        /***********************************************************************
        
                Initialize the mime-map and the servlet logging instance

        ***********************************************************************/

        static this ()
        {
                irp = new ServletException ("Invalid resource path");
                
                mimeMap = new MutableDictionary;

                // load up the content-types
                foreach (MimeMap mm; list)
                         mimeMap.put (mm.ext, mm.mime);
                mimeMap.optimize();
        }

        /***********************************************************************
        
                Construct a context with the given name, and a base-path
                of the current working directory.

        ***********************************************************************/

        this (char[] name, Logger log = null)
        {
                this (name, ".");
        }

        /***********************************************************************
        
                Construct a context with the given name, and the specified 
                base-path. The latter is where files and properties will be
                located from.

        ***********************************************************************/

        this (char[] name, char[] basePath, Logger log = null)
        in {
           assert (name !is null);
           assert (basePath !is null);
           }
        body
        {
                this.name = name;
                this.basePath = FilePath.asPadded(basePath);

                // each context may have its own logger. This skirts around 
                // the current (Feb, 2005) lack of static-ctor ordering in D
                if (! log)
                      log = Log.getLogger ("mango.net.servlet.ServletContext");
                this.logger = log;

                if (name.length > 0)
                    if (name[0] != '/' || name[$-1] == '/')
                        throw new ServletException ("Invalid context specification");

                attributes = new MutableDictionary;
                configuration = new MutableDictionary;
        }
    
        /***********************************************************************
        
                Return the name of this context.

        ***********************************************************************/

        char[] getName ()
        {
                return name;
        }
    
        /***********************************************************************
        
                Return the attributes of this context

        ***********************************************************************/

        synchronized Dictionary getAttributes ()
        {
                return attributes;
        }
    
        /***********************************************************************
        
                Return the current configuration of this context

        ***********************************************************************/

        synchronized Dictionary getConfiguration ()
        {
                return configuration;
        }
    
        /***********************************************************************
        
                Swizzle the attributes of this context. This is not to
                be exposed publicly.

        ***********************************************************************/

        protected synchronized ServletContext setAttributes (MutableDictionary other)
        {
                attributes = other;
                return this;
        }
    
        /***********************************************************************
        
                Swizzle the configuration of this context. This is not to
                be exposed publicly.

        ***********************************************************************/

        protected synchronized ServletContext setConfiguration (MutableDictionary other)
        {
                configuration = other;
                return this;
        }
    
        /***********************************************************************
        
                Return the major version number.

        ***********************************************************************/

        int getMajorVersion ()
        {
                return 1;
        }
    
        /***********************************************************************
        
                Return the minor number.

        ***********************************************************************/

        int getMinorVersion ()
        {
                return 0;
        }

        /***********************************************************************
        
                Return the mime type for a given file extension. Returns
                null if the extension is not known.

        ***********************************************************************/

        char[] getMimeType (char[] ext)
        {
                return mimeMap.get (ext);
        }

        /***********************************************************************
        
                Return a FileConduit for the given path. The file is located
                via the base-path. 

                Throws an IOException if the path is invalid, or there's a
                problem of some kind with the file.

        ***********************************************************************/

        FileConduit getResourceAsFile (char[] path)
        {
                return new FileConduit (getResourceAsPath(path));
        }

        /***********************************************************************
        
                Return a FileConduit for the given path. The file is located
                via the base-path. 

                Throws an IOException if the path is invalid, or there's a
                problem of some kind with the file.

        ***********************************************************************/

        char[] getResourceAsPath (char[] path)
        {
                checkPath (path);
                return basePath ~ path;
        }

        /***********************************************************************
        
                Send an informational message to the logger subsystem

        ***********************************************************************/

        IServletContext log (char[] msg)
        {
                logger.info (msg);
                return this;
        }

        /***********************************************************************
        
                Send a error message to the logger subsystem

        ***********************************************************************/

        IServletContext log (char[] msg, Object error)
        {
                logger.error (msg ~ error.toUtf8());
                return this;
        }

        /***********************************************************************
        
                Return the identity of this server

        ***********************************************************************/

        char[] getServerInfo ()
        {
                return ServerIdentity;
        }

        /***********************************************************************
        
                Check the given path to see if it tries to subvert the
                base-path notion. Throws an IOException if anything dodgy
                is noted.

        ***********************************************************************/

        IServletContext checkPath (char[] path)
        {
                if (path.length == 0)
                    throw irp;

                char c = path [path.length-1];
                if (Text.indexOf (path, "..") >= 0 || 
                    c == '/'                       ||
                    c == '\\'                      ||
                    c == '.')
                    throw irp;

                return this;
        }
}
