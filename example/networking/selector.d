/*******************************************************************************
  copyright:   Copyright (c) 2006 Juan Jose Comellas. All rights reserved
  license:     BSD style: $(LICENSE)
  author:      Juan Jose Comellas <juanjo@comellas.com.ar>
*******************************************************************************/

private
{
    version (Posix)
    {
        import tango.io.selector.PollSelector;
    }
    else version (linux)
    {
        import tango.io.selector.EpollSelector;
        import tango.sys.linux.linux;
    }

    import tango.io.selector.model.ISelector;
    import tango.io.selector.Selector;
    import tango.io.selector.SelectSelector;
    import tango.io.selector.SelectorException;
    import tango.io.Conduit;
    import tango.io.Stdout;
    import tango.net.Socket;
    import tango.net.SocketConduit;
    import tango.net.ServerSocket;
    import tango.core.Exception;
    import tango.core.Thread;
    import tango.sys.Common;
    import tango.sys.TimeConverter;
    import tango.stdc.errno;
}


const uint      HANDLE_COUNT    = 4;
const uint      EVENT_COUNT     = 4;
const uint      LOOP_COUNT      = 50000;
const char[]    SERVER_ADDR     = "127.0.0.1";
const ushort    SERVER_PORT     = 4000;
const uint      MAX_LENGTH      = 16;

int main(char[][] args)
{
    ISelector selector;

    for (int i = 0; i < 5; i++)
    {
        // Testing the SelectSelector
        Stdout.formatln("* Pass {0}: Testing the select-based selector", i + 1);
        selector = new SelectSelector();
        testSelector(selector);
    }

    // Testing the PollSelector
    version (Posix)
    {
        for (int i = 0; i < 5; i++)
        {
            Stdout.formatln("* Pass {0}: Testing the poll-based selector", i + 1);
            selector = new PollSelector();
            testSelector(selector);
        }
    }

    // Testing the EpollSelector
    version (linux)
    {
        for (int i = 0; i < 5; i++)
        {
            Stdout.formatln("* Pass {0}: Testing the epoll-based selector", i + 1);
            selector = new EpollSelector();
            testSelector(selector);
        }
    }

    return 0;
}


/**
 * Create a server socket and run the Selector on it.
 */
void testSelector(ISelector selector)
{
    uint        connectCount        = 0;
    uint        receiveCount        = 0;
    uint        sendCount           = 0;
    uint        failedConnectCount  = 0;
    uint        failedReceiveCount  = 0;
    uint        failedSendCount     = 0;
    uint        closeCount          = 0;
    uint        errorCount          = 0;
    Interval    start               = currentTime();
    Thread      clientThread;

    selector.open(HANDLE_COUNT, EVENT_COUNT);

    clientThread = new Thread(&clientThreadFunc);
    clientThread.start();

    try
    {
        Interval            timeout         = cast(Interval) (Interval.second * 1); // 1 sec
        InternetAddress     addr            = new InternetAddress(SERVER_ADDR, SERVER_PORT);
        ServerSocket        serverSocket    = new ServerSocket(addr, 5);
        SocketConduit       clientSocket;
        char[MAX_LENGTH]    buffer;
        int                 eventCount;
        uint                count;
        int                 i = 0;

        debug (selector)
            Stdout.println("[SRV] Registering server socket to Selector");
        selector.register(serverSocket, Event.Read);

        while (true)
        {
            debug (selector)
                Stdout.formatln("[SRV][{0}] Waiting for events from Selector", i);

            eventCount = selector.select(timeout);

            debug (selector)
                Stdout.formatln("[SRV][{0}] {1} events received from Selector", i, eventCount);

            if (eventCount > 0)
            {
                foreach (SelectionKey selectionKey; selector.selectedSet())
                {
                    debug (selector)
                        Stdout.formatln("[SRV][{0}] Event mask for socket {1} is 0x{2:x4}",
                                        i, cast(int) selectionKey.conduit.fileHandle(),
                                        cast(uint) selectionKey.events);

                    if (selectionKey.isReadable())
                    {
                        if (selectionKey.conduit is serverSocket)
                        {
                            debug (selector)
                                Stdout.formatln("[SRV][{0}] New connection from client", i);

                            clientSocket = serverSocket.accept();
                            if (clientSocket !is null)
                            {
                                selector.register(clientSocket, Event.Read);
                                connectCount++;
                            }
                            else
                            {
                                debug (selector)
                                    Stdout.formatln("[SRV][{0}] New connection attempt failed", i);
                                failedConnectCount++;
                            }
                        }
                        else
                        {
                            // Reading from a client socket
                            debug (selector)
                                Stdout.formatln("[SRV][{0}] Receiving message from client", i);

                            count = (cast(SocketConduit) selectionKey.conduit).read(buffer);
                            if (count != IConduit.Eof)
                            {
                                debug (selector)
                                    Stdout.formatln("[SRV][{0}] Received {1} from client ({2} bytes)",
                                                    i, buffer[0..count], count);
                                selector.reregister(selectionKey.conduit, Event.Write);
                                receiveCount++;
                            }
                            else
                            {
                                debug (selector)
                                    Stdout.formatln("[SRV][{0}] Handle {1} was closed; removing it from Selector",
                                                    i, cast(int) selectionKey.conduit.fileHandle());
                                selector.unregister(selectionKey.conduit);
                                (cast(SocketConduit) selectionKey.conduit).close();
                                failedReceiveCount++;
                                continue;
                            }
                        }
                    }

                    if (selectionKey.isWritable())
                    {
                        debug (selector)
                            Stdout.formatln("[SRV][{0}] Sending PONG to client", i);

                        count = (cast(SocketConduit) selectionKey.conduit).write("PONG");
                        if (count != IConduit.Eof)
                        {
                            debug (selector)
                                Stdout.formatln("[SRV][{0}] Sent PONG to client ({1} bytes)", i, count);

                            selector.reregister(selectionKey.conduit, Event.Read);
                            sendCount++;
                        }
                        else
                        {
                            debug (selector)
                                Stdout.formatln("[SRV][{0}] Handle {1} was closed; removing it from Selector",
                                                i, selectionKey.conduit.fileHandle());
                            selector.unregister(selectionKey.conduit);
                            (cast(SocketConduit) selectionKey.conduit).close();
                            failedSendCount++;
                            continue;
                        }
                    }

                    if (selectionKey.isError() || selectionKey.isHangup() || selectionKey.isInvalidHandle())
                    {
                        char[] status;

                        if (selectionKey.isHangup())
                        {
                            closeCount++;
                            status = "Hangup";
                        }
                        else
                        {
                            errorCount++;
                            if (selectionKey.isInvalidHandle())
                                status = "Invalid request";
                            else
                                status = "Error";
                        }

                        debug (selector)
                        {
                            Stdout.formatln("[SRV][{0}] {1} in handle {2} from Selector",
                                            i, status, cast(int) selectionKey.conduit.fileHandle());

                            Stdout.formatln("[SRV][{0}] Unregistering handle {1} from Selector",
                                            i, cast(int) selectionKey.conduit.fileHandle());
                        }
                        selector.unregister(selectionKey.conduit);
                        (cast(Conduit) selectionKey.conduit).close();

                        if (selectionKey.conduit !is serverSocket)
                        {
                            continue;
                        }
                        else
                        {
                            break;
                        }
                    }
                }
            }
            else
            {
                debug (selector)
                    Stdout.formatln("[SRV][{0}] No more pending events in Selector; aborting", i);
                break;
            }
            i++;

            // Thread.sleep(1 * 1000_000);
            /*
            if (i % 100 == 0)
            {
                fullCollect();
                getStats(gc)
            }
            */
        }

        serverSocket.getSocket().close();
    }
    catch (SelectorException e)
    {
        Stdout.formatln("  Selector exception caught:\n{0}", e.toUtf8());
    }
    catch (Exception e)
    {
        Stdout.formatln("  Exception caught:\n{0}", e.toUtf8());
    }

    Stdout.formatln("*   Success: connect={0}; recv={1}; send={2}; close={3}\n"
                    "*   Failure: connect={4}, recv={5}; send={6}; error={7}",
                    connectCount, receiveCount, sendCount, closeCount,
                    failedConnectCount, failedReceiveCount, failedSendCount, errorCount);

    Stdout.formatln("* Total time: {0} ms", cast(uint) ((currentTime() - start) / Interval.milli));

    clientThread.join();

    selector.close();
}


