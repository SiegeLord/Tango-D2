/*******************************************************************************

        copyright:      Copyright (c) 2008 Jeff Davey. All rights reserved

        license:        BSD style: $(LICENSE)

        author:         Jeff Davey <j@submersion.com>

*******************************************************************************/

module tango.net.device.SSLSocket;

private import tango.net.util.PKI;

private import tango.net.device.Socket;

private import tango.net.device.Berkeley;

private import tango.net.util.c.OpenSSL;

/*******************************************************************************

    SSLSocket is a sub-class of Socket. It's purpose is to
    provide SSL encryption at the socket level as well as easily fit into
    existing Tango network applications that may already be using Socket.

    SSLSocket requires the OpenSSL library, and uses a dynamic binding
    to the library. You can find the library at http://www.openssl.org and a
    Win32 specific port at http://www.slproweb.com/products/Win32OpenSSL.html.

    SSLSockets have two modes:

    1. Client mode, useful for connecting to existing servers, but not
    accepting new connections. Accepting a new connection will cause
    the library to stall on a write on connection.

    2. Server mode, useful for creating an SSL server, but not connecting
    to an existing server. Connection will cause the library to stall on a
    read on connection.

    Example SSL client
    ---
    auto s = new SSLSocket;
    if (s.connect("www.yahoo.com", 443))
    {
        char[1024] buff;

        s.write("GET / HTTP/1.0\r\n\r\n");
        auto bytesRead = s.read(buff);
        if (bytesRead != s.Eof)
            Stdout.formatln("received: {}", buff[0..bytesRead]);
    }
    ---

*******************************************************************************/

class SSLSocket : Socket
{
    protected BIO *sslSocket = null;
    protected SSLCtx sslCtx = null;
/+
    private bool timeout;
    private SocketSet readSet;
    private SocketSet writeSet;
+/
    /*******************************************************************************

        Create a default Client Mode SSLSocket.

    *******************************************************************************/

    this (bool config = true)
    {
        super();

        if (config)
            setCtx (new SSLCtx, true);
    }

/+
    /*******************************************************************************

        Creates a Client Mode SSLSocket

        This is overriding the Socket ctor in order to emulate the
        existing free-list frameowrk.

        Specifying anything other than ProtocolType.TCP or SocketType.STREAM will
        cause an Exception to be thrown.

    *******************************************************************************/

    override this(SocketType type, ProtocolType protocol)
    {
        if (protocol != ProtocolType.TCP)
            throw new Exception("SSL is only supported over TCP.");
        if (type != SocketType.STREAM)
            throw new Exception("SSL is only supporting with streaming types.");
        super(AddressFamily.INET, type, protocol); // hardcoding this to INET for now
        //if (create)
        {
            sslCtx = new SSLCtx();
            sslSocket = _convertToSSL(sslCtx, false, true);
        }
    }

    /*******************************************************************************

        Creates a SSLSocket

        This class allows the ability to turn a regular Socket into an
        SSLSocket. It also gives the ability to change an SSLSocket
        into Server Mode or ClientMode.

        Params:
            sock = The socket to wrap in SSL
            SSLCtx = the SSL Context as provided by the PKI layer.
            clientMode = if true the socket will be Client Mode, Server otherwise.

    *******************************************************************************/


    this(Socket sock, SSLCtx ctx, bool clientMode = true)
    {
        super(AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP, false); // hardcoding to inet now
        socket_ = sock;
        sslCtx = ctx;
        sslSocket = _convertToSSL(sslCtx, false, clientMode);
    }

    ~this()
    {
        if (sslSocket)
        {
            BIO_reset(sslSocket);
            BIO_free_all(sslSocket);
            sslSocket = null;
        }
    }
+/

    /*******************************************************************************

        Release this SSLSocket.

        As per Socket.detach.

    *******************************************************************************/

    override void detach()
    {
        if (sslSocket)
        {
            BIO_reset(sslSocket);
            BIO_free_all(sslSocket);
            sslSocket = null;
        }
        super.detach();
    }

    /*******************************************************************************

        Writes the passed buffer to the underlying socket stream. This will
        block until socket error.

        As per Socket.write

    *******************************************************************************/

    override size_t write(const(void)[] src)
    {
        if (src.length is 0)
            return 0;

        int bytes = BIO_write(sslSocket, cast(void*)src.ptr, cast(uint)src.length);
        if (bytes <= 0)
            return Eof;
        return cast(size_t) bytes;
    }

    /*******************************************************************************

         Reads from the underlying socket stream. If needed, setTimeout will
        set the max length of time the read will take before returning.

        As per Socket.read

    *******************************************************************************/


