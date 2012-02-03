/*******************************************************************************
     copyright:      Copyright (c) 2007-2008 Tango. All rights reserved

     license:        BSD style: $(LICENSE)

     version:        August 2008: Initial version

     author:         Lester L. Martin II
*******************************************************************************/

module tango.io.vfs.FtpFolder;


private {
    import tango.net.ftp.FtpClient;
    import tango.io.vfs.model.Vfs;
    import tango.io.vfs.FileFolder;
    import tango.io.device.Conduit;
    import tango.text.Util;
    import Time = tango.time.Time;
}

private const(char)[] fixName(const(char)[] toFix) {
    if (containsPattern(toFix, "/"))
        toFix = toFix[(locatePrior(toFix, '/') + 1) .. $];
    return toFix;
}

private const(char)[] checkFirst(const(char)[] toFix) {
    for(; toFix.length>0 && toFix[$-1] == '/';)
        toFix = toFix[0 .. ($-1)];
    return toFix;
}

private const(char)[] checkLast(const(char)[] toFix) {
for(;toFix.length>1 &&  toFix[0] == '/' && toFix[1] == '/' ;)
        toFix = toFix[1 .. $];
    if(toFix.length && toFix[0] != '/')
        toFix = '/' ~ toFix;
    return toFix;
}

private const(char)[] checkCat(const(char)[] first, const(char)[] last) {
    return checkFirst(first) ~ checkLast(last);
}

private FtpFileInfo[] getEntries(FTPConnection ftp, const(char)[] path = "") {
    FtpFileInfo[] orig = ftp.ls(path);
    FtpFileInfo[] temp2;
    FtpFileInfo[] use;
    FtpFileInfo[] temp;
    foreach(FtpFileInfo inf; orig) {
        if(inf.type == FtpFileType.dir) {
            temp ~= inf;
        }
    }
    foreach(FtpFileInfo inf; temp) {
        temp2 ~= getEntries((ftp.cd(inf.name) , ftp));
        //wasn't here at the beginning
        foreach(inf2; temp2) {
            inf2.name = checkCat(inf.name, inf2.name);
            use ~= inf2;
        }
        orig ~= use;
        //end wasn't here at the beginning
        ftp.cdup();
    }
    return orig;
}

private FtpFileInfo[] getFiles(FTPConnection ftp, const(char)[] path = "") {
    FtpFileInfo[] infos = getEntries(ftp, path);
    FtpFileInfo[] return_;
    foreach(FtpFileInfo info; infos) {
        if(info.type == FtpFileType.file || info.type == FtpFileType.other || info.type == FtpFileType.unknown)
            return_ ~= info;
    }
    return return_;
}

private FtpFileInfo[] getFolders(FTPConnection ftp, const(char)[] path = "") {
    FtpFileInfo[] infos = getEntries(ftp, path);
    FtpFileInfo[] return_;
    foreach(FtpFileInfo info; infos) {
        if(info.type == FtpFileType.dir || info.type == FtpFileType.cdir || info.type == FtpFileType.pdir)
            return_ ~= info;
    }
    return return_;
}

/******************************************************************************
    Defines a folder over FTP that has yet to be opened, may not exist, and
      may be created.
******************************************************************************/

class FtpFolderEntry: VfsFolderEntry {

    const(char)[] toString_, name_, username_, password_;
    uint port_;

    public this(const(char)[] server, const(char)[] path, const(char)[] username = "",
                const(char)[] password = "", uint port = 21)
    in {
        assert(server.length > 0);
    }
    body {
        toString_ = checkFirst(server);
        name_ = checkLast(path);
        username_ = username;
        password_ = password;
        port_ = port;
    }

    /***********************************************************************
     Open a folder
     ***********************************************************************/

    final VfsFolder open() {
        return new FtpFolder(toString_, name_, username_, password_, port_);
    }

    /***********************************************************************
     Create a new folder
     ***********************************************************************/

