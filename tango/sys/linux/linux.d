
/* Written by Walter Bright, Christopher E. Miller, and many others.
 * www.digitalmars.com
 * Placed into public domain.
 */

module tango.sys.linux.linux;

private import tango.stdc.config; // for c_long

//alias int pid_t;   // use tango.stdc.posix.sys.types instead
//alias int off_t;   // use tango.stdc.posix.sys.types instead
//alias uint mode_t; // use tango.stdc.posix.sys.types instead
alias uint uid_t;  // use tango.stdc.posix.sys.types instead
alias uint gid_t;  // use tango.stdc.posix.sys.types instead

/+
enum : int
{
	SIGHUP = 1,
	SIGINT = 2,
	SIGQUIT = 3,
	SIGILL = 4,
	SIGTRAP = 5,
	SIGABRT = 6,
	SIGIOT = 6,
	SIGBUS = 7,
	SIGFPE = 8,
	SIGKILL = 9,
	SIGUSR1 = 10,
	SIGSEGV = 11,
	SIGUSR2 = 12,
	SIGPIPE = 13,
	SIGALRM = 14,
	SIGTERM = 15,
	SIGSTKFLT = 16,
	SIGCHLD = 17,
	SIGCONT = 18,
	SIGSTOP = 19,
	SIGTSTP = 20,
	SIGTTIN = 21,
	SIGTTOU = 22,
	SIGURG = 23,
	SIGXCPU = 24,
	SIGXFSZ = 25,
	SIGVTALRM = 26,
	SIGPROF = 27,
	SIGWINCH = 28,
	SIGPOLL = 29,
	SIGIO = 29,
	SIGPWR = 30,
	SIGSYS = 31,
	SIGUNUSED = 31,
}
+/
enum
{
    O_RDONLY = 0,
    O_WRONLY = 1,
    O_RDWR = 2,
    O_CREAT = 0100,
    O_EXCL = 0200,
    O_TRUNC = 01000,
    O_APPEND = 02000,
}

struct struct_stat	// distinguish it from the stat() function
{
    ulong st_dev;
    ushort __pad1;
    uint st_ino;
    uint st_mode;
    uint st_nlink;
    uint st_uid;
    uint st_gid;
    ulong st_rdev;
    ushort __pad2;
    int st_size;
    int st_blksize;
    int st_blocks;
    int st_atime;
    uint __unused1;
    int st_mtime;
    uint __unused2;
    int st_ctime;
    uint __unused3;
    uint __unused4;
    uint __unused5;
}

enum : int
{
    S_IFIFO  = 0010000,
    S_IFCHR  = 0020000,
    S_IFDIR  = 0040000,
    S_IFBLK  = 0060000,
    S_IFREG  = 0100000,
    S_IFLNK  = 0120000,
    S_IFSOCK = 0140000,

    S_IFMT   = 0170000
}

extern (C)
{
    int access(char*, int);
    int open(char*, int, ...);
    int read(int, void*, int);
    int write(int, void*, int);
    int close(int);
    int lseek(int, int, int);
    int fstat(int, struct_stat*);
    int lstat(char*, struct_stat*);
    int stat(char*, struct_stat*);
    //int chdir(char*);              // use tango.stdc.posix.unistd
    int mkdir(char*, int);
    int rmdir(char*);
    //char* getcwd(char*, int);      // use tango.stdc.posix.unistd
    //int chmod(char*, mode_t);      // use tango.stdc.posix.sys.stat
    //int fork();                    // use tango.stdc.posix.unistd
    //int dup(int);                  // use tango.stdc.posix.unistd
    //int dup2(int, int);            // use tango.stdc.posix.unistd
    //int pipe(int[2]);              // use tango.stdc.posix.unistd
    //pid_t wait(int*);              // use tango.stdc.posix.sys.wait
    //int waitpid(pid_t, int*, int); // use tango.stdc.posix.sys.wait
}

struct timeval
{
    int tv_sec;
    int tv_usec;
}

struct tm
{
    int tm_sec;
    int tm_min;
    int tm_hour;
    int tm_mday;
    int tm_mon;
    int tm_year;
    int tm_wday;
    int tm_yday;
    int tm_isdst;
    int tm_gmtoff;
    int tm_zone;
}

extern (C)
{
    // These are also defined in tango.stdc.posix.time, but it should be
    // safe to have them here as well, as they are extern declarations.
    extern int      daylight;
    extern c_long   timezone;

    int gettimeofday(timeval*, void*);
    int time(int*);
    tm *localtime(int*);
}

/**************************************************************/
// Memory mapping from <sys/mman.h> and <bits/mman.h>
//
//enum
//{
//	PROT_NONE	= 0,
//	PROT_READ	= 1,
//	PROT_WRITE	= 2,
//	PROT_EXEC	= 4,
//}
//
// Memory mapping sharing types

