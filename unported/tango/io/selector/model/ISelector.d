/*******************************************************************************
  copyright:   Copyright (c) 2006 Juan Jose Comellas. All rights reserved
  license:     BSD style: $(LICENSE)
  author:      Juan Jose Comellas $(EMAIL juanjo@comellas.com.ar)
*******************************************************************************/

module tango.io.selector.model.ISelector;

public import tango.time.Time;

public import tango.io.model.IConduit;

/**
 * Events that are used to register a Conduit to a selector and are returned
 * in a SelectionKey after calling ISelector.select().
 */
enum Event: uint
{
    None            = 0,        // No event
    // IMPORTANT: Do not change the values of the following symbols. They were
    //            set in this way to map the values returned by the POSIX poll()
    //            system call.
    Read            = (1 << 0), // POLLIN
    UrgentRead      = (1 << 1), // POLLPRI
    Write           = (1 << 2), // POLLOUT
    // The following events should not be used when registering a conduit to a
    // selector. They are only used when returning events to the user.
    Error           = (1 << 3), // POLLERR
    Hangup          = (1 << 4), // POLLHUP
    InvalidHandle   = (1 << 5)  // POLLNVAL
}


/**
 * The SelectionKey struct holds the information concerning the conduits and
 * their association to a selector. Each key keeps a reference to a registered
 * conduit and the events that are to be tracked for it. The 'events' member
 * of the key can take two meanings, depending on where it's used. If used
 * with the register() method of the selector it represents the events we want
 * to track; if used within a foreach cycle on an ISelectionSet it represents
 * the events that have been detected for a conduit.
 *
 * The SelectionKey can also hold an optional object via the 'attachment'
 * member. This member is very convenient to keep application-specific data
 * that will be needed when the tracked events are triggered.
 *
 * See_also: $(SYMLINK ISelector, ISelector),
 *           $(SYMLINK ISelectionSet, ISelectionSet)
 */
struct SelectionKey
{
    /**
     * The conduit referred to by the SelectionKey.
     */
    ISelectable conduit;

    /**
     * The registered (or selected) events as a bit mask of different Event
     * values.
     */
    Event events;

    /**
     * The attached Object referred to by the SelectionKey.
     */
    Object attachment;

    /**
     * Check if a Read event has been associated to this SelectionKey.
     */
    public bool isReadable()
    {
        return ((events & Event.Read) != 0);
    }

    /**
     * Check if an UrgentRead event has been associated to this SelectionKey.
     */
    public bool isUrgentRead()
    {
        return ((events & Event.UrgentRead) != 0);
    }

    /**
     * Check if a Write event has been associated to this SelectionKey.
     */
    public bool isWritable()
    {
        return ((events & Event.Write) != 0);
    }

    /**
     * Check if an Error event has been associated to this SelectionKey.
     */
    public bool isError()
    {
        return ((events & Event.Error) != 0);
    }

    /**
     * Check if a Hangup event has been associated to this SelectionKey.
     */
    public bool isHangup()
    {
        return ((events & Event.Hangup) != 0);
    }

    /**
     * Check if an InvalidHandle event has been associated to this SelectionKey.
     */
    public bool isInvalidHandle()
    {
        return ((events & Event.InvalidHandle) != 0);
    }
}


/**
 * Container that holds the SelectionKey's for all the conduits that have
 * triggered events during a previous invocation to ISelector.select().
 * Instances of this container are normally returned from calls to
 * ISelector.selectedSet().
 */
interface ISelectionSet
{
    /**
     * Returns the number of SelectionKey's in the set.
     */
    public abstract uint length();

    /**
     * Operator to iterate over a set via a foreach block.  Note that any
     * modifications to the SelectionKey will be ignored.
     */
    public abstract int opApply(int delegate(ref SelectionKey) dg);
}


