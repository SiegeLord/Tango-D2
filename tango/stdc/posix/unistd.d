/**
 * D header file for POSIX.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */
module tango.stdc.posix.unistd;

private import tango.stdc.posix.config;
private import tango.stdc.stddef;
public import tango.stdc.posix.inttypes;  // for intptr_t
public import tango.stdc.posix.sys.types; // for size_t, ssize_t, uid_t, gid_t, off_t, pid_t, useconds_t
public import tango.sys.consts.unistd;
extern (C):

const STDIN_FILENO  = 0;
const STDOUT_FILENO = 1;
const STDERR_FILENO = 2;

__gshared char*   optarg;
__gshared int     optind;
__gshared int     opterr;
__gshared int     optopt;

int     access(in char*, int);
uint    alarm(uint);
int     chdir(in char*);
int     chroot(in char*);
int     chown(in char*, uid_t, gid_t);
int     close(int);
size_t  confstr(int, char*, size_t);
int     dup(int);
int     dup2(int, int);
int     execl(in char*, in char*, ...);
int     execle(in char*, in char*, ...);
int     execlp(in char*, in char*, ...);
int     execv(in char*, in char**);
int     execve(in char*, in char**, in char**);
int     execvp(in char*, in char**);
void    _exit(int);
int     fchown(int, uid_t, gid_t);
pid_t   fork();
c_long  fpathconf(int, int);
//int     ftruncate(int, off_t);
char*   getcwd(char*, size_t);
gid_t   getegid();
uid_t   geteuid();
gid_t   getgid();
int     getgroups(int, gid_t *);
int     gethostname(char*, size_t);
char*   getlogin();
int     getlogin_r(char*, size_t);
int     getopt(int, in char**, in char*);
pid_t   getpgrp();
pid_t   getpid();
pid_t   getppid();
uid_t   getuid();
int     isatty(int);
int     link(in char*, in char*);
//off_t   lseek(int, off_t, int);
c_long  pathconf(in char*, int);
int     pause();
int     pipe(int*);
ssize_t read(int, void*, size_t);
ssize_t readlink(in char*, char*, size_t);
int     rmdir(in char*);
int     setegid(gid_t);
int     seteuid(uid_t);
int     setgid(gid_t);
int     setpgid(pid_t, pid_t);
pid_t   setsid();
int     setuid(uid_t);
uint    sleep(uint);
int     symlink(in char*, in char*);
c_long  sysconf(int);
pid_t   tcgetpgrp(int);
int     tcsetpgrp(int, pid_t);
char*   ttyname(int);
int     ttyname_r(int, char*, size_t);
int     unlink(in char*);
ssize_t write(int, in void*, size_t);

version( linux )
{
  static if( __USE_LARGEFILE64 )
  {
    off_t lseek64(int, off_t, int);
    alias lseek64 lseek;
  }
  else
  {
    off_t lseek(int, off_t, int);
  }
  static if( __USE_LARGEFILE64 )
  {
    int   ftruncate64(int, off_t);
    alias ftruncate64 ftruncate;
  }
  else
  {
    int   ftruncate(int, off_t);
  }
}
else version( FreeBSD )
{
    off_t lseek(int, off_t, int);
    int   ftruncate(int, off_t);
}
else version( solaris )
{
  static if( __USE_LARGEFILE64 )
  {
    off_t lseek64(int, off_t, int);
    alias lseek64 lseek;
  }
  else
  {
    off_t lseek(int, off_t, int);
  }
  static if( __USE_LARGEFILE64 )
  {
    int   ftruncate64(int, off_t);
    alias ftruncate64 ftruncate;
  }
  else
  {
    int   ftruncate(int, off_t);
  }
}
else
{
    off_t lseek(int, off_t, int);
    int   ftruncate(int, off_t);
}

//
// File Synchronization (FSC)
//
int fsync(int);

//
// Synchronized I/O (SIO)
//
int fdatasync(int);

//
// XOpen (XSI)
//
/*
char*      crypt(in char*, in char*);
char*      ctermid(char*);
void       encrypt(char[64], int);
int        fchdir(int);
c_long     gethostid();
pid_t      getpgid(pid_t);
pid_t      getsid(pid_t);
char*      getwd(char*); // LEGACY
int        lchown(in char*, uid_t, gid_t);
int        lockf(int, int, off_t);
int        nice(int);
ssize_t    pread(int, void*, size_t, off_t);
ssize_t    pwrite(int, in void*, size_t, off_t);
pid_t      setpgrp();
int        setregid(gid_t, gid_t);
int        setreuid(uid_t, uid_t);
void       swab(in void*, void*, ssize_t);
void       sync();
int        truncate(in char*, off_t);
useconds_t ualarm(useconds_t, useconds_t);
int        usleep(useconds_t);
pid_t      vfork();
*/

