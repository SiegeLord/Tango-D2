module tango.stdc.posix.sys.poll;

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
