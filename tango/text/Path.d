module tango.text.Path;

private import tango.io.FileConst;
private import tango.text.UniChar;

version (Posix)
{
    private import tango.stdc.stdlib;
    private import tango.core.Array;
    private import tango.sys.linux.linux; // TODO: Shouldn't be necessary
    private import tango.stdc.posix.stdlib;
    private import tango.stdc.errno;
    private import tango.core.Exception;

    private extern (C) int strlen (char *);
}

class NormalizeException : Exception {

    this (char[] msg) { super("NormalizeException: " ~ msg); }
}

/***********************************************************************

    Convert path separators to the correct format. This mutates
    the provided 'path' content, so .dup it as necessary.

***********************************************************************/

private char[] normalizeSlashes(char[] path)
{
        version (Win32)
                 char from = '/', to = '\\';
             else
                char to = '/', from = '\\';

             foreach (inout c; path)
                      if (c is from)
                          c = to;
             return path;
}

/***********************************************************************

    Normalizes a path component as specified in section 5.2 of RFC 2396.

    ./ in path is removed
    /. at the end is removed
    <segment>/.. at the end is removed
    <segment>/../ in path is removed

    Unless normSlash is set to false, all slashes will be converted
    to the systems path separator character.

    Note that any number of ../ segments at the front is ignored, 
    unless it is an absolute path, in which case an exception will
    be thrown. A relative path with ../ segments at the front is only
    considered valid if it can be joined with a path such that it can 
    be fully normalized.

    Throws: NormalizeException if the root separator is followed by ..

    Examples:
    -----
    version(Win32)
    {
     normalize(r"home\foo\bar\..\john\..\doe"); // => "home\foo\doe"  
    }
    version(Posix)
    {
     normalize("/home/foo/./bar/../../john/doe"); // => "/home/john/doe"
    }
    ----- 

***********************************************************************/

char[] normalize(char[] path, bool normSlash = true)
in {
    assert (path.length > 1);
}
body {
    char[] normpath;
    if (normSlash) normpath = normalizeSlashes(path.dup);
    else normpath = path.dup;

    /*
       Internal helper that finds a slash followed by a dot
    */
    int findSlashDot(char[] path, int start) {
        assert(start < path.length);
        foreach(i, c; path[start..$]) {
            if (c == FileConst.PathSeparatorChar) {
                if (path[start+i+1] == '.') {
                    return i + start + 1;
                }
            }
        }
        return -1;
    }

    /*
       Internal helper that finds a slash starting at the back
    */
    int findSlash(char[] path, int start) {
        assert(start < path.length);

        if (start < 0)
            return -1;

        foreach_reverse (i, c; path[0..start]) {
            if (c == FileConst.PathSeparatorChar) {
                return i;
            }
        }
        return -1;
    }

    /*
        Internal helper that recursively shortens all segments with dots.
    */
    char[] removeDots(char[] path, int start) {
        assert (start < path.length);
        assert (path[start] == '.');
        if (start + 1 == path.length) {
            // path ends with /., remove
            return path[0..start];
        }
        else if (path[start+1] == FileConst.PathSeparatorChar) {
            // path has /./, remove ./
            path = path[0..start] ~ path[start+2..$];
            int idx = findSlashDot(path, start);
            if (idx < 0) {
                // no more /., return path
                return path;
            }
            return removeDots(path, idx); 
        }
        else if (path[start..start+2] == "..") {
            // found /.. sequence
            if (start-2 < 0) { // && path[start-1] == FileConst.PathSeparatorChar) {
                throw new NormalizeException("Invalid absolute path, root separator can not be followed by ..");
            }
            int idx = findSlash(path, start - 2);
            if (start + 2 == path.length) {
                // path ends with /..
                if (idx < 0) {
                    // no more slashes in front of /.., resolves to empty path
                    return "";
                }
                // remove /.. and preceding segment and return
                return path[0..idx];
            }
            else if (path[start+2] == FileConst.PathSeparatorChar) {
                // found /../ sequence
                // if no slashes before /../, set path to everything after
                // if <segment>/../ is ../../, keep
                // otherwise, remove <segment>/../
                if (path[idx+1..start-1] == "..") {
                    idx = findSlashDot(path, start+4);
                    if (idx < 0) {
                        // no more /., path fully shortened
                        return path;
                    }
                    return removeDots(path, idx);
                }
                path = path[0..idx < 0 ? 0 : idx + 1] ~ path[start+3..$];
                idx = findSlashDot(path, idx < 0 ? 0 : idx);
                if (idx < 0) {
                    // no more /., path fully shortened
                    return path;
                }
                // examine next /.
                return removeDots(path, idx); 
            }
        }
    }

    // if path starts with ./, remove
    if (normpath.length > 1 && normpath[0] == '.' && 
        normpath[1] == FileConst.PathSeparatorChar) {
        normpath = normpath[2..$];
    }
    int idx = findSlashDot(normpath, 0);
    if (idx > -1) {
        normpath = removeDots(normpath, idx);
    }

    return normpath;
}

