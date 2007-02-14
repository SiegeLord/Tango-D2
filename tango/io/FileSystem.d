/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: March 2004

        author:         Kris, Chris Sauls (Win95 file support)

*******************************************************************************/

module tango.io.FileSystem;

private import  tango.sys.Common;

private import  tango.io.FileConst;
private import  tango.io.FilePath;
private import  tango.io.FileProxy;

private import  tango.core.Exception;

private import  Text = tango.text.Util;

private import  tango.sys.Environment : getEnv;


version (Win32)
        {
        private import Utf = tango.text.convert.Utf;
        }
     else
        {
        private import tango.stdc.string;
        private import tango.stdc.posix.unistd;
        private import tango.stdc.posix.sys.stat;
        // private import tango.stdc.posix.utime;
        // private import tango.io.FileConduit;
        }


/*******************************************************************************

        Models an OS-specific file-system. Included here are methods to
        manipulate the current working directory.

*******************************************************************************/

class FileSystem
{
        /***********************************************************************

                Convert the provided path to an absolute path, using the
                current working directory. If the given path is already
                an absolute path, return it intact.

        ***********************************************************************/

        static FilePath absolutePath (FilePath path)
        {
                if (path.isAbsolute)
                    return path;

                return getDirectory.append (path);
        }

        /***********************************************************************

        ***********************************************************************/

        package static void exception (char[] msg)
        {
                throw new IOException (msg);
        }


        version (Win32)
        {
                /***************************************************************

                        Set the current working directory

                ***************************************************************/

                static void setDirectory (FilePath fp)
                {
                        version (Win32SansUnicode)
                                {
                                if (! SetCurrentDirectoryA (fp.cString.ptr))
                                       exception ("Failed to set current directory");
                                }
                             else
                                {
                                wchar[MAX_PATH+1] tmp = void;

                                if (! SetCurrentDirectoryW (Utf.toUtf16(fp.cString, tmp).ptr))
                                      exception ("Failed to set current directory");
                                }
                }

                /***************************************************************

                        Get the current working directory

                ***************************************************************/

                static FilePath getDirectory ()
                {
                        version (Win32SansUnicode)
                                {
                                int length = GetCurrentDirectoryA (0, null);
                                if (length)
                                   {
                                   auto dir = new char [length];
                                   GetCurrentDirectoryA (length, dir.ptr);
                                   return new FilePath (dir[0 .. $-1]);
                                   }
                                }
                             else
                                {
                                int length = GetCurrentDirectoryW (0, null);
                                if (length)
                                   {
                                   char[MAX_PATH] tmp = void;
                                   auto dir = new wchar [length];

                                   GetCurrentDirectoryW (length, dir.ptr);
                                   return new FilePath (Utf.toUtf8 (dir, tmp)[0 .. $-1]);
                                   }
                                }
                        exception ("Failed to get current directory");
                        return null;
                }
/+
                /***************************************************************

                        Copy file from src to dst

                ***************************************************************/

                static void copy(FilePath src, FilePath dst)
                {
                        version (Win32SansUnicode)
                                {
                                if (! CopyFileA(src.cString, dst.cString, false))
                                    exception ("Failed to copy file " ~ src.toUtf8 ~ " to " ~ dst.toUtf8); 
                                }
                            else
                                {
                                wchar[MAX_PATH+1] tmp1 = void;
                                wchar[MAX_PATH+1] tmp2 = void;

                                if (! CopyFileW (Utf.toUtf16(src.cString, tmp1).ptr, Utf.toUtf16(dst.cString, tmp2).ptr, false))
                                      exception ("Failed to copy file " ~ src.toUtf8 ~ " to " ~ dst.toUtf8);
                                }
                }
+/
        }


        version (Posix)
        {
                /***************************************************************

                        Set the current working directory

                ***************************************************************/

                static void setDirectory (FilePath fp)
                {
                        if (tango.stdc.posix.unistd.chdir (fp.cString.ptr))
                            exception ("Failed to set current directory");
                }

                /***************************************************************

                        Get the current working directory

                ***************************************************************/

                static FilePath getDirectory ()
                {
                        char[512] tmp = void;

                        char *s = tango.stdc.posix.unistd.getcwd (tmp.ptr, tmp.length);
                        if (s)
                            return new FilePath (s[0..strlen(s)]);

                        exception ("Failed to get current directory");
                }
/+
                /***************************************************************

                        Copy file from src to dst, preserving time attributes

                ***************************************************************/

                static void copy(FilePath src, FilePath dst)
                {
                        stat_t stats;

                        if (posix.stat (src.cString.ptr, &stats))
                            exception("Failed to copy file " ~ src.toUtf8 ~ " to " ~ dst.toUtf8);

                        (new FileConduit(dst, FileConduit.ReadWriteCreate)).copy (
                              new FileConduit(src));

                        utimbuf utim;
                        utim.actime = stats.st_atime;
                        utim.modtime = stats.st_mtime;
                        if (utime(dst.cString.ptr, &utim) == -1)
                            exception("Failed to update time of destination file " ~ dst.toUtf8);
                }
+/

        }
        
        /**
         * From args[0], figure out the binary's installed path.  Returns false on
         * failure
         */
        bool exePath (char[] argvz, inout FilePath binpath)
        {
            binpath = argvz;
            
            // on Windows, this is a .exe
            version (Windows) {
                if (binpath.getExt.length is 0)
                    binpath = binpath.append(".exe");
            }
            
            // is this a directory?
            if (binpath.isChild) {
                if (!binpath.isAbsolute) {
                    // make it absolute
                    binpath = FileSystem.absolutePath(binpath);
                }
                return true;
            }
            
            version (Windows) {
                // is it in cwd?
                FileProxy cwdpath = FileSystem.getDirectory.append (binpath);
                if (cwdpath.isExisting) {
                    binpath = cwdpath.getPath;
                    return true;
                }
            }
    
            // rifle through the path
            foreach (pe; Text.patterns (getEnv("PATH"), FileConst.SystemPathSeparatorString)) {
                FileProxy fp = binpath.asPath(pe);
                if (fp.isExisting) {
                    version (Windows) {
                        binpath = fp.getPath;
                        return true;
                    } else {
                        stat_t stats;
                        stat(fp.getPath.cString.ptr, &stats);
                        if (stats.st_mode & 0100) {
                            binpath = fp.getPath;
                            return true;
                        }
                    }
                }
            }
            
            // bad
            return false;
        }
}

