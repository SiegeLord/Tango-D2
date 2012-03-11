/**
 * D header file for POSIX.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */
module tango.stdc.posix.stdlib;

private import tango.stdc.posix.config;
public import tango.stdc.stdlib;
public import tango.stdc.posix.sys.wait;

extern (C):

//
// Required (defined in tango.stdc.stdlib)
//
/*
EXIT_FAILURE
EXIT_SUCCESS
NULL
RAND_MAX
MB_CUR_MAX
div_t
ldiv_t
lldiv_t
size_t
wchar_t

void    _Exit(int);
void    abort();
int     abs(int);
int     atexit(void function());
double  atof(in char*);
int     atoi(in char*);
c_long  atol(in char*);
long    atoll(in char*);
void*   bsearch(in void*, in void*, size_t, size_t, int function(in void*, in void*));
void*   calloc(size_t, size_t);
div_t   div(int, int);
void    exit(int);
void    free(void*);
char*   getenv(in char*);
c_long  labs(c_long);
ldiv_t  ldiv(c_long, c_long);
long    llabs(long);
lldiv_t lldiv(long, long);
void*   malloc(size_t);
int     mblen(in char*, size_t);
size_t  mbstowcs(wchar_t*, in char*, size_t);
int     mbtowc(wchar_t*, in char*, size_t);
void    qsort(void*, size_t, size_t, int function(in void*, in void*));
int     rand();
void*   realloc(void*, size_t);
void    srand(uint);
double  strtod(in char*, char**);
float   strtof(in char*, char**);
c_long  strtol(in char*, char**, int);
real    strtold(in char*, char**);
long    strtoll(in char*, char**, int);
c_ulong strtoul(in char*, char**, int);
ulong   strtoull(in char*, char**, int);
int     system(in char*);
size_t  wcstombs(char*, in wchar_t*, size_t);
int     wctomb(char*, wchar_t);
*/

//
// Advisory Information (ADV)
//
/*
int posix_memalign(void**, size_t, size_t);
*/

version( linux )
{
    int posix_memalign(void**, size_t, size_t);
}

//
// C Extension (CX)
//
/*
int setenv(in char*, in char*, int);
int unsetenv(in char*);
*/

version( linux )
{
    int setenv(in char*, in char*, int);
    int unsetenv(in char*);

    void* valloc(size_t); // LEGACY non-standard
}
else version( darwin )
{
    int setenv(in char*, in char*, int);
    int unsetenv(in char*);

    void* valloc(size_t); // LEGACY non-standard
}
else version( FreeBSD )
{
    int setenv(in char*, in char*, int);
    int unsetenv(in char*);

    void* valloc(size_t); // LEGACY non-standard
}
else version( solaris )
{
    int setenv(in char*, in char*, int);
    int unsetenv(in char*);

    void* valloc(size_t); // LEGACY non-standard
}

//
// Thread-Safe Functions (TSF)
//
/*
int rand_r(uint*);
*/

version( linux )
{
    int rand_r(uint*);
}
else version( darwin )
{
    int rand_r(uint*);
}
else version( FreeBSD )
{
    int rand_r(uint*);
}
else version( solaris )
{
    int rand_r(uint*);
}

//
// XOpen (XSI)
//
/*
WNOHANG     (defined in tango.stdc.posix.sys.wait)
WUNTRACED   (defined in tango.stdc.posix.sys.wait)
WEXITSTATUS (defined in tango.stdc.posix.sys.wait)
WIFEXITED   (defined in tango.stdc.posix.sys.wait)
WIFSIGNALED (defined in tango.stdc.posix.sys.wait)
WIFSTOPPED  (defined in tango.stdc.posix.sys.wait)
WSTOPSIG    (defined in tango.stdc.posix.sys.wait)
WTERMSIG    (defined in tango.stdc.posix.sys.wait)

c_long a64l(in char*);
double drand48();
char*  ecvt(double, int, int *, int *); // LEGACY
double erand48(ushort[3]);
char*  fcvt(double, int, int *, int *); // LEGACY
char*  gcvt(double, int, char*); // LEGACY
// per spec: int getsubopt(char** char* const*, char**);
int    getsubopt(char**, in char**, char**);
int    grantpt(int);
char*  initstate(uint, char*, size_t);
c_long jrand48(ushort[3]);
char*  l64a(c_long);
void   lcong48(ushort[7]);
c_long lrand48();
char*  mktemp(char*); // LEGACY
int    mkstemp(char*);
c_long mrand48();
c_long nrand48(ushort[3]);
int    posix_openpt(int);
char*  ptsname(int);
int    putenv(char*);
c_long random();
char*  realpath(in char*, char*);
ushort seed48(ushort[3]);
void   setkey(in char*);
char*  setstate(in char*);
void   srand48(c_long);
void   srandom(uint);
int    unlockpt(int);
*/