enum
{
//  MAP_SHARED	= 1,
//	MAP_PRIVATE	= 2,
	MAP_TYPE	= 0x0F,
//	MAP_FIXED	= 0x10,
	MAP_FILE	= 0,
	MAP_ANONYMOUS	= 0x20,
//	MAP_ANON	= 0x20,
	MAP_GROWSDOWN	= 0x100,
	MAP_DENYWRITE	= 0x800,
	MAP_EXECUTABLE	= 0x1000,
	MAP_LOCKED	= 0x2000,
	MAP_NORESERVE	= 0x4000,
	MAP_POPULATE	= 0x8000,
	MAP_NONBLOCK	= 0x10000,
}

// Values for msync()

//enum
//{	MS_ASYNC	= 1,
//	MS_INVALIDATE	= 2,
//	MS_SYNC		= 4,
//}

// Values for mlockall()

// enum // stdc.posix.sys.mman
// {
// 	MCL_CURRENT	= 1,
// 	MCL_FUTURE	= 2,
// }

// Values for mremap()

enum
{
	MREMAP_MAYMOVE	= 1,
}

// Values for madvise

enum
{	MADV_NORMAL	= 0,
	MADV_RANDOM	= 1,
	MADV_SEQUENTIAL	= 2,
	MADV_WILLNEED	= 3,
	MADV_DONTNEED	= 4,
}

extern (C)
{
//void* mmap(void*, size_t, int, int, int, off_t);
//const void* MAP_FAILED = cast(void*)-1;

//int munmap(void*, size_t);
int mprotect(void*, size_t, int);
//int msync(void*, size_t, int);
int madvise(void*, size_t, int);

//int mlock(void*, size_t);   // stdc.posix.sys.mman
//int munlock(void*, size_t); // stdc.posix.sys.mman
//int mlockall(int);          // stdc.posix.sys.mman
//int munlockall();           // stdc.posix.sys.mman

void* mremap(void*, size_t, size_t, int);
int mincore(void*, size_t, ubyte*);
int remap_file_pages(void*, size_t, int, size_t, int);
int shm_open(char*, int, int);
int shm_unlink(char*);
}

extern(C)
{

    enum
    {
        DT_UNKNOWN = 0,
        DT_FIFO = 1,
        DT_CHR = 2,
        DT_DIR = 4,
        DT_BLK = 6,
        DT_REG = 8,
        DT_LNK = 10,
        DT_SOCK = 12,
        DT_WHT = 14,
    }

    //struct dirent
    //{
    //    int d_ino;
    //    off_t d_off;
    //    ushort d_reclen;
    //    ubyte d_type;
    //    char[256] d_name;
    //}

    //struct DIR
    //{
    //    // Managed by OS.
    //}

    //DIR* opendir(char* name);             // use tango.stdc.posix.dirent
    //int closedir(DIR* dir);               // use tango.stdc.posix.dirent
    //dirent* readdir(DIR* dir);            // use tango.stdc.posix.dirent
    //void rewinddir(DIR* dir);             // use tango.stdc.posix.dirent
    //off_t telldir(DIR* dir);              // use tango.stdc.posix.dirent
    //void seekdir(DIR* dir, off_t offset); // use tango.stdc.posix.dirent
}


extern(C)
{
	private import tango.core.Intrinsic;


	int select(int nfds, fd_set* readfds, fd_set* writefds, fd_set* errorfds, timeval* timeout);
	//int fcntl(int s, int f, ...); // use tango.stdc.posix.fcntl

	/+
	enum
	{
		EINTR = 4,
		EINPROGRESS = 115,
	}
	+/


	const uint FD_SETSIZE = 1024;
	//const uint NFDBITS = 8 * int.sizeof; // DMD 0.110: 8 * (int).sizeof is not an expression
	const int NFDBITS = 32;


	struct fd_set
	{
		int[FD_SETSIZE / NFDBITS] fds_bits;
		alias fds_bits __fds_bits;
	}


	int FDELT(int d)
	{
		return d / NFDBITS;
	}


	int FDMASK(int d)
	{
		return 1 << (d % NFDBITS);
	}


	// Removes.
	void FD_CLR(int fd, fd_set* set)
	{
		btr(cast(uint*)&set.fds_bits.ptr[FDELT(fd)], cast(uint)(fd % NFDBITS));
	}


	// Tests.
	int FD_ISSET(int fd, fd_set* set)
	{
		return bt(cast(uint*)&set.fds_bits.ptr[FDELT(fd)], cast(uint)(fd % NFDBITS));
	}


	// Adds.
	void FD_SET(int fd, fd_set* set)
	{
		bts(cast(uint*)&set.fds_bits.ptr[FDELT(fd)], cast(uint)(fd % NFDBITS));
	}


	// Resets to zero.
	void FD_ZERO(fd_set* set)
	{
		set.fds_bits[] = 0;
	}
}

