/*******************************************************************************
  copyright:   Copyright (c) 2006 Juan Jose Comellas. All rights reserved
  license:     BSD style: $(LICENSE)
  author:      Juan Jose Comellas $(EMAIL juanjo@comellas.com.ar)
*******************************************************************************/

module tango.io.selector.SelectSelector;



public import tango.io.model.IConduit;

private import Time = tango.core.Time;
public import tango.io.selector.model.ISelector;

private import tango.io.selector.AbstractSelector;
private import tango.io.selector.SelectorException;
private import tango.sys.Common;

private import tango.stdc.errno;

debug (selector)
{
    private import tango.io.Stdout;
    private import tango.text.convert.Integer;
}


version (Windows)
{
    private import tango.core.Thread;

    private
    {
        // Opaque struct
        struct fd_set
        {
        }

        extern (Windows) int select(int nfds, fd_set* readfds, fd_set* writefds,
                                    fd_set* errorfds, timeval* timeout);
    }
}

version (Posix)
{
    private import tango.core.BitArray;
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
 * int eventCount = selector.select(0.1); // 0.1 seconds
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
    /**
     * Alias for the select() method as we're not reimplementing it in
     * this class.
     */
    alias AbstractSelector.select select;

    uint _size;
    private SelectionKey[ISelectable.Handle] _keys;
    private HandleSet _readSet;
    private HandleSet _writeSet;
    private HandleSet _exceptionSet;
    private HandleSet _selectedReadSet;
    private HandleSet _selectedWriteSet;
    private HandleSet _selectedExceptionSet;
    int _eventCount;
    version (Posix)
    {
        private ISelectable.Handle _maxfd = cast(ISelectable.Handle) -1;

        /**
         * Default number of SelectionKey's that will be handled by the
         * SelectSelector.
         */
        public enum uint DefaultSize = 1024;
    }
    else
    {
        /**
         * Default number of SelectionKey's that will be handled by the
         * SelectSelector.
         */
        public enum uint DefaultSize = 63;
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
    override public void open(uint size = DefaultSize, uint maxEvents = DefaultSize)
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
    override public void close()
    {
        _size = 0;
        _keys = null;
        _readSet = HandleSet.init;
        _writeSet = HandleSet.init;
        _exceptionSet = HandleSet.init;
        _selectedReadSet = HandleSet.init;
        _selectedWriteSet = HandleSet.init;
        _selectedExceptionSet = HandleSet.init;
    }

    private HandleSet *allocateSet(ref HandleSet set, ref HandleSet selectedSet)
    {
        if(!set.initialized)
        {
            set.setup(_size);
            selectedSet.setup(_size);
        }
        return &set;
    }

    /**
     * Associate a conduit to the selector and track specific I/O events.
     * If a conduit is already associated with the selector, the events and
     * attachment are upated.
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
    override public void register(ISelectable conduit, Event events, Object attachment = null)
    in
    {
        assert(conduit !is null && conduit.fileHandle());
    }
    body
    {
        ISelectable.Handle handle = conduit.fileHandle();

        debug (selector)
            Stdout.format("--- SelectSelector.register(handle={0}, events=0x{1:x})\n",
                          cast(int) handle, cast(uint) events);

        SelectionKey *key = (handle in _keys);
        if (key !is null)
        {
            if ((events & Event.Read) || (events & Event.Hangup))
            {
                allocateSet(_readSet, _selectedReadSet).set(handle);
            }
            else if (_readSet.initialized)
            {
                _readSet.clear(handle);
            }

            if ((events & Event.Write))
            {
                allocateSet(_writeSet, _selectedWriteSet).set(handle);
            }
            else if (_writeSet.initialized)
            {
                _writeSet.clear(handle);
            }

            if (events & Event.Error)
            {
                allocateSet(_exceptionSet, _selectedExceptionSet).set(handle);
            }
            else if (_exceptionSet.initialized)
            {
                _exceptionSet.clear(handle);
            }

            version (Posix)
            {
                if (handle > _maxfd)
                    _maxfd = handle;
            }

            key.events = events;
            key.attachment = attachment;
        }
        else
        {
            // Keep record of the Conduits for whom we're tracking events.
            _keys[handle] = SelectionKey(conduit, events, attachment);

            if ((events & Event.Read) || (events & Event.Hangup))
            {
                allocateSet(_readSet, _selectedReadSet).set(handle);
            }

            if (events & Event.Write)
            {
                allocateSet(_writeSet, _selectedWriteSet).set(handle);
            }

            if (events & Event.Error)
            {
                allocateSet(_exceptionSet, _selectedExceptionSet).set(handle);
            }

            version (Posix)
            {
                if (handle > _maxfd)
                    _maxfd = handle;
            }
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
    override public void unregister(ISelectable conduit)
    {
        if (conduit !is null)
        {
            ISelectable.Handle handle = conduit.fileHandle();

            debug (selector)
                Stdout.format("--- SelectSelector.unregister(handle={0})\n",
                              cast(int) handle);

            SelectionKey* removed = (handle in _keys);

            if (removed !is null)
            {
                if (removed.events & Event.Error)
                {
                    _exceptionSet.clear(handle);
                }
                if (removed.events & Event.Write)
                {
                    _writeSet.clear(handle);
                }
                if ((removed.events & Event.Read) || (removed.events & Event.Hangup))
                {
                    _readSet.clear(handle);
                }
                _keys.remove(handle);

                version (Posix)
                {
                    // If we're removing the biggest handle we've entered so far
                    // we need to recalculate this value for the set.
                    if (handle == _maxfd)
                    {
                        while (--_maxfd >= 0)
                        {
                            if (_readSet.isSet(_maxfd) ||
                                _writeSet.isSet(_maxfd) ||
                                _exceptionSet.isSet(_maxfd))
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
                                  cast(int) conduit.fileHandle());
                throw new UnregisteredConduitException(__FILE__, __LINE__);
            }
        }
    }

    /**
     * Wait for I/O events from the registered conduits for a specified
     * amount of time.
     *
     * Params:
     * timeout  = TimeSpan with the maximum amount of time that the
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
    override public int select(TimeSpan timeout)
    {
        fd_set *readfds;
        fd_set *writefds;
        fd_set *exceptfds;
        timeval tv;
        version (Windows)
            bool handlesAvailable = false;

        debug (selector)
            Stdout.format("--- SelectSelector.select(timeout={0} msec)\n", timeout.millis);

        if (_readSet.initialized)
        {
            debug (selector)
                _readSet.dump("_readSet");

            version (Windows)
                handlesAvailable = handlesAvailable || (_readSet.length > 0);

            readfds = cast(fd_set*) _selectedReadSet.copy(_readSet);
        }
        if (_writeSet.initialized)
        {
            debug (selector)
                _writeSet.dump("_writeSet");

            version (Windows)
                handlesAvailable = handlesAvailable || (_writeSet.length > 0);

            writefds = cast(fd_set*) _selectedWriteSet.copy(_writeSet);
        }
        if (_exceptionSet.initialized)
        {
            debug (selector)
                _exceptionSet.dump("_exceptionSet");

            version (Windows)
                handlesAvailable = handlesAvailable || (_exceptionSet.length > 0);

            exceptfds = cast(fd_set*) _selectedExceptionSet.copy(_exceptionSet);
        }

        version (Posix)
        {
            while (true)
            {
                toTimeval(&tv, timeout);

                // FIXME: add support for the wakeup() call.
                _eventCount = .select(_maxfd + 1, readfds, writefds, exceptfds, timeout is TimeSpan.max ? null : &tv);

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
            // Windows returns an error when select() is called with all three
            // handle sets empty, so we emulate the POSIX behavior by calling
            // Thread.sleep().
            if (handlesAvailable)
            {
                toTimeval(&tv, timeout);

                // FIXME: Can a system call be interrupted on Windows?
                _eventCount = .select(uint.max, readfds, writefds, exceptfds, timeout is TimeSpan.max ? null : &tv);

                debug (selector)
                    Stdout.format("---   .select() returned {0}\n", _eventCount);
            }
            else
            {
                Thread.sleep(Time.seconds(timeout.interval()));
                _eventCount = 0;
            }
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
    override public ISelectionSet selectedSet()
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
    override public SelectionKey key(ISelectable conduit)
    {
        if(conduit !is null)
        {
            if(auto k = conduit.fileHandle in _keys)
            {
                return *k;
            }
        }
        return SelectionKey.init;
    }

    /**
     * Return the number of keys resulting from the registration of a conduit
     * to the selector.
     */
    override public size_t count()
    {
        return _keys.length;
    }

    /**
     * Iterate through the currently registered selection keys.  Note that
     * you should not erase or add any items from the selector while
     * iterating, although you can register existing conduits again.
     */
    int opApply(scope int delegate(ref SelectionKey) dg)
    {
        int result = 0;
        foreach(v; _keys)
        {
            if((result = dg(v)) != 0)
                break;
        }
        return result;
    }
}

/**
 * SelectionSet for the select()-based Selector.
 */
private class SelectSelectionSet: ISelectionSet
{
    SelectionKey[ISelectable.Handle] _keys;
    uint _eventCount;
    HandleSet _readSet;
    HandleSet _writeSet;
    HandleSet _exceptionSet;

    this(SelectionKey[ISelectable.Handle] keys, uint eventCount,
                   HandleSet readSet, HandleSet writeSet, HandleSet exceptionSet)
    {
        _keys = keys;
        _eventCount = eventCount;
        _readSet = readSet;
        _writeSet = writeSet;
        _exceptionSet = exceptionSet;
    }

    @property size_t length()
    {
        return _eventCount;
    }

    int opApply(scope int delegate(ref SelectionKey) dg)
    {
        int rc = 0;
        ISelectable.Handle handle;
        Event events;

        debug (selector)
            Stdout.format("--- SelectSelectionSet.opApply() ({0} elements)\n", _eventCount);

        foreach (SelectionKey current; _keys)
        {
            handle = current.conduit.fileHandle();

            if (_readSet.isSet(handle))
                events = Event.Read;
            else
                events = Event.None;

            if (_writeSet.isSet(handle))
                events |= Event.Write;

            if (_exceptionSet.isSet(handle))
                events |= Event.Error;

            // Only invoke the delegate if there is an event for the conduit.
            if (events != Event.None)
            {
                current.events = events;

                debug (selector)
                    Stdout.format("---   Calling foreach delegate with selection key ({0}, 0x{1:x})\n",
                                  cast(int) handle, cast(uint) events);

                if ((rc = dg(current)) != 0)
                {
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


version (Windows)
{
    /**
     * Helper class used by the select()-based Selector to store handles.
     * On Windows the handles are kept in an array of uints and the first
     * element of the array stores the array "length" (i.e. number of handles
     * in the array). Everything is stored so that the native select() API
     * can use the HandleSet without additional conversions by just casting it
     * to a fd_set*.
     */
    private struct HandleSet
    {
        /** Default number of handles that will be held in the HandleSet. */
        const uint DefaultSize = 63;

        uint[] _buffer;

        /**
         * Constructor. Sets the initial number of handles that will be held
         * in the HandleSet.
         */
        void setup(uint size = DefaultSize)
        {
            _buffer = new uint[1 + size];
            _buffer[0] = 0;
        }

        /**
         *  return true if this handle set has been initialized.
         */
        @property bool initialized()
        {
            return _buffer.length > 0;
        }

        /**
         * Return the number of handles present in the HandleSet.
         */
        @property uint length()
        {
            return _buffer[0];
        }

        /**
         * Add the handle to the set.
         */
        void set(ISelectable.Handle handle)
        in
        {
            assert(handle);
        }
        body
        {
            if (!isSet(handle))
            {
                // If we added too many sockets we increment the size of the buffer
                if (++_buffer[0] >= _buffer.length)
                {
                    _buffer.length = _buffer[0] + 1;
                }
                _buffer[_buffer[0]] = cast(uint) handle;
            }
        }

        /**
         * Remove the handle from the set.
         */
        void clear(ISelectable.Handle handle)
        {
            for (uint i = 1; i <= _buffer[0]; ++i)
            {
                if (_buffer[i] == cast(uint) handle)
                {
                    // We don't need to keep the handles in the order in which
                    // they were inserted, so we optimize the removal by
                    // copying the last element to the position of the removed
                    // element.
                    if (i != _buffer[0])
                    {
                        _buffer[i] = _buffer[_buffer[0]];
                    }
                    _buffer[0]--;
                    return;
                }
            }
        }

        /**
         * Copy the contents of the HandleSet into this instance.
         */
        HandleSet copy(HandleSet handleSet)
        {
            if(handleSet._buffer.length > _buffer.length)
            {
                _buffer.length = handleSet._buffer[0] + 1;
            }


            _buffer[] = handleSet._buffer[0.._buffer.length];
            return this;
        }

        /**
         * Check whether the handle has been set.
         */
        public bool isSet(ISelectable.Handle handle)
        {
            if(_buffer.length == 0)
                return false;

            uint* start;
            uint* stop;

            for (start = _buffer.ptr + 1, stop = start + _buffer[0]; start != stop; start++)
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
            return cast(fd_set*) _buffer.ptr;
        }


        debug (selector)
        {
            /**
             * Dump the contents of a HandleSet into stdout.
             */
            void dump(const(char)[] name = null)
            {
                if (_buffer !is null && _buffer.length > 0 && _buffer[0] > 0)
                {
                    const(char)[] handleStr = new char[16];
                    const(char)[] handleListStr;
                    bool isFirst = true;

                    if (name is null)
                    {
                        name = "HandleSet";
                    }

                    for (uint i = 1; i < _buffer[0]; ++i)
                    {
                        if (!isFirst)
                        {
                            handleListStr ~= ", ";
                        }
                        else
                        {
                            isFirst = false;
                        }

                        handleListStr ~= itoa(handleStr, _buffer[i]);
                    }

                    Stdout.formatln("--- {0}[{1}]: {2}", name, _buffer[0], handleListStr);
                }
            }
        }
    }
}
else version (Posix)
{
    private import tango.core.BitManip;

    /**
     * Helper class used by the select()-based Selector to store handles.
     * On POSIX-compatible platforms the handles are kept in an array of bits.
     * Everything is stored so that the native select() API can use the
     * HandleSet without additional conversions by casting it to a fd_set*.
     */
    private struct HandleSet
    {
        /** Default number of handles that will be held in the HandleSet. */
        enum uint DefaultSize     = 1024;

        BitArray _buffer;

        /**
         * Constructor. Sets the initial number of handles that will be held
         * in the HandleSet.
         */
        void setup(uint size = DefaultSize)
        {
            if (size < 1024)
                size = 1024;

            _buffer.length = size;
        }

        /**
         * Return true if the handleset has been initialized
         */
        @property bool initialized()
        {
            return _buffer.length > 0;
        }

        /**
         * Add a handle to the set.
         */
        public void set(ISelectable.Handle handle)
        {
            // If we added too many sockets we increment the size of the buffer
            uint fd = cast(uint)handle;
            if(fd >= _buffer.length)
                _buffer.length = fd + 1;
            _buffer[fd] = true;
        }

        /**
         * Remove a handle from the set.
         */
        public void clear(ISelectable.Handle handle)
        {
            auto fd = cast(uint)handle;
            if(fd < _buffer.length)
                _buffer[fd] = false;
        }

        /**
         * Copy the contents of the HandleSet into this instance.
         */
        HandleSet copy(HandleSet handleSet)
        {
            //
            // adjust the length if necessary
            //
            if(handleSet._buffer.length != _buffer.length)
                _buffer.length = handleSet._buffer.length;
            
            _buffer[] = handleSet._buffer;
            return this;
        }

        /**
         * Check whether the handle has been set.
         */
        bool isSet(ISelectable.Handle handle)
        {
            auto fd = cast(uint)handle;
            if(fd < _buffer.length)
                return _buffer[fd];
            return false;
        }

        /**
         * Cast the current object to a pointer to an fd_set, to be used with the
         * select() system call.
         */
        fd_set* opCast()
        {
            return cast(fd_set*) _buffer.ptr;
        }

        debug (selector)
        {
            /**
             * Dump the contents of a HandleSet into stdout.
             */
            void dump(const(char)[] name = null)
            {
                if (_buffer !is null && _buffer.length > 0)
                {
                    const(char)[] handleStr = new char[16];
                    const(char)[] handleListStr;
                    bool isFirst = true;

                    if (name is null)
                    {
                        name = "HandleSet";
                    }

                    for (uint i = 0; i < _buffer.length * _buffer[0].sizeof; ++i)
                    {
                        if (isSet(cast(ISelectable.Handle) i))
                        {
                            if (!isFirst)
                            {
                                handleListStr ~= ", ";
                            }
                            else
                            {
                                isFirst = false;
                            }
                            handleListStr ~= itoa(handleStr, i);
                        }
                    }
                    Stdout.formatln("--- {0}: {1}", name, handleListStr);
                }
            }
        }
    }
}
