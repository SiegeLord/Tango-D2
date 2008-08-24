/*******************************************************************************

        copyright:      Copyright (c) 2006 Lars Ivar Igesund, Thomas Kühne,
                                            Grzegorz Adam Hankiewicz

        license:        BSD style: $(LICENSE)

        version:        Dec 2006: Initial release

        author:         Lars Ivar Igesund, Thomas Kühne,
                        Grzegorz Adam Hankiewicz

*******************************************************************************/

module tango.util.PathUtil;

private import  tango.core.Exception;

private extern (C) void memmove (void* dst, void* src, uint bytes);

/*******************************************************************************

    Normalizes a path component as specified in section 5.2 of RFC 2396.

    ./ in path is removed
    /. at the end is removed
    <segment>/.. at the end is removed
    <segment>/../ in path is removed

    On Windows, \ will be converted to / prior to normalization.

    Note that any number of ../ segments at the front is ignored,
    unless it is an absolute path, in which case an exception will
    be thrown. A relative path with ../ segments at the front is only
    considered valid if it can be joined with a path such that it can
    be fully normalized.

    The input path is copied into either the provided buffer, or a heap
    allocated array if no buffer was provided. Normalization modifies
    this copy before returning the relevant slice.

    Throws: IllegalArgumentException if the root separator is followed by ..

    Examples:
    -----
     normalize("/home/foo/./bar/../../john/doe"); // => "/home/john/doe"
    -----

*******************************************************************************/

char[] normalize(char[] path, char[] buf = null)
{
    uint end;
version (Windows) {
    /*
       Internal helper to patch slashes
    */
    char[] normalizeSlashes(char[] path)
    {
        char to = '/', from = '\\';

        foreach (inout c; path)
                 if (c is from)
                     c = to;
        return path;
    }
}
    /*
       Internal helper to truncate the path, avoids heap usage.
    */
    void truncate(char[] path, char[] slice1, char[] slice2) {
        memmove(path.ptr, slice1.ptr, slice1.length);
        memmove(path.ptr + slice1.length, slice2.ptr, slice2.length);
        assert (end > slice1.length+slice2.length);
        end = slice1.length+slice2.length;
    }

    /*
       Internal helper that finds a slash followed by a dot
    */
    int findSlashDot(char[] path, int start) {
        assert(start < end);
        foreach(i, c; path[start..end-1]) 
            if (c == '/') {
                if (path[start+i+1] == '/')
                    truncate(path, path[0..start+i+1], path[start+i+2..end]);
                if (path[start+i+1] == '.') 
                    return i + start + 1;
            }

        return -1;
    }

    /*
       Internal helper that finds a slash starting at the back
    */
    int findSlash(char[] path, int start) {
        assert(start < end);

        if (start < 0)
            return -1;

        for (int i = start; i >= 0; i--) {
            if (path[i] == '/') {
                return i;
            }
        }
        return -1;
    }

    /*
        Internal helper that recursively shortens all segments with dots.
    */
    void removeDots(char[] path, int start) {
        assert (start < end);
        assert (path[start] == '.');
        if (start + 1 == end) {
            // path ends with /., remove
            end = start - 1;
            return;
        }
        else if (path[start+1] == '/') {
            // remove all subsequent './'
            do {
                truncate(path, path[0..start], path[start+2..end]);
            } while (start + 2 < end && path[start..start+2] == "./");
            int idx = findSlashDot(path, start - 1);
            if (idx < 0) {
                // no more /., return path
                return;
            }
            return removeDots(path, idx);
        }
        else if (path[start..start+2] == "..") {
            // found /.. sequence
version (Windows) {
            if (start == 3 && path[1] == '/') { // absolute, X:/..
                throw new IllegalArgumentException("PathUtil :: Invalid absolute path, root can't be followed by ..");
            }

}
else {
            if (start == 1) { // absolute
                throw new IllegalArgumentException("PathUtil :: Invalid absolute path, root separator can't be followed by ..");
            }
}
            int idx = findSlash(path, start - 2);
            if (start + 2 == end) {
                // path ends with /..
                if (idx < 0) {
                    // no more slashes in front of /.., resolves to empty path
                    end = 0;
                    return;
                }
                // remove /.. and preceding segment and return
                end = idx;
                return;
            }
            else if (path[start+2] == '/') {
                // found /../ sequence
                // if no slashes before /../, set path to everything after
                // if <segment>/../ is ../../, keep
                // otherwise, remove <segment>/../
                if (path[idx+1..start-1] == "..") {
                    idx = findSlashDot(path, start+4);
                    if (idx < 0) {
                        // no more /., path fully shortened
                        return;
                    }
                    return removeDots(path, idx);
                }
                truncate(path, path[0..idx < 0 ? 0 : idx + 1], path[start+3..end]);
                idx = findSlashDot(path, idx < 0 ? 0 : idx);
                if (idx < 0) {
                    // no more /., path fully shortened
                    return;
                }
                // examine next /.
                return removeDots(path, idx);
            }
        }
        else {
            if (findSlash(path, end - 1) < start)
                // segment is filename that starts with ., and at the end
                return;
            else {
                // not at end
                int idx = findSlashDot(path, start);
                if (idx > -1) 
                    return removeDots(path, idx);
                else
                    return;
            }
        }
        assert(false, "PathUtil :: invalid code path");
    }

    if (path.length == 0)
        return path;

    char[] normpath;
    if (buf is null) {
        normpath = path.dup;
    }
    else {
        normpath = buf; 
        normpath[0..path.length] = path;
    }

version (Windows) {
    normpath = normalizeSlashes(normpath);
}
    end = normpath.length;

    // if path starts with ./, remove all subsequent instances
    while (end > 1 && normpath[0] == '.' && normpath[1] == '/') {
        truncate(normpath, normpath[0..0], normpath[2..end]);
    }
    int idx = findSlashDot(normpath, 0);
    if (idx > -1) {
        removeDots(normpath, idx);
    }

    return normpath[0..end];
}