    override size_t read(void[] dst)
    {
/+
        timeout = false;
        if (tv.tv_usec | tv.tv_sec)
        {
            size_t rtn = Eof;
            // need to switch to nonblocking...
            bool blocking = socket_.blocking;
            if (blocking) socket_.blocking = false;
            do
            {
                int bytesRead = BIO_read(sslSocket, dst.ptr, dst.length);
                if (bytesRead <= 0)
                {
                    bool read = false;
                    bool write = false;
                    if (!BIO_should_retry(sslSocket))
                        break;
                    if (BIO_should_read(sslSocket))
                        read = true;
                    if (BIO_should_write(sslSocket))
                        write = true;
                    if (read || write)
                    {
                        if (read)
                        {
                            if (readSet is null)
                                readSet = new SocketSet(1);
                            readSet.reset();
                            readSet.add(socket_);
                        }
                        if (write)
                        {
                            if (writeSet is null)
                                writeSet = new SocketSet(1);
                            writeSet.reset();
                            writeSet.add(socket_);
                        }
                        auto copy = tv;
                        int i = socket_.select(read ? readSet : null, write ? writeSet : null, null, &copy);
                        if (i <= 0)
                        {
                            if (i is 0)
                                timeout = true;
                            break;
                        }
                    }
                    else if (BIO_should_io_special(sslSocket)) // wasn't write, wasn't read.. something "special" just wait for the socket to become ready...
                        Thread.sleep(.05);
                    else
                        break;
                }
                else
                {
                    rtn = bytesRead;
                    break;
                }
            } while(BIO_should_retry(sslSocket));
            if (blocking) socket_.blocking = blocking;
            return rtn;
        }
+/
        int bytes = BIO_read(sslSocket, dst.ptr, cast(uint)dst.length);
        if (bytes <= 0)
            return Eof;
        return cast(size_t) bytes;
    }

    /*******************************************************************************

        Shuts down the underlying socket for reading and writing.

        As per Socket.shutdown

    *******************************************************************************/

    override SSLSocket shutdown()
    {
        SSL *obj;
        BIO_get_ssl(sslSocket, &obj);
        if (obj)
        {
            if (!SSL_get_shutdown)
                SSL_set_shutdown(obj, SSL_SENT_SHUTDOWN | SSL_RECEIVED_SHUTDOWN);
        }
        return this;
    }

    /*******************************************************************************

        Used in conjuction with the above ctor with the create flag disabled. It is
        useful for accepting a new socket into a SSLSocket, and then re-using
        the Server's existing SSLCtx.

        Params:
            ctx = SSLCtx class as provided by PKI
            clientMode = if true, the socket will be in Client Mode, Server otherwise.

    *******************************************************************************/


    void setCtx(SSLCtx ctx, bool clientMode = true)
    {
        sslCtx = ctx;
        sslSocket = _convertToSSL(sslCtx, false, clientMode);
    }

    /*
        Converts an existing socket (should be TCP) to an "SSL" socket
        close = close the socket when finished -- should probably be false usually
        client = if true, "client-mode" if false "server-mode"
    */
    private BIO *_convertToSSL(SSLCtx sslCtx, bool close, bool client)
    {
        BIO *rtn = null;

        BIO *socketBio = BIO_new_socket(native.handle, close ? BIO_CLOSE : BIO_NOCLOSE);
        if (socketBio)
        {
            rtn = BIO_new_ssl(sslCtx.native, client);
            if (rtn)
                rtn = BIO_push(rtn, socketBio);
            if (!rtn)
                BIO_free_all(socketBio);
        }

        if (rtn is null)
            throwOpenSSLError();
        return rtn;
    }
}


/*******************************************************************************

    SSLServerSocket is a sub-class of ServerSocket. It's purpose is to provide
    SSL encryption at the socket level as well as easily tie into existing
    Tango applications that may already be using ServerSocket.

    SSLServerSocket requires the OpenSSL library, and uses a dynamic binding
    to the library. You can find the library at http://www.openssl.org and a
    Win32 specific port at http://www.slproweb.com/products/Win32OpenSSL.html.

    Example SSL server
    ---
    auto cert = new Certificate(cast(char[])File.get("public.pem"));
    auto pkey = new PrivateKey(cast(char[])File.get("private.pem"));
    auto ctx = new SSLCtx;
    ctx.certificate(cert).privateKey(pkey);
    auto server = new SSLServerSocket(443, ctx);
    for(;;)
    {
        auto sc = server.accept;
        sc.write("HTTP/1.1 200\r\n\r\n<b>Hello World</b>");
        sc.shutdown.close;
    }
    ---

*******************************************************************************/

class SSLServerSocket : ServerSocket
{
    private SSLCtx sslCtx;

    /*******************************************************************************

    *******************************************************************************/

    this (ushort port, SSLCtx ctx, int backlog=32, bool reuse=false)
    {
        scope addr = new IPv4Address (port);
        this (addr, ctx, backlog, reuse);
    }

