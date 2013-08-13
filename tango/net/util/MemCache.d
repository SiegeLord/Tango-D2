/*******************************************************************************

        copyright:      Copyright (c) 2005 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Mar 2005: Initial release

        author:         Kris

*******************************************************************************/

module tango.net.util.MemCache;

private import  tango.io.Console;

private import  Thr = tango.core.Thread, /* Because the druntime folks in their infinite wisdom decided to publically import core.time in thread */
                tango.core.Exception,
                tango.core.Time;

private import  tango.io.stream.Lines,
                tango.io.stream.Buffered;

private import  tango.net.device.Socket,
                tango.net.InternetAddress;

private import  Integer = tango.text.convert.Integer;


/******************************************************************************

******************************************************************************/

class MemCache : Thr.Thread
{
        private shared(Connection)[] hosts;
        private bool            active;
        private uint            watchdog;

        /**********************************************************************

        **********************************************************************/

        this (const(char[])[] hosts, uint watchdog = 3)
        {
                super (&run);
                setHosts (hosts);

                // save configuration
                this.watchdog = watchdog;

                // start the watchdog
                active = true;
                super.start();
        }

        /**********************************************************************

        **********************************************************************/

        final void close ()
        {
                if (hosts)
                   {
                   foreach (shared Connection server; hosts)
                            server.close();
                   hosts = null;
                   }
        }

        /**********************************************************************

                Store the key and value

        **********************************************************************/

        final bool set (const(void)[][] key, const(void)[][] value, int flags=0, int timeout=0)
        {
                return select(key).put("set", key, value, flags, timeout);
        }

        /**********************************************************************

                Store the value if key does not already exist

        **********************************************************************/

        final bool add (const(void)[][] key, const(void)[][] value, int flags=0, int timeout=0)
        {
                return select(key).put("add", key, value, flags, timeout);
        }

        /**********************************************************************

                Store the value only if key exists

        **********************************************************************/

        final bool replace (const(void)[][] key, const(void)[][] value, int flags=0, int timeout=0)
        {
                return select(key).put("replace", key, value, flags, timeout);
        }

        /**********************************************************************

                Remove the specified key and make key "invalid" for the
                duration of timeout, causing add(), get() and remove() on
                the same key to fail within that period

        **********************************************************************/

        final bool remove (const(void)[][] key, int timeout=0)
        {
                return select(key).remove(key, timeout);
        }

        /**********************************************************************

                VALUE <key> <flags> <bytes>\r\n
                <data block>\r\n

        **********************************************************************/

        final bool get (const(void)[][] key, Buffer buffer)
        {
                return select(key).get(key, buffer);
        }

        /**********************************************************************

        **********************************************************************/

        final bool incr (const(void)[][] key, uint value)
        {
                uint result;
                return incr (key, value, result);
        }

        /**********************************************************************

        **********************************************************************/

        final bool decr (const(void)[][] key, uint value)
        {
                uint result;
                return decr (key, value, result);
        }

        /**********************************************************************

        **********************************************************************/

        final bool incr (const(void)[][] key, uint value, ref uint result)
        {
                return select(key).bump ("incr", key, value, result);
        }

        /**********************************************************************

        **********************************************************************/

        final bool decr (const(void)[][] key, uint value, ref uint result)
        {
                return select(key).bump ("decr", key, value, result);
        }

        /**********************************************************************

        **********************************************************************/

        final void status (void delegate (const(char)[], const(char[])[] list) dg)
        {
                foreach (shared Connection server; hosts)
                         server.status (dg);
        }

        /**********************************************************************

        **********************************************************************/

        final Buffer buffer (uint size)
        {
                return new Buffer (size);
        }

        /**********************************************************************

        **********************************************************************/

        final void setHosts (const(char[])[] hosts)
        {
                auto conn = new shared(Connection) [hosts.length];

                foreach (int i, const(char)[] host; hosts)
                         conn[i] = cast(shared) new Connection(host);

                // set new list of connections
                this.hosts = conn;
                connect (conn);
        }

        /**********************************************************************

                Connection watchdog thread

        **********************************************************************/

        private void run ()
        {
                while (active)
                       try {
                           Thr.Thread.sleep (seconds(watchdog));
                           debug(TangoMemCache) Cout ("testing connections ...").newline;
                           connect (hosts);
                           } catch (Exception e)
                                    debug(TangoMemCache) Cout ("memcache watchdog: ") (e.toString).newline;
        }

        /**********************************************************************

        **********************************************************************/

        private shared(Connection) select (const(void)[][] key)
        {
                return hosts[jhash(key) % hosts.length];
        }

        /**********************************************************************

        **********************************************************************/

        private void connect (shared(Connection)[] hosts)
        {
                foreach (Connection c; cast(Connection[])hosts)
                         c.connect();
        }

        /**********************************************************************

        **********************************************************************/

        static class Buffer
        {
                private size_t    extent;
                private void[]  content;

