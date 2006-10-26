/*******************************************************************************
  copyright:   Copyright (c) 2006 Juan Jose Comellas. All rights reserved
  license:     BSD style: $(LICENSE)
  author:      Juan Jose Comellas <juanjo@comellas.com.ar>
*******************************************************************************/

module tango.io.selector.SelectSelector;

public import tango.io.model.IConduit;

private import tango.io.selector.model.ISelector;
private import tango.io.selector.AbstractSelector;
private import tango.io.selector.SelectorException;
private import tango.sys.Common;
private import tango.sys.TimeConverter;
private import tango.stdc.errno;

debug (selector)
    import tango.io.Stdout;


version (Win32)
{
    /**
     * Helper class used by the select()-based Selector to store handles.
     * On Windows the handles are kept in an array of uints and the first
     * element of the array stores the array "length" (i.e. number of handles
     * in the array). Everything is stored so that the native select() API
     * can use the HandleSet without additional conversions by just casting it
     * to a fd_set*.
     */
    private class HandleSet
    {
        /** Default number of handles that will be held in the HandleSet. */
        public const uint DefaultSize = 63;

        private uint[] _buffer;
        private alias _buffer[0] _count;

        /**
         * Constructor. Sets the initial number of handles that will be held
         * in the HandleSet.
         */
        public this(uint size = DefaultSize)
        {
            _buffer = new uint[1 + size];
            _count  = 0;
        }

        /**
         * Clear all the bits corresponding to the file descriptors in the set.
         */
        private void reset()
        {
            _count = 0;
        }

        /**
         * Add a file descriptor to the set.
         */
        public void add(IConduit.Handle handle)
        in
        {
            assert(handle >= 0);
        }
        body
        {
            // If we added too many sockets we increment the size of the buffer
            if (++_count >= _buffer.length)
            {
                _buffer.length = _count + 1;
            }
            _buffer[_count] = cast(uint) handle;
        }

        /**
         * Remove a file descriptor from the set.
         */
        public void remove(IConduit.Handle handle)
        {
            if (_count > 0)
            {
                size_t i;

                for (i = 1; i < _buffer.length; ++i)
                {
                    if (_buffer[i] == handle)
                        goto found;
                }
                return;

            found:
                // We don't need to keep the handles in the order in which
                // they were inserted, so we optimize the removal by copying
                // the last element to the position of the removed element.
                if (i != buffer.length - 1)
                {
                    _buffer[i] = _buffer[_buffer.length - 1];
                }
                _count--;

                /*
                uint* start;
                uint* stop;

                for (start = _buffer + 1, stop = start + _count; start != stop; start++)
                {
                    if (*start == handle)
                        goto found;
                }
                return;

            found:
                for (++start; start != stop; start++)
                {
                    *(start - 1) = *start;
                }
                _count--;
                */
            }
        }

        /**
         * Copy the contents of the HandleSet into this instance.
         */
        private void copy(HandleSet handleSet)
        {
            if (handleSet !is null)
            {
                _buffer[] = handleSet._buffer[];
            }
            else
            {
                _buffer = null;
            }
        }

        /**
         * Check whether the file descriptor has been set.
         */
        public bool isSet(IConduit.Handle handle)
        {
            uint* start;
            uint* stop;

            for (start = _buffer + 1, stop = start + _count; start != stop; start++)
            {
                if (*start == cast(uint) handle)
                    return true;
            }
            return false;
        }

        /**
         * Cast the current object to a pointer to an fd_set, to be used with the
         * select() system call.
         */
        public fd_set* opCast()
        {
            return cast(fd_set*) &_buffer;
        }
    }
}
else version (Posix)
{
    private import tango.core.Intrinsic;

    /**
     * Helper class used by the select()-based Selector to store handles.
     * On POSIX-compatible platforms the handles are kept in an array of bits.
     * Everything is stored so that the native select() API can use the
     * HandleSet without additional conversions by casting it to a fd_set*.
     */
    private class HandleSet
    {
        /** Default number of handles that will be held in the HandleSet. */
        const uint DefaultSize     = 1024;
        /** Number of bits per element held in the _buffer */
        const uint BitsPerElement = uint.sizeof * 8;

        private uint[] _buffer;

        /**
         * Constructor. Sets the initial number of handles that will be held
         * in the HandleSet.
         */
        protected this(uint size = DefaultSize)
        {
            uint count;

            if (size < 1024)
                size = 1024;

            count = size / BitsPerElement;
            if (size % BitsPerElement != 0)
                count++;
            _buffer = new uint[count];
        }

        /**
         * Clear all the bits corresponding to the file descriptors in the set.
         */
        public void reset()
        {
            _buffer[] = 0;
        }

        /**
         * Add a file descriptor to the set.
         */
        public void add(IConduit.Handle handle)
        {
            // If we added too many sockets we increment the size of the buffer
            if (cast(uint) handle >= BitsPerElement * _buffer.length)
            {
                _buffer.length = cast(uint) handle + 1;
            }
            bts(&_buffer[elementOffset(handle)], bitOffset(handle));
        }

        /**
         * Remove a file descriptor from the set.
         */
        public void remove(IConduit.Handle handle)
        {
            btr(&_buffer[elementOffset(handle)], bitOffset(handle));
        }

        /**
         * Copy the contents of the HandleSet into this instance.
         */
        private void copy(HandleSet handleSet)
        {
            if (handleSet !is null)
            {
                _buffer[] = handleSet._buffer[];
            }
            else
            {
                _buffer = null;
            }
        }

        /**
         * Check whether the file descriptor has been set.
         */
        public bool isSet(IConduit.Handle handle)
        {
            return (bt(&_buffer[elementOffset(handle)], bitOffset(handle)) != 0);
        }

        /**
         * Cast the current object to a pointer to an fd_set, to be used with the
         * select() system call.
         */
        public fd_set* opCast()
        {
            return cast(fd_set*) _buffer;
        }

        /**
         * Calculate the offset (in uints) of a file descriptor in the set.
         */
        private static uint elementOffset(IConduit.Handle handle)
        {
            return cast(uint) handle / BitsPerElement;
        }

        /**
         * Calculate the offset of the bit corresponding to a file descriptor in the set.
         */
        private static uint bitOffset(IConduit.Handle handle)
        {
            return cast(uint) handle % BitsPerElement;
        }
    }
}


