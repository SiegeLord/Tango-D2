/**
 * D header file for POSIX.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */
module tango.stdc.posix.pwd;

private import tango.stdc.config;
public import tango.stdc.posix.sys.types; // for gid_t, uid_t

extern (C):

//
// Required
//
/*
struct passwd
{
    char*   pw_name;
    uid_t   pw_uid;
    gid_t   pw_gid;
    char*   pw_dir;
    char*   pw_shell;
}

passwd* getpwnam(char*);
passwd* getpwuid(uid_t);
*/

version( linux )
{
    struct passwd
    {
        char*   pw_name;
        char*   pw_passwd;
        uid_t   pw_uid;
        gid_t   pw_gid;
        char*   pw_gecos;
        char*   pw_dir;
        char*   pw_shell;
    }
}

passwd* getpwnam(char*);
passwd* getpwuid(uid_t);

//
// Thread-Safe Functions (TSF)
//
/*
int getpwnam_r(char*, passwd*, char*, size_t, passwd**);
int getpwuid_r(uid_t, passwd*, char*, size_t, passwd**);
*/

version( linux )
{
    int getpwnam_r(char*, passwd*, char*, size_t, passwd**);
    int getpwuid_r(uid_t, passwd*, char*, size_t, passwd**);
}

//
// XOpen (XSI)
//
/*
void    endpwent();
passwd* getpwent();
void    setpwent();
*/