    final VfsFolder create() {
        FTPConnection conn;

        scope(failure) {
            if(conn !is null)
                conn.close();
        }

        scope(exit) {
            if(conn !is null)
                conn.close();
        }

        conn = new FTPConnection(toString_, username_, password_, port_);
        conn.mkdir(name_);

        return new FtpFolder(toString_, name_, username_, password_, port_);
    }

    /***********************************************************************
     Test to see if a folder exists
     ***********************************************************************/

    @property final bool exists() {
        FTPConnection conn;

    

        scope(exit) {
            if(conn !is null)
                conn.close();
        }

        bool return_;
        if(name_ == "") {
            try {
                conn = new FTPConnection(toString_, username_, password_, port_);
                return_ = true;
            } catch(Exception e) {
                return false;
            }
        } else {
            try {
                conn = new FTPConnection(toString_, username_, password_, port_);
                try {
                    conn.cd(name_);
                    return_ = true;
                } catch(Exception e) {
                    if(conn.exist(name_) == 2)
                        return_ = true;
                    else
                        return_ = false;
                }
            } catch(Exception e) {
                return_ = false;
            }
        }

        return return_;
    }
}

/******************************************************************************
     Represents a FTP Folder in full, allowing one to address
     specific folders of an FTP File system.
******************************************************************************/

class FtpFolder: VfsFolder {

    const(char)[] toString_, name_, username_, password_;
    uint port_;

    public this(const(char)[] server, const(char)[] path, const(char)[] username = "",
                const(char)[] password = "", uint port = 21)
    in {
        assert(server.length > 0);
    }
    body {
        toString_ = checkFirst(server);
        name_ = checkLast(path);
        username_ = username;
        password_ = password;
        port_ = port;
    }

    /***********************************************************************
     Return a short name
     ***********************************************************************/

    @property final const(char)[] name() {
        return fixName(name_);
    }

    /***********************************************************************
     Return a long name
     ***********************************************************************/

    override final string toString() {
        return checkCat(toString_, name_).idup;
    }

    /***********************************************************************
     Return a contained file representation
     ***********************************************************************/

    @property final VfsFile file(const(char)[] path) {
        return new FtpFile(toString_, checkLast(checkCat(name_, path)), username_, password_,
            port_);
    }

    /***********************************************************************
     Return a contained folder representation
     ***********************************************************************/

    @property final VfsFolderEntry folder(const(char)[] path) {
        return new FtpFolderEntry(toString_, checkLast(checkCat(name_, path)), username_,
            password_, port_);
    }

    /***********************************************************************
     Returns a folder set containing only this one. Statistics
     are inclusive of entries within this folder only
     ***********************************************************************/

    @property final VfsFolders self() {
        FTPConnection conn;

        scope(exit) {
            if(conn !is null)
                conn.close();
        }

        const(char)[] connect = toString_;

        if(connect[$ - 1] == '/') {
            connect = connect[0 .. ($ - 1)];
        }

        conn = new FTPConnection(connect, username_, password_, port_);

        if(name_ != "")
            conn.cd(name_);

        return new FtpFolders(toString_, name_, username_, password_, port_,
            getFiles(conn), true);
    }

    /***********************************************************************
     Returns a subtree of folders. Statistics are inclusive of
     files within this folder and all others within the tree
     ***********************************************************************/

    @property final VfsFolders tree() {
        FTPConnection conn;

    

        scope(exit) {
            if(conn !is null)
                conn.close();
        }

        const(char)[] connect = toString_;

        if(connect[$ - 1] == '/') {
            connect = connect[0 .. ($ - 1)];
        }

        conn = new FTPConnection(connect, username_, password_, port_);

        if(name_ != "")
            conn.cd(name_);

        return new FtpFolders(toString_, name_, username_, password_, port_,
            getEntries(conn), false);
    }