debug (UnitTest) {

    void main() {}

unittest {

    assert (normalize ("/foo/../john") == "/john");
    assert (normalize ("foo/../john") == "john");
    assert (normalize ("foo/bar/..") == "foo");
    assert (normalize ("foo/bar/../john") == "foo/john");
    assert (normalize ("foo/bar/doe/../../john") == "foo/john");
    assert (normalize ("foo/bar/doe/../../john/../bar") == "foo/bar");
    assert (normalize ("./foo/bar/doe") == "foo/bar/doe");
    assert (normalize ("./foo/bar/doe/../../john/../bar") == "foo/bar");
    assert (normalize ("./foo/bar/../../john/../bar") == "bar");
    assert (normalize ("foo/bar/./doe/../../john") == "foo/john");
    assert (normalize ("../../foo/bar") == "../../foo/bar");
    assert (normalize ("../../../foo/bar") == "../../../foo/bar");
}

}

/**********************************************************************

     Matches filename characters.
     
     Under Windows, the comparison is done ignoring case. Under Linux
     an exact match is performed.

     Returns: true if c1 matches c2, false otherwise.

     Throws: Nothing.

     Examples:
     -----
     version(Win32)
     {
         charMatch('a', 'b') // => false
         charMatch('A', 'a') // => true
     }
     version(Posix)
     {
         charMatch('a', 'b') // => false
         charMatch('A', 'a') // => false
     }
     -----
**********************************************************************/

bool charMatch(dchar c1, dchar c2)
{
    version (Win32)
    {
        if (c1 != c2)
        {
            return toUniLower(c1) == toUniLower(c2);
        }
        return true;
    }
    version (Posix)
    {
        return c1 == c2;
    }
}

/**********************************************************************
    Matches a pattern against a filename.

    Some characters of pattern have special a meaning (they are
    <i>meta-characters</i>) and <b>can't</b> be escaped. These are:
    <p><table>
    <tr><td><b>*</b></td>
        <td>Matches 0 or more instances of any character.</td></tr>
    <tr><td><b>?</b></td>
        <td>Matches exactly one instances of any character.</td></tr>
    <tr><td><b>[</b><i>chars</i><b>]</b></td>
        <td>Matches one instance of any character that appears
        between the brackets.</td></tr>
    <tr><td><b>[!</b><i>chars</i><b>]</b></td>
        <td>Matches one instance of any character that does not appear
        between the brackets after the exclamation mark.</td></tr>
    </table><p>
    Internally individual character comparisons are done calling
    charMatch(), so its rules apply here too. Note that path
    separators and dots don't stop a meta-character from matching
    further portions of the filename.

    Returns: true if pattern matches filename, false otherwise.

    See_Also: charMatch().

    Throws: Nothing.

    Examples:
    -----
    version(Win32)
    {
        patternMatch("foo.bar", "*") // => true
        patternMatch(r"foo/foo\bar", "f*b*r") // => true
        patternMatch("foo.bar", "f?bar") // => false
        patternMatch("Goo.bar", "[fg]???bar") // => true
        patternMatch(r"d:\foo\bar", "d*foo?bar") // => true
    }
    version(Posix)
    {
        patternMatch("Go*.bar", "[fg]???bar") // => false
        patternMatch("/foo*home/bar", "?foo*bar") // => true
        patternMatch("foobar", "foo?bar") // => true
    }
    -----
**********************************************************************/

