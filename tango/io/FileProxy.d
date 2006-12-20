/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
                        
        version:        Initial release: March 2004      
        
        author:         $(UL Kris)
                        $(UL Brad Anderson)
                        $(UL teqdruid)
                        $(UL Anders (Darwin support))
                        $(UL Chris Sauls (Win95 file support))

*******************************************************************************/

module tango.io.FileProxy;

private import  tango.sys.Common;

public  import  tango.io.FilePath;

private import  tango.io.Exception;

private import  tango.text.convert.Utf;


/*******************************************************************************

*******************************************************************************/

version (Win32)
        {
        extern (Windows) BOOL   MoveFileExA (LPCSTR,LPCSTR,DWORD);
        extern (Windows) BOOL   MoveFileExW (LPCWSTR,LPCWSTR,DWORD);

        private const DWORD     REPLACE_EXISTING   = 1,
                                COPY_ALLOWED       = 2,
                                DELAY_UNTIL_REBOOT = 4,
                                WRITE_THROUGH      = 8;

        version (Win32SansUnicode)
                {
                private extern (C) int strlen (char *s);
                private alias WIN32_FIND_DATA FIND_DATA;
                }
             else
                {
                private extern (C) int wcslen (wchar *s);
                private alias WIN32_FIND_DATAW FIND_DATA;
                }
        }


version (Posix)
        {
        private import tango.stdc.stdio;
        private import tango.stdc.string;
        private import tango.stdc.posix.dirent;

        version (darwin)
                {
                // missing from tango.stdc.darwin.darwin in GDC 0.9 :

                alias long off_t;

                extern (C)
                       {
                       struct  dirent
                               {
                               int      d_ino;
                               off_t    d_off;
                               ushort   d_reclen;
                               ubyte    d_type;
                               char[256] d_name;
                               }

                       struct DIR
                             {
                             // Managed by OS.
                             }

                       DIR* opendir(char* name);
                       int closedir(DIR* dir);
                       dirent* readdir(DIR* dir);
                       void rewinddir(DIR* dir);
                       off_t telldir(DIR* dir);
                       void seekdir(DIR* dir, off_t offset);
                       }
                }
        }


/*******************************************************************************

        Models a generic file. Use this to manipulate files and directories
        in conjunction with FilePath, FileSystem and FileConduit. 

        Compile with -version=Win32SansUnicode to enable Win95 & Win32s file
        support.
        
*******************************************************************************/

class FileProxy
{
        private FilePath path;
        private wchar[]  name16;

        private alias tango.text.convert.Utf Utf;

        /***********************************************************************
        
                Construct a FileProxy from the provided FilePath

        ***********************************************************************/
                                  
        this (FilePath path)
        {
                this.path = path;
                name16 = Utf.toUtf16 (path.cString);
        }

        /***********************************************************************
        
                Construct a FileProxy from a text string

        ***********************************************************************/

        this (char[] path)
        {
                this (new FilePath (path));
        }

        /***********************************************************************
        
                Return the FilePath associated with this FileProxy

        ***********************************************************************/

        FilePath getPath ()
        {
                return path;
        }               

        /***********************************************************************
        
                Return the name of the associated path

        ***********************************************************************/

        char[] toUtf8 ()
        {
                return path.toUtf8;
        }               

        /***********************************************************************
        
                Does this path currently exist?

        ***********************************************************************/

        bool isExisting ()               
        {
                try {
                    getSize();
                    return true;
                    } catch (IOException){}
                return false;
        }            

        /***********************************************************************
        
                List the files contained within the associated path:

                ---
                auto proxy = new FileProxy (".");

                foreach (path; proxy.toList)
                         Stdout (path).newline;
                ---

        ***********************************************************************/

        FilePath[] toList ()
        {

                return toList (delegate bool(FilePath fp) {return true;});
        }              

        /***********************************************************************

        ***********************************************************************/