    /***********************************************************************
     Iterate over the set of immediate child folders. This is
     useful for reflecting the hierarchy
     ***********************************************************************/

    final int opApply(scope int delegate(ref VfsFolder) dg) {
        FTPConnection conn;

    

        scope(exit) {
            if(conn !is null)
                conn.close();
        }

        const(char)[] connect = toString_;

        if(connect[$ - 1] == '/') {
            connect = connect[0 .. ($ - 1)];
        }

        conn = new FTPConnection(connect, username_, password_, port_);

        if(name_ != "")
            conn.cd(name_);

        FtpFileInfo[] info = getFolders(conn);

        int result;

        foreach(FtpFileInfo fi; info) {
            VfsFolder x = new FtpFolder(toString_, checkLast(checkCat(name_, fi.name)), username_,
                password_, port_);
            if((result = dg(x)) != 0)
                break;
        }

        return result;
    }

    /***********************************************************************
     Clear all content from this folder and subordinates
     ***********************************************************************/

    final VfsFolder clear() {
        FTPConnection conn;

        scope(exit) {
            if(conn !is null)
                conn.close();
        }

        const(char)[] connect = toString_;

        if(connect[$ - 1] == '/') {
            connect = connect[0 .. ($ - 1)];
        }

        conn = new FTPConnection(connect, username_, password_, port_);

        if(name_ != "")
            conn.cd(name_);

        conn = new FTPConnection(connect, username_, password_, port_);

        conn.cd(name_);

        FtpFileInfo[] reverse(FtpFileInfo[] infos) {
            FtpFileInfo[] reversed;
            for(sizediff_t i = infos.length - 1; i >= 0; i--) {
                reversed ~= infos[i];
            }
            return reversed;
        }

        foreach(VfsFolder f; tree.subset(null))
        conn.rm(f.name);

        foreach(FtpFileInfo entries; getEntries(conn))
        conn.del(entries.name);

        //foreach(VfsFolder f; tree.subset(null))
        //    conn.rm(f.name);

        return this;
    }

    /***********************************************************************
     Is folder writable?
     ***********************************************************************/

    @property final bool writable() {
        try {
            FTPConnection conn;

            scope(failure) {
                if(conn !is null)
                    conn.close();
            }

            scope(exit) {
                if(conn !is null)
                    conn.close();
            }

            const(char)[] connect = toString_;

            if(connect[$ - 1] == '/') {
                connect = connect[0 .. ($ - 1)];
            }

            conn = new FTPConnection(connect, username_, password_, port_);

            if(name_ != "")
                conn.cd(name_);

            conn.mkdir("ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890");
            conn.rm("ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890");
            return true;

        } catch(Exception e) {
            return false;
        }
    }

    /***********************************************************************
     Close and/or synchronize changes made to this folder. Each
     driver should take advantage of this as appropriate, perhaps
     combining multiple files together, or possibly copying to a
     remote location
     ***********************************************************************/

    VfsFolder close(bool commit = true) {
        return this;
    }

    /***********************************************************************
     A folder is being added or removed from the hierarchy. Use
     this to test for validity (or whatever) and throw exceptions
     as necessary
     ***********************************************************************/

    void verify(VfsFolder folder, bool mounting) {
        return;
    }
}

/******************************************************************************
     A set of folders within an FTP file system as was selected by the
     Adapter or as was selected at initialization.
******************************************************************************/

class FtpFolders: VfsFolders {

    const(char)[] toString_, name_, username_, password_;
    uint port_;
    bool flat_;
    FtpFileInfo[] infos_;

    package this(const(char)[] server, const(char)[] path, const(char)[] username = "",
                 const(char)[] password = "", uint port = 21, FtpFileInfo[] infos = null,
                 bool flat = false)
    in {
        assert(server.length > 0);
    }
    body {
        toString_ = checkFirst(server);
        name_ = checkLast(path);
        username_ = username;
        password_ = password;
        port_ = port;
        infos_ = infos;
        flat_ = flat;
    }

