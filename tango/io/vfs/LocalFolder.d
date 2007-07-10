/*******************************************************************************

        copyright:      Copyright (c) 2007 Lars Ivar Igesund. 
                        All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Jul 2007: Initial version

        author:         Lars Ivar

*******************************************************************************/


module tango.io.vfs.LocalFolder;

private import tango.io.FilePath,
               tango.io.FileSystem,
               tango.io.FileConduit;
private import tango.io.model.IConduit;
private import tango.net.Uri;
private import tango.io.vfs.Folder;

/*******************************************************************************

*******************************************************************************/

class LocalFolder : Folder
{
    private FilePath _localPath;
    private ulong _fileCount = ulong.max;
    private ulong _fileCountR = ulong.max;
    private ulong _contentSize = ulong.max;
    private ulong _contentSizeR = ulong.max;
    
    this(char[] path)
    {
        this(new FilePath(FilePath.padded(path)));
    }

    this(FilePath path)
    {
        if (!path.exists)
            path.createFolder;

        if (!path.isFolder)
            throw new Exception(path.toUtf8 ~ " is not a folder");

        // Assume provided path is relative to current working dir
        _localPath = FileSystem.toAbsolute(path);
        
    }

    char[][] toList (bool prefixed = false)
    {
        return _localPath.toList(prefixed);
    }

    Folder toList(void delegate(char[], char[], bool) dg)
    {
        _localPath.toList(dg);
        return this;
    }

    Folder createFolder(char[] path)
    {
        FilePath dir = new FilePath(_localPath.toUtf8);
        dir = cast(FilePath)dir.append(FilePath.padded(path));
        dir.createFolder;

        return new LocalFolder(dir);
    }

    bool exists(char[] path)
    {
        scope file = new FilePath(_localPath.toUtf8);
        file = cast(FilePath)file.append(path);
        return file.exists;
    }

    InputStream read(char[] path)
    {
        scope file = new FilePath(_localPath.toUtf8);
        file = cast(FilePath)file.append(path);
        auto stream = new FileConduit(file);
        return stream;
    }

    /*************************************************************************

        Opens a folder relative to the path of this folder.

        Returns:
            A reference to the opened folder, or null if it doesn't exist.

    *************************************************************************/

    Folder openFolder(char[] path)
    {
        scope dir = new FilePath(_localPath.toUtf8);
        dir = cast(FilePath)dir.append(path);

        if (dir.isFolder)
            return new LocalFolder(dir.toUtf8);
 
        return null;
    }

    Folder write(char[] path, InputStream stream)
    {
        scope file = new FilePath(_localPath.toUtf8);
        file = cast(FilePath)file.append(path);
        scope newfile = new FileConduit(file, FileConduit.WriteCreate);
        newfile.output.copy(stream);

        return this;
    }


    /+
    Folder remove(char[] path)
    {
        // TODO
        return null;
    }
    +/

    /************************************************************************

    *************************************************************************/

    ulong fileCount(bool recurse = true)
    {
        ulong count = 0;
        void countDelegate(char[] prefix, char[] str, bool isDirectory) {
            if(str == "." || str == "..") return 1;
            
            if(isDirectory && recurse){
                // recurse
                scope path = prefix ~ str; 
                scope recpath = new FilePath(path);
                recpath.toList(&countDelegate);
            }
            else{
                count++;
            }               
            return 1;
        }
        _localPath.toList(&countDelegate);

        return count;
    }

    /+
    ulong folderCount(bool recurse = true)
    {
        // TODO
        return 0;
    }
    +/

    ulong contentSize(bool recurse = true)
    {
        ulong size = 0;
        void sizeDelegate(char[] prefix, char[] str, bool isDirectory) {
            if(str == "." || str == "..") return 1;

            scope path = prefix ~ str; 
            scope fpath = new FilePath(path);
            
            if(isDirectory){
                if (recurse)
                    // recurse
                    fpath.toList(&sizeDelegate);
            }
            else{
                size += fpath.fileSize;
            }               
            return 1;
        }
        _localPath.toList(&sizeDelegate);

        return size;
    }

    bool isWritable() 
    { 
        return _localPath.isWritable; 
    }

    FilePath localPath()
    {
        return _localPath;
    }

    UriView uri()
    {
        return new Uri("file", "", _localPath.toUtf8);
    }

    char[] toUtf8() 
    {
        return _localPath.toUtf8;
    }

}