/**
 * Selector that uses the select() system call to receive I/O events for
 * the registered conduits. To use this class you would normally do
 * something like this:
 *
 * Examples:
 * ---
 * import tango.io.selector.SelectSelector;
 *
 * Socket socket;
 * ISelector selector = new SelectSelector();
 *
 * selector.open(100, 10);
 *
 * // Register to read from socket
 * selector.register(socket, Event.Read);
 *
 * uint eventCount = selector.select(Msec(100));
 * if (eventCount > 0)
 * {
 *     // We can now read from the socket
 *     socket.read();
 * }
 * else if (eventCount == 0)
 * {
 *     // Timeout
 * }
 * else if (eventCount == -1)
 * {
 *     // Another thread called the wakeup() method.
 * }
 * else
 * {
 *     // Error: should never happen.
 * }
 *
 * selector.close();
 * ---
 */
public class SelectSelector: AbstractSelector
{
    uint _size;
    private SelectionKey[IConduit.Handle] _keys;
    private HandleSet _readSet;
    private HandleSet _writeSet;
    private HandleSet _exceptionSet;
    private HandleSet _selectedReadSet;
    private HandleSet _selectedWriteSet;
    private HandleSet _selectedExceptionSet;
    int _eventCount;
    version (Posix)
    {
        private IConduit.Handle _maxfd = cast(IConduit.Handle) -1;
    }

    /**
     * Open the select()-based selector.
     *
     * Params:
     * size         = maximum amount of conduits that will be registered;
     *                it will grow dynamically if needed.
     * maxEvents    = maximum amount of conduit events that will be
     *                returned in the selection set per call to select();
     *                this value is currently not used by this selector.
     */
    public void open(uint size = HandleSet.DefaultSize, uint maxEvents = HandleSet.DefaultSize)
    in
    {
        assert(size > 0);
    }
    body
    {
        _size = size;
    }