debug (UnitTest)
{

    unittest
    {
        assert (normalize ("") == "");
        assert (normalize ("/home/../john/../.tango/.htaccess") == "/.tango/.htaccess");
        assert (normalize ("/home/../john/../.tango/foo.conf") == "/.tango/foo.conf");
        assert (normalize ("/home/john/.tango/foo.conf") == "/home/john/.tango/foo.conf");
        assert (normalize ("/foo/bar/.htaccess") == "/foo/bar/.htaccess");
        assert (normalize ("foo/bar/././.") == "foo/bar");
        assert (normalize ("././foo/././././bar") == "foo/bar");
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
        assert (normalize ("d/") == "d/");
        assert (normalize ("/home/john/./foo/bar.txt") == "/home/john/foo/bar.txt");
        assert (normalize ("/home//john") == "/home/john");

version (Windows) {
        assert (normalize ("\\foo\\..\\john") == "/john");
        assert (normalize ("foo\\..\\john") == "john");
        assert (normalize ("foo\\bar\\..") == "foo");
        assert (normalize ("foo\\bar\\..\\john") == "foo/john");
        assert (normalize ("foo\\bar\\doe\\..\\..\\john") == "foo/john");
        assert (normalize ("foo\\bar\\doe\\..\\..\\john\\..\\bar") == "foo/bar");
        assert (normalize (".\\foo\\bar\\doe") == "foo/bar/doe");
        assert (normalize (".\\foo\\bar\\doe\\..\\..\\john\\..\\bar") == "foo/bar");
        assert (normalize (".\\foo\\bar\\..\\..\\john\\..\\bar") == "bar");
        assert (normalize ("foo\\bar\\.\\doe\\..\\..\\john") == "foo/john");
        assert (normalize ("..\\..\\foo\\bar") == "../../foo/bar");
        assert (normalize ("..\\..\\..\\foo\\bar") == "../../../foo/bar");
}
    }
}


/******************************************************************************

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
    
******************************************************************************/

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


debug (UnitTest)
{
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


/******************************************************************************

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
******************************************************************************/

private bool charMatch(char c1, char c2)
{
    version (Win32)
    {
        
        if (c1 != c2)
        {
            return ((c1 >= 'a' && c1 <= 'z') ? c1 - ('a' - 'A') : c1) ==
                   ((c2 >= 'a' && c2 <= 'z') ? c2 - ('a' - 'A') : c2);
        }
        return true;
    }
    version (Posix)
    {
        return c1 == c2;
    }
}

