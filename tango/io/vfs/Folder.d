/*******************************************************************************

        copyright:      Copyright (c) 2007 Lars Ivar Igesund. 
                        All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Jul 2007: Initial version

        author:         Lars Ivar

*******************************************************************************/

module tango.io.vfs.Folder;

private import tango.io.model.IConduit;
private import tango.net.model.UriView;

interface Folder : FolderView
{

    Folder createFolder(char[] path);
    Folder openFolder(char[] path);
    Folder write(char[] path, InputStream stream);
//    Folder remove(char[] path);
 
}

interface FolderView
{
    char[][] toList (bool prefixed = false);
    Folder toList (void delegate(char[], char[], bool) dg);

    bool exists(char[] path);
    InputStream read(char[] path);

    ulong fileCount(bool recurse = true);
//    ulong folderCount(bool recurse = true);
    ulong contentSize(bool recurse = true);

    bool isWritable();

    UriView uri();
    char[] toUtf8();
}
