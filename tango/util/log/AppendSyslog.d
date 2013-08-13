/*******************************************************************************

 copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

 license:        BSD style: $(LICENSE)
 
 version:        Initial release: May 2004
 
 author:         Kris & Marenz

 *******************************************************************************/

module tango.util.log.AppendSyslog;

private import tango.time.Time;

private import Path = tango.io.Path, tango.io.device.File, tango.io.FilePath;

private import tango.io.model.IFile;

private import tango.util.log.Log, tango.util.log.AppendFile;

private import Integer = tango.text.convert.Integer;

private import tango.text.convert.Format;

private import tango.util.MinMax;

private import tango.sys.Process;

/*******************************************************************************

 Append log messages to a file set 

 *******************************************************************************/

public class AppendSyslog: Filer
{
    private Mask mask_;
    private long max_size, file_size, max_files, compress_index;
    
    private FilePath file_path;
    private char[] path;
    private char[] compress_suffix;
    private Process compress_cmd;
    
    /***********************************************************************
     
     Create an AppendSyslog upon a file-set with the specified 
     path and optional layout. The minimal file count is two 
     and the maximum is 1000 (explicitly 999). 
     The minimal compress_begin index is 2.
     

        Params:
            path            = path to the first logfile
            count           = maximum number of logfiles
            max_size        = maximum size of a logfile in bytes
            compress_cmd    = command to use to compress logfiles
            compress_suffix = suffix for compressed logfiles
            compress_begin  = index after which logfiles should be compressed
            how             = which layout to use 

     ***********************************************************************/

    this ( char[] path, uint count, long max_size, 
           char[] compress_cmd = null, char[] compress_suffix = null,
           size_t compress_begin = 2, Appender.Layout how = null )
    {
        assert (path);
        assert (count < 1000);
        assert (compress_begin >= 2);
        
        // Get a unique fingerprint for this instance
        mask_ = register(path);

        auto style = File.WriteAppending;
        style.share = File.Share.Read;
        auto conduit = new File(path, style);

        configure(conduit);
        
        // remember the maximum size 
        this.max_size  = max_size;
        // and the current size
        this.file_size = conduit.length;
        this.max_files = count;
        
        // set provided layout (ignored when null)
        layout(how);
        
        this.file_path = new FilePath(path);
        this.file_path.pop();
        
        this.path = path.dup;
        // "gzip {}"   this.path.{}
        
        char[512] buf, buf1;
        
        auto compr_path = Format.sprint(buf, "{}.{}", this.path, compress_begin);
        
        auto cmd = Format.sprint(buf1, compress_cmd, compr_path);
            
        this.compress_cmd    = new Process(cmd.dup);
        this.compress_suffix = "." ~ compress_suffix;
        this.compress_index  = compress_begin;
    }

    /***********************************************************************
     
     Return the fingerprint for this class

     ***********************************************************************/

    @property override final Mask mask ( ) const
    {
        return mask_;
    }

    /***********************************************************************
     
     Return the name of this class

     ***********************************************************************/

    @property override final const(char)[] name ( ) const
    {
        return this.classinfo.name;
    }

    /***********************************************************************
     
     Append an event to the output
     
     ***********************************************************************/

    override final void append ( LogEvent event )
    {
        synchronized(this)
        {
            char[] msg;

            // file already full?
            if (file_size >= max_size) nextFile();

            size_t write ( const(void)[] content )
            {
                file_size += content.length;
                return buffer.write(content);
            }

            // write log message and flush it
            layout.format(event, &write);
            write(tango.io.model.IFile.FileConst.NewlineString);
            buffer.flush();
        }
    }

    private void openConduit ()
    {
        this.file_size = 0;          
        // make it shareable for read
        auto style = File.WriteAppending;
        style.share = File.Share.Read;
        (cast(File) this.conduit).open(this.path, style);
        //this.buffer.output(this.conduit);
    }
    
    /***********************************************************************
     
     Switch to the next file within the set

     ***********************************************************************/
    
    private void nextFile ( )
    {
        size_t free, used;       

        long oldest = 1;
        char[512] buf;
        
        buf[0 .. this.path.length] = this.path[];
        buf[this.path.length]  = '.';
        
        // release currently opened file
        this.conduit.detach();
        
        foreach ( ref file; this.file_path )
        {
            auto pathlen = file.path.length;
            
            if ( file.name.length > this.path.length + 1 - pathlen &&
                 file.name[0 .. this.path.length - pathlen] == this.path[pathlen .. $] )
            {
                size_t ate = 0;
                auto num = Integer.parse(file.name[this.path.length - pathlen + 1 .. $], 0, &ate);
                
                if ( ate != 0 )
                {        
                    oldest = max!(long)(oldest, num);
                }
            }
        }
                
        for ( long i = oldest; i > 0; --i )
        {
            const(char)[] compress = i >= this.compress_index ? 
                                     this.compress_suffix : "";
            
            auto path = Format.sprint(buf, "{}.{}{}", this.path, i,
                                      compress);
            
            this.file_path.set(path, true);
            
            if ( this.file_path.exists() )
            {
                if ( i + 1 < this.max_files)
                {                    
                    path = Format.sprint(buf, "{}.{}{}\0", this.path, i+1,
                                         compress);
                    
                    this.file_path.rename(path);
                    
                    if ( i + 1 == this.compress_index ) with (this.compress_cmd) 
                    {
                        if ( isRunning() )
                        {
                            wait();
                            close();
                        }       
                        
                        execute();
                    }                    
                }
                else this.file_path.remove();
            }            
        }
        
        this.file_path.set(this.path);
               
        if ( this.file_path.exists() )
        {
            auto path = Format.sprint(buf, "{}.{}\0", this.path, 1);
                
            this.file_path.rename(path);
        }
            
        this.openConduit ();
                
        this.file_path.set(this.path);                
        this.file_path.pop();
    }
}

/*******************************************************************************

 *******************************************************************************/

debug (AppendSyslog)
{
    void main ( )
    {
        Log.root.add(new AppendFiles("foo", 5, 6));
        auto log = Log.lookup("fu.bar");
        log.trace("hello {}", "world");
        log.trace("hello {}", "world");
        log.trace("hello {}", "world");
        log.trace("hello {}", "world");
        log.trace("hello {}", "world");
        log.trace("hello {}", "world");
        log.trace("hello {}", "world");
        log.trace("hello {}", "world");
        log.trace("hello {}", "world");
        log.trace("hello {}", "world");
        log.trace("hello {}", "world");
        log.trace("hello {}", "world");
        log.trace("hello {}", "world");
        log.trace("hello {}", "world");
        log.trace("hello {}", "world");
        log.trace("hello {}", "world");

    }
}
