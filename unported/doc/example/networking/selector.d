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
    import tango.net.InternetAddress;
    import tango.io.device.Conduit;
    import tango.net.device.Socket;
    import tango.time.Clock;
    import tango.core.Exception;
    import tango.core.Thread;
    import tango.sys.Common;
    import tango.stdc.errno;
    import tango.util.log.Log;
    import tango.util.log.LayoutDate;
    import tango.util.log.AppendConsole;
}


const uint      HANDLE_COUNT    = 4;
const uint      EVENT_COUNT     = 4;
const uint      LOOP_COUNT      = 50000;
const char[]    SERVER_ADDR     = "127.0.0.1";
const ushort    SERVER_PORT     = 4000;
const uint      MAX_LENGTH      = 16;

int main(char[][] args)
{
    Logger log = Log.lookup("selector");
    log.add (new AppendConsole(new LayoutDate));

    ISelector selector;

    for (int i = 0; i < 1; i++)
    {
        // Testing the SelectSelector
        log.info("Pass {0}: Testing the select-based selector", i + 1);
        selector = new SelectSelector;
        testSelector(selector);
    }

    // Testing the PollSelector
    version (Posix)
    {
        for (int i = 0; i < 1; i++)
        {
            log.info("Pass {0}: Testing the poll-based selector", i + 1);
            selector = new PollSelector;
            testSelector(selector);
        }
    }

    // Testing the EpollSelector
    version (linux)
    {
        for (int i = 0; i < 1; i++)
        {
            log.info("Pass {0}: Testing the epoll-based selector", i + 1);
            selector = new EpollSelector;
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
    Logger log = Log.getLogger("selector.server");

    uint        connectCount        = 0;
    uint        receiveCount        = 0;
    uint        sendCount           = 0;
    uint        failedConnectCount  = 0;
    uint        failedReceiveCount  = 0;
    uint        failedSendCount     = 0;
    uint        closeCount          = 0;
    uint        errorCount          = 0;
    Time        start               = Clock.now;
    Thread      clientThread;

    selector.open(HANDLE_COUNT, EVENT_COUNT);

    clientThread = new Thread(&clientThreadFunc);
    clientThread.start();

    try
    {
        TimeSpan            timeout         = TimeSpan.fromSeconds(1);
        InternetAddress     addr            = new InternetAddress(SERVER_ADDR, SERVER_PORT);
        ServerSocket        serverSocket    = new ServerSocket(addr, 5);
        Socket       clientSocket;
        char[MAX_LENGTH]    buffer;
        int                 eventCount;
        uint                count;
        int                 i = 0;

        debug (selector)
            log.trace("Registering server socket to Selector");

        selector.register(serverSocket, Event.Read);

        while (true)
        {
            debug (selector)
                log.trace("[{0}] Waiting for events from Selector", i);

            eventCount = selector.select(timeout);

            debug (selector)
                log.trace("[{0}] {1} events received from Selector", i, eventCount);

            if (eventCount > 0)
            {
                ISelectable[] removeThese;
                foreach (SelectionKey selectionKey; selector.selectedSet())
                {
                    debug (selector)
                        log.trace("[{0}] Event mask for socket {1} is 0x{2:x4}",
                                   i, cast(int) selectionKey.conduit.fileHandle,
                                   cast(uint) selectionKey.events);

                    if (selectionKey.isReadable)
                    {
                        if (selectionKey.conduit is serverSocket)
                        {
                            debug (selector)
                                log.trace("[{0}] New connection from client", i);

                            clientSocket = serverSocket.accept;
                            if (clientSocket !is null)
                            {
                                selector.register(clientSocket, Event.Read);
                                connectCount++;
                            }
                            else
                            {
                                debug (selector)
                                    log.trace("[{0}] New connection attempt failed", i);
                                failedConnectCount++;
                            }
                        }
                        else
                        {
                            // Reading from a client socket
                            debug (selector)
                                log.trace("[{0}] Receiving message from client", i);

                            count = (cast(Socket) selectionKey.conduit).read(buffer);
                            if (count != IConduit.Eof)
                            {
                                debug (selector)
                                    log.trace("[{0}] Received {1} from client ({2} bytes)",
                                               i, buffer[0..count], count);
                                selector.register(selectionKey.conduit, Event.Write);
                                receiveCount++;
                            }
                            else
                            {
                                debug (selector)
                                    log.trace("[{0}] Handle {1} was closed; removing it from Selector",
                                                     i, cast(int) selectionKey.conduit.fileHandle);
                                // note, we cannot unregister because we are
                                // in the middle of a foreach loop.  Delay
                                // unregistering and closing until after the
                                // loop is done.
                                //selector.unregister(selectionKey.conduit);
                                //(cast(Socket) selectionKey.conduit).close();
                                removeThese ~= selectionKey.conduit;
                                failedReceiveCount++;
                                continue;
                            }
                        }
                    }

                    if (selectionKey.isWritable)
                    {
                        debug (selector)
                            log.trace("[{0}] Sending PONG to client", i);

                        count = (cast(Socket) selectionKey.conduit).write("PONG");
                        if (count != IConduit.Eof)
                        {
                            debug (selector)
                                log.trace("[{0}] Sent PONG to client ({1} bytes)", i, count);

                            selector.register(selectionKey.conduit, Event.Read);
                            sendCount++;
                        }
                        else
                        {
                            debug (selector)
                                log.trace("[{0}] Handle {1} was closed; removing it from Selector",
                                           i, selectionKey.conduit.fileHandle);
                            // note, see comment above
                            //selector.unregister(selectionKey.conduit);
                            //(cast(Socket) selectionKey.conduit).close();
                            removeThese ~= selectionKey.conduit;
                            failedSendCount++;
                            continue;
                        }
                    }

                    if (selectionKey.isError || selectionKey.isHangup || selectionKey.isInvalidHandle)
                    {
                        char[] status;

                        if (selectionKey.isHangup)
                        {
                            closeCount++;
                            status = "Hangup";
                        }
                        else
                        {
                            errorCount++;
                            if (selectionKey.isInvalidHandle)
                                status = "Invalid request";
                            else
                                status = "Error";
                        }

                        debug (selector)
                        {
                            log.trace("[{0}] {1} in handle {2} from Selector",
                                       i, status, cast(int) selectionKey.conduit.fileHandle);

                            log.trace("[{0}] Unregistering handle {1} from Selector",
                                       i, cast(int) selectionKey.conduit.fileHandle);
                        }
                        // note, see comment above
                        //selector.unregister(selectionKey.conduit);
                        //(cast(Conduit) selectionKey.conduit).close();
                        removeThese ~= selectionKey.conduit;

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
                foreach(c; removeThese)
                {
                    selector.unregister(c);
                    (cast(Conduit) c).close;
                }
            }
            else
            {
                debug (selector)
                    log.trace("[{0}] No more pending events in Selector; aborting", i);
                break;
            }
            i++;

            // Thread.sleep(1.0);
            /*
            if (i % 100 == 0)
            {
                fullCollect();
                getStats(gc)
            }
            */
        }

        serverSocket.detach;
    }
    catch (SelectorException e)
    {
        log.error("Selector exception caught:\n{0}", e.toString);
    }
    catch (Exception e)
    {
        log.error("Exception caught:\n{0}", e.toString);
    }

    log.info("Success: connect={0}; recv={1}; send={2}; close={3}", 
              connectCount, receiveCount, sendCount, closeCount);
    log.info("Failure: connect={0}, recv={1}; send={2}; error={3}", 
             failedConnectCount, failedReceiveCount, failedSendCount, errorCount);

    log.info("Total time: {0} ms", cast(uint) (Clock.now - start).millis);

    clientThread.join;

    selector.close;
}


/**
 * Thread that creates a client socket and sends messages to the server socket.
 */
void clientThreadFunc()
{
    Logger log = Log.getLogger("selector.client");
    Socket socket  = new Socket;

    Thread.sleep(0.010);      // 10 milliseconds

    try
    {
        InternetAddress     addr = new InternetAddress(SERVER_ADDR, SERVER_PORT);
        char[MAX_LENGTH]    buffer;
        uint count;
        int i;

        debug (selector)
            log.trace("[{0}] Connecting to server", i);

        socket.connect(addr);

        for (i = 1; i <= LOOP_COUNT; i++)
        {
            debug (selector)
                log.trace("[{0}] Sending PING to server", i);

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
                    log.trace("[{0}] Sent PING to server ({1} bytes)", i, count);

                    log.trace("[{0}] Receiving message from server", i);
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
                        log.trace("[{0}] Received {1} from server ({2} bytes)",
                                   i, buffer[0..count], count);
                }
                else
                {
                    debug (selector)
                        log.trace("[{0}] Handle was closed; aborting",
                                   i, socket.fileHandle);
                    break;
                }
            }
            else
            {
                debug (selector)
                    log.trace("[{0}] Handle {1} was closed; aborting",
                               i, socket.fileHandle);
                break;
            }
        }
        socket.shutdown;
        socket.close;
    }
    catch (Exception e)
    {
        log.error("Exception caught:\n{0}", e.toString);
    }
    debug (selector)
        log.trace("Leaving thread");
}
