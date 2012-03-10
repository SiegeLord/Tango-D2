/**
 * D header file for POSIX.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Christian Schneider
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 * Source:    Copied/edited from tango.stdc.posix.pwd
 */
module tango.stdc.posix.grp;

private import tango.stdc.posix.config;
public import tango.stdc.posix.sys.types; // for gid_t, uid_t

extern (C):

//
// Required
//
/*
struct group
{
    char*   gr_name;
    gid_t   gr_gid;
    char**  gr_mem;
}

group* getgrnam(in char*);
group* getgrgid(gid_t);
*/

version( linux )
{
    struct group
    {
        char*   gr_name;
        char*   gr_passwd;
        gid_t   gr_gid;
        char**  gr_mem;
    }
}
else version( darwin )
{
    struct group
    {
        char*   gr_name;
        char*   gr_passwd;
        gid_t   gr_gid;
        char**  gr_mem;
    }
}
else version( FreeBSD )
{
    struct group
    {
        char*   gr_name;
        char*   gr_passwd;
        gid_t   gr_gid;
        char**  gr_mem;
    }
}
else version( solaris )
{
    struct group
    {
        char*   gr_name;
        char*   gr_passwd;
        gid_t   gr_gid;
        char**  gr_mem;
    }
}
group* getgrnam(in char*);
group* getgrgid(gid_t);

//
// Thread-Safe Functions (TSF)
//
/*
int getgrnam_r(in char*, group*, char*, size_t, group**);
int getgrgid_r(gid_t, group*, char*, size_t, group**);
*/

version( linux )
{
    int getgrnam_r(in char*, group*, char*, size_t, group**);
    int getgrgid_r(gid_t, group*, char*, size_t, group**);
}
else version( darwin )
{
    int getgrnam_r(in char*, group*, char*, size_t, group**);
    int getgrgid_r(gid_t, group*, char*, size_t, group**);
}
else version( FreeBSD )
{
    int getgrnam_r(in char*, group*, char*, size_t, group**);
    int getgrgid_r(gid_t, group*, char*, size_t, group**);
}
else version( solaris )
{
    int getgrnam_r(in char*, group*, char*, size_t, group**);
    int getgrgid_r(gid_t, group*, char*, size_t, group**);
}
//
// XOpen (XSI)
//
/*
void    endgrent();
passwd* getgrent();
void    setgrent();
*/

version( linux )
{
    void    endgrent();
    group* getgrent();
    void    setgrent();
}
else version ( darwin )
{
    void    endgrent();
    group* getgrent();
    void    setgrent();
}
else version (FreeBSD)
{
    void    endgrent();
    group* getgrent();
    void    setgrent();
}
else version ( solaris )
{
    void    endgrent();
    group* getgrent();
    void    setgrent();
}