                /**************************************************************

                **************************************************************/

                private this (size_t size)
                {
                        this.content = new byte [size];
                }

                /**************************************************************

                **************************************************************/

                bool expand (size_t size)
                {
                        if (size > content.length)
                            content.length = size;
                        return true;
                }

                /**************************************************************

                **************************************************************/

                void[] set (size_t size)
                {
                        extent = size;
                        return get();
                }

                /**************************************************************

                **************************************************************/

                void[] get ()
                {
                        return content [0..extent];
                }
        }

	/**********************************************************************

	        jhash() -- hash a variable-length key into a 32-bit value

	          k     : the key (the unaligned variable-length array of bytes)
	          len   : the length of the key, counting by bytes
	          level : can be any 4-byte value

	        Returns a 32-bit value.  Every bit of the key affects every bit of
	        the return value.  Every 1-bit and 2-bit delta achieves avalanche.

	        About 4.3*len + 80 X86 instructions, with excellent pipelining

	        The best hash table sizes are powers of 2.  There is no need to do
	        mod a prime (mod is sooo slow!).  If you need less than 32 bits,
	        use a bitmask.  For example, if you need only 10 bits, do

	                    h = (h & hashmask(10));

	        In which case, the hash table should have hashsize(10) elements.
	        If you are hashing n strings (ub1 **)k, do it like this:

	                    for (i=0, h=0; i<n; ++i) h = hash( k[i], len[i], h);

	        By Bob Jenkins, 1996.  bob_jenkins@burtleburtle.net.  You may use
	        this code any way you wish, private, educational, or commercial.
	        It's free.

	        See http://burlteburtle.net/bob/hash/evahash.html
	        Use for hash table lookup, or anything where one collision in 2^32
	        is acceptable. Do NOT use for cryptographic purposes.

	**********************************************************************/

	static final uint jhash (const(void)[][] x, uint c = 0)
	{
	        uint    a,
	                b;

	        a = b = 0x9e3779b9;

            auto len = x.length;
	        ubyte* k = cast(ubyte *) x.ptr;

	        // handle most of the key
	        while (len >= 12)
	              {
	              a += *cast(uint *)(k+0);
	              b += *cast(uint *)(k+4);
	              c += *cast(uint *)(k+8);

	              a -= b; a -= c; a ^= (c>>13);
	              b -= c; b -= a; b ^= (a<<8);
	              c -= a; c -= b; c ^= (b>>13);
	              a -= b; a -= c; a ^= (c>>12);
	              b -= c; b -= a; b ^= (a<<16);
	              c -= a; c -= b; c ^= (b>>5);
	              a -= b; a -= c; a ^= (c>>3);
	              b -= c; b -= a; b ^= (a<<10);
	              c -= a; c -= b; c ^= (b>>15);
	              k += 12; len -= 12;
	              }

	        // handle the last 11 bytes
	        c += x.length;
	        switch (len)
	               {
	               case 11: c += (cast(uint)k[10]<<24); goto case;
	               case 10: c += (cast(uint)k[9]<<16); goto case;
	               case 9 : c += (cast(uint)k[8]<<8); goto case;
	               case 8 : b += (cast(uint)k[7]<<24); goto case;
	               case 7 : b += (cast(uint)k[6]<<16); goto case;
	               case 6 : b += (cast(uint)k[5]<<8); goto case;
	               case 5 : b += k[4]; goto case;
	               case 4 : a += (cast(uint)k[3]<<24); goto case;
	               case 3 : a += (cast(uint)k[2]<<16); goto case;
	               case 2 : a += (cast(uint)k[1]<<8); goto case;
	               case 1 : a += k[0]; break;
	               default:
	               }

	        a -= b; a -= c; a ^= (c>>13);
	        b -= c; b -= a; b ^= (a<<8);
	        c -= a; c -= b; c ^= (b>>13);
	        a -= b; a -= c; a ^= (c>>12);
	        b -= c; b -= a; b ^= (a<<16);
	        c -= a; c -= b; c ^= (b>>5);
	        a -= b; a -= c; a ^= (c>>3);
	        b -= c; b -= a; b ^= (a<<10);
	        c -= a; c -= b; c ^= (b>>15);

	        return c;
	}
}


/******************************************************************************

******************************************************************************/

private class Connection
{
        private alias Lines!(char) Line;

        private const(char)[]          host;           // original host address
        private __gshared Line         line;           // reading lines from server
        private __gshared Bin          input;          // input stream
        private __gshared Bout         output;         // output stream
        private __gshared Socket       conduit;        // socket to server
        private InternetAddress address;        // where server is listening
        private bool            connected;      // currently connected?

        /**********************************************************************

        **********************************************************************/

        this (const(char)[] host)
        {
                this.host = host;
                conduit = new Socket;
                output = new Bout (conduit);
                input = new Bin (conduit);
                line = new Line (input);
                address = new InternetAddress (host);
        }

