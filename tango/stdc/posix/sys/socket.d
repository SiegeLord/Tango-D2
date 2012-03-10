/**
 * D header file for POSIX.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: The Open Group Base Specifications Issue 6, IEEE Std 1003.1, 2004 Edition
 */
module tango.stdc.posix.sys.socket;

private import tango.stdc.posix.config;
public import tango.stdc.posix.sys.types; // for ssize_t, size_t
public import tango.stdc.posix.sys.uio;   // for iovec
public import tango.sys.consts.socket;
extern (C):

//
// Required
//
/*
socklen_t
sa_family_t

struct sockaddr
{
    sa_family_t sa_family;
    char        sa_data[];
}

struct sockaddr_storage
{
    sa_family_t ss_family;
}

struct msghdr
{
    void*         msg_name;
    socklen_t     msg_namelen;
    struct iovec* msg_iov;
    int           msg_iovlen;
    void*         msg_control;
    socklen_t     msg_controllen;
    int           msg_flags;
}

struct iovec {} // from tango.stdc.posix.sys.uio

struct cmsghdr
{
    socklen_t cmsg_len;
    int       cmsg_level;
    int       cmsg_type;
}

SCM_RIGHTS

CMSG_DATA(cmsg)
CMSG_NXTHDR(mhdr,cmsg)
CMSG_FIRSTHDR(mhdr)

struct linger
{
    int l_onoff;
    int l_linger;
}

SOCK_DGRAM
SOCK_SEQPACKET
SOCK_STREAM

SOL_SOCKET

SO_ACCEPTCONN
SO_BROADCAST
SO_DEBUG
SO_DONTROUTE
SO_ERROR
SO_KEEPALIVE
SO_LINGER
SO_OOBINLINE
SO_RCVBUF
SO_RCVLOWAT
SO_RCVTIMEO
SO_REUSEADDR
SO_SNDBUF
SO_SNDLOWAT
SO_SNDTIMEO
SO_TYPE

SOMAXCONN

MSG_CTRUNC
MSG_DONTROUTE
MSG_EOR
MSG_OOB
MSG_PEEK
MSG_TRUNC
MSG_WAITALL

AF_INET
AF_UNIX
AF_UNSPEC

SHUT_RD
SHUT_RDWR
SHUT_WR

int     accept(int, sockaddr*, socklen_t*);
int     bind(int, in sockaddr*, socklen_t);
int     connect(int, in sockaddr*, socklen_t);
int     getpeername(int, sockaddr*, socklen_t*);
int     getsockname(int, sockaddr*, socklen_t*);
int     getsockopt(int, int, int, void*, socklen_t*);
int     listen(int, int);
ssize_t recv(int, void*, size_t, int);
ssize_t recvfrom(int, void*, size_t, int, sockaddr*, socklen_t*);
ssize_t recvmsg(int, msghdr*, int);
ssize_t send(int, in void*, size_t, int);
ssize_t sendmsg(int, in msghdr*, int);
ssize_t sendto(int, in void*, size_t, int, in sockaddr*, socklen_t);
int     setsockopt(int, int, int, in void*, socklen_t);
int     shutdown(int, int);
int     socket(int, int, int);
int     sockatmark(int);
int     socketpair(int, int, int, int[2]);
*/