version( linux )
{
    //WNOHANG     (defined in tango.stdc.posix.sys.wait)
    //WUNTRACED   (defined in tango.stdc.posix.sys.wait)
    //WEXITSTATUS (defined in tango.stdc.posix.sys.wait)
    //WIFEXITED   (defined in tango.stdc.posix.sys.wait)
    //WIFSIGNALED (defined in tango.stdc.posix.sys.wait)
    //WIFSTOPPED  (defined in tango.stdc.posix.sys.wait)
    //WSTOPSIG    (defined in tango.stdc.posix.sys.wait)
    //WTERMSIG    (defined in tango.stdc.posix.sys.wait)

    c_long a64l(in char*);
    double drand48();
    char*  ecvt(double, int, int *, int *); // LEGACY
    double erand48(ushort[3]);
    char*  fcvt(double, int, int *, int *); // LEGACY
    char*  gcvt(double, int, char*); // LEGACY
    int    getsubopt(char**, in char**, char**);
    int    grantpt(int);
    char*  initstate(uint, char*, size_t);
    c_long jrand48(ushort[3]);
    char*  l64a(c_long);
    void   lcong48(ushort[7]);
    c_long lrand48();
    char*  mktemp(char*); // LEGACY
    //int    mkstemp(char*);
    c_long mrand48();
    c_long nrand48(ushort[3]);
    int    posix_openpt(int);
    char*  ptsname(int);
    int    putenv(char*);
    c_long random();
    char*  realpath(in char*, char*);
    ushort seed48(ushort[3]);
    void   setkey(in char*);
    char*  setstate(in char*);
    void   srand48(c_long);
    void   srandom(uint);
    int    unlockpt(int);

  static if( __USE_LARGEFILE64 )
  {
    int    mkstemp64(char*);
    alias  mkstemp64 mkstemp;
  }
  else
  {
    int    mkstemp(char*);
  }
}
else version( darwin )
{
    //WNOHANG     (defined in tango.stdc.posix.sys.wait)
    //WUNTRACED   (defined in tango.stdc.posix.sys.wait)
    //WEXITSTATUS (defined in tango.stdc.posix.sys.wait)
    //WIFEXITED   (defined in tango.stdc.posix.sys.wait)
    //WIFSIGNALED (defined in tango.stdc.posix.sys.wait)
    //WIFSTOPPED  (defined in tango.stdc.posix.sys.wait)
    //WSTOPSIG    (defined in tango.stdc.posix.sys.wait)
    //WTERMSIG    (defined in tango.stdc.posix.sys.wait)

    c_long a64l(in char*);
    double drand48();
    char*  ecvt(double, int, int *, int *); // LEGACY
    double erand48(ushort[3]);
    char*  fcvt(double, int, int *, int *); // LEGACY
    char*  gcvt(double, int, char*); // LEGACY
    int    getsubopt(char**, in char**, char**);
    int    grantpt(int);
    char*  initstate(uint, char*, size_t);
    c_long jrand48(ushort[3]);
    char*  l64a(c_long);
    void   lcong48(ushort[7]);
    c_long lrand48();
    char*  mktemp(char*); // LEGACY
    int    mkstemp(char*);
    c_long mrand48();
    c_long nrand48(ushort[3]);
    int    posix_openpt(int);
    char*  ptsname(int);
    int    putenv(char*);
    c_long random();
    char*  realpath(in char*, char*);
    ushort seed48(ushort[3]);
    void   setkey(in char*);
    char*  setstate(in char*);
    void   srand48(c_long);
    void   srandom(uint);
    int    unlockpt(int);
}
else version( FreeBSD )
{
    //WNOHANG     (defined in tango.stdc.posix.sys.wait)
    //WUNTRACED   (defined in tango.stdc.posix.sys.wait)
    //WEXITSTATUS (defined in tango.stdc.posix.sys.wait)
    //WIFEXITED   (defined in tango.stdc.posix.sys.wait)
    //WIFSIGNALED (defined in tango.stdc.posix.sys.wait)
    //WIFSTOPPED  (defined in tango.stdc.posix.sys.wait)
    //WSTOPSIG    (defined in tango.stdc.posix.sys.wait)
    //WTERMSIG    (defined in tango.stdc.posix.sys.wait)

    c_long a64l(in char*);
    double drand48();
    
    // Unimplemented on FreeBSD, but required by tango 
    import tango.stdc.math : modf; 
    char* ecvt(double arg, int ndigits, int* decpt, int* sign) 
    { 
        return(cvt(arg, ndigits, decpt, sign, true)); 
    } 
    char* fcvt(double arg, int ndigits, int* decpt, int* sign) 
    { 
        return(cvt(arg, ndigits, decpt, sign, false)); 
    } 
    private char* cvt(double arg, int ndigits, int* decpt, int* sign, bool eflag) 
    { 
        int r2; 
        double fi, fj; 
        char* p, p1; 
        char[] buf; 
    
        if (ndigits<0) 
            ndigits = 0; 
        buf = new char[ndigits]; 
    
        r2 = 0; 
        *sign = 0; 
        p = &buf[0]; 
        if (arg<0) { 
            *sign = 1; 
            arg = -arg; 
        } 
        arg = modf(arg, &fi); 
        p1 = &buf[$-1]; 
        /* 
         * Do integer part 
         */ 
        if (fi != 0) { 
            p1 = &buf[$-1]; 
            while (fi != 0) { 
                fj = modf(fi/10, &fi); 
                *--p1 = cast(char)((cast(char) (fj+.03)*10) + '0');
                r2++; 
            } 
            while (p1 < &buf[$-1]) 
                *p++ = *p1++; 
        } else if (arg > 0) { 
            while ((fj = arg*10) < 1) { 
                arg = fj; 
                r2--; 
            } 
        } 
        p1 = &buf[ndigits]; 
        if (!eflag) 
            p1 += r2; 
        *decpt = r2; 
        if (p1 < &buf[0]) { 
            buf[0] = '\0'; 
            return(buf.ptr); 
        } 
        while (p<=p1 && p<&buf[$-1]) { 
            arg *= 10; 
            arg = modf(arg, &fj); 
            *p++ = cast(char) (cast(char)(fj) + '0');
        } 
        if (p1 >= &buf[$-1]) { 
            buf[$-2] = '\0'; 
            return(buf.ptr); 
        } 
        p = p1; 
        *p1 += 5; 
        while (*p1 > '9') { 
            *p1 = '0'; 
            if (p1>buf.ptr) 
                ++*--p1; 
            else { 
                *p1 = '1'; 
                (*decpt)++; 
                if (!eflag) { 
                    if (p>buf.ptr) 
                        *p = '0'; 
                    p++; 
                } 
            } 
        } 
        *p = '\0'; 
        return(buf.ptr); 
    } 

    double erand48(ushort[3]);
    int    getsubopt(char**, in char**, char**);
    int    grantpt(int);
    char*  initstate(uint, char*, size_t);
    c_long jrand48(ushort[3]);
    char*  l64a(c_long);
    void   lcong48(ushort[7]);
    c_long lrand48();
    char*  mktemp(char*); // LEGACY
    int    mkstemp(char*);
    c_long mrand48();
    c_long nrand48(ushort[3]);
    int    posix_openpt(int);
    char*  ptsname(int);
    int    putenv(char*);
    c_long random();
    char*  realpath(in char*, char*);
    ushort seed48(ushort[3]);
    void   setkey(in char*);
    char*  setstate(in char*);
    void   srand48(c_long);
    void   srandom(uint);
    int    unlockpt(int);
}
else version( solaris )
{
    //WNOHANG     (defined in tango.stdc.posix.sys.wait)
    //WUNTRACED   (defined in tango.stdc.posix.sys.wait)
    //WEXITSTATUS (defined in tango.stdc.posix.sys.wait)
    //WIFEXITED   (defined in tango.stdc.posix.sys.wait)
    //WIFSIGNALED (defined in tango.stdc.posix.sys.wait)
    //WIFSTOPPED  (defined in tango.stdc.posix.sys.wait)
    //WSTOPSIG    (defined in tango.stdc.posix.sys.wait)
    //WTERMSIG    (defined in tango.stdc.posix.sys.wait)

    c_long a64l(in char*);
    double drand48();
    //char*  ecvt(double, int, int *, int *); // LEGACY
    double erand48(ushort[3]);
    //char*  fcvt(double, int, int *, int *); // LEGACY
    //char*  gcvt(double, int, char*); // LEGACY
    int    getsubopt(char**, in char**, char**);
    int    grantpt(int);
    char*  initstate(uint, char*, size_t);
    c_long jrand48(ushort[3]);
    char*  l64a(c_long);
    void   lcong48(ushort[7]);
    c_long lrand48();
    char*  mktemp(char*); // LEGACY
    int    mkstemp(char*);
    c_long mrand48();
    c_long nrand48(ushort[3]);
    int    posix_openpt(int);
    char*  ptsname(int);
    int    putenv(char*);
    c_long random();
    char*  realpath(in char*, char*);
    ushort seed48(ushort[3]);
    void   setkey(in char*);
    char*  setstate(in char*);
    void   srand48(c_long);
    void   srandom(uint);
    int    unlockpt(int);
}
