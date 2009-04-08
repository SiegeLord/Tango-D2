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
	import tango.time.Time;
}

private char[] fixName(char[] toFix) {
	if (containsPattern(toFix, "/"))
		toFix = toFix[(locatePrior(toFix, '/') + 1) .. length];
	return toFix;
}

private char[] checkFirst(char[] toFix) {
	for(; toFix[$-1] == '/';)
		toFix = toFix[0 .. ($-1)];
	return toFix;
}

private char[] checkLast(char[] toFix) {
	if (toFix[0] != '/')
		toFix = '/' ~ toFix;
	return toFix;
}

private char[] checkCat(char[] first, char[] last) {
	return checkFirst(first) ~ checkLast(last);
}
private FtpFileInfo[] getEntries(FTPConnection ftp, char[] path = "") {
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

private FtpFileInfo[] getFiles(FTPConnection ftp, char[] path = "") {
	FtpFileInfo[] infos = getEntries(ftp, path);
	FtpFileInfo[] return_;
	foreach(FtpFileInfo info; infos) {
		if(info.type == FtpFileType.file || info.type == FtpFileType.other || info.type == FtpFileType.unknown)
			return_ ~= info;
	}
	return return_;
}

private FtpFileInfo[] getFolders(FTPConnection ftp, char[] path = "") {
	FtpFileInfo[] infos = getEntries(ftp, path);
	FtpFileInfo[] return_;
	foreach(FtpFileInfo info; infos) {
		if(info.type == FtpFileType.dir || info.type == FtpFileType.cdir || info.type == FtpFileType.pdir)
			return_ ~= info;
	}
	return return_;
}

class FtpFolderEntry: VfsFolderEntry {

	char[] toString_, name_, username_, password_;
	uint port_;

	public this(char[] server, char[] path, char[] username = "",
	            char[] password = "", uint port = 21)
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

	VfsFolder open() {
		return new FtpFolder(toString_, name_, username_, password_, port_);
	}

	/***********************************************************************
	 Create a new folder
	 ***********************************************************************/

	VfsFolder create() {
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

	bool exists() {
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

class FtpFolder: VfsFolder {

	char[] toString_, name_, username_, password_;
	uint port_;

	public this(char[] server, char[] path, char[] username = "",
	            char[] password = "", uint port = 21)
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

	char[] name() {
		return fixName(name_);
	}

	/***********************************************************************
	 Return a long name
	 ***********************************************************************/

	char[] toString() {
		return checkCat(toString_, name_);
	}

	/***********************************************************************
	 Return a contained file representation 
	 ***********************************************************************/

	VfsFile file(char[] path) {
		return new FtpFile(toString_, checkLast(checkCat(name_, path)), username_, password_,
			port_);
	}

	/***********************************************************************
	 Return a contained folder representation 
	 ***********************************************************************/

	VfsFolderEntry folder(char[] path) {
		return new FtpFolderEntry(toString_, checkLast(checkCat(name_, path)), username_,
			password_, port_);
	}

	/***********************************************************************
	 Returns a folder set containing only this one. Statistics 
	 are inclusive of entries within this folder only
	 ***********************************************************************/

	VfsFolders self() {
		FTPConnection conn;

		

		scope(exit) {
			if(conn !is null)
				conn.close();
		}

		char[] connect = toString_;

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

	VfsFolders tree() {
		FTPConnection conn;

		

		scope(exit) {
			if(conn !is null)
				conn.close();
		}

		char[] connect = toString_;

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

	int opApply(int delegate(inout VfsFolder) dg) {
		FTPConnection conn;

		

		scope(exit) {
			if(conn !is null)
				conn.close();
		}

		char[] connect = toString_;

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

	VfsFolder clear() {
		FTPConnection conn;

		

		scope(exit) {
			if(conn !is null)
				conn.close();
		}

		char[] connect = toString_;

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
			for(int i = infos.length - 1; i >= 0; i--) {
				reversed ~= infos[i];
			}
			return reversed;
		}

		foreach(VfsFolder f; tree.subset(null))
		conn.rm(f.name);

		foreach(FtpFileInfo entries; getEntries(conn))
		conn.del(entries.name);

		//foreach(VfsFolder f; tree.subset(null))
		//	conn.rm(f.name);

		return new FtpFolder(toString_, name_, username_, password_, port_);
	}

	/***********************************************************************
	 Is folder writable?
	 ***********************************************************************/

	bool writable() {
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

			char[] connect = toString_;

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
		return new FtpFolder(toString_, name_, username_, password_, port_);
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

class FtpFolders: VfsFolders {

	char[] toString_, name_, username_, password_;
	uint port_;
	bool flat_;
	FtpFileInfo[] infos_;

	public this(char[] server, char[] path, char[] username = "",
	            char[] password = "", uint port = 21)
	in {
		assert(server.length > 0);
	}
	body {
		toString_ = checkFirst(server);
		name_ = checkLast(path);
		username_ = username;
		password_ = password;
		port_ = port;

		FTPConnection conn;

		

		scope(exit) {
			if(conn !is null)
				conn.close();
		}

		char[] connect = toString_;

		if(connect[$ - 1] == '/') {
			connect = connect[0 .. ($ - 1)];
		}

		conn = new FTPConnection(connect, username_, password_, port_);

		if(name_ != "")
			conn.cd(name_);

		infos_ = getEntries(conn);
	}

	package this(char[] server, char[] path, char[] username = "",
	             char[] password = "", uint port = 21, FtpFileInfo[] infos = null,
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

	public this(char[] server, char[] path, char[] username = "",
	            char[] password = "", uint port = 21, bool flat = false)
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

		char[] connect = toString_;

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

	int opApply(int delegate(inout VfsFolder) dg) {
		FTPConnection conn;

		

		scope(exit) {
			if(conn !is null)
				conn.close();
		}

		char[] connect = toString_;

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

	uint files() {
		FTPConnection conn;

		

		scope(exit) {
			if(conn !is null)
				conn.close();
		}

		char[] connect = toString_;

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

	uint folders() {
		FTPConnection conn;

		

		scope(exit) {
			if(conn !is null)
				conn.close();
		}

		char[] connect = toString_;

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

	uint entries() {
		FTPConnection conn;

		

		scope(exit) {
			if(conn !is null)
				conn.close();
		}

		char[] connect = toString_;

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

	ulong bytes() {
		FTPConnection conn;

		

		scope(exit) {
			if(conn !is null)
				conn.close();
		}

		char[] connect = toString_;

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

	VfsFolders subset(char[] pattern) {
		FTPConnection conn;

		

		scope(exit) {
			if(conn !is null)
				conn.close();
		}

		char[] connect = toString_;

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

	VfsFiles catalog(char[] pattern) {
		FTPConnection conn;

		

		scope(exit) {
			if(conn !is null)
				conn.close();
		}

		char[] connect = toString_;

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

	VfsFiles catalog(VfsFilter filter = null) {
		FTPConnection conn;

		

		scope(exit) {
			if(conn !is null)
				conn.close();
		}

		char[] connect = toString_;

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

class FtpFile: VfsFile {

	char[] toString_, name_, username_, password_;
	uint port_;
	bool conOpen;
	FTPConnection conn;

	public this(char[] server, char[] path, char[] username = "",
	            char[] password = "", uint port = 21)
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

	char[] name() {
		return fixName(name_);
	}

	/***********************************************************************
	 Return a long name
	 ***********************************************************************/

	char[] toString() {
		return checkCat(toString_, name_);
	}

	/***********************************************************************
	 Does this file exist?
	 ***********************************************************************/

	bool exists() {
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

		char[] connect = toString_;

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

	ulong size() {
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

		char[] connect = toString_;

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

	VfsFile copy(VfsFile source) {
		output.copy(source.input);
		return new FtpFile(toString_, name_, username_, password_, port_);
	}

	/***********************************************************************
	 Create and copy the given source, and remove the source
	 ***********************************************************************/

	VfsFile move(VfsFile source) {
		copy(source);
		source.remove;
		return new FtpFile(toString_, name_, username_, password_, port_);
	}

	/***********************************************************************
	 Create a new file instance
	 ***********************************************************************/

	VfsFile create() {
		char[1] a = "0";
		output.write(a);
		return new FtpFile(toString_, name_, username_, password_, port_);
	}

	/***********************************************************************
	 Create a new file instance and populate with stream
	 ***********************************************************************/

	VfsFile create(InputStream stream) {
		output.copy(stream);
		return new FtpFile(toString_, name_, username_, password_, port_);
	}

	/***********************************************************************
	 Remove this file
	 ***********************************************************************/

	VfsFile remove() {

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

		char[] connect = toString_;

		if(connect[$ - 1] == '/') {
			connect = connect[0 .. ($ - 1)];
		}

		if(!conOpen) {
			conn = new FTPConnection(connect, username_, password_, port_);
		}

		conn.del(name_);

		return new FtpFile(toString_, name_, username_, password_, port_);
	}

	/***********************************************************************
	 Return the input stream. Don't forget to close it
	 ***********************************************************************/

	InputStream input() {

		scope(failure) {
			if(!conOpen)
				if(conn !is null)
					conn.close();
		}

		char[] connect = toString_;

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

	OutputStream output() {

		scope(failure) {
			if(!conOpen)
				if(conn !is null)
					conn.close();
		}

		char[] connect = toString_;

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

	VfsFile dup() {
		return new FtpFile(toString_, name_, username_, password_, port_);
	}

    /***********************************************************************
     Time modified
     ***********************************************************************/

    Time mtime() {
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

		char[] connect = toString_;

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

    Time ctime() {
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

		char[] connect = toString_;

		if(connect[$ - 1] == '/') {
			connect = connect[0 .. ($ - 1)];
		}

		if(!conOpen) {
			conn = new FTPConnection(connect, username_, password_, port_);
		}

        return conn.getFileInfo(name_).create;
    }

    Time atime() {
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

		char[] connect = toString_;

		if(connect[$ - 1] == '/') {
			connect = connect[0 .. ($ - 1)];
		}

		if(!conOpen) {
			conn = new FTPConnection(connect, username_, password_, port_);
		}

        return conn.getFileInfo(name_).modify;
    }
}

class FtpFiles: VfsFiles {

	char[] toString_, name_, username_, password_;
	uint port_;
	FtpFileInfo[] infos_;

	public this(char[] server, char[] path, char[] username = "",
	            char[] password = "", uint port = 21, FtpFileInfo[] infos = null)
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

	void fillInfos() {

		FTPConnection conn;

		

		scope(exit) {
			if(conn !is null)
				conn.close();
		}

		char[] connect = toString_;

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

	int opApply(int delegate(inout VfsFile) dg) {
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

	uint files() {
		return infos_.length;
	}

	/***********************************************************************
	 Return the total size of all files 
	 ***********************************************************************/

	ulong bytes() {
		ulong return_;

		foreach(FtpFileInfo inf; infos_) {
			return_ += inf.size;
		}

		return return_;
	}
}

