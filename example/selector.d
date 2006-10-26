/*******************************************************************************
  copyright:   Copyright (c) 2006 Juan Jose Comellas. All rights reserved
  license:     BSD style: $(LICENSE)
  author:      Juan Jose Comellas <juanjo@comellas.com.ar>
*******************************************************************************/

private
{
    import tango.io.selector.model.ISelector;
    import tango.io.selector.Selector;
    import tango.io.selector.EpollSelector;
    import tango.io.selector.PollSelector;
    import tango.io.selector.SelectSelector;
    import tango.io.selector.SelectorException;
    import tango.io.Conduit;
    import tango.io.Exception;
    import tango.io.Stdout;
    import tango.net.Socket;
    import tango.net.SocketConduit;
    import tango.net.ServerSocket;
    import tango.core.Thread;
    import tango.sys.Common;
    import tango.sys.linux.linux;
    import tango.sys.TimeConverter;
    import tango.stdc.errno;
    import tango.text.convert.Unicode;
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
        Stdout.format("* Pass {0}: Testing the select-based selector\n", i + 1);
        selector = new SelectSelector();
        testSelector(selector);
    }

    for (int i = 0; i < 5; i++)
    {
        // Testing the PollSelector
        version (Posix)
        {
            Stdout.format("* Pass {0}: Testing the poll-based selector\n", i + 1);
            selector = new PollSelector();
            testSelector(selector);
        }
    }

    for (int i = 0; i < 5; i++)
    {
        // Testing the EpollSelector
        version (linux)
        {
            Stdout.format("* Pass {0}: Testing the epoll-based selector\n", i + 1);
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
            Stdout.print("[SRV] Registering server socket to Selector\n");
        selector.register(serverSocket, Event.Read);

        while (true)
        {
            debug (selector)
                Stdout.format("[SRV][{0}] Waiting for events from Selector\n", i);

            eventCount = selector.select(timeout);

            debug (selector)
                Stdout.format("[SRV][{0}] {1} events received from Selector\n", i, eventCount);

            if (eventCount > 0)
            {
                foreach (SelectionKey selectionKey; selector.selectedSet())
                {
                    debug (selector)
                        Stdout.format("[SRV][{0}] Event mask for socket {1} is 0x{2:x4}\n",
                                      i, cast(int) selectionKey.conduit.getHandle(),
                                      cast(uint) selectionKey.events);

                    if (selectionKey.isReadable())
                    {
                        if (selectionKey.conduit is serverSocket)
                        {
                            debug (selector)
                                Stdout.format("[SRV][{0}] New connection from client\n", i);

                            clientSocket = serverSocket.accept();
                            if (clientSocket !is null)
                            {
                                selector.register(clientSocket, Event.Read);
                                connectCount++;
                            }
                            else
                            {
                                debug (selector)
                                    Stdout.format("[SRV][{0}] New connection attempt failed\n", i);
                                failedConnectCount++;
                            }
                        }
                        else
                        {
                            // Reading from a client socket
                            debug (selector)
                                Stdout.format("[SRV][{0}] Receiving message from client\n", i);

                            count = selectionKey.conduit.read(buffer);
                            if (count != IConduit.Eof)
                            {
                                debug (selector)
                                    Stdout.format("[SRV][{0}] Received {1} from client ({2} bytes)\n",
                                                  i, buffer[0..count], count);
                                selector.reregister(selectionKey.conduit, Event.Write);
                                receiveCount++;
                            }
                            else
                            {
                                debug (selector)
                                    Stdout.format("[SRV][{0}] Handle {1} was closed; removing it from Selector\n",
                                                  i, cast(int) selectionKey.conduit.getHandle());
                                selector.unregister(selectionKey.conduit);
                                selectionKey.conduit.close();
                                failedReceiveCount++;
                                continue;
                            }
                        }
                    }

                    if (selectionKey.isWritable())
                    {
                        debug (selector)
                            Stdout.format("[SRV][{0}] Sending PONG to client\n", i);

                        count = selectionKey.conduit.write("PONG");
                        if (count != IConduit.Eof)
                        {
                            debug (selector)
                                Stdout.format("[SRV][{0}] Sent PONG to client ({1} bytes)\n", i, count);

                            selector.reregister(selectionKey.conduit, Event.Read);
                            sendCount++;
                        }
                        else
                        {
                            debug (selector)
                                Stdout.format("[SRV][{0}] Handle {1} was closed; removing it from Selector\n",
                                              i, selectionKey.conduit.getHandle());
                            selector.unregister(selectionKey.conduit);
                            selectionKey.conduit.close();
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
                            Stdout.format("[SRV][{0}] {1} in handle {2} from Selector\n",
                                          i, status, cast(int) selectionKey.conduit.getHandle());

                            Stdout.format("[SRV][{0}] Unregistering handle {1} from Selector\n",
                                          i, cast(int) selectionKey.conduit.getHandle());
                        }
                        selector.unregister(selectionKey.conduit);
                        selectionKey.conduit.close();

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
                    Stdout.format("[SRV][{0}] No more pending events in Selector; aborting\n", i);
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

        serverSocket.shutdown();
        serverSocket.close();
    }
    catch (SelectorException e)
    {
        Stdout.format("  Selector exception caught:\n{0}\n", e.toUtf8());
    }
    catch (Exception e)
    {
        Stdout.format("  Exception caught:\n{0}\n", e.toUtf8());
    }

    Stdout.format("*   Success: connect={0}; recv={1}; send={2}; close={3}\n"
                  "*   Failure: connect={4}, recv={5}; send={6}; error={7}\n",
                  connectCount, receiveCount, sendCount, closeCount,
                  failedConnectCount, failedReceiveCount, failedSendCount, errorCount);

    Stdout.format("* Total time: {0} ms\n", cast(uint) ((currentTime() - start) / Interval.milli));

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
            Stdout.format("[CLI][{0}] Connecting to server\n", i);

        socket.connect(addr);

        for (i = 1; i <= LOOP_COUNT; i++)
        {
            debug (selector)
                Stdout.format("[CLI][{0}] Sending PING to server\n", i);

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
                    Stdout.format("[CLI][{0}] Sent PING to server ({1} bytes)\n", i, count);

                    Stdout.format("[CLI][{0}] Receiving message from server\n", i);
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
                        Stdout.format("[CLI][{0}] Received {1} from server ({2} bytes)\n",
                                      i, buffer[0..count], count);
                }
                else
                {
                    debug (selector)
                        Stdout.format("[CLI][{0}] Handle was closed; aborting\n",
                                      i, socket.getHandle());
                    break;
                }
            }
            else
            {
                debug (selector)
                    Stdout.format("[CLI][{0}] Handle {1} was closed; aborting\n",
                                  i, socket.getHandle());
                break;
            }
        }
        socket.shutdown();
        socket.close();
    }
    catch (Exception e)
    {
        debug (selector)
            Stdout.format("[CLI] Exception caught:\n{0}\n", e.toUtf8());
    }
    debug (selector)
        Stdout.format("[CLI] Leaving thread\n");

    return 0;
}