    /**
     * Close the selector.
     *
     * Remarks:
     * It can be called multiple times without harmful side-effects.
     */
    public void close()
    {
        _size = 0;
        _keys = null;
        _readSet = null;
        _writeSet = null;
        _exceptionSet = null;
        _selectedReadSet = null;
        _selectedWriteSet = null;
        _selectedExceptionSet = null;
    }

    /**
     * Associate a conduit to the selector and track specific I/O events.
     *
     * Params:
     * conduit      = conduit that will be associated to the selector;
     *                must be a valid conduit (i.e. not null and open).
     * events       = bit mask of Event values that represent the events
     *                that will be tracked for the conduit.
     * attachment   = optional object with application-specific data that
     *                will be available when an event is triggered for the
     *                conduit
     *
     * Throws:
     * RegisteredConduitException if the conduit had already been
     * registered to the selector.
     *
     * Examples:
     * ---
     * selector.register(conduit, Event.Read | Event.Write, object);
     * ---
     */
    public void register(IConduit conduit, Event events, Object attachment = null)
    in
    {
        assert(conduit !is null && conduit.getHandle() >= 0);
    }
    body
    {
        IConduit.Handle handle = conduit.getHandle();

        debug (selector)
            Stdout.format("--- SelectSelector.register(handle={0}, events=0x{1:x})\n",
                   cast(int) handle, cast(uint) events);

        // We make sure that the conduit is not already registered to
        // the Selector
        SelectionKey* key = (conduit.getHandle() in _keys);

        if (key is null)
        {
            // Keep record of the Conduits for whom we're tracking events.
            _keys[handle] = new SelectionKey(conduit, events, attachment);

            if ((events & Event.Read) || (events & Event.Hangup))
            {
                if (_readSet is null)
                {
                    _readSet = new HandleSet(_size);
                    _selectedReadSet = new HandleSet(_size);
                }
                _readSet.add(handle);
            }

            if (events & Event.Write)
            {
                if (_writeSet is null)
                {
                    _writeSet = new HandleSet(_size);
                    _selectedWriteSet = new HandleSet(_size);
                }
                _writeSet.add(handle);
            }

            if (events & Event.Error)
            {
                if (_exceptionSet is null)
                {
                    _exceptionSet = new HandleSet(_size);
                    _selectedExceptionSet = new HandleSet(_size);
                }
                _exceptionSet.add(handle);
            }

            version (Posix)
            {
                if (handle > _maxfd)
                    _maxfd = handle;
            }
        }
        else
        {
            throw new RegisteredConduitException(__FILE__, __LINE__);
        }
    }

    /**
     * Modify the events that are being tracked or the 'attachment' field
     * for an already registered conduit.
     *
     * Params:
     * conduit      = conduit that will be associated to the selector;
     *                must be a valid conduit (i.e. not null and open).
     * events       = bit mask of Event values that represent the events
     *                that will be tracked for the conduit.
     * attachment   = optional object with application-specific data that
     *                will be available when an event is triggered for the
     *                conduit
     *
     * Remarks:
     * The 'attachment' member of the SelectionKey will always be
     * overwritten, even if it's null.
     *
     * Throws:
     * UnregisteredConduitException if the conduit had not been previously
     * registered to the selector.
     *
     * Examples:
     * ---
     * selector.reregister(conduit, Event.Write, object);
     * ---
     */
    public void reregister(IConduit conduit, Event events, Object attachment = null)
    in
    {
        assert(conduit !is null && conduit.getHandle() >= 0);
    }
    body
    {
        IConduit.Handle handle = conduit.getHandle();

        debug (selector)
            Stdout.format("--- SelectSelector.reregister(handle={0}, events=0x{1:x})\n",
                          cast(int) handle, cast(uint) events);

        SelectionKey *key = (handle in _keys);
        if (key !is null)
        {
            if ((events & Event.Read) || (events & Event.Hangup))
            {
                if (_readSet is null)
                {
                    _readSet = new HandleSet(_size);
                    _selectedReadSet = new HandleSet(_size);
                }
                _readSet.add(handle);
            }
            else if (_readSet !is null)
            {
                _readSet.remove(handle);
            }

            if ((events & Event.Write))
            {
                if (_writeSet is null)
                {
                    _writeSet = new HandleSet(_size);
                    _selectedWriteSet = new HandleSet(_size);
                }
                _writeSet.add(handle);
            }
            else if (_writeSet !is null)
            {
                _writeSet.remove(handle);
            }

            if (events & Event.Error)
            {
                if (_exceptionSet is null)
                {
                    _exceptionSet = new HandleSet(_size);
                    _selectedExceptionSet = new HandleSet(_size);
                }
                _exceptionSet.add(handle);
            }
            else if (_exceptionSet !is null)
            {
                _exceptionSet.remove(handle);
            }

            version (Posix)
            {
                if (handle > _maxfd)
                    _maxfd = handle;
            }

            (*key).events = events;
            (*key).attachment = attachment;
        }
        else
        {
            throw new UnregisteredConduitException(__FILE__, __LINE__);
        }
    }