extern (C)
{
    /* From <dlfcn.h>
     * See http://www.opengroup.org/onlinepubs/007908799/xsh/dlsym.html
     */

    const int RTLD_NOW = 0x00002;	// Correct for Red Hat 8

    void* dlopen(char* file, int mode);
    int   dlclose(void* handle);
    void* dlsym(void* handle, char* name);
    char* dlerror();
}

extern (C)
{
    /* from <pwd.h>
     */

    struct passwd
    {
        char *pw_name;
        char *pw_passwd;
        uid_t pw_uid;
        gid_t pw_gid;
        char *pw_gecos;
        char *pw_dir;
        char *pw_shell;
    }

    int getpwnam_r(char*, passwd*, void*, size_t, passwd**);
}

version (linux)
{
	// From <sys/poll.h>: support for the UNIX poll() system call
	extern (C)
	{
		enum: short
		{
			// Event types that can be polled for. These bits may be set in `events'
			// to indicate the interesting event types; they will appear in `revents'
			// to indicate the status of the file descriptor.
			POLLIN      = 0x001,	// There is data to read.
			POLLPRI     = 0x002,	// There is urgent data to read.
			POLLOUT     = 0x004,	// Writing now will not block.

			// Event types always implicitly polled for. These bits need not be set in
			// `events', but they will appear in `revents' to indicate the status of
			// the file descriptor.
			POLLERR     = 0x008,	// Error condition.
			POLLHUP     = 0x010,	// Hung up.
			POLLNVAL    = 0x020		// Invalid polling request.
		}

		// Type used for the number of file descriptors.
		alias uint nfds_t;

		// Data structure describing a polling request.
		struct pollfd
		{
			int fd;					// File descriptor to poll.
			short events;			// Types of events poller cares about.
			short revents;			// Types of events that actually occurred.
		}

		// Poll the file descriptors described by the NFDS structures starting at
		// FDS. If TIMEOUT is nonzero and not -1, allow TIMEOUT milliseconds for
		// an event to occur; if TIMEOUT is -1, block until an event occurs.
		// Returns the number of file descriptors with events, zero if timed out,
		// or -1 for errors.
		int poll(pollfd* fds, nfds_t nfds, int timeout);
	}
}

version (linux)
{
	// From <sys/epoll.h>: support for the Linux epoll_*() system calls
	extern (C)
	{
		enum: uint
		{
			EPOLLIN         = 0x001,
			EPOLLPRI        = 0x002,
			EPOLLOUT        = 0x004,
			EPOLLRDNORM     = 0x040,
			EPOLLRDBAND     = 0x080,
			EPOLLWRNORM     = 0x100,
			EPOLLWRBAND     = 0x200,
			EPOLLMSG        = 0x400,
			EPOLLERR        = 0x008,
			EPOLLHUP        = 0x010,
			EPOLLONESHOT    = (1 << 30),
			EPOLLET         = (1 << 31)
		}

		// Valid opcodes ( "op" parameter ) to issue to epoll_ctl().
		public const int EPOLL_CTL_ADD = 1;	// Add a file descriptor to the interface.
		public const int EPOLL_CTL_DEL = 2;	// Remove a file descriptor from the interface.
		public const int EPOLL_CTL_MOD = 3;	// Change file descriptor epoll_event structure.

		union epoll_data
		{
			void* ptr;
			int fd;
			uint u32;
			ulong u64;
		}

		alias epoll_data epoll_data_t;

		struct epoll_event
		{
			uint events;		// Epoll events
			epoll_data_t data;	// User data variable
		}

		// Creates an epoll instance. Returns an fd for the new instance.
		// The "size" parameter is a hint specifying the number of file
		// descriptors to be associated with the new instance. The fd
		// returned by epoll_create() should be closed with close().
		int epoll_create(int size);

		// Manipulate an epoll instance "epfd". Returns 0 in case of success,
		// -1 in case of error (the "errno" variable will contain the
		// specific error code) The "op" parameter is one of the EPOLL_CTL_*
		// constants defined above. The "fd" parameter is the target of the
		// operation. The "event" parameter describes which events the caller
		// is interested in and any associated user data.
		int epoll_ctl(int epfd, int op, int fd, epoll_event* event);

		// Wait for events on an epoll instance "epfd". Returns the number of
		// triggered events returned in "events" buffer. Or -1 in case of
		// error with the "errno" variable set to the specific error code. The
		// "events" parameter is a buffer that will contain triggered
		// events. The "maxevents" is the maximum number of events to be
		// returned (usually size of "events"). The "timeout" parameter
		// specifies the maximum wait time in milliseconds (-1 == infinite).
		int epoll_wait(int epfd, epoll_event* events, int maxevents, int timeout);
	}
}



