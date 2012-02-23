/*******************************************************************************

        copyright:      Copyright (c) 2007 Tango. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Jul 2007: Initial version

        author:         Lars Ivar, Kris

*******************************************************************************/

module tango.io.vfs.model.Vfs;



private import tango.time.Time : Time;

private import tango.io.model.IConduit;

private import tango.io.model.IFile : FileInfo;

/*******************************************************************************

        alias FileInfo for filtering

*******************************************************************************/

alias FileInfo VfsFilterInfo;
alias VfsFilterInfo* VfsInfo;

// return false to exclude something
alias bool delegate(VfsInfo) VfsFilter;


/*******************************************************************************

*******************************************************************************/

struct VfsStats
{
        ulong   bytes;                  // byte count of files
        size_t  files,                  // number of files
                folders;                // number of folders
}

/*******************************************************************************

******************************************************************************/

interface VfsHost : VfsFolder
{
        /**********************************************************************

                Add a child folder. The child cannot 'overlap' with others
                in the tree of the same type. Circular references across a
                tree of virtual folders are detected and trapped.

                The second argument represents an optional name that the
                mount should be known as, instead of the name exposed by
                the provided folder (it is not an alias).

        **********************************************************************/

        VfsHost mount (VfsFolder folder, const(char)[] name=null);

        /***********************************************************************

                Add a set of child folders. The children cannot 'overlap'
                with others in the tree of the same type. Circular references
                are detected and trapped.

        ***********************************************************************/

        VfsHost mount (VfsFolders group);

        /**********************************************************************

                Unhook a child folder

        **********************************************************************/

        VfsHost dismount (VfsFolder folder);

        /**********************************************************************

                Add a symbolic link to another file. These are referenced
                by file() alone, and do not show up in tree traversals

        **********************************************************************/

        VfsHost map (VfsFile target, const(char)[] name);

        /***********************************************************************

                Add a symbolic link to another folder. These are referenced
                by folder() alone, and do not show up in tree traversals

        ***********************************************************************/

        VfsHost map (VfsFolderEntry target, const(char)[] name);
}


/*******************************************************************************

        Supports a model a bit like CSS selectors, where a selection
        of operands is made before applying some operation. For example:
        ---
        // count of files in this folder
        auto count = folder.self.files;

        // accumulated file byte-count
        auto bytes = folder.self.bytes;

        // a group of one folder (itself)
        auto folders = folder.self;
        ---

        The same approach is used to select the subtree descending from
        a folder:
        ---
        // count of files in this tree
        auto count = folder.tree.files;

        // accumulated file byte-count
        auto bytes = folder.tree.bytes;

        // the group of child folders
        auto folders = folder.tree;
        ---

        Filtering can be applied to the tree resulting in a sub-group.
        Group operations remain applicable. Note that various wildcard
        characters may be used in the filtering:
        ---
        // select a subset of the resultant tree
        auto folders = folder.tree.subset("install");

        // get total file bytes for a tree subset, using wildcards
        auto bytes = folder.tree.subset("foo*").bytes;
        ---

        Files are selected from a set of folders in a similar manner:
        ---
        // files called "readme.txt" in this folder
        auto count = folder.self.catalog("readme.txt").files;

        // files called "read*.*" in this tree
        auto count = folder.tree.catalog("read*.*").files;

        // all txt files belonging to folders starting with "ins"
        auto count = folder.tree.subset("ins*").catalog("*.txt").files;

        // custom-filtered files within a subtree
        auto count = folder.tree.catalog(&filter).files;
        ---

        Sets of folders and files support iteration via foreach:
        ---
        foreach (folder; root.tree)
                 Stdout.formatln ("folder name:{}", folder.name);

        foreach (folder; root.tree.subset("ins*"))
                 Stdout.formatln ("folder name:{}", folder.name);

        foreach (file; root.tree.catalog("*.d"))
                 Stdout.formatln ("file name:{}", file.name);
        ---

        Creating and opening a sub-folder is supported in a similar
        manner, where the single instance is 'selected' before the
        operation is applied. Open differs from create in that the
        folder must exist for the former:
        ---
        root.folder("myNewFolder").create;

        root.folder("myExistingFolder").open;
        ---

        File manipulation is handled in much the same way:
        ---
        root.file("myNewFile").create;

        auto source = root.file("myExistingFile");
        root.file("myCopiedFile").copy(source);
        ---

        The principal benefits of these approaches are twofold: 1) it
        turns out to be notably more efficient in terms of traversal, and
        2) there's no casting required, since there is a clean separation
        between files and folders.

        See VfsFile for more information on file handling

*******************************************************************************/

interface VfsFolder
{
        /***********************************************************************

                Return a short name

        ***********************************************************************/

        @property const(char)[] name ();

        /***********************************************************************

                Return a long name

        ***********************************************************************/

        string toString ();

        /***********************************************************************

                Return a contained file representation

        ***********************************************************************/

        @property VfsFile file (const(char)[] path);

        /***********************************************************************

                Return a contained folder representation

        ***********************************************************************/

        @property VfsFolderEntry folder (const(char)[] path);

        /***********************************************************************

                Returns a folder set containing only this one. Statistics
                are inclusive of entries within this folder only

        ***********************************************************************/

        @property VfsFolders self ();