    /**
     * Remove a conduit from the selector.
     *
     * Params:
     * conduit      = conduit that had been previously associated to the
     *                selector; it can be null.
     *
     * Remarks:
     * Unregistering a null conduit is allowed and no exception is thrown
     * if this happens.
     *
     * Throws:
     * UnregisteredConduitException if the conduit had not been previously
     * registered to the selector.
     */
    public void unregister(IConduit conduit)
    {
        if (conduit !is null)
        {
            IConduit.Handle handle = conduit.getHandle();

            debug (selector)
                Stdout.format("--- SelectSelector.unregister(handle={0})\n",
                              cast(int) handle);

            SelectionKey* removed = (handle in _keys);

            if (removed !is null)
            {
                if (_exceptionSet !is null)
                {
                    _exceptionSet.remove(handle);
                }
                if (_writeSet !is null)
                {
                    _writeSet.remove(handle);
                }
                if (_readSet !is null)
                {
                    _readSet.remove(handle);
                }
                _keys.remove(handle);

                version (Posix)
                {
                    // If we're removing the biggest file descriptor we've entered so far
                    // we need to recalculate this value for the set.
                    if (handle == _maxfd)
                    {
                        while (--_maxfd >= 0)
                        {
                            if ((_readSet !is null && _readSet.isSet(_maxfd)) ||
                                (_writeSet !is null && _writeSet.isSet(_maxfd)) ||
                                (_exceptionSet !is null && _exceptionSet.isSet(_maxfd)))
                            {
                                break;
                            }
                        }
                    }
                }
            }
            else
            {
                debug (selector)
                    Stdout.format("--- SelectSelector.unregister(handle={0}): conduit was not found\n",
                                  cast(int) conduit.getHandle());
                throw new UnregisteredConduitException(__FILE__, __LINE__);
            }
        }
    }