bool patternMatch(char[] filename, char[] pattern)
in
{
    // Verify that pattern[] is valid
    int i;
    int inbracket = false;

    for (i = 0; i < pattern.length; i++)
    {
        switch (pattern[i])
        {
        case '[':
            assert(!inbracket);
            inbracket = true;
            break;

        case ']':
            assert(inbracket);
            inbracket = false;
            break;

        default:
            break;
        }
    }
}
body
{
    int pi;
    int ni;
    char pc;
    char nc;
    int j;
    int not;
    int anymatch;

    ni = 0;
    for (pi = 0; pi < pattern.length; pi++)
    {
        pc = pattern[pi];
        switch (pc)
        {
        case '*':
            if (pi + 1 == pattern.length)
                goto match;
            for (j = ni; j < filename.length; j++)
            {
                if (patternMatch(filename[j .. filename.length], 
                            pattern[pi + 1 .. pattern.length]))
                    goto match;
            }
            goto nomatch;

        case '?':
            if (ni == filename.length)
            goto nomatch;
            ni++;
            break;

        case '[':
            if (ni == filename.length)
                goto nomatch;
            nc = filename[ni];
            ni++;
            not = 0;
            pi++;
            if (pattern[pi] == '!')
            {	
                not = 1;
                pi++;
            }
            anymatch = 0;
            while (1)
            {
                pc = pattern[pi];
                if (pc == ']')
                    break;
                if (!anymatch && charMatch(nc, pc))
                    anymatch = 1;
                pi++;
            }
            if (!(anymatch ^ not))
                goto nomatch;
            break;

        default:
            if (ni == filename.length)
                goto nomatch;
            nc = filename[ni];
            if (!charMatch(pc, nc))
                goto nomatch;
            ni++;
            break;
        }
    }
    if (ni < filename.length)
        goto nomatch;

    match:
    return true;

    nomatch:
    return false;
}

debug (UnitTest) {

unittest
{
    version (Win32)
	assert(patternMatch("foo", "Foo"));
    version (Posix)
	assert(!patternMatch("foo", "Foo"));
    assert(patternMatch("foo", "*"));
    assert(patternMatch("foo.bar", "*"));
    assert(patternMatch("foo.bar", "*.*"));
    assert(patternMatch("foo.bar", "foo*"));
    assert(patternMatch("foo.bar", "f*bar"));
    assert(patternMatch("foo.bar", "f*b*r"));
    assert(patternMatch("foo.bar", "f???bar"));
    assert(patternMatch("foo.bar", "[fg]???bar"));
    assert(patternMatch("foo.bar", "[!gh]*bar"));

    assert(!patternMatch("foo", "bar"));
    assert(!patternMatch("foo", "*.*"));
    assert(!patternMatch("foo.bar", "f*baz"));
    assert(!patternMatch("foo.bar", "f*b*x"));
    assert(!patternMatch("foo.bar", "[gh]???bar"));
    assert(!patternMatch("foo.bar", "[!fg]*bar"));
    assert(!patternMatch("foo.bar", "[fg]???baz"));
}

}

/**********************************************************************
    Performs tilde expansion in paths.

    There are two ways of using tilde expansion in a path. One
    involves using the tilde alone or followed by a path separator. In
    this case, the tilde will be expanded with the value of the
    environment variable <i>HOME</i>.  The second way is putting
    a username after the tilde (i.e. <tt>~john/Mail</tt>). Here,
    the username will be searched for in the user database
    (i.e. <tt>/etc/passwd</tt> on Unix systems) and will expand to
    whatever path is stored there.  The username is considered the
    string after the tilde ending at the first instance of a path
    separator.

    Note that using the <i>~user</i> syntax may give different
    values from just <i>~</i> if the environment variable doesn't
    match the value stored in the user database.

    When the environment variable version is used, the path won't
    be modified if the environment variable doesn't exist or it
    is empty. When the database version is used, the path won't be
    modified if the user doesn't exist in the database or there is
    not enough memory to perform the query.

    Returns: inputPath with the tilde expanded, or just inputPath
    if it could not be expanded.
    For Windows, expandTilde() merely returns its argument inputPath.

    Throws: OutOfMemoryException if there is not enough
    memory to perform
    the database lookup for the <i>~user</i> syntax.

    Examples:
    -----
    import tango.text.Path;

    void process_file(char[] filename)
    {
         char[] path = FilePath.expandTilde(filename);
        ...
    }
    -----

    -----
    import tango.text.Path;

    const char[] RESOURCE_DIR_TEMPLATE = "~/.applicationrc";
    char[] RESOURCE_DIR;    // This gets expanded in main().

    int main(char[][] args)
    {
        RESOURCE_DIR = FilePath.expandTilde(RESOURCE_DIR_TEMPLATE);
        ...
    }
    -----
**********************************************************************/

char[] expandTilde(char[] inputPath)
{
    version(Posix)
    {
        // Return early if there is no tilde in path.
        if (inputPath.length < 1 || inputPath[0] != '~')
            return inputPath;

        if (inputPath.length == 1 || inputPath[1] == FileConst.PathSeparatorChar)
            return expandFromEnvironment(inputPath);
        else
            return expandFromDatabase(inputPath);
    }
    else version(Win32)
    {
        // TODO: Put here real windows implementation.
        return inputPath;
    }
    else
    {
        static assert(0); // Guard. Implement on other platforms.
    }
}