    public this(const(char)[] server, const(char)[] path, const(char)[] username = "",
                const(char)[] password = "", uint port = 21, bool flat = false)
    in {
        assert(server.length > 0);
    }
    body {
        toString_ = checkFirst(server);
        name_ = checkLast(path);
        username_ = username;
        password_ = password;
        port_ = port;
        flat_ = flat;

        FTPConnection conn;

        scope(exit) {
            if(conn !is null)
                conn.close();
        }

        const(char)[] connect = toString_;

        if(connect[$ - 1] == '/') {
            connect = connect[0 .. ($ - 1)];
        }

        conn = new FTPConnection(connect, username_, password_, port_);

        if(name_ != "")
            conn.cd(name_);

        if(!flat_)
            infos_ = getEntries(conn);
        else
            infos_ = getFiles(conn);
    }

    /***********************************************************************
     Iterate over the set of contained VfsFolder instances
     ***********************************************************************/

    final int opApply(scope int delegate(ref VfsFolder) dg) {
        FTPConnection conn;

        scope(exit) {
            if(conn !is null)
                conn.close();
        }

        const(char)[] connect = toString_;

        if(connect[$ - 1] == '/') {
            connect = connect[0 .. ($ - 1)];
        }

        conn = new FTPConnection(connect, username_, password_, port_);

        if(name_ != "")
            conn.cd(name_);

        FtpFileInfo[] info = getFolders(conn);

        int result;

        foreach(FtpFileInfo fi; info) {
            VfsFolder x = new FtpFolder(toString_, checkLast(checkCat(name_, fi.name)),
                username_, password_, port_);
    
            // was
            // VfsFolder x = new FtpFolder(toString_ ~ "/" ~ name_, fi.name,
            // username_, password_, port_);
            if((result = dg(x)) != 0)
                break;
        }

        return result;
    }

    /***********************************************************************
     Return the number of files
     ***********************************************************************/

    @property final size_t files() {
        FTPConnection conn;

        scope(exit) {
            if(conn !is null)
                conn.close();
        }

        const(char)[] connect = toString_;

        if(connect[$ - 1] == '/') {
            connect = connect[0 .. ($ - 1)];
        }

        conn = new FTPConnection(connect, username_, password_, port_);

        if(name_ != "")
            conn.cd(name_);

        return getFiles(conn).length;
    }

    /***********************************************************************
     Return the number of folders
     ***********************************************************************/

    @property final size_t folders() {
        FTPConnection conn;

        scope(exit) {
            if(conn !is null)
                conn.close();
        }

        const(char)[] connect = toString_;

        if(connect[$ - 1] == '/') {
            connect = connect[0 .. ($ - 1)];
        }

        conn = new FTPConnection(connect, username_, password_, port_);

        if(name_ != "")
            conn.cd(name_);

        return getFolders(conn).length;
    }

    /***********************************************************************
     Return the total number of entries (files + folders)
     ***********************************************************************/

    @property final size_t entries() {
        FTPConnection conn;

        scope(exit) {
            if(conn !is null)
                conn.close();
        }

        const(char)[] connect = toString_;

        if(connect[$ - 1] == '/') {
            connect = connect[0 .. ($ - 1)];
        }

        conn = new FTPConnection(connect, username_, password_, port_);

        if(name_ != "")
            conn.cd(name_);

        return getEntries(conn).length;
    }

    /***********************************************************************
     Return the total size of contained files
     ***********************************************************************/

    @property final ulong bytes() {
        FTPConnection conn;

        scope(exit) {
            if(conn !is null)
                conn.close();
        }

        const(char)[] connect = toString_;

        if(connect[$ - 1] == '/') {
            connect = connect[0 .. ($ - 1)];
        }

        conn = new FTPConnection(connect, username_, password_, port_);

        if(name_ != "")
            conn.cd(name_);

        ulong return_;

        foreach(FtpFileInfo inf; getEntries(conn)) {
            return_ += inf.size;
        }

        return return_;
    }