        version (Win32)
        {
                /***************************************************************

                        Throw an exception using the last known error

                ***************************************************************/

                private void exception ()
                {
                        throw new IOException (path.toUtf8 ~ ": " ~ SysError.lastMsg);
                }

                /***************************************************************

                        Get info about this path

                ***************************************************************/

                private uint getInfo (void delegate (inout FIND_DATA info) dg)
                {
                        FIND_DATA info;

                        version (Win32SansUnicode)
                                 HANDLE h = FindFirstFileA (path.cString, &info);
                             else
                                HANDLE h = FindFirstFileW (name16.ptr, &info);

                        if (h == INVALID_HANDLE_VALUE)
                            exception ();

                        if (dg)
                            dg (info);
                        FindClose (h);

                        return info.dwFileAttributes;
                }

                /***************************************************************
                        
                        Return the file length (in bytes)

                ***************************************************************/

                ulong getSize ()
                {
                        ulong _size;

                        void size (inout FIND_DATA info)
                        {
                                _size = (cast(ulong) info.nFileSizeHigh << 32) + 
                                                     info.nFileSizeLow;
                        }

                        getInfo (&size);
                        return _size;
                }

                /***************************************************************

                        Is this file writable?

                ***************************************************************/

                bool isWritable ()               
                {
                        return cast (bool) ((getInfo(null) & FILE_ATTRIBUTE_READONLY) == 0);
                }            

                /***************************************************************

                        Is this file really a directory?

                ***************************************************************/

                bool isDirectory ()               
                {
                        return cast(bool) ((getInfo(null) & FILE_ATTRIBUTE_DIRECTORY) != 0);
                }            

                /***************************************************************

                        Return the time when the file was last modified

                ***************************************************************/

                ulong getModifiedTime ()
                {
                        ulong _time;

                        void time (inout FIND_DATA info)
                        {
                                _time = (cast(ulong) info.ftLastWriteTime.dwHighDateTime << 32) + 
                                                     info.ftLastWriteTime.dwLowDateTime;
                        }

                        getInfo (&time);
                        return _time;
                }               

                /***************************************************************

                        Return the time when the file was last accessed

                ***************************************************************/

                ulong getAccessedTime ()
                {
                        ulong _time;

                        void time (inout FIND_DATA info)
                        {
                                _time = (cast(ulong) info.ftLastAccessTime.dwHighDateTime << 32) + 
                                                     info.ftLastAccessTime.dwLowDateTime;
                        }

                        getInfo (&time);
                        return _time;
                }               

                /***************************************************************

                        Return the time when the file was created

                ***************************************************************/

                ulong getCreatedTime ()
                {
                        ulong _time;

                        void time (inout FIND_DATA info)
                        {
                                _time = (cast(ulong) info.ftCreationTime.dwHighDateTime << 32) + 
                                                     info.ftCreationTime.dwLowDateTime;
                        }

                        getInfo (&time);
                        return _time;
                }               

                /***************************************************************

                        Remove the file/directory from the file-system

                ***************************************************************/

                FileProxy remove ()
                {
                        if (isDirectory ())
                           {
                           version (Win32SansUnicode)
                                   {
                                   if (! RemoveDirectoryA (path.cString))
                                         exception();
                                   }
                                else
                                   {
                                   if (! RemoveDirectoryW (name16.ptr))
                                         exception();
                                   }
                           }
                        else
                           version (Win32SansUnicode)
                                   {
                                   if (! DeleteFileA (path.cString))
                                         exception();
                                   }
                                else
                                   {
                                   if (! DeleteFileW (name16.ptr))
                                         exception();
                                   }

                        return this;
                }           

                /***************************************************************

                       change the name or location of a file/directory, and
                       adopt the provided FilePath

                ***************************************************************/

                FileProxy rename (FilePath dst)
                {
                        const int Typical = REPLACE_EXISTING + COPY_ALLOWED + 
                                                               WRITE_THROUGH;

                        int result;

                        version (Win32SansUnicode)
                                 result = MoveFileExA (path.cString, dst.cString, Typical);
                             else
                                result = MoveFileExW (name16.ptr, Utf.toUtf16(dst.cString).ptr, Typical);

                        if (! result)
                              exception();

                        path = dst;
                        return this;
                }

                /***************************************************************

                        Create a new file 

                ***************************************************************/

                FileProxy createFile ()
                {
                        HANDLE h;

                        version (Win32SansUnicode)
                                 h = CreateFileA (path.cString, GENERIC_WRITE, 
                                                  0, null, CREATE_ALWAYS, 
                                                  FILE_ATTRIBUTE_NORMAL, null);
                             else
                                h = CreateFileW (name16.ptr, GENERIC_WRITE, 
                                                 0, null, CREATE_ALWAYS, 
                                                 FILE_ATTRIBUTE_NORMAL, null);

                        if (h == INVALID_HANDLE_VALUE)
                            exception ();

                        if (! CloseHandle (h))
                              exception ();

                        return this;
                }

                /***************************************************************

                        Create a new directory

                ***************************************************************/

                FileProxy createDirectory ()
                {
                        version (Win32SansUnicode)
                                {
                                if (! CreateDirectoryA (path.cString, null))
                                      exception();
                                }
                             else
                                {
                                if (! CreateDirectoryW (name16.ptr, null))
                                      exception();
                                }
                        return this;
                }

                /***************************************************************
                        
                        List the set of children within this directory. 

                ***************************************************************/

                FilePath[] toList (bool delegate(FilePath fp) filter)
                {
                        int                     i;
                        wchar[]                 c;
                        HANDLE                  h;
                        FilePath                fp;
                        FilePath[]              list;
                        FIND_DATA               fileinfo;

                        int next()
                        {
                                version (Win32SansUnicode)
                                         return FindNextFileA (h, &fileinfo);
                                     else
                                         return FindNextFileW (h, &fileinfo);
                        }
                        
                        list = new FilePath[50];

                        version (Win32SansUnicode)
                                h = FindFirstFileA ((path.toUtf8 ~ "\\*\0").ptr, &fileinfo);
                             else
                                h = FindFirstFileW ((name16[0..$-1] ~ "\\*\0").ptr, &fileinfo);

                        if (h != INVALID_HANDLE_VALUE)
                            try {
                                do {
                                   // make a copy of the file name for listing
                                   version (Win32SansUnicode)
                                           {
                                           int len = strlen (fileinfo.cFileName);
                                           fp = new FilePath (fileinfo.cFileName [0 .. len]);
                                           }
                                        else
                                           {
                                           int len = wcslen (fileinfo.cFileName.ptr);
                                           fp = new FilePath (Utf.toUtf8(fileinfo.cFileName [0 .. len]));
                                           }

                                   if (i >= list.length)
                                      list.length = list.length * 2;

                                   if (filter (fp))
                                      {
                                      list[i] = fp;
                                      ++i;
                                      }
                                   } while (next);
                                } finally {
                                          FindClose (h);
                                          }
                        list.length = i;
                        return list;
                }
        }

                
        /***********************************************************************

        ***********************************************************************/