        /***********************************************************************

                Returns a subtree of folders. Statistics are inclusive of
                files within this folder and all others within the tree

        ***********************************************************************/

        @property VfsFolders tree ();

        /***********************************************************************

                Iterate over the set of immediate child folders. This is
                useful for reflecting the hierarchy

        ***********************************************************************/

        int opApply (scope int delegate(ref VfsFolder) dg);

        /***********************************************************************

                Clear all content from this folder and subordinates

        ***********************************************************************/

        VfsFolder clear ();

        /***********************************************************************

                Is folder writable?

        ***********************************************************************/

        @property bool writable ();

        /***********************************************************************

                Close and/or synchronize changes made to this folder. Each
                driver should take advantage of this as appropriate, perhaps
                combining multiple files together, or possibly copying to a
                remote location

        ***********************************************************************/

        VfsFolder close (bool commit = true);

        /***********************************************************************

                A folder is being added or removed from the hierarchy. Use
                this to test for validity (or whatever) and throw exceptions
                as necessary

        ***********************************************************************/

        void verify (VfsFolder folder, bool mounting);

        //VfsFolder copy(VfsFolder from, const(char)[] to);
        //VfsFolder move(Entry from, VfsFolder toFolder, const(char)[] toName);
        //const(char)[] absolutePath(const(char)[] path);
}


/*******************************************************************************

        Operations upon a set of folders

*******************************************************************************/

interface VfsFolders
{
        /***********************************************************************

                Iterate over the set of contained VfsFolder instances

        ***********************************************************************/

        int opApply (scope int delegate(ref VfsFolder) dg);

        /***********************************************************************

                Return the number of files

        ***********************************************************************/

        @property size_t files ();

        /***********************************************************************

                Return the number of folders

        ***********************************************************************/

        @property size_t folders ();

        /***********************************************************************

                Return the total number of entries (files + folders)

        ***********************************************************************/

        @property size_t entries ();

        /***********************************************************************

                Return the total size of contained files

        ***********************************************************************/

        @property ulong bytes ();

        /***********************************************************************

                Return a subset of folders matching the given pattern

        ***********************************************************************/

        VfsFolders subset (const(char)[]  pattern);

       /***********************************************************************

                Return a set of files matching the given pattern

        ***********************************************************************/

        @property VfsFiles catalog (const(char)[]  pattern);

        /***********************************************************************

                Return a set of files matching the given filter

        ***********************************************************************/

        @property VfsFiles catalog (VfsFilter filter = null);
}


/*******************************************************************************

        Operations upon a set of files

*******************************************************************************/

interface VfsFiles
{
        /***********************************************************************

                Iterate over the set of contained VfsFile instances

        ***********************************************************************/

        int opApply (scope int delegate(ref VfsFile) dg);

        /***********************************************************************

                Return the total number of entries

        ***********************************************************************/

        @property size_t files ();

        /***********************************************************************

                Return the total size of all files

        ***********************************************************************/

        @property ulong bytes ();
}


/*******************************************************************************

        A specific file representation

*******************************************************************************/

interface VfsFile
{
        /***********************************************************************

                Return a short name

        ***********************************************************************/

        @property const(char)[] name ();

        /**********************************************************************
 
                Return a long name

        ***********************************************************************/

        immutable(char)[] toString ();

        /***********************************************************************

                Does this file exist?

        ***********************************************************************/

        @property bool exists ();

        /***********************************************************************

                Return the file size

        ***********************************************************************/

        @property ulong size ();

        /***********************************************************************

                Create and copy the given source

        ***********************************************************************/

        VfsFile copy (VfsFile source);

        /***********************************************************************

                Create and copy the given source, and remove the source

        ***********************************************************************/

        VfsFile move (VfsFile source);

        /***********************************************************************

                Create a new file instance

        ***********************************************************************/

        VfsFile create ();

        /***********************************************************************

                Create a new file instance and populate with stream

        ***********************************************************************/

        VfsFile create (InputStream stream);

        /***********************************************************************

                Remove this file

        ***********************************************************************/

        VfsFile remove ();

        /***********************************************************************

                Return the input stream. Don't forget to close it

        ***********************************************************************/

        @property InputStream input ();

        /***********************************************************************

                Return the output stream. Don't forget to close it

        ***********************************************************************/

        @property OutputStream output ();

        /***********************************************************************

                Duplicate this entry

        ***********************************************************************/

        @property VfsFile dup ();

        /***********************************************************************

                The modified time of the folder

        ***********************************************************************/

        @property Time modified ();
}


/*******************************************************************************

        Handler for folder operations. Needs some work ...

*******************************************************************************/

interface VfsFolderEntry
{
        /***********************************************************************

                Open a folder

        ***********************************************************************/

        VfsFolder open ();

        /***********************************************************************

                Create a new folder

        ***********************************************************************/

        VfsFolder create ();

        /***********************************************************************

                Test to see if a folder exists

        ***********************************************************************/

        @property bool exists ();
}


/*******************************************************************************

    Would be used for things like zip files, where the
    implementation mantains the contents in memory or on disk, and where
    the actual zip file isn't/shouldn't be written until one is finished
    filling it up (for zip due to inefficient file format).

*******************************************************************************/

interface VfsSync
{
        /***********************************************************************

        ***********************************************************************/

        VfsFolder sync ();
}