    /*******************************************************************************

        Constructs a new SSLServerSocket. This constructor is similar to
        ServerSocket, except it takes a SSLCtx as provided by PKI.

        Params:
            addr = the address to bind and listen on.
            ctx = the provided SSLCtx
            backlog = the number of connections to backlog before refusing connection
            reuse = if enabled, allow rebinding of existing ip/port

    *******************************************************************************/

    this(Address addr, SSLCtx ctx, int backlog=32, bool reuse=false)
    {
        super(addr, backlog, reuse);
        sslCtx = ctx;
    }

    alias ServerSocket.accept accept;

    /*******************************************************************************

      Accepts a new connection and copies the provided server SSLCtx to a new
      SSLSocket.

    *******************************************************************************/

    SSLSocket accept (SSLSocket recipient = null)
    {
        if (recipient is null)
            recipient = new SSLSocket(false);

        super.accept (recipient);
        recipient.setCtx(sslCtx, false);
        return recipient;
    }
}





version(Test)
{
    import tetra.util.Test;
    import tango.io.Stdout;
    import tango.io.device.File;
    import tango.io.FilePath;
    import tango.core.Thread;
    import tango.stdc.stringz;

    extern (C)
    {
        int blah(int booger, void *x)
        {
            return 1;
        }
    }


    unittest
    {
        auto t2 = 1.0;
        loadOpenSSL();
        Test.Status sslCTXTest(ref char[][] messages)
        {
            auto s1 = new SSLSocket();
            if (s1)
            {
                bool good = false;
                try
                    auto s2 = new SSLSocket(SocketType.STREAM,  ProtocolType.UDP);
                catch (Exception e)
                    good = true;

                if (good)
                {
                    Socket mySock = new Socket(AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP);
                    if (mySock)
                    {
                        Certificate publicCertificate;
                        PrivateKey privateKey;
                        try
                        {
                            publicCertificate = new Certificate(cast(char[])File.get ("public.pem"));
                            privateKey = new PrivateKey(cast(char[])File.get ("private.pem"));
                        }
                        catch (Exception ex)
                        {
                            privateKey = new PrivateKey(2048);
                            publicCertificate = new Certificate();
                            publicCertificate.privateKey(privateKey).serialNumber(123).dateBeforeOffset(t1).dateAfterOffset(t2);
                            publicCertificate.setSubject("CA", "Alberta", "Place", "None", "First Last", "no unit", "email@example.com").sign(publicCertificate, privateKey);
                        }
                        auto sslCtx = new SSLCtx();
                        sslCtx.certificate(publicCertificate).privateKey(privateKey).checkKey();
                        auto s3 = new SSLSocket(mySock, sslCtx);
                        if (s3)
                            return Test.Status.Success;
                    }
                }
            }
            return Test.Status.Failure;
        }

        Test.Status sslReadWriteTest(ref char[][] messages)
        {
            auto s1 = new SSLSocket();
            auto address = new IPv4Address("209.20.65.224", 443);
            if (s1.connect(address))
            {
                char[] command = "GET /result.txt\r\n";
                s1.write(command);
                char[1024] result;
                uint bytesRead = s1.read(result);
                if (bytesRead > 0 && bytesRead != Eof && (result[0 .. bytesRead] == "I got results!\n"))
                    return Test.Status.Success;
                else
                    messages ~= Stdout.layout()("Received wrong results: (bytesRead: {}), (result: {})", bytesRead, result[0..bytesRead]);
            }
            return Test.Status.Failure;
        }

        Test.Status sslReadWriteTestWithTimeout(ref char[][] messages)
        {
            auto s1 = new SSLSocket();
            auto address = new IPv4Address("209.20.65.224", 443);
            if (s1.connect(address))
            {
                char[] command = "GET /result.txt HTTP/1.1\r\nHost: submersion.com\r\n\r\n";
                s1.write(command);
                char[1024] result;
                uint bytesRead = s1.read(result);
                char[] expectedResult = "HTTP/1.1 200 OK";
                if (bytesRead > 0 && bytesRead != Eof && (result[0 .. expectedResult.length] == expectedResult))
                {
                    s1.setTimeout(t2);
                    while (bytesRead != s1.Eof)
                        bytesRead = s1.read(result);
                    if (s1.hadTimeout)
                        return Test.Status.Success;
                    else
                        messages ~= Stdout.layout()("Did not get timeout on read: {}", bytesRead);
                }
                else
                    messages ~= Stdout.layout()("Received wrong results: (bytesRead: {}), (result: {})", bytesRead, result[0..bytesRead]);
            }
            return Test.Status.Failure;
        }

        auto t = new Test("tetra.net.SSLSocket");
        t["SSL_CTX"] = &sslCTXTest;
        t["Read/Write"] = &sslReadWriteTest;
        t["Read/Write Timeout"] = &sslReadWriteTestWithTimeout;
        t.run();
    }
}