version( linux )
{
    char*      crypt(in char*, in char*);
    char*      ctermid(char*);
    void       encrypt(char[64], int);
    int        fchdir(int);
    c_long     gethostid();
    pid_t      getpgid(pid_t);
    pid_t      getsid(pid_t);
    char*      getwd(char*); // LEGACY
    int        lchown(in char*, uid_t, gid_t);
    //int        lockf(int, int, off_t);
    int        nice(int);
    //ssize_t    pread(int, void*, size_t, off_t);
    //ssize_t    pwrite(int, in void*, size_t, off_t);
    pid_t      setpgrp();
    int        setregid(gid_t, gid_t);
    int        setreuid(uid_t, uid_t);
    void       swab(in void*, void*, ssize_t);
    void       sync();
    //int        truncate(in char*, off_t);
    useconds_t ualarm(useconds_t, useconds_t);
    int        usleep(useconds_t);
    pid_t      vfork();

  static if( __USE_LARGEFILE64 )
  {
    int        lockf64(int, int, off_t);
    alias      lockf64 lockf;

    ssize_t    pread64(int, void*, size_t, off_t);
    alias      pread64 pread;

    ssize_t    pwrite64(int, in void*, size_t, off_t);
    alias      pwrite64 pwrite;

    int        truncate64(in char*, off_t);
    alias      truncate64 truncate;
  }
  else
  {
    int        lockf(int, int, off_t);
    ssize_t    pread(int, void*, size_t, off_t);
    ssize_t    pwrite(int, in void*, size_t, off_t);
    int        truncate(in char*, off_t);
  }
}
else version (darwin)
{
    char*      crypt(in char*, in char*);
    char*      ctermid(char*);
    void       encrypt(char[64], int);
    int        fchdir(int);
    c_long     gethostid();
    pid_t      getpgid(pid_t);
    pid_t      getsid(pid_t);
    char*      getwd(char*); // LEGACY
    int        lchown(in char*, uid_t, gid_t);
    int        lockf(int, int, off_t);
    int        nice(int);
    ssize_t    pread(int, void*, size_t, off_t);
    ssize_t    pwrite(int, in void*, size_t, off_t);
    pid_t      setpgrp();
    int        setregid(gid_t, gid_t);
    int        setreuid(uid_t, uid_t);
    void       swab(in void*, void*, ssize_t);
    void       sync();
    int        truncate(in char*, off_t);
    useconds_t ualarm(useconds_t, useconds_t);
    int        usleep(useconds_t);
    pid_t      vfork();
}
else version (FreeBSD)
{
    char*      crypt(in char*, in char*);
    //char*      ctermid(char*);
    void       encrypt(char*, int);
    int        fchdir(int);
    c_long     gethostid();
    int        getpgid(pid_t);
    int        getsid(pid_t);
    char*      getwd(char*); // LEGACY
    int        lchown(in char*, uid_t, gid_t);
    int        lockf(int, int, off_t);
    int        nice(int);
    ssize_t    pread(int, void*, size_t, off_t);
    ssize_t    pwrite(int, in void*, size_t, off_t);
    int        setpgrp(pid_t, pid_t);
    int        setregid(gid_t, gid_t);
    int        setreuid(uid_t, uid_t);
    void       swab(in void*, void*, ssize_t);
    void       sync();
    int        truncate(in char*, off_t);
    useconds_t ualarm(useconds_t, useconds_t);
    int        usleep(useconds_t);
    pid_t      vfork();
}
else version (solaris)
{
	char*      crypt(in char*, in char*);
	//char*      ctermid(char*);
	void       encrypt(char*, int);
	int        fchdir(int);
	c_long     gethostid();
	int        getpgid(pid_t);
	int        getsid(pid_t);
	char*      getwd(char*); // LEGACY
	int        lchown(in char*, uid_t, gid_t);
	int        nice(int);
	int        setpgrp(pid_t, pid_t);
	int        setregid(gid_t, gid_t);
	int        setreuid(uid_t, uid_t);
	void       swab(in void*, void*, ssize_t);
	void       sync();
	useconds_t ualarm(useconds_t, useconds_t);
	int        usleep(useconds_t);
	pid_t      vfork();

  static if( __USE_LARGEFILE64 )
  {
    int        lockf64(int, int, off_t);
    alias      lockf64 lockf;

    ssize_t    pread64(int, void*, size_t, off_t);
    alias      pread64 pread;

    ssize_t    pwrite64(int, in void*, size_t, off_t);
    alias      pwrite64 pwrite;

    int        truncate64(in char*, off_t);
    alias      truncate64 truncate;
  }
  else
  {
    int        lockf(int, int, off_t);
    ssize_t    pread(int, void*, size_t, off_t);
    ssize_t    pwrite(int, in void*, size_t, off_t);
    int        truncate(in char*, off_t);
  }
}

