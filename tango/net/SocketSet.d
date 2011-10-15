/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved
        license:        BSD style: $(LICENSE)
        version:        Aug 2011: Druntime ready for D2
        author:         Kris

*******************************************************************************/

module tango.net.SocketSet;

private import core.sys.posix.sys.select;
private import core.sys.posix.sys.time;

private import tango.io.model.ISelectable;
private import tango.net.Socket;

/*******************************************************************************

        a set of sockets for Socket.select()

*******************************************************************************/

public class SocketSet
{
        private size_t nbytes; //Win32: excludes uint.size "count"
        private byte* buf;

        version(Windows)
        {
                uint count()
                {
                        return *(cast(uint*)buf);
                }

                void count(int setter)
                {
                        *(cast(uint*)buf) = setter;
                }


                socket_t* first()
                {
                        return cast(socket_t*)(buf + uint.sizeof);
                }
        }
        else version (Posix)
        {
                private import core.bitop;

                size_t nfdbits;
                socket_t _maxfd = 0;

                size_t fdelt(socket_t s)
                {
                        return cast(size_t)s / nfdbits;
                }


                size_t fdmask(socket_t s)
                {
                        return 1 << cast(size_t)s % nfdbits;
                }


                size_t* first()
                {
                        return cast(size_t*)buf;
                }

                public socket_t maxfd()
                {
                        return _maxfd;
                }
        }


        public:

        this (uint max)
        {
                version(Win32)
                {
                        nbytes = max * socket_t.sizeof;
                        buf = (new byte[nbytes + uint.sizeof]).ptr;
                        count = 0;
                }
                else version (Posix)
                {
                        if (max <= 32)
                            nbytes = 32 * uint.sizeof;
                        else
                            nbytes = max * uint.sizeof;

                        buf = (new byte[nbytes]).ptr;
                        nfdbits = nbytes * 8;
                        //clear(); //new initializes to 0
                }
                else
                {
                        static assert(0);
                }
        }

        this (SocketSet o) 
        {
                nbytes = o.nbytes;
                auto size = nbytes;
                version (Win32) 
                         size += uint.sizeof;

                version (Posix) 
                        {
                        nfdbits = o.nfdbits;
                        _maxfd = o._maxfd;
                        }
                
                auto b = new byte[size];
                b[] = o.buf[0..size];
                buf = b.ptr;
        }

        this()
        {
                version(Win32)
                {
                        this(64);
                }
                else version (Posix)
                {
                        this(32);
                }
                else
                {
                        static assert(0);
                }
        }

        SocketSet dup() 
        {
                return new SocketSet (this);
        }
        
        SocketSet reset()
        {
                version(Win32)
                {
                        count = 0;
                }
                else version (Posix)
                {
                        buf[0 .. nbytes] = 0;
                        _maxfd = 0;
                }
                else
                {
                        static assert(0);
                }
                return this;
        }

        void add(socket_t s)
        in
        {
                version(Win32)
                {
                        assert(count < max); //added too many sockets; specify a higher max in the constructor
                }
        }
        body
        {
                version(Win32)
                {
                        uint c = count;
                        first[c] = s;
                        count = c + 1;
                }
                else version (Posix)
                {
                        if (s > _maxfd)
                                _maxfd = s;

                        bts(cast(size_t*)&first[fdelt(s)], cast(size_t)s % nfdbits);
                }
                else
                {
                        static assert(0);
                }
        }

        void add(ISelectable selectable)
        {
                add(cast(socket_t)selectable.handle);
        }

        void remove(socket_t s)
        {
                version(Win32)
                {
                        uint c = count;
                        socket_t* start = first;
                        socket_t* stop = start + c;

                        for(; start != stop; start++)
                        {
                                if(*start == s)
                                        goto found;
                        }
                        return; //not found

                        found:
                        for(++start; start != stop; start++)
                        {
                                *(start - 1) = *start;
                        }

                        count = c - 1;
                }
                else version (Posix)
                {
                        btr(cast(size_t*)&first[fdelt(s)], cast(size_t)s % nfdbits);

                        // If we're removing the biggest file descriptor we've
                        // entered so far we need to recalculate this value
                        // for the socket set.
                        if (s == _maxfd)
                        {
                                while (--_maxfd >= 0)
                                {
                                        if (isSet(_maxfd))
                                        {
                                                break;
                                        }
                                }
                        }
                }
                else
                {
                        static assert(0);
                }
        }

        void remove(ISelectable selectable)
        {
                remove(cast(socket_t)selectable.handle);
        }

        size_t isSet(socket_t s)
        {
                version(Win32)
                {
                        socket_t* start = first;
                        socket_t* stop = start + count;

                        for(; start != stop; start++)
                        {
                                if(*start == s)
                                        return true;
                        }
                        return false;
                }
                else version (Posix)
                {
                        //return bt(cast(uint*)&first[fdelt(s)], cast(uint)s % nfdbits);
                        size_t index = cast(size_t)s % nfdbits;
                        return (cast(size_t*)&first[fdelt(s)])[index / (uint.sizeof*8)] & (1 << (index & ((uint.sizeof*8) - 1)));
                }
                else
                {
                        static assert(0);
                }
        }

        size_t isSet(ISelectable selectable)
        {
                return isSet(cast(socket_t)selectable.handle);
        }

        size_t max()
        {
                return nbytes / socket_t.sizeof;
        }

        fd_set* toFd_set()
        {
                return cast(fd_set*)buf;
        }
}