debug(UnitTest) {

unittest
{
    version (Posix)
    {
    // Retrieve the current home variable.
    char* c_home = getenv("HOME");

    // Testing when there is no environment variable.
    unsetenv("HOME");
    assert(expandTilde("~/") == "~/");
    assert(expandTilde("~") == "~");

    // Testing when an environment variable is set.
    int ret = setenv("HOME", "tango/test\0", 1);
    assert(ret == 0);
    assert(expandTilde("~/") == "tango/test/");
    assert(expandTilde("~") == "tango/test");

    // The same, but with a variable ending in a slash.
    ret = setenv("HOME", "tango/test/\0", 1);
    assert(ret == 0);
    assert(expandTilde("~/") == "tango/test/");
    assert(expandTilde("~") == "tango/test");

    // Recover original HOME variable before continuing.
    if (c_home)
        setenv("HOME", c_home, 1);
    else
        unsetenv("HOME");

    // Test user expansion for root. Are there unices without /root?
    assert(expandTilde("~root") == "/root");
    assert(expandTilde("~root/") == "/root/");
    assert(expandTilde("~Idontexist/hey") == "~Idontexist/hey");
    }
}
}

version (Posix)
{

/***********************************************************************
        Replaces the tilde from path with the environment variable 
        HOME.

 **********************************************************************/
static private char[] expandFromEnvironment(char[] path)
{
    assert(path.length >= 1);
    assert(path[0] == '~');
    
    // Get HOME and use that to replace the tilde.
    char* home = getenv("HOME");
    if (home == null)
        return path;

    return combineCPathWithDPath(home, path, 1);
}


/***********************************************************************
        Joins a path from a C string to the remainder of path.
 
        The last path separator from c_path is discarded. The result
        is joined to path[char_pos .. length] if char_pos is smaller
        than length, otherwise path is not appended to c_path.
 **********************************************************************/
static private char[] combineCPathWithDPath(char* cPath, char[] path, int charPos)
{
    assert(cPath != null);
    assert(path.length > 0);
    assert(charPos >= 0);

    // Search end of C string
    size_t end = strlen(cPath);

    // Remove trailing path separator, if any
    if (end && cPath[end - 1] == FileConst.PathSeparatorChar)
    end--;

    // Create our own copy, as lifetime of cPath is undocumented
    char[] cp = cPath[0 .. end].dup;

    // Do we append something from path?
    if (charPos < path.length)
        cp ~= path[charPos..$];

    return cp;
}


/***********************************************************************

        Replaces the tilde from path with the path from the user 
        database.
 
 **********************************************************************/
static private char[] expandFromDatabase(char[] path)
{
    assert(path.length > 2 || (path.length == 2 && path[1] != FileConst.PathSeparatorChar));
    assert(path[0] == '~');

    // Extract username, searching for path separator.
    char[] username;
    int last_char = find(path, FileConst.PathSeparatorChar);

    if (last_char == -1)
        {
        username = path[1 .. length] ~ '\0';
        last_char = username.length + 1;
        }
    else
        {
        username = path[1 .. last_char] ~ '\0';
        }

    assert(last_char > 1);
    
    // Reserve C memory for the getpwnam_r() function.
    passwd result;
    int extra_memory_size = 5 * 1024;
    void* extra_memory;

    while (1)
        {
        extra_memory = tango.stdc.stdlib.malloc(extra_memory_size);
        if (extra_memory == null)
            goto Lerror;

        // Obtain info from database.
        passwd *verify;
        tango.stdc.errno.errno(0);
        if (getpwnam_r(username, &result, extra_memory, extra_memory_size,
        &verify) == 0)
            {
            // Failure if verify doesn't point at result.
            if (verify != &result)
            // username is not found, so return path[]
                goto Lnotfound;
            break;
            }

        if (tango.stdc.errno.errno() != ERANGE)
            goto Lerror;

        // extra_memory isn't large enough
        tango.stdc.stdlib.free(extra_memory);
        extra_memory_size *= 2;
        }

    path = combineCPathWithDPath(result.pw_dir, path, last_char);

    Lnotfound:
        tango.stdc.stdlib.free(extra_memory);
        return path;

    Lerror:
        // Errors are going to be caused by running out of memory
        if (extra_memory)
            tango.stdc.stdlib.free(extra_memory);
        throw new OutOfMemoryException("Not enough memory for user lookup in tilde expansion.", __LINE__);
    return null;
}

}