    /***********************************************************************
     Return a subset of folders matching the given pattern
     ***********************************************************************/

    final VfsFolders subset(const(char)[]  pattern) {
        FTPConnection conn;

        scope(exit) {
            if(conn !is null)
                conn.close();
        }

        const(char)[] connect = toString_;

        if(connect[$ - 1] == '/') {
            connect = connect[0 .. ($ - 1)];
        }

        conn = new FTPConnection(connect, username_, password_, port_);

        if(name_ != "")
            conn.cd(name_);

        FtpFileInfo[] return__;

        if(pattern !is null)
            foreach(FtpFileInfo inf; getFolders(conn)) {
            if(containsPattern(inf.name, pattern))
                return__ ~= inf;
        }
        else
            return__ = getFolders(conn);

        return new FtpFolders(toString_, name_, username_, password_, port_,
            return__);
    }

    /***********************************************************************
     Return a set of files matching the given pattern
     ***********************************************************************/

    @property final VfsFiles catalog(const(char)[]  pattern) {
        FTPConnection conn;

        scope(exit) {
            if(conn !is null)
                conn.close();
        }

        const(char)[] connect = toString_;

        if(connect[$ - 1] == '/') {
            connect = connect[0 .. ($ - 1)];
        }

        conn = new FTPConnection(connect, username_, password_, port_);

        if(name_ != "")
            conn.cd(name_);

        FtpFileInfo[] return__;

        if(pattern !is null) {
            foreach(FtpFileInfo inf; getFiles(conn)) {
                if(containsPattern(inf.name, pattern)) {
                    return__ ~= inf;
                }
            }
        } else {
            return__ = getFiles(conn);
        }

        return new FtpFiles(toString_, name_, username_, password_, port_,
            return__);
    }

    /***********************************************************************
     Return a set of files matching the given filter
     ***********************************************************************/

    @property final VfsFiles catalog(VfsFilter filter = null) {
        FTPConnection conn;

        scope(exit) {
            if(conn !is null)
                conn.close();
        }

        const(char)[] connect = toString_;

        if(connect[$ - 1] == '/') {
            connect = connect[0 .. ($ - 1)];
        }

        conn = new FTPConnection(connect, username_, password_, port_);

        if(name_ != "")
            conn.cd(name_);

        FtpFileInfo[] return__;

        if(filter !is null)
            foreach(FtpFileInfo inf; getFiles(conn)) {
            VfsFilterInfo vinf;
            vinf.bytes = inf.size;
            vinf.name = inf.name;
            vinf.folder = false;
            vinf.path = checkCat(checkFirst(toString_), checkCat(name_ ,inf.name));
            if(filter(&vinf))
                return__ ~= inf;
        }
        else
            return__ = getFiles(conn);

        return new FtpFiles(toString_, name_, username_, password_, port_,
            return__);
    }
}

/*******************************************************************************
     Represents a file over a FTP file system.
*******************************************************************************/

class FtpFile: VfsFile {

    const(char)[] toString_, name_, username_, password_;
    uint port_;
    bool conOpen;
    FTPConnection conn;

    public this(const(char)[] server, const(char)[] path, const(char)[] username = "",
                const(char)[] password = "", uint port = 21)
    in {
        assert(server.length > 0);
    }
    body {
        toString_ = checkFirst(server);
        name_ = checkLast(path);
        username_ = username;
        password_ = password;
        port_ = port;
    }

    /***********************************************************************
     Return a short name
     ***********************************************************************/

    @property final const(char)[] name() {
        return fixName(name_);
    }

    /***********************************************************************
     Return a long name
     ***********************************************************************/

    override final string toString() {
        return checkCat(toString_, name_).idup;
    }

