/*******************************************************************************

        copyright:      Copyright (c) 2006 Lars Ivar Igesund, Thomas Kühne,
                                           Grzegorz Adam Hankiewicz

        license:        BSD style: $(LICENSE)

        version:        Initial release: December 2006

        author:         Lars Ivar Igesund, Thomas Kühne,
                        Grzegorz Adam Hankiewicz

*******************************************************************************/

module tango.sys.unix.Tilde;

version (Posix)
{
    import tango.stdc.stdlib;
    import tango.text.Util;
    import tango.stdc.posix.pwd;
    import tango.stdc.posix.stdlib;
    import tango.stdc.errno;
    import tango.core.Exception;

    private extern (C) int strlen (char *);
}
else
   static assert (0, "tango.sys.unix.Tilde requires version(Posix) declared");

/******************************************************************************

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

    Throws: OutOfMemoryException if there is not enough memory to 
            perform the database lookup for the <i>~user</i> syntax.

    Examples:
    -----
    import tango.sys.unix.Tilde;

    void process_file(char[] filename)
    {
         char[] path = expandTilde(filename);
        ...
    }
    -----

    -----
    import tango.sys.unix.Tilde;

    const char[] RESOURCE_DIR_TEMPLATE = "~/.applicationrc";
    char[] RESOURCE_DIR;    // This gets expanded below.

    static this()
    {
        RESOURCE_DIR = expandTilde(RESOURCE_DIR_TEMPLATE);
    }
    -----
******************************************************************************/

char[] expandTilde (char[] inputPath)
{
        // Return early if there is no tilde in path.
        if (inputPath.length < 1 || inputPath[0] != '~')
            return inputPath;

        if (inputPath.length == 1 || inputPath[1] == '/')
            return expandFromEnvironment(inputPath);
        else
            return expandFromDatabase(inputPath);
}


/*******************************************************************************

        Replaces the tilde from path with the environment variable
        HOME.

******************************************************************************/

private char[] expandFromEnvironment(char[] path)
{
    assert(path.length >= 1);
    assert(path[0] == '~');

    // Get HOME and use that to replace the tilde.
    char* home = getenv("HOME");
    if (home == null)
        return path;

    return combineCPathWithDPath(home, path, 1);
}


/*******************************************************************************

        Joins a path from a C string to the remainder of path.

        The last path separator from c_path is discarded. The result
        is joined to path[char_pos .. length] if char_pos is smaller
        than length, otherwise path is not appended to c_path.
        
******************************************************************************/

private char[] combineCPathWithDPath(char* cPath, char[] path, int charPos)
{
    assert(cPath != null);
    assert(path.length > 0);
    assert(charPos >= 0);

    // Search end of C string
    size_t end = strlen(cPath);

    // Remove trailing path separator, if any
    if (end && cPath[end - 1] == '/')
    end--;

    // Create our own copy, as lifetime of cPath is undocumented
    char[] cp = cPath[0 .. end].dup;

    // Do we append something from path?
    if (charPos < path.length)
        cp ~= path[charPos..$];

    return cp;
}


/*******************************************************************************

        Replaces the tilde from path with the path from the user
        database.

******************************************************************************/

private char[] expandFromDatabase(char[] path)
{
    assert(path.length > 2 || (path.length == 2 && path[1] != '/'));
    assert(path[0] == '~');

    // Extract username, searching for path separator.
    char[] username;
    int last_char = locate(path, '/');

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
        if (getpwnam_r(username.ptr, &result, cast(char*)extra_memory, extra_memory_size,
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


/*******************************************************************************

*******************************************************************************/

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