/**
 * A selector is a multiplexor for I/O events associated to a Conduit.
 * All selectors must implement this interface.
 *
 * A selector needs to be initialized by calling the open() method to pass
 * it the initial amount of conduits that it will handle and the maximum
 * amount of events that will be returned per call to select(). In both cases,
 * these values are only hints and may not even be used by the specific
 * ISelector implementation you choose to use, so you cannot make any
 * assumptions regarding what results from the call to select() (i.e. you
 * may receive more or less events per call to select() than what was passed
 * in the 'maxEvents' argument. The amount of conduits that the selector can
 * manage will be incremented dynamically if necessary.
 *
 * To add or modify conduit registrations in the selector, use the register()
 * method.  To remove conduit registrations from the selector, use the
 * unregister() method.
 *
 * To wait for events from the conduits you need to call any of the select()
 * methods. The selector cannot be modified from another thread while
 * blocking on a call to these methods.
 *
 * Once the selector is no longer used you must call the close() method so
 * that the selector can free any resources it may have allocated in the call
 * to open().
 *
 * Examples:
 * ---
 * import tango.io.selector.model.ISelector;
 * import tango.io.SocketConduit;
 * import tango.io.Stdout;
 *
 * ISelector selector;
 * SocketConduit conduit1;
 * SocketConduit conduit2;
 * MyClass object1;
 * MyClass object2;
 * int eventCount;
 *
 * // Initialize the selector assuming that it will deal with 2 conduits and
 * // will receive 2 events per invocation to the select() method.
 * selector.open(2, 2);
 *
 * selector.register(conduit, Event.Read, object1);
 * selector.register(conduit, Event.Write, object2);
 *
 * eventCount = selector.select();
 *
 * if (eventCount > 0)
 * {
 *     char[16] buffer;
 *     int count;
 *
 *     foreach (SelectionKey key, selector.selectedSet())
 *     {
 *         if (key.isReadable())
 *         {
 *             count = (cast(SocketConduit) key.conduit).read(buffer);
 *             if (count != IConduit.Eof)
 *             {
 *                 Stdout.format("Received '{0}' from peer\n", buffer[0..count]);
 *                 selector.register(key.conduit, Event.Write, key.attachment);
 *             }
 *             else
 *             {
 *                 selector.unregister(key.conduit);
 *                 key.conduit.close();
 *             }
 *         }
 *
 *         if (key.isWritable())
 *         {
 *             count = (cast(SocketConduit) key.conduit).write("MESSAGE");
 *             if (count != IConduit.Eof)
 *             {
 *                 Stdout.print("Sent 'MESSAGE' to peer\n");
 *                 selector.register(key.conduit, Event.Read, key.attachment);
 *             }
 *             else
 *             {
 *                 selector.unregister(key.conduit);
 *                 key.conduit.close();
 *             }
 *         }
 *
 *         if (key.isError() || key.isHangup() || key.isInvalidHandle())
 *         {
 *             selector.unregister(key.conduit);
 *             key.conduit.close();
 *         }
 *     }
 * }
 *
 * selector.close();
 * ---
 */
interface ISelector
{
    /**
     * Initialize the selector.
     *
     * Params:
     * size         = Value that provides a hint for the maximum amount of
     *                conduits that will be registered
     * maxEvents    = Value that provides a hint for the maximum amount of
     *                conduit events that will be returned in the selection
     *                set per call to select.
     */
    public abstract void open(uint size, uint maxEvents);

    /**
     * Free any operating system resources that may have been allocated in the
     * call to open().
     *
     * Remarks:
     * Not all of the selectors need to free resources other than allocated
     * memory, but those that do will normally also add a call to close() in
     * their destructors.
     */
    public abstract void close();

    /**
     * Associate a conduit to the selector and track specific I/O events.
     * If the conduit is already part of the selector, modify the events or
     * atachment.
     *
     * Params:
     * conduit      = Conduit that will be associated to the selector;
     *                must be a valid conduit (i.e. not null and open).
     * events       = Bit mask of Event values that represent the events that
     *                will be tracked for the conduit.
     * attachment   = Optional object with application-specific data that will
     *                be available when an event is triggered for the conduit
     *
     * Examples:
     * ---
     * ISelector selector;
     * SocketConduit conduit;
     * MyClass object;
     *
     * selector.register(conduit, Event.Read | Event.Write, object);
     * ---
     */
    public abstract void register(ISelectable conduit, Event events,
                                  Object attachment = null);


    /**
     * Deprecated, use register instead.
     */
    deprecated public abstract void reregister(ISelectable conduit, Event
            events, Object attachment = null);

    /**
     * Remove a conduit from the selector.
     *
     * Params:
     * conduit      = Conduit that had been previously associated to the
     *                selector; it can be null.
     *
     * Remarks:
     * Unregistering a null conduit is allowed and no exception is thrown
     * if this happens.
     */
    public abstract void unregister(ISelectable conduit);


    /**
     * Wait indefinitely for I/O events from the registered conduits.
     *
     * Returns:
     * The amount of conduits that have received events; 0 if no conduits
     * have received events within the specified timeout and -1 if there
     * was an error.
     */
    public abstract int select();

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
     * have received events within the specified timeout.
     */
    public abstract int select(TimeSpan timeout);

    /**
     * Wait for I/O events from the registered conduits for a specified
     * amount of time.
     *
     * Note: This representation of timeout is not always accurate, so it is
     * possible that the function will return with a timeout before the
     * specified period.  For more accuracy, use the TimeSpan version.
     *
     * Note: Implementers should define this method as:
     * -------
     * select(TimeSpan.interval(timeout));
     * -------
     *
     * Params:
     * timeout  = The maximum amount of time in seconds that the
     *            selector will wait for events from the conduits; the
     *            amount of time is relative to the current system time
     *            (i.e. just the number of milliseconds that the selector
     *            has to wait for the events).
     *
     * Returns:
     * The amount of conduits that have received events; 0 if no conduits
     * have received events within the specified timeout.
     */
    public abstract int select(double timeout);

    /**
     * Return the selection set resulting from the call to any of the select()
     * methods.
     *
     * Remarks:
     * If the call to select() was unsuccessful or it did not return any
     * events, the returned value will be null.
     */
    public abstract ISelectionSet selectedSet();

    /**
     * Return the selection key resulting from the registration of a conduit
     * to the selector.
     *
     * Remarks:
     * If the conduit is not registered to the selector the returned
     * value will SelectionKey.init. No exception will be thrown by this
     * method.
     */
    public abstract SelectionKey key(ISelectable conduit);

    /**
     * Iterate through the currently registered selection keys.  Note that you
     * should not erase or add any items from the selector while iterating,
     * although you can register existing conduits again.
     */
    public abstract int opApply(int delegate(ref SelectionKey sk) dg);
}