    /***********************************************************************
     Does this file exist?
     ***********************************************************************/

    @property final bool exists() {
        scope(failure) {
            if(!conOpen)
                if(conn !is null)
                    conn.close();
        }

        scope(exit) {
            if(!conOpen)
                if(conn !is null)
                    conn.close();
        }

        bool return_;

        const(char)[] connect = toString_;

        if(connect[$ - 1] == '/') {
            connect = connect[0 .. ($ - 1)];
        }

        if(!conOpen) {
            conn = new FTPConnection(connect, username_, password_, port_);
        }

        if(conn.exist(name_) == 1) {
            return_ = true;
        } else {
            return_ = false;
        }

        return return_;
    }

    /***********************************************************************
     Return the file size
     ***********************************************************************/

    @property final ulong size() {
        scope(failure) {
            if(!conOpen)
                if(conn !is null)
                    conn.close();
        }

        scope(exit) {
            if(!conOpen)
                if(conn !is null)
                    conn.close();
        }

        const(char)[] connect = toString_;

        if(connect[$ - 1] == '/') {
            connect = connect[0 .. ($ - 1)];
        }

        if(!conOpen) {
            conn = new FTPConnection(connect, username_, password_, port_);
        }

        return conn.size(name_);
    }

    /***********************************************************************
     Create and copy the given source
     ***********************************************************************/

    final VfsFile copy(VfsFile source) {
        output.copy(source.input);
        return this;
    }

    /***********************************************************************
     Create and copy the given source, and remove the source
     ***********************************************************************/

    final VfsFile move(VfsFile source) {
        copy(source);
        source.remove();
        return this;
    }

    /***********************************************************************
     Create a new file instance
     ***********************************************************************/

    final VfsFile create() {
        char[1] a = "0";
        output.write(a);
        return this;
    }

    /***********************************************************************
     Create a new file instance and populate with stream
     ***********************************************************************/

    final VfsFile create(InputStream stream) {
        output.copy(stream);
        return this;
    }

    /***********************************************************************
     Remove this file
     ***********************************************************************/

    final VfsFile remove() {

        conn.close();

        conOpen = false;

        scope(failure) {
            if(!conOpen)
                if(conn !is null)
                    conn.close();
        }

        scope(exit) {
            if(!conOpen)
                if(conn !is null)
                    conn.close();
        }

        const(char)[] connect = toString_;

        if(connect[$ - 1] == '/') {
            connect = connect[0 .. ($ - 1)];
        }

        if(!conOpen) {
            conn = new FTPConnection(connect, username_, password_, port_);
        }

        conn.del(name_);

        return this;
    }

    /***********************************************************************
     Return the input stream. Don't forget to close it
     ***********************************************************************/

    @property final InputStream input() {

        scope(failure) {
            if(!conOpen)
                if(conn !is null)
                    conn.close();
        }

        const(char)[] connect = toString_;

        if(connect[$ - 1] == '/') {
            connect = connect[0 .. ($ - 1)];
        }

        if(!conOpen) {
            conn = new FTPConnection(connect, username_, password_, port_);
        }

        conOpen = true;

        return conn.input(name_);
    }

    /***********************************************************************
     Return the output stream. Don't forget to close it
     ***********************************************************************/

    @property final OutputStream output() {

        scope(failure) {
            if(!conOpen)
                if(conn !is null)
                    conn.close();
        }

        const(char)[] connect = toString_;

        if(connect[$ - 1] == '/') {
            connect = connect[0 .. ($ - 1)];
        }

        if(!conOpen) {
            conn = new FTPConnection(connect, username_, password_, port_);
        }

        conOpen = true;

        return conn.output(name_);
    }

    /***********************************************************************
     Duplicate this entry
     ***********************************************************************/

    @property final VfsFile dup() {
        return new FtpFile(toString_, name_, username_, password_, port_);
    }

    /***********************************************************************
     Time modified
     ***********************************************************************/