        version (Posix)
        {
                /***************************************************************

                        Throw an exception using the last known error

                ***************************************************************/

                private void exception ()
                {
                        throw new IOException (path.toUtf8 ~ ": " ~ SysError.lastMsg);
                }

                /***************************************************************

                        Get info about this path

                ***************************************************************/

                private uint getInfo (void delegate (inout struct_stat info) dg)
                {
                        struct_stat stats;

                        if (posix.stat (path.cString.ptr, &stats))
                            exception();

                        if (dg)
                            dg (stats);

                        return stats.st_mode;
                }               

                /***************************************************************

                        Return the file length (in bytes)

                ***************************************************************/

                ulong getSize ()
                {
                        ulong _size;

                        void size (inout struct_stat info)
                        {
                                _size = cast(ulong) info.st_size;    // 32 bits only
                        }

                        getInfo (&size);
                        return _size;
                }

                /***************************************************************

                        Is this file writable?

                ***************************************************************/

                bool isWritable ()               
                {
                        return (getInfo(null) & O_RDONLY) == 0;
                }            

                /***************************************************************

                        Is this file really a directory?

                ***************************************************************/

                bool isDirectory ()               
                {
                        return (getInfo(null) & S_IFDIR) != 0;
                }            

                /***************************************************************

                        Return the time when the file was last modified

                ***************************************************************/

                ulong getModifiedTime ()
                {
                        ulong _time;

                        void time (inout struct_stat info)
                        {
                               _time = cast(ulong) info.st_mtime;
                        }

                        getInfo (&time);
                        return _time;
                }               

                /***************************************************************

                        Return the time when the file was last accessed

                ***************************************************************/

                ulong getAccessedTime ()
                {
                        ulong _time;

                        void time (inout struct_stat info)
                        {
                               _time = cast(ulong) info.st_atime;
                        }

                        getInfo (&time);
                        return _time;
                }               

                /***************************************************************

                        Return the time when the file was created

                ***************************************************************/

                ulong getCreatedTime ()
                {
                        ulong _time;

                        void time (inout struct_stat info)
                        {
                               _time = cast(ulong) info.st_ctime;
                        }

                        getInfo (&time);
                        return _time;
                }               

                /***************************************************************

                        Remove the file/directory from the file-system

                ***************************************************************/

                FileProxy remove ()
                {
                        if (isDirectory())
                           {
                           if (posix.rmdir (path.cString.ptr))
                               exception ();
                           }
                        else           
                           if (tango.stdc.stdio.remove (path.cString.ptr) == -1)
                               exception ();

                        return this;
                }              

                /***************************************************************

                       change the name or location of a file/directory, and
                       adopt the provided FilePath

                ***************************************************************/

                FileProxy rename (FilePath dst)
                {
                        if (tango.stdc.stdio.rename (path.cString.ptr, dst.cString.ptr) == -1)
                            exception ();

                        path = dst;
                        return this;
                }

                /***************************************************************

                        Create a new file 

                ***************************************************************/

                FileProxy createFile ()
                {
                        int fd;

                        fd = posix.open (path.cString.ptr, O_CREAT | O_WRONLY | O_TRUNC, 0660);
                        if (fd == -1)
                            exception();

                        if (posix.close(fd) == -1)
                            exception();

                        return this;
                }              

                /***************************************************************

                        Create a new directory

                ***************************************************************/

                FileProxy createDirectory ()
                {
                        if (posix.mkdir (path.cString.ptr, 0777))
                            exception();

                        return this;
                }

                /***************************************************************
                
                        List the set of children within this directory. 

                ***************************************************************/

                FilePath[] toList (bool delegate(FilePath fp) filter)
                {
                        int             i;
                        DIR*            dir;
                        dirent*         entry;
                        FilePath[]      list;

                        dir = tango.stdc.posix.dirent.opendir (path.cString.ptr);
                        if (! dir) 
                              exception();

                        list = new FilePath [50];
                        while ((entry = tango.stdc.posix.dirent.readdir(dir)) != null)
                        {
                              int len = tango.stdc.string.strlen (entry.d_name.ptr);

                              // make a copy of the file name for listing
                              auto fp = new FilePath (entry.d_name[0 ..len]);

                              if (i >= list.length)
                                  list.length = list.length * 2;

                              if (filter (fp))
                                 {
                                 list[i] = fp;
                                 ++i;
                                 }
                        }

                        list.length = i;
                        tango.stdc.posix.dirent.closedir (dir);
                        return list;
                }
        }
}

