/**
 * D header file for POSIX.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */
module tango.stdc.posix.unistd;

private import tango.stdc.config;
private import tango.stdc.stddef;
public import tango.stdc.posix.inttypes;  // for intptr_t
public import tango.stdc.posix.sys.types; // for size_t, ssize_t, uid_t, gid_t, off_t, pid_t, and useconds_t

extern (C):

const auto STDIN_FILENO  = 0;
const auto STDOUT_FILENO = 1;
const auto STDERR_FILENO = 2;

char*   optarg;
int     optind;
int     opterr;
int     optopt;

int     access(char*, int);
uint    alarm(uint);
int     chdir(char*);
int     chown(char*, uid_t, gid_t);
int     close(int);
size_t  confstr(int, char*, size_t);
int     dup(int);
int     dup2(int, int);
int     execl(char*, char*, ...);
int     execle(char*, char*, ...);
int     execlp(char*, char*, ...);
int     execv(char*, char**);
int     execve(char*, char**, char**);
int     execvp(char*, char**);
void    _exit(int);
int     fchown(int, uid_t, gid_t);
pid_t   fork();
c_long  fpathconf(int, int);
int     ftruncate(int, off_t);
char*   getcwd(char*, size_t);
gid_t   getegid();
uid_t   geteuid();
gid_t   getgid();
int     getgroups(int, gid_t *);
int     gethostname(char*, size_t);
char*   getlogin();
int     getlogin_r(char*, size_t);
int     getopt(int, char**, char*);
pid_t   getpgrp();
pid_t   getpid();
pid_t   getppid();
uid_t   getuid();
int     isatty(int);
int     link(char*, char*);
off_t   lseek(int, off_t, int);
c_long  pathconf(char*, int);
int     pause();
int     pipe(int[2]);
ssize_t read(int, void*, size_t);
ssize_t readlink(char*, char*, size_t);
int     rmdir(char*);
int     setegid(gid_t);
int     seteuid(uid_t);
int     setgid(gid_t);
int     setpgid(pid_t, pid_t);
pid_t   setsid();
int     setuid(uid_t);
uint    sleep(uint);
int     symlink(char*, char*);
c_long  sysconf(int);
pid_t   tcgetpgrp(int);
int     tcsetpgrp(int, pid_t);
char*   ttyname(int);
int     ttyname_r(int, char*, size_t);
int     unlink(char*);
ssize_t write(int, void*, size_t);

//
// File Synchronization (FSC)
//
/*
int fsync(int);
*/

//
// Synchronized I/O (SIO)
//
/*
int fdatasync(int);
*/

//
// XOpen (XSI)
//
/*
char*      crypt(char*, char*);
char*      ctermid(char*);
void       encrypt(char[64], int);
int        fchdir(int);
c_long     gethostid();
pid_t      getpgid(pid_t);
pid_t      getsid(pid_t);
char*      getwd(char*); // LEGACY
int        lchown(char*, uid_t, gid_t);
int        lockf(int, int, off_t);
int        nice(int);
ssize_t    pread(int, void*, size_t, off_t);
ssize_t    pwrite(int, void*, size_t, off_t);
pid_t      setpgrp();
int        setregid(gid_t, gid_t);
int        setreuid(uid_t, uid_t);
void       swab(void*, void*, ssize_t);
void       sync();
int        truncate(char*, off_t);
useconds_t ualarm(useconds_t, useconds_t);
int        usleep(useconds_t);
pid_t      vfork();
*/

version( linux )
{
    char*      crypt(char*, char*);
    char*      ctermid(char*);
    void       encrypt(char[64], int);
    int        fchdir(int);
    c_long     gethostid();
    pid_t      getpgid(pid_t);
    pid_t      getsid(pid_t);
    char*      getwd(char*); // LEGACY
    int        lchown(char*, uid_t, gid_t);
    int        lockf(int, int, off_t);
    int        nice(int);
    ssize_t    pread(int, void*, size_t, off_t);
    ssize_t    pwrite(int, void*, size_t, off_t);
    pid_t      setpgrp();
    int        setregid(gid_t, gid_t);
    int        setreuid(uid_t, uid_t);
    void       swab(void*, void*, ssize_t);
    void       sync();
    int        truncate(char*, off_t);
    useconds_t ualarm(useconds_t, useconds_t);
    int        usleep(useconds_t);
    pid_t      vfork();
}
else version (darwin)
{
    char*      crypt(char*, char*);
    char*      ctermid(char*);
    void       encrypt(char[64], int);
    int        fchdir(int);
    c_long     gethostid();
    pid_t      getpgid(pid_t);
    pid_t      getsid(pid_t);
    char*      getwd(char*); // LEGACY
    int        lchown(char*, uid_t, gid_t);
    int        lockf(int, int, off_t);
    int        nice(int);
    ssize_t    pread(int, void*, size_t, off_t);
    ssize_t    pwrite(int, void*, size_t, off_t);
    pid_t      setpgrp();
    int        setregid(gid_t, gid_t);
    int        setreuid(uid_t, uid_t);
    void       swab(void*, void*, ssize_t);
    void       sync();
    int        truncate(char*, off_t);
    useconds_t ualarm(useconds_t, useconds_t);
    int        usleep(useconds_t);
    pid_t      vfork();
}