    /**
     * Wait for I/O events from the registered conduits for a specified
     * amount of time.
     *
     * Params:
     * timeout  = Interval with the maximum amount of time that the
     *            selector will wait for events from the conduits; the
     *            amount of time is relative to the current system time
     *            (i.e. just the number of milliseconds that the selector
     *            has to wait for the events).
     *
     * Returns:
     * The amount of conduits that have received events; 0 if no conduits
     * have received events within the specified timeout; and -1 if the
     * wakeup() method has been called from another thread.
     *
     * Throws:
     * InterruptedSystemCallException if the underlying system call was
     * interrupted by a signal and the 'restartInterruptedSystemCall'
     * property was set to false; SelectorException if there were no
     * resources available to wait for events from the conduits.
     */
    public int select(Interval timeout)
    {
        fd_set *readfds;
        fd_set *writefds;
        fd_set *exceptfds;
        timeval tv;

        debug (selector)
            Stdout.format("--- SelectSelector.select(timeout={0} usec)\n",
                          (timeout != Interval.infinity ? timeout / Interval.milli : -1));

        if (_readSet !is null)
        {
            _selectedReadSet.copy(_readSet);
            readfds = cast(fd_set*) _selectedReadSet;
        }
        if (_writeSet !is null)
        {
            _selectedWriteSet.copy(_writeSet);
            writefds = cast(fd_set*) _selectedWriteSet;
        }
        if (_exceptionSet !is null)
        {
            _selectedExceptionSet.copy(_writeSet);
            exceptfds = cast(fd_set*) _selectedExceptionSet;
        }

        version (Posix)
        {
            while (true)
            {
                // FIXME: add support for the wakeup() call.
                _eventCount = .select(_maxfd + 1, readfds, writefds, exceptfds,
                                      (timeout != Interval.infinity ? toTimeval(&tv, timeout) : null));
                debug (selector)
                    Stdout.format("---   .select() returned {0} (maxfd={1})\n",
                                  _eventCount, cast(int) _maxfd);
                if (_eventCount >= 0)
                {
                    break;
                }
                else
                {
                    if (errno != EINTR || !_restartInterruptedSystemCall)
                    {
                        // checkErrno() always throws an exception
                        checkErrno(__FILE__, __LINE__);
                    }
                    debug (selector)
                        Stdout.print("--- Restarting select() after being interrupted\n");
                }
            }
        }
        else
        {
            // FIXME: Can a system call be interrupted on Windows?
            _eventCount = .select(IConduit.Handle.max, writefds, exceptfds,
                                  (timeout != Interval.infinity ? toTimeval(&tv, timeout) : null));
            debug (selector)
                Stdout.format("---   .select() returned {0}\n", _eventCount);
        }
        return _eventCount;
    }

    /**
     * Return the selection set resulting from the call to any of the
     * select() methods.
     *
     * Remarks:
     * If the call to select() was unsuccessful or it did not return any
     * events, the returned value will be null.
     */
    public ISelectionSet selectedSet()
    {
        return (_eventCount > 0 ? new SelectSelectionSet(_keys, cast(uint) _eventCount, _selectedReadSet,
                                                         _selectedWriteSet, _selectedExceptionSet) : null);
    }

    /**
     * Return the selection key resulting from the registration of a
     * conduit to the selector.
     *
     * Remarks:
     * If the conduit is not registered to the selector the returned
     * value will be null. No exception will be thrown by this method.
     */
    public SelectionKey key(IConduit conduit)
    {
        return (conduit !is null ? _keys[conduit.getHandle()] : null);
    }
}

/**
 * SelectionSet for the select()-based Selector.
 */
private class SelectSelectionSet: ISelectionSet
{
    private SelectionKey[IConduit.Handle] _keys;
    private uint _eventCount;
    private HandleSet _readSet;
    private HandleSet _writeSet;
    private HandleSet _exceptionSet;

    protected this(SelectionKey[IConduit.Handle] keys, uint eventCount,
                   HandleSet readSet, HandleSet writeSet, HandleSet exceptionSet)
    {
        _keys = keys;
        _eventCount = eventCount;
        _readSet = readSet;
        _writeSet = writeSet;
        _exceptionSet = exceptionSet;
    }

    public uint length()
    {
        return _eventCount;
    }

    public int opApply(int delegate(inout SelectionKey) dg)
    {
        int rc = 0;
        IConduit.Handle handle;
        Event events;

        debug (selector)
            Stdout.format("--- SelectSelectionSet.opApply() ({0} elements)\n", _eventCount);

        foreach (SelectionKey current; _keys)
        {
            handle = current.conduit.getHandle();

            if (_readSet !is null && _readSet.isSet(handle))
                events = Event.Read;
            else
                events = Event.None;

            if (_writeSet !is null && _writeSet.isSet(handle))
                events |= Event.Write;

            if (_exceptionSet !is null && _exceptionSet.isSet(handle))
                events |= Event.Error;

            // Only invoke the delegate if there is an event for the IConduit.
            if (events != Event.None)
            {
                current.events = events;

                debug (selector)
                    Stdout.format("---   Calling foreach delegate with selection key ({0}, 0x{1:x})\n",
                                  cast(int) handle, cast(uint) events);

                if (dg(current) != 0)
                {
                    rc = -1;
                    break;
                }
            }
            else
            {
                debug (selector)
                    Stdout.format("---   Handle {0} doesn't have pending events\n",
                                  cast(int) handle);
            }
        }
        return rc;
    }
}
