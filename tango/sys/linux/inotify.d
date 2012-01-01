module tango.sys.linux.inotify;

version (linux)
{
    // From <sys/inotify.h>: support for the Linux inotify_* system calls
    extern (C)
    {
        struct inotify_event
        {
            int wd;         /* Watch descriptor.  */
            uint mask;      /* Watch mask.  */
            uint cookie;    /* Cookie to synchronize two events.  */
            uint len;       /* Length (including NULs) of name.  */
            /* char name[]; /* Name.  */
        }

        enum: uint
        {
            /* Supported events suitable for MASK parameter of INOTIFY_ADD_WATCH.  */
            IN_ACCESS           = 0x00000001,   /* File was accessed.  */
            IN_MODIFY           = 0x00000002,   /* File was modified.  */
            IN_ATTRIB           = 0x00000004,   /* Metadata changed.  */
            IN_CLOSE_WRITE      = 0x00000008,   /* Writtable file was closed.  */
            IN_CLOSE_NOWRITE    = 0x00000010,   /* Unwrittable file was closed.  */
            IN_CLOSE            = 0x00000018,   /* Close. */
            IN_OPEN             = 0x00000020,   /* File was opened.  */
            IN_MOVED_FROM       = 0x00000040,   /* File was moved from X.  */
            IN_MOVED_TO         = 0x00000080,   /* File was moved to Y.  */
            IN_MOVE             = 0x000000c0,   /* Moves.  */
            IN_CREATE           = 0x00000100,   /* Subfile was created.  */
            IN_DELETE           = 0x00000200,   /* Subfile was deleted.  */
            IN_DELETE_SELF      = 0x00000400,   /* Self was deleted.  */
            IN_MOVE_SELF        = 0x00000800,   /* Self was moved.  */
            
            /* Events sent by the kernel.  */
            IN_UMOUNT           = 0x00002000,   /* Backing fs was unmounted.  */
            IN_Q_OVERFLOW       = 0x00004000,   /* Event queued overflowed  */
            IN_IGNORED          = 0x00008000,   /* File was ignored  */
            
            /* Special flags.  */
            IN_ONLYDIR          = 0x01000000,   /* Only watch the path if it is a directory.  */
            IN_DONT_FOLLOW      = 0x02000000,   /* Do not follow a sym link.  */
            IN_MASK_ADD         = 0x20000000,   /* Add to the mask of an already existing watch.  */
            IN_ISDIR            = 0x40000000,   /* Event occurred against dir.  */
            IN_ONESHOT          = 0x80000000,   /* Only send event once.  */
            
            IN_ALL_EVENTS       = 0x00000fff,   /* All events which a program can wait on.  */
        }
        
        /* Create and initialize inotify instance.  */
        int inotify_init ();

        /* Add watch of object NAME to inotify instance FD.  Notify about events specified by MASK.  */
        int inotify_add_watch (int fd, char* name, uint mask);

        /* Remove the watch specified by WD from the inotify instance FD.  */
        int inotify_rm_watch (int fd, uint wd);
    }
}