    @property final Time.Time mtime() {
        conn.close();

        conOpen = false;

        scope(failure) {
            if(!conOpen)
                if(conn !is null)
                    conn.close();
        }

        scope(exit) {
            if(!conOpen)
                if(conn !is null)
                    conn.close();
        }

        const(char)[] connect = toString_;

        if(connect[$ - 1] == '/') {
            connect = connect[0 .. ($ - 1)];
        }

        if(!conOpen) {
            conn = new FTPConnection(connect, username_, password_, port_);
        }

        return conn.getFileInfo(name_).modify;
    }

    /***********************************************************************
     Time created
     ***********************************************************************/

    @property final Time.Time ctime() {
        conn.close();

        conOpen = false;

        scope(failure) {
            if(!conOpen)
                if(conn !is null)
                    conn.close();
        }

        scope(exit) {
            if(!conOpen)
                if(conn !is null)
                    conn.close();
        }

        const(char)[] connect = toString_;

        if(connect[$ - 1] == '/') {
            connect = connect[0 .. ($ - 1)];
        }

        if(!conOpen) {
            conn = new FTPConnection(connect, username_, password_, port_);
        }

        return conn.getFileInfo(name_).create;
    }

    @property final Time.Time atime() {
        conn.close();

        conOpen = false;

        scope(failure) {
            if(!conOpen)
                if(conn !is null)
                    conn.close();
        }

        scope(exit) {
            if(!conOpen)
                if(conn !is null)
                    conn.close();
        }

        const(char)[] connect = toString_;

        if(connect[$ - 1] == '/') {
            connect = connect[0 .. ($ - 1)];
        }

        if(!conOpen) {
            conn = new FTPConnection(connect, username_, password_, port_);
        }

        return conn.getFileInfo(name_).modify;
    }
        
        /***********************************************************************

                Modified time of the file

        ***********************************************************************/

    @property final Time.Time modified ()
    {
        return mtime ();
    }
}

/******************************************************************************
  Represents a selection of Files.
******************************************************************************/

class FtpFiles: VfsFiles {

    const(char)[] toString_, name_, username_, password_;
    uint port_;
    FtpFileInfo[] infos_;

    public this(const(char)[] server, const(char)[] path, const(char)[] username = "",
                const(char)[] password = "", uint port = 21, FtpFileInfo[] infos = null)
    in {
        assert(server.length > 0);
    }
    body {
        toString_ = checkFirst(server);
        name_ = checkLast(path);
        username_ = username;
        password_ = password;
        port_ = port;
        if(infos !is null)
            infos_ = infos;
        else
            fillInfos();
    }

    final void fillInfos() {

        FTPConnection conn;

    

        scope(exit) {
            if(conn !is null)
                conn.close();
        }

        const(char)[] connect = toString_;

        if(connect[$ - 1] == '/') {
            connect = connect[0 .. ($ - 1)];
        }

        conn = new FTPConnection(connect, username_, password_, port_);

        if(name_ != "")
            conn.cd(name_);

        infos_ = getFiles(conn);
    }

    /***********************************************************************
     Iterate over the set of contained VfsFile instances
     ***********************************************************************/

    final int opApply(scope int delegate(ref VfsFile) dg) {
        int result = 0;

        foreach(FtpFileInfo inf; infos_) {
            VfsFile x = new FtpFile(toString_, checkLast(checkCat(name_, inf.name)),
                username_, password_, port_);
            if((result = dg(x)) != 0)
                break;
        }

        return result;
    }

    /***********************************************************************
     Return the total number of entries
     ***********************************************************************/

    @property final size_t files() {
        return infos_.length;
    }

    /***********************************************************************
     Return the total size of all files
     ***********************************************************************/

    @property final ulong bytes() {
        ulong return_;

        foreach(FtpFileInfo inf; infos_) {
            return_ += inf.size;
        }

        return return_;
    }
}