version( linux )
{
    alias uint   socklen_t;
    alias ushort sa_family_t;

    struct sockaddr
    {
        sa_family_t sa_family;
        byte[14]    sa_data;
    }

    private enum : size_t
    {
        _SS_SIZE    = 128,
        _SS_PADSIZE = _SS_SIZE - (c_ulong.sizeof * 2)
    }

    struct sockaddr_storage
    {
        sa_family_t ss_family;
        c_ulong     __ss_align;
        byte[_SS_PADSIZE] __ss_padding;
    }

    struct msghdr
    {
        void*     msg_name;
        socklen_t msg_namelen;
        iovec*    msg_iov;
        size_t    msg_iovlen;
        void*     msg_control;
        size_t    msg_controllen;
        int       msg_flags;
    }

    struct cmsghdr
    {
        size_t cmsg_len;
        int    cmsg_level;
        int    cmsg_type;
        static if( false /* (!is( __STRICT_ANSI__ ) && __GNUC__ >= 2) || __STDC_VERSION__ >= 199901L */ )
        {
            ubyte[1] __cmsg_data;
        }
    }

    static if( false /* (!is( __STRICT_ANSI__ ) && __GNUC__ >= 2) || __STDC_VERSION__ >= 199901L */ )
    {
        extern (D) ubyte[1] CMSG_DATA( cmsghdr* cmsg ) { return cmsg.__cmsg_data; }
    }
    else
    {
        extern (D) ubyte*   CMSG_DATA( cmsghdr* cmsg ) { return cast(ubyte*)( cmsg + 1 ); }
    }

    private cmsghdr* __cmsg_nxthdr(msghdr*, cmsghdr*);
    alias            __cmsg_nxthdr CMSG_NXTHDR;

    extern (D) size_t CMSG_FIRSTHDR( msghdr* mhdr )
    {
        return ( mhdr.msg_controllen >= cmsghdr.sizeof
                             ? cast(size_t) mhdr.msg_control
                             : cast(size_t) 0 );
    }

    struct linger
    {
        int l_onoff;
        int l_linger;
    }

    int     accept(int, sockaddr*, socklen_t*);
    int     bind(int, in sockaddr*, socklen_t);
    int     connect(int, in sockaddr*, socklen_t);
    int     getpeername(int, sockaddr*, socklen_t*);
    int     getsockname(int, sockaddr*, socklen_t*);
    int     getsockopt(int, int, int, void*, socklen_t*);
    int     listen(int, int);
    ssize_t recv(int, void*, size_t, int);
    ssize_t recvfrom(int, void*, size_t, int, sockaddr*, socklen_t*);
    ssize_t recvmsg(int, msghdr*, int);
    ssize_t send(int, in void*, size_t, int);
    ssize_t sendmsg(int, in msghdr*, int);
    ssize_t sendto(int, in void*, size_t, int, in sockaddr*, socklen_t);
    int     setsockopt(int, int, int, in void*, socklen_t);
    int     shutdown(int, int);
    int     socket(int, int, int);
    int     sockatmark(int);
    int     socketpair(int, int, int, int[2]);
}
else version( darwin )
{
    alias uint   socklen_t;
    alias ubyte  sa_family_t;

    struct sockaddr
    {
        ubyte       sa_len;
        sa_family_t sa_family;
        byte[14]    sa_data;
    }

    private enum : size_t
    {
        _SS_PAD1    = long.sizeof - ubyte.sizeof - sa_family_t.sizeof,
        _SS_PAD2    = 128 - ubyte.sizeof - sa_family_t.sizeof - _SS_PAD1 - long.sizeof
    }

    struct sockaddr_storage
    {
         ubyte          ss_len;
         sa_family_t    ss_family;
         byte[_SS_PAD1] __ss_pad1;
         long           __ss_align;
         byte[_SS_PAD2] __ss_pad2;
    }

    struct msghdr
    {
        void*     msg_name;
        socklen_t msg_namelen;
        iovec*    msg_iov;
        int       msg_iovlen;
        void*     msg_control;
        socklen_t msg_controllen;
        int       msg_flags;
    }

    struct cmsghdr
    {
         socklen_t cmsg_len;
         int       cmsg_level;
         int       cmsg_type;
    }

    /+
    CMSG_DATA(cmsg)     ((unsigned char *)(cmsg) + \
                         ALIGN(sizeof(struct cmsghdr)))
    CMSG_NXTHDR(mhdr, cmsg) \
                        (((unsigned char *)(cmsg) + ALIGN((cmsg)->cmsg_len) + \
                         ALIGN(sizeof(struct cmsghdr)) > \
                         (unsigned char *)(mhdr)->msg_control +(mhdr)->msg_controllen) ? \
                         (struct cmsghdr *)0 /* NULL */ : \
                         (struct cmsghdr *)((unsigned char *)(cmsg) + ALIGN((cmsg)->cmsg_len)))
    CMSG_FIRSTHDR(mhdr) ((struct cmsghdr *)(mhdr)->msg_control)
    +/

    struct linger
    {
        int l_onoff;
        int l_linger;
    }

    int     accept(int, sockaddr*, socklen_t*);
    int     bind(int, in sockaddr*, socklen_t);
    int     connect(int, in sockaddr*, socklen_t);
    int     getpeername(int, sockaddr*, socklen_t*);
    int     getsockname(int, sockaddr*, socklen_t*);
    int     getsockopt(int, int, int, void*, socklen_t*);
    int     listen(int, int);
    ssize_t recv(int, void*, size_t, int);
    ssize_t recvfrom(int, void*, size_t, int, sockaddr*, socklen_t*);
    ssize_t recvmsg(int, msghdr*, int);
    ssize_t send(int, in void*, size_t, int);
    ssize_t sendmsg(int, in msghdr*, int);
    ssize_t sendto(int, in void*, size_t, int, in sockaddr*, socklen_t);
    int     setsockopt(int, int, int, in void*, socklen_t);
    int     shutdown(int, int);
    int     socket(int, int, int);
    int     sockatmark(int);
    int     socketpair(int, int, int, int[2]);
}
else version( FreeBSD )
{
    alias uint   socklen_t;
    alias ubyte  sa_family_t;

    struct sockaddr
    {
        ubyte       sa_len;
        sa_family_t sa_family;
        byte[14]    sa_data;
    }

    private
    {
        const _SS_ALIGNSIZE = long.sizeof;
        const uint _SS_MAXSIZE = 128;
        const _SS_PAD1SIZE = _SS_ALIGNSIZE - ubyte.sizeof - sa_family_t.sizeof;
        const _SS_PAD2SIZE = _SS_MAXSIZE - ubyte.sizeof - sa_family_t.sizeof - _SS_PAD1SIZE - _SS_ALIGNSIZE;
    }

    struct sockaddr_storage
    {
         ubyte          ss_len;
         sa_family_t    ss_family;
         byte[_SS_PAD1SIZE] __ss_pad1;
         long           __ss_align;
         byte[_SS_PAD2SIZE] __ss_pad2;
    }

    struct msghdr
    {
        void*     msg_name;
        socklen_t msg_namelen;
        iovec*    msg_iov;
        int       msg_iovlen;
        void*     msg_control;
        socklen_t msg_controllen;
        int       msg_flags;
    }

    struct cmsghdr
    {
         socklen_t cmsg_len;
         int       cmsg_level;
         int       cmsg_type;
    }

    /+
    CMSG_DATA(cmsg)     ((unsigned char *)(cmsg) + \
                         ALIGN(sizeof(struct cmsghdr)))
    CMSG_NXTHDR(mhdr, cmsg) \
                        (((unsigned char *)(cmsg) + ALIGN((cmsg)->cmsg_len) + \
                         ALIGN(sizeof(struct cmsghdr)) > \
                         (unsigned char *)(mhdr)->msg_control +(mhdr)->msg_controllen) ? \
                         (struct cmsghdr *)0 /* NULL */ : \
                         (struct cmsghdr *)((unsigned char *)(cmsg) + ALIGN((cmsg)->cmsg_len)))
    CMSG_FIRSTHDR(mhdr) ((struct cmsghdr *)(mhdr)->msg_control)
    +/

    struct linger
    {
        int l_onoff;
        int l_linger;
    }

    int     accept(int, sockaddr*, socklen_t*);
    int     bind(int, in sockaddr*, socklen_t);
    int     connect(int, in sockaddr*, socklen_t);
    int     getpeername(int, sockaddr*, socklen_t*);
    int     getsockname(int, sockaddr*, socklen_t*);
    int     getsockopt(int, int, int, void*, socklen_t*);
    int     listen(int, int);
    ssize_t recv(int, void*, size_t, int);
    ssize_t recvfrom(int, void*, size_t, int, sockaddr*, socklen_t*);
    ssize_t recvmsg(int, msghdr*, int);
    ssize_t send(int, in void*, size_t, int);
    ssize_t sendmsg(int, in msghdr*, int);
    ssize_t sendto(int, in void*, size_t, int, in sockaddr*, socklen_t);
    int     setsockopt(int, int, int, in void*, socklen_t);
    int     shutdown(int, int);
    int     socket(int, int, int);
    int     sockatmark(int);
    int     socketpair(int, int, int, int[2]);
}
else version( solaris )
{
    alias uint   socklen_t;
    alias ushort sa_family_t;

    struct sockaddr
    {
        sa_family_t sa_family;
        char[14]    sa_data;
    }

    private
    {
        alias double sockaddr_maxalign_t;
        const _SS_ALIGNSIZE = sockaddr_maxalign_t.sizeof;
        const _SS_MAXSIZE   = 256;
        const _SS_PAD1SIZE  = _SS_ALIGNSIZE - sa_family_t.sizeof;
        const _SS_PAD2SIZE  = _SS_MAXSIZE - (sa_family_t.sizeof + _SS_PAD1SIZE + _SS_ALIGNSIZE);
    }

    struct sockaddr_storage
    {
        sa_family_t ss_family;  /* Address family */
        /* Following fields are implementation specific */
        char        _ss_pad1[_SS_PAD1SIZE];
        sockaddr_maxalign_t _ss_align;
        char        _ss_pad2[_SS_PAD2SIZE];
    }
    
    struct msghdr
    {
        void*         msg_name;
        socklen_t     msg_namelen;
        iovec*        msg_iov;
        int           msg_iovlen;
        void*         msg_control;
        socklen_t     msg_controllen;
        int           msg_flags;
    }

    struct iovec {} // from tango.stdc.posix.sys.uio

    struct cmsghdr
    {
        socklen_t cmsg_len;
        int       cmsg_level;
        int       cmsg_type;
    }
    
    private
    {
        const _CMSG_DATA_ALIGNMENT = int.sizeof;
        version (X86)           const _CMSG_HDR_ALIGNMENT = 4;
        else version(X86_64)    const _CMSG_HDR_ALIGNMENT = 4;
        else /* SPARC */        const _CMSG_HDR_ALIGNMENT = 8;
        
        extern (D)
        {
            private ubyte* _CMSG_DATA_ALIGN(cmsghdr* x) { 
                return cast(ubyte*)((cast(size_t)x + _CMSG_DATA_ALIGNMENT - 1) & ~(_CMSG_DATA_ALIGNMENT - 1));
            }
            private size_t _CMSG_HDR_ALIGN(cmsghdr* x) { 
                return (cast(size_t)x + _CMSG_HDR_ALIGNMENT - 1) & ~(_CMSG_HDR_ALIGNMENT - 1);
            }
        }
    }
    
    extern (D) ubyte*   CMSG_DATA( cmsghdr* cmsg ) { return cast(ubyte*)_CMSG_DATA_ALIGN( cmsg + 1 ); }

    extern (D) cmsghdr* CMSG_FIRSTHDR( msghdr* mhdr )
    {
        return mhdr.msg_controllen >= cmsghdr.sizeof
            ? cast(cmsghdr*) mhdr.msg_control
            : null;
    }

    extern (D) cmsghdr* CMSG_NXTHDR( msghdr* m, cmsghdr* c )
    {
        /* Hurrah for unreadable C macros! */
        
        if(c is null) return CMSG_FIRSTHDR(m);
        
        size_t aligned_cmsg = _CMSG_HDR_ALIGN(c);
        return
            (aligned_cmsg + c.cmsg_len + cmsghdr.sizeof) > (cast(size_t)m.msg_control + m.msg_controllen)
            ? null
            : cast(cmsghdr*)(aligned_cmsg + c.cmsg_len);
    }
    
    struct linger
    {
        int l_onoff;
        int l_linger;
    }


    int     accept(int, sockaddr*, socklen_t*);
    int     bind(int, in sockaddr*, socklen_t);
    int     connect(int, in sockaddr*, socklen_t);
    int     getpeername(int, sockaddr*, socklen_t*);
    int     getsockname(int, sockaddr*, socklen_t*);
    int     getsockopt(int, int, int, void*, socklen_t*);
    int     listen(int, int);
    ssize_t recv(int, void*, size_t, int);
    ssize_t recvfrom(int, void*, size_t, int, sockaddr*, socklen_t*);
    ssize_t recvmsg(int, msghdr*, int);
    ssize_t send(int, in void*, size_t, int);
    ssize_t sendmsg(int, in msghdr*, int);
    ssize_t sendto(int, in void*, size_t, int, in sockaddr*, socklen_t);
    int     setsockopt(int, int, int, in void*, socklen_t);
    int     shutdown(int, int);
    int     socket(int, int, int);
    int     sockatmark(int);
    int     socketpair(int, int, int, int[2]);
}
