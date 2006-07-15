/*******************************************************************************
  copyright:   Copyright (c) 2006 Juan Jose Comellas. All rights reserved
  license:     BSD style: $(LICENSE)
  author:      Juan Jose Comellas <juanjo@comellas.com.ar>
*******************************************************************************/

module tango.io.selector.model.ISelector;

public import tango.io.model.IConduit;
public import tango.io.selector.Interval;

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
 * The SelectionKey class holds the information concerning the conduits and
 * their association to a selector. Each key keeps a reference to a registered
 * conduit and the events that are to be tracked for it. The 'events' member
 * of the key can take two meanings, depending on where it's used. If used
 * with the registration methods of the selector (register(), reregister()) it
 * represents the events we want to track; if used within a foreach cycle
 * on an ISelectionSet it represents the events that have been detected for a
 * conduit.
 *
 * The SelectionKey can also hold an optional object via the 'attachment'
 * member. This member is very convenient to keep application-specific data
 * that will be needed when the tracked events are triggered.
 *
 * See $(LINK $(CODEURL)tango.io.selector.ISelector),
 * $(LINK $(CODEURL)tango.io.selector.ISelectionSet)
 */
class SelectionKey
{
    private IConduit _conduit;
    private Event _events;
    private Object _attachment;

    /**
     * Constructor
     */
    public this()
    {
    }

    /**
     * Constructor
     *
     * Params:
     * conduit      = conduit that will be associated to this SelectionKey
     * events       = events that will be tracked for the conduit
     * attachment   = optional object with application-specific data that will
     *                be available when an event is triggered for the conduit
     *
     * Examples:
     * ---
     * SocketConduit cond;
     *
     * auto key = new SelectionKey(cond, Event.Read | Event.Write);
     * ---
     */
    public this(IConduit conduit, Event events, Object attachment = null)
    {
        _conduit = conduit;
        _events = events;
        _attachment = null;
    }

    /**
     * Return the conduit held by the instance.
     */
    public IConduit conduit()
    {
        return _conduit;
    }

    /**
     * Set the conduit held by the instance
     */
    public void conduit(IConduit conduit)
    {
        _conduit = conduit;
    }

    /**
     * Return the registered events as a bit mask of different Event values.
     */
    public Event events()
    {
        return _events;
    }

    /**
     * Set the registered events as a bit mask of different Event values.
     */
    public void events(Event events)
    {
        _events = events;
    }

    /**
     * Return the attached Object held by the instance.
     */
    public Object attachment()
    {
        return _attachment;
    }

    /**
     * Set the attached Object held by the instance
     */
    public void attachment(Object attachment)
    {
        _attachment = attachment;
    }

    /**
     * Check if a Read event has been associated to this SelectionKey.
     */
    public bool isReadable()
    {
        return ((_events & Event.Read) != 0);
    }

    /**
     * Check if an UrgentRead event has been associated to this SelectionKey.
     */
    public bool isUrgentRead()
    {
        return ((_events & Event.UrgentRead) != 0);
    }

    /**
     * Check if a Write event has been associated to this SelectionKey.
     */
    public bool isWritable()
    {
        return ((_events & Event.Write) != 0);
    }

    /**
     * Check if an Error event has been associated to this SelectionKey.
     */
    public bool isError()
    {
        return ((_events & Event.Error) != 0);
    }

    /**
     * Check if a Hangup event has been associated to this SelectionKey.
     */
    public bool isHangup()
    {
        return ((_events & Event.Hangup) != 0);
    }

    /**
     * Check if an InvalidHandle event has been associated to this SelectionKey.
     */
    public bool isInvalidHandle()
    {
        return ((_events & Event.InvalidHandle) != 0);
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
     * Operator to iterate over a set via a foreach block.
     */
    public abstract int opApply(int delegate(inout SelectionKey) dg);
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
 * To add, modify or remove conduit registrations to the selector you use
 * the register(), reregister() and unregister() methods respectively.
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
 * import mango.io.selector.model.ISelector;
 * import mango.io.SocketConduit;
 * import mango.io.Stdout;
 *
 * ISelector selector;
 * SocketConduit conduit1;
 * SocketConduit conduit2;
 * MyClass object1;
 * MyClass object2;
 * uint eventCount;
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
 *             count = key.conduit.read(buffer);
 *             if (count != IConduit.Eof)
 *             {
 *                 Stdout.format("Received '{0}' from peer\n", buffer[0..count]);
 *                 selector.reregister(key.conduit, Event.Write, key.attachment);
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
 *             count = key.conduit.write("MESSAGE");
 *             if (count != IConduit.Eof)
 *             {
 *                 Stdout.print("Sent 'MESSAGE' to peer\n");
 *                 selector.reregister(key.conduit, Event.Read, key.attachment);
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
     * size         = value that provides a hint for the maximum amount of
     *                conduits that will be registered
     * maxEvents    = value that provides a hint for the maximum amount of
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
     *
     * Params:
     * conduit      = conduit that will be associated to the selector;
     *                must be a valid conduit (i.e. not null and open).
     * events       = bit mask of Event values that represent the events that
     *                will be tracked for the conduit.
     * attachment   = optional object with application-specific data that will
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
    public abstract void register(IConduit conduit, Event events,
                                  Object attachment = null);

    /**
     * Modify the events that are being tracked or the 'attachment' field
     * for an already registered conduit.
     *
     * Params:
     * conduit      = conduit that will be associated to the selector;
     *                must be a valid conduit (i.e. not null and open).
     * events       = bit mask of Event values that represent the events that
     *                will be tracked for the conduit.
     * attachment   = optional object with application-specific data that will
     *                be available when an event is triggered for the conduit
     *
     * Remarks:
     * The 'attachment' member of the SelectionKey will always be overwritten,
     * even if it's null.
     *
     * Examples:
     * ---
     * ISelector selector;
     * SocketConduit conduit;
     * MyClass object;
     *
     * selector.reregister(conduit, Event.Write, object);
     * ---
     */
    public abstract void reregister(IConduit conduit, Event events,
                                    Object attachment = null);
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
     */
    public abstract void unregister(IConduit conduit);

    /**
     * Wait indefinitely for I/O events from the registered conduits.
     *
     * Returns:
     * The amount of conduits that have received events; 0 if no conduits
     * have received events within the specified timeout; and -1 if the
     * wakeup() method has been called from another thread.
     */
    public abstract int select();

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
     */
    public abstract int select(Interval timeout);

    /**
     * Causes the first call to select() that has not yet returned to return
     * immediately.
     *
     * If another thread is currently blocked in a call to any of the
     * select() methods then that call will return immediately. If no
     * selection operation is currently in progress then the next invocation
     * of one of these methods will return immediately. In any case the value
     * returned by that invocation may be non-zero. Subsequent invocations of
     * the select() methods will block as usual unless this method is invoked
     * again in the meantime.
     */
    // public abstract void wakeup();

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
     * value will be null. No exception will be thrown by this method.
     */
    public abstract SelectionKey key(IConduit conduit);
}
