/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: March 2004      
        
        author:         Kris

*******************************************************************************/

module tango.io.model.FilePathView;

/*******************************************************************************

        Models a file name. These are expected to be used as the constructor 
        argument to File implementations. The intention is that they easily
        convert to other representations such as absolute, canonical, or Url.
        Note that this class is immutable. Use FilePath if you wish
        to alter specific attributes.

        File paths containing non-ansi characters should be UTF-8 encoded. 
        Supporting Unicode in this manner was deemed to be more suitable 
        than providing a wchar version of FilePath, and is both consistent 
        & compatible with the approach taken with the Uri class.

*******************************************************************************/

abstract class FilePathView
{
          // simplistic string appender
        protected alias void delegate (void[]) Consumer;

        /***********************************************************************
        
                Returns true if this FilePathView is *not* relative to the 
                current working directory.

        ***********************************************************************/

        abstract bool isAbsolute ();

        /***********************************************************************
        
                Returns true if this FilePathView is empty

        ***********************************************************************/

        abstract bool isEmpty ();

        /***********************************************************************
                
                Returns true if this FilePathView has a parent.

        ***********************************************************************/

        abstract bool isChild ();

        /***********************************************************************
                
                Return the root of this path. Roots are constructs such as
                "c:"

        ***********************************************************************/

        abstract char[] getRoot ();

        /***********************************************************************
        
                Return the file path. Paths start with a '/' but do not
                end with one. The root path is empty. Directory paths 
                are split such that the directory name is placed into
                the 'name' member.

        ***********************************************************************/

        abstract char[] getPath ();

        /***********************************************************************
        
                Return the name of this file, or directory.

        ***********************************************************************/

        abstract char[] getName ();

        /***********************************************************************
        
                Return the file-extension, sans seperator

        ***********************************************************************/

        abstract char[] getExtension ();

        /***********************************************************************
        
                Suffix is like extension, except it can include multiple
                '.' sequences. For example, "wumpus1.foo.bar" has suffix
                "foo.bar" and extension "bar".

        ***********************************************************************/

        abstract char[] getSuffix ();

        /***********************************************************************
        
                Return a null terminated utf8 version of this file path, where
                the length does not include the trailing null

        ***********************************************************************/

        abstract char[] toUtf8 ();
        
        /***********************************************************************
        
                Return a null terminated utf8 version of this file path, where
                the length optionally includes the trailing null
                
        ***********************************************************************/

        abstract char[] toUtf8 (bool withNull);

        /***********************************************************************
        
                Return a null terminated utf16 version of this file path, where
                the length optionally includes the trailing null

        ***********************************************************************/

        abstract wchar[] toUtf16 (bool withNull = false);

        /***********************************************************************
        
                Returns a FilePathView representing the parent of this one. An
                exception is thrown if there is not parent (at the root).

        ***********************************************************************/

        abstract FilePathView toParent ();
        
        /***********************************************************************
        
                Return a cloned FilePathView with a different name, extension,
                and suffix.

        ***********************************************************************/

        abstract FilePathView toSibling (char[] name, char[] ext=null, char[] suffix=null);
        
        /***********************************************************************

                Convert this FilePathView to a char[] via the provided Consumer

        ***********************************************************************/

        abstract Consumer produce (Consumer consume);
        
        /***********************************************************************
        
                Splice this FilePathView onto the end of the provided base path.
                Output is return as a char[].

        ***********************************************************************/

        abstract char[] splice (FilePathView base);

        /***********************************************************************

            Returns the base name of this file path, that is name and suffix.

        ***********************************************************************/

        abstract FilePathView getFile();

        /***********************************************************************

            Returns the directory name, that is root and path. It is returned
            as a FilePathView with empty name, suffix and extension.

        ***********************************************************************/

        abstract FilePathView getDirectory();
}