        /**********************************************************************

        **********************************************************************/

        private void connect ()
        {
                if (! connected)
                      try {
                          conduit.connect (address);
                          connected = true;
                          debug(TangoMemCache) Cout ("connected to ") (host).newline;
                          } catch (Throwable th)
                                   debug(TangoMemCache) Cout ("failed to connect to ")(host).newline;
        }

        /**********************************************************************

        **********************************************************************/

        private synchronized void close ()
        {
                bool alive = connected;
                connected = false;

                if (alive)
                    conduit.close();
        }

        /**********************************************************************

        **********************************************************************/

        private synchronized void error ()
        {
                // close this dead socket
                close();

                // open another one for next attempt to connect
                conduit.socket.reopen();
        }

        /**********************************************************************

        **********************************************************************/

        private synchronized bool put (const(char)[] cmd, const(void)[][] key, const(void)[][] value, int flags, int timeout)
        {
                if (connected)
                    try {
                        char[16] tmp;

                        output.clear();
                        output.append ("delete ")
                              .append (key)
                              .append (" ")
                              .append (Integer.format (tmp, timeout))
                              .append ("\r\n")
                              .flush();

                        if (line.next)
                            return line.get() == "DELETED";
                        } catch (IOException e)
                                 error();
                return false;
        }

        /**********************************************************************

                VALUE <key> <flags> <bytes>\r\n
                <data block>\r\n

        **********************************************************************/

        private synchronized bool get (const(void)[][] key, MemCache.Buffer buffer)
        {
                if (connected)
                    try {
                        output.clear();
                        output.append ("get ")
                              .append (key)
                              .append ("\r\n")
                              .flush();

                        if (line.next)
                           {
                           const(char)[] content = line.get();
                           if (content.length > 4 && content[0..5] == "VALUE")
                              {
                              size_t i = 0;

                              // parse the incoming content-length
                              for (i=content.length; content[--i] != ' ';)
                                  {}
                              i = cast(size_t) Integer.parse (content[i .. $]);

                              // ensure output buffer has enough space
                              buffer.expand (i);
                              void[] dst = buffer.set (i);

                              // fill the buffer content
                              if (! input.fill (dst))
                                    return false;

                              // eat the CR and test terminator
                              line.next;
                              line.next;
                              return line.get() == "END";
                              }
                           }
                        } catch (IOException e)
                                 error();
                return false;
        }

        /**********************************************************************

                Remove the specified key and make key "invalid" for the
                duration of timeout, causing add(), get() and remove() on
                the same key to fail within that period

        **********************************************************************/

        private synchronized bool remove (const(void)[][] key, int timeout=0)
        {
                if (connected)
                    try {
                        char[16] tmp;

                        output.clear();
                        output.append ("delete ")
                              .append (key)
                              .append (" ")
                              .append (Integer.format (tmp, timeout))
                              .append ("\r\n")
                              .flush();

                        if (line.next)
                            return line.get() == "DELETED";
                        } catch (IOException e)
                                 error();
                return false;
        }

        /**********************************************************************

        **********************************************************************/

        private synchronized bool bump (const(char)[] cmd, const(void)[][] key, uint value,
                                        ref uint result)
        {
                if (connected)
                    try {
                        char[16] tmp;

                        output.clear();
                        output.append (cmd)
                              .append (" ")
                              .append (key)
                              .append (" ")
                              .append (Integer.format (tmp, value))
                              .append ("\r\n")
                              .flush();

                        if (line.next)
                            if (line.get() != "NOT_FOUND")
                               {
                               result = cast(uint)Integer.parse (line.get());
                               return true;
                               }
                        } catch (IOException e)
                                 error();
                return false;
        }

        /**********************************************************************

        **********************************************************************/

        private synchronized void status (scope void delegate (const(char)[], const(char[])[] list) dg)
        {
                if (connected)
                    try {
                        const(char[])[] list;

                        output.clear();
                        output.write ("stats\r\n");

                        while (line.next)
                               if (line.get() == "END")
                                  {
                                  dg (cast(char[])host, list);
                                      break;
                                  }
                               else
                                  list ~= line.get();

                        } catch (IOException e)
                                 error();
        }

}


debug (TangoMemCache)
{
/******************************************************************************

******************************************************************************/

void main()
{
        __gshared const(char[])[] hosts = ["192.168.111.224:11211"];

        auto cache = new MemCache (hosts);

        cache.set ("foo", "bar");
        cache.set ("foo", "wumpus");

        auto buffer = cache.buffer (1024);
        if (cache.get ("foo", buffer))
            Cout ("value: ") (cast(const(char)[]) buffer.get).newline;

        void stat (const(char)[] host, const(char[])[] list)
        {
                foreach (const(char)[] line; list)
                         Cout (host) (" ") (line).newline;
        }

        while (true)
              {
              cache.status (&stat);
              Thr.Thread.sleep (seconds(1.0));
              }
        Cout ("exiting");
}
}