/**
 * Thread that creates a client socket and sends messages to the server socket.
 */
void clientThreadFunc()
{
    SocketConduit socket = new SocketConduit();

    Thread.sleep(Interval.milli * 10);      // 10 milliseconds

    try
    {
        InternetAddress     addr    = new InternetAddress(SERVER_ADDR, SERVER_PORT);
        char[MAX_LENGTH]    buffer;
        uint count;
        int i;

        debug (selector)
            Stdout.formatln("[CLI][{0}] Connecting to server", i);

        socket.connect(addr);

        for (i = 1; i <= LOOP_COUNT; i++)
        {
            debug (selector)
                Stdout.formatln("[CLI][{0}] Sending PING to server", i);

            while (true)
            {
                try
                {
                    count = socket.write("PING");
                    break;
                }
                catch (SocketException e)
                {
                    if (errno != EINTR)
                        throw e;
                }
            }
            if (count != IConduit.Eof)
            {
                debug (selector)
                {
                    Stdout.formatln("[CLI][{0}] Sent PING to server ({1} bytes)", i, count);

                    Stdout.formatln("[CLI][{0}] Receiving message from server", i);
                }
                while (true)
                {
                    try
                    {
                        count = socket.read(buffer);
                        break;
                    }
                    catch (SocketException e)
                    {
                        if (errno != EINTR)
                            throw e;
                    }
                }
                if (count != IConduit.Eof)
                {
                    debug (selector)
                        Stdout.formatln("[CLI][{0}] Received {1} from server ({2} bytes)",
                                        i, buffer[0..count], count);
                }
                else
                {
                    debug (selector)
                        Stdout.formatln("[CLI][{0}] Handle was closed; aborting",
                                        i, socket.fileHandle());
                    break;
                }
            }
            else
            {
                debug (selector)
                    Stdout.formatln("[CLI][{0}] Handle {1} was closed; aborting",
                                    i, socket.fileHandle());
                break;
            }
        }
        socket.shutdown();
        socket.close();
    }
    catch (Exception e)
    {
        debug (selector)
            Stdout.formatln("[CLI] Exception caught:\n{0}", e.toUtf8());
    }
    debug (selector)
        Stdout.formatln("[CLI] Leaving thread");

    return 0;
}