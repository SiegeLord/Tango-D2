/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        May 2004 : Initial release
        version:        Oct 2004: Hierarchy moved due to circular dependencies
        version:        Apr 2008: Lazy delegates removed due to awkward usage
        author:         Kris


        Simplified, pedestrian usage:
        ---
        import tango.util.log.Config;

        Log ("hello world");
        Log ("temperature is {} degrees", 75);
        ---

        Generic usage:

        Loggers are named entities, sometimes shared, sometimes specific to
        a particular portion of code. The names are generally hierarchical in
        nature, using dot notation (with '.') to separate each named section.
        For example, a typical name might be something like "mail.send.writer"
        ---
        import tango.util.log.Log;

        auto log = Log.lookup ("mail.send.writer");

        log.info  ("an informational message");
        log.error ("an exception message: {}", exception);

        etc ...
        ---

        It is considered good form to pass a logger instance as a function or
        class-ctor argument, or to assign a new logger instance during static
        class construction. For example: if it were considered appropriate to
        have one logger instance per class, each might be constructed like so:
        ---
        private Logger log;

        static this()
        {
            log = Log.lookup (nameOfThisClassOrStructOrModule);
        }
        ---

        Messages passed to a Logger are assumed to be either self-contained
        or configured with "{}" notation a la Layout & Stdout:
        ---
        log.warn ("temperature is {} degrees!", 101);
        ---

        Note that an internal workspace is used to format the message, which
        is limited to 2000 bytes. Use "{.256}" truncation notation to limit
        the size of individual message components, or use explicit formatting:
        ---
        char[4096] buf = void;

        log.warn (log.format (buf, "a very long message: {}", someLongMessage));
        ---

        To avoid overhead when constructing arguments passed to formatted
        messages, you should check to see whether a logger is active or not:
        ---
        if (log.warn)
            log.warn ("temperature is {} degrees!", complexFunction());
        ---

        tango.log closely follows both the API and the behaviour as documented
        at the official Log4J site, where you'll find a good tutorial. Those
        pages are hosted over
        <A HREF="http://logging.apache.org/log4j/docs/documentation.html">here</A>.

*******************************************************************************/

module tango.util.log.Log;

private import  tango.sys.Common;

private import  tango.time.Clock;

private import  tango.core.Exception;

private import  tango.io.model.IConduit;

private import  tango.text.convert.Format;

private import  tango.util.log.model.ILogger;

/*******************************************************************************

        Platform issues ...

*******************************************************************************/

version (GNU)
        {
        private import tango.core.Vararg;
        alias void* Arg;
        alias va_list ArgList;
        }
else version (DigitalMars)
        {
        private import tango.core.Vararg;
        alias void* Arg;
        alias va_list ArgList;

    version(X86_64)  version = DigitalMarsX64;

        }
     else
        {
        alias void* Arg;
        alias void* ArgList;
        }

/*******************************************************************************

        Pull in additional functions from the C library

*******************************************************************************/

extern (C)
{
        private int memcmp (const(void) *, const(void) *, size_t);
}

version (Win32)
{
        private extern(Windows) int QueryPerformanceCounter(ulong *count);
        private extern(Windows) int QueryPerformanceFrequency(ulong *frequency);
}

/*******************************************************************************

        These represent the standard LOG4J event levels. Note that
        Debug is called Trace here, because debug is a reserved word
        in D

*******************************************************************************/

alias ILogger.Level Level;


/*******************************************************************************

        Manager for routing Logger calls to the default hierarchy. Note
        that you may have multiple hierarchies per application, but must
        access the hierarchy directly for root() and lookup() methods within
        each additional instance.

*******************************************************************************/

public struct Log
{
        // support for old API
        public alias lookup getLogger;

        // trivial usage via opCall
        public alias formatln opCall;

        // internal use only
        private static __gshared Hierarchy base;
        private static __gshared Time beginTime;

        version (Win32)
        {
                private static __gshared double multiplier;
                private static __gshared ulong  timerStart;
        }

        private struct  Pair {const(char)[] name; Level value;}

        private static  __gshared Level [immutable(char)[]] map;

        private static  __gshared Pair[] Pairs =
                        [
                        {"TRACE",  Level.Trace},
                        {"Trace",  Level.Trace},
                        {"trace",  Level.Trace},
                        {"INFO",   Level.Info},
                        {"Info",   Level.Info},
                        {"info",   Level.Info},
                        {"WARN",   Level.Warn},
                        {"Warn",   Level.Warn},
                        {"warn",   Level.Warn},
                        {"ERROR",  Level.Error},
                        {"Error",  Level.Error},
                        {"error",  Level.Error},
                        {"Fatal",  Level.Fatal},
                        {"FATAL",  Level.Fatal},
                        {"fatal",  Level.Fatal},
                        {"NONE",   Level.None},
                        {"None",   Level.None},
                        {"none",   Level.None},
                        ];

        // logging-level names
        private __gshared immutable char[][] LevelNames =
        [
                "Trace", "Info", "Warn", "Error", "Fatal", "None"
        ];

        /***********************************************************************

                Initialize the base hierarchy

        ***********************************************************************/

        shared static this ()
        {
                base = new Hierarchy ("tango");

                foreach (p; Pairs)
                         map[p.name] = p.value;

                version (Posix)
                {
                        beginTime = Clock.now;
                }

                version (Win32)
                {
                        ulong freq;

                        if (! QueryPerformanceFrequency (&freq))
                              throw new PlatformException ("high-resolution timer is not available");

                        QueryPerformanceCounter (&timerStart);
                        multiplier = cast(double) TimeSpan.TicksPerSecond / freq;
                        beginTime = Clock.now;
                }
        }

        /***********************************************************************

                Return the level of a given name

        ***********************************************************************/

        static Level convert (const(char[]) name, Level def=Level.Trace)
        {
                auto p = name in map;
                if (p)
                    return *p;
                return def;
        }

        /***********************************************************************

                Return the current time

        ***********************************************************************/

        @property static Time time ()
        {
                version (Posix)
                {
                        return Clock.now;
                }

                version (Win32)
                {
                        ulong now;

                        QueryPerformanceCounter (&now);
                        return beginTime + TimeSpan(cast(long)((now - timerStart) * multiplier));
                }
        }

        /***********************************************************************

                Return the root Logger instance. This is the ancestor of
                all loggers and, as such, can be used to manipulate the
                entire hierarchy. For instance, setting the root 'level'
                attribute will affect all other loggers in the tree.

        ***********************************************************************/

        @property static Logger root ()
        {
                return base.root;
        }

        /***********************************************************************

                Return an instance of the named logger. Names should be
                hierarchical in nature, using dot notation (with '.') to
                separate each name section. For example, a typical name
                might be something like "tango.io.Stdout".

                If the logger does not currently exist, it is created and
                inserted into the hierarchy. A parent will be attached to
                it, which will be either the root logger or the closest
                ancestor in terms of the hierarchical name space.

        ***********************************************************************/

        static Logger lookup (const(char[]) name)
        {
                return base.lookup (name);
        }

        /***********************************************************************

                Return text name for a log level

        ***********************************************************************/

        static const(char)[] convert (int level)
        {
                assert (level >= Level.Trace && level <= Level.None);
                return LevelNames[level];
        }

        /***********************************************************************

                Return the singleton hierarchy.

        ***********************************************************************/

        static Hierarchy hierarchy ()
        {
                return base;
        }

        /***********************************************************************

                Pedestrian usage support, as an alias for Log.root.info()

        ***********************************************************************/

        static void formatln (const(char[]) fmt, ...)
        {
            version (DigitalMarsX64)
            {
                va_list ap;

                version(GNU) {} else va_start(ap, __va_argsave);

                scope(exit) va_end(ap);

                root.format (Level.Info, fmt, _arguments, ap);
            }
            else            
                root.format (Level.Info, fmt, _arguments, _argptr);
        }

        /***********************************************************************

                Initialize the behaviour of a basic logging hierarchy.

                Adds a StreamAppender to the root node, and sets
                the activity level to be everything enabled.

        ***********************************************************************/

        static void config (OutputStream stream, bool flush = true)
        {
                root.add (new AppendStream (stream, flush));
        }
}


/*******************************************************************************

        Loggers are named entities, sometimes shared, sometimes specific to
        a particular portion of code. The names are generally hierarchical in
        nature, using dot notation (with '.') to separate each named section.
        For example, a typical name might be something like "mail.send.writer"
        ---
        import tango.util.log.Log;format

        auto log = Log.lookup ("mail.send.writer");

        log.info  ("an informational message");
        log.error ("an exception message: {}", exception.toString);

        etc ...
        ---

        It is considered good form to pass a logger instance as a function or
        class-ctor argument, or to assign a new logger instance during static
        class construction. For example: if it were considered appropriate to
        have one logger instance per class, each might be constructed like so:
        ---
        private Logger log;

        static this()
        {
            log = Log.lookup (nameOfThisClassOrStructOrModule);
        }
        ---

        Messages passed to a Logger are assumed to be either self-contained
        or configured with "{}" notation a la Layout & Stdout:
        ---
        log.warn ("temperature is {} degrees!", 101);
        ---

        Note that an internal workspace is used to format the message, which
        is limited to 2048 bytes. Use "{.256}" truncation notation to limit
        the size of individual message components. You can also use your own
        formatting buffer:
        ---
        log.buffer (new char[](4096));

        log.warn ("a very long warning: {}", someLongWarning);
        ---

        Or you can use explicit formatting:
        ---
        char[4096] buf = void;

        log.warn (log.format (buf, "a very long warning: {}", someLongWarning));
        ---

        To avoid overhead when constructing argument passed to formatted
        messages, you should check to see whether a logger is active or not:
        ---
        if (log.enabled (log.Warn))
            log.warn ("temperature is {} degrees!", complexFunction());
        ---

        The above will be handled implicitly by the logging system when
        macros are added to the language (used to be handled implicitly
        via lazy delegates, but usage of those turned out to be awkward).

        tango.log closely follows both the API and the behaviour as documented
        at the official Log4J site, where you'll find a good tutorial. Those
        pages are hosted over
        <A HREF="http://logging.apache.org/log4j/docs/documentation.html">here</A>.

*******************************************************************************/

public class Logger : ILogger
{

        alias Level.Trace Trace;        // shortcut to Level values
        alias Level.Info  Info;         // ...
        alias Level.Warn  Warn;         // ...
        alias Level.Error Error;        // ...
        alias Level.Fatal Fatal;        // ...

        alias append      opCall;       // shortcut to append

        /***********************************************************************

                Context for a hierarchy, used for customizing behaviour
                of log hierarchies. You can use this to implement dynamic
                log-levels, based upon filtering or some other mechanism

        ***********************************************************************/

        interface Context
        {
                /// return a label for this context
                @property const const(char)[] label ();

                /// first arg is the setting of the logger itself, and
                /// the second arg is what kind of message we're being
                /// asked to produce
                const bool enabled (Level setting, Level target);
        }

        /***********************************************************************

        ***********************************************************************/

        private Logger          next,
                                parent;

        private Hierarchy       host_;
        private const(char)[]          name_;
        private Level           level_;
        private bool            additive_;
        private Appender        appender_;
        private char[]          buffer_;
        private size_t          buffer_size_;

        /***********************************************************************

                Construct a LoggerInstance with the specified name for the
                given hierarchy. By default, logger instances are additive
                and are set to emit all events.

        ***********************************************************************/

        private this (Hierarchy host, const(char[]) name)
        {
                host_ = host;
                level_ = Level.Trace;
                additive_ = true;
                name_ = name;
        }

        /***********************************************************************

                Is this logger enabed for the specified Level?

        ***********************************************************************/

        final bool enabled (Level level = Level.Fatal)
        {
                return host_.context.enabled (level_, level);
        }

        /***********************************************************************

                Is trace enabled?

        ***********************************************************************/

        final bool trace ()
        {
                return enabled (Level.Trace);
        }

        /***********************************************************************

                Append a trace message

        ***********************************************************************/

        final void trace (const(char[]) fmt, ...)
        {
            version (DigitalMarsX64)
            {
                va_list ap;

                va_start(ap, __va_argsave);

                scope(exit) va_end(ap);

                format (Level.Trace, fmt, _arguments, ap);
            }
            else            
                format (Level.Trace, fmt, _arguments, _argptr);
        }

        /***********************************************************************

                Is info enabled?

        ***********************************************************************/

        final bool info ()
        {
                return enabled (Level.Info);
        }

        /***********************************************************************

                Append an info message

        ***********************************************************************/

        final void info (const(char[]) fmt, ...)
        {
            version (DigitalMarsX64)
            {
                va_list ap;

                va_start(ap, __va_argsave);

                scope(exit) va_end(ap);

                format (Level.Info, fmt, _arguments, ap);
            }
            else            
                format (Level.Info, fmt, _arguments, _argptr);
        }

        /***********************************************************************

                Is warn enabled?

        ***********************************************************************/

        final bool warn ()
        {
                return enabled (Level.Warn);
        }

        /***********************************************************************

                Append a warning message

        ***********************************************************************/

        final void warn (const(char[]) fmt, ...)
        {
            version (DigitalMarsX64)
            {
                va_list ap;

                va_start(ap, __va_argsave);

                scope(exit) va_end(ap);

                format (Level.Warn, fmt, _arguments, ap);
            }
            else            
                format (Level.Warn, fmt, _arguments, _argptr);
        }

        /***********************************************************************

                Is error enabled?

        ***********************************************************************/

        final bool error ()
        {
                return enabled (Level.Error);
        }

        /***********************************************************************

                Append an error message

        ***********************************************************************/

        final void error (const(char[]) fmt, ...)
        {
            version (DigitalMarsX64)
            {
                va_list ap;

                va_start(ap, __va_argsave);

                scope(exit) va_end(ap);

                format (Level.Error, fmt, _arguments, ap);
            }
            else            
                format (Level.Error, fmt, _arguments, _argptr);
        }

        /***********************************************************************

                Is fatal enabled?

        ***********************************************************************/

        final bool fatal ()
        {
                return enabled (Level.Fatal);
        }

        /***********************************************************************

                Append a fatal message

        ***********************************************************************/

        final void fatal (const(char[]) fmt, ...)
        {
            version (DigitalMarsX64)
            {
                va_list ap;

                va_start(ap, __va_argsave);

                scope(exit) va_end(ap);

                format (Level.Fatal, fmt, _arguments, ap);
            }
            else            
                format (Level.Fatal, fmt, _arguments, _argptr);
        }

        /***********************************************************************

                Return the name of this Logger (sans the appended dot).

        ***********************************************************************/

        @property final const(char)[] name ()
        {
                size_t i = name_.length;
                if (i > 0)
                    --i;
                return name_[0 .. i];
        }

        /***********************************************************************

                Return the Level this logger is set to

        ***********************************************************************/

        final Level level ()
        {
                return level_;
        }

        /***********************************************************************

                Set the current level for this logger (and only this logger).

        ***********************************************************************/

        final Logger level (Level l)
        {
                return level (l, false);
        }

        /***********************************************************************

                Set the current level for this logger, and (optionally) all
                of its descendents.

        ***********************************************************************/

        final Logger level (Level level, bool propagate)
        {
                level_ = level;
                if (propagate)
                    foreach (log; host_)
                             if (log.isChildOf (name_))
                                 log.level_ = level;
                return this;
        }

        /***********************************************************************

                Is this logger additive? That is, should we walk ancestors
                looking for more appenders?

        ***********************************************************************/

        @property final const bool additive ()
        {
                return additive_;
        }

        /***********************************************************************

                Set the additive status of this logger. See bool additive().

        ***********************************************************************/

        @property final Logger additive (bool enabled)
        {
                additive_ = enabled;
                return this;
        }

        /***********************************************************************

                Add (another) appender to this logger. Appenders are each
                invoked for log events as they are produced. At most, one
                instance of each appender will be invoked.

        ***********************************************************************/

        final Logger add (Appender another)
        {
                assert (another);
                another.next = appender_;
                appender_ = another;
                return this;
        }

        /***********************************************************************

                Remove all appenders from this Logger

        ***********************************************************************/

        final Logger clear ()
        {
                appender_ = null;
                return this;
        }

        /***********************************************************************

                Get the current formatting buffer (null if none).

        ***********************************************************************/

        @property final char[] buffer ()
        {
                return buffer_;
        }

        /***********************************************************************

                Set the current formatting buffer.

                Set to null to use the default internal buffer.

        ***********************************************************************/

        @property final Logger buffer (char[] buf)
        {
                buffer_ = buf;
                buffer_size_ = buf.length;
                return this;
        }

        /***********************************************************************

                Get time since this application started

        ***********************************************************************/

        @property final const TimeSpan runtime ()
        {
                return Clock.now - Log.beginTime;
        }

        /***********************************************************************

                Send a message to this logger via its appender list.

        ***********************************************************************/

        final Logger append (Level level, lazy const(char[]) exp)
        {
                if (host_.context.enabled (level_, level))
                   {
                   LogEvent event;

                   // set the event attributes and append it
                   event.set (host_, level, exp, name.length ? name_[0..$-1] : "root");
                   append (event);
                   }
                return this;
        }

        /***********************************************************************

                Send a message to this logger via its appender list.

        ***********************************************************************/

        private void append (LogEvent event)
        {
                // combine appenders from all ancestors
                auto links = this;
                Appender.Mask masks = 0;
                do {
                   auto appender = links.appender_;

                   // this level have an appender?
                   while (appender)
                         {
                         auto mask = appender.mask;

                         // have we visited this appender already?
                         if ((masks & mask) is 0)
                              // is appender enabled for this level?
                              if (appender.level <= event.level)
                                 {
                                 // append message and update mask
                                 appender.append (event);
                                 masks |= mask;
                                 }
                         // process all appenders for this node
                         appender = appender.next;
                         }
                     // process all ancestors
                   } while (links.additive_ && ((links = links.parent) !is null));
        }

        /***********************************************************************

                Return a formatted string from the given arguments

        ***********************************************************************/

        final char[] format (char[] buffer, const(char[]) formatStr, ...)
        {
            version (DigitalMarsX64)
            {
                va_list ap;

                va_start(ap, __va_argsave);

                scope(exit) va_end(ap);

                return Format.vprint (buffer, formatStr, _arguments, ap);
            }
            else
                return Format.vprint (buffer, formatStr, _arguments, _argptr);

        }

        /***********************************************************************

                Format and emit text from the given arguments

        ***********************************************************************/

        final Logger format (Level level, const(char[]) fmt, TypeInfo[] types, ArgList args)
        {
                if (types.length)
                {
                    if (buffer_ is null)
                        formatWithDefaultBuffer(level, fmt, types, args);
                    else
                        formatWithProvidedBuffer(level, fmt, types, args);
                }
                else
                   append (level, fmt);
                return this;
        }

        private void formatWithDefaultBuffer(Level level, const(char)[] fmt, TypeInfo[] types, ArgList args)
        {
            char[2048] tmp = void;
            formatWithBuffer(level, fmt, types, args, tmp);
        }

        private void formatWithProvidedBuffer(Level level, const(char)[] fmt, TypeInfo[] types, ArgList args)
        {
            formatWithBuffer(level, fmt, types, args, buffer_);
            buffer_.length = buffer_size_;
        }

        private void formatWithBuffer(Level level, const(char)[] fmt, TypeInfo[] types, ArgList args, char[] buf)
        {
            append (level, Format.vprint (buf, fmt, types, args));
        }

        /***********************************************************************

                See if the provided Logger name is a parent of this one. Note
                that each Logger name has a '.' appended to the end, such that
                name segments will not partially match.

        ***********************************************************************/

        private final bool isChildOf (const(char[]) candidate)
        {
                auto len = candidate.length;

                // possible parent if length is shorter
                if (len < name_.length)
                    // does the prefix match? Note we append a "." to each
                    // (the root is a parent of everything)
                    return (len is 0 ||
                            memcmp (&candidate[0], &name_[0], len) is 0);
                return false;
        }

        /***********************************************************************

                See if the provided Logger is a better match as a parent of
                this one. This is used to restructure the hierarchy when a
                new logger instance is introduced

        ***********************************************************************/

        private final bool isCloserAncestor (Logger other)
        {
                auto name = other.name_;
                if (isChildOf (name))
                    // is this a better (longer) match than prior parent?
                    if ((parent is null) || (name.length >= parent.name_.length))
                         return true;
                return false;
        }
}

/*******************************************************************************

        The Logger hierarchy implementation. We keep a reference to each
        logger in a hash-table for convenient lookup purposes, plus keep
        each logger linked to the others in an ordered group. Ordering
        places shortest names at the head and longest ones at the tail,
        making the job of identifying ancestors easier in an orderly
        fashion. For example, when propagating levels across descendents
        it would be a mistake to propagate to a child before all of its
        ancestors were taken care of.

*******************************************************************************/

private class Hierarchy : Logger.Context
{
        private Logger                  root_;
        private const(char)[]           name_,
                                        address_;
        private Logger.Context          context_;
        private Logger[char[]]          loggers;


        /***********************************************************************

                Construct a hierarchy with the given name.

        ***********************************************************************/

        this (const(char[]) name)
        {
                name_ = name;
                address_ = "network";

                // insert a root node; the root has an empty name
                root_ = new Logger (this, "");
                context_ = this;
        }

        /**********************************************************************

        **********************************************************************/

        final const const(char)[] label ()
        {
                return "";
        }

        /**********************************************************************


        **********************************************************************/

        final const bool enabled (Level level, Level test)
        {
                return test >= level;
        }

        /**********************************************************************

                Return the name of this Hierarchy

        **********************************************************************/

        @property final const const(char)[] name ()
        {
                return name_;
        }

        /**********************************************************************

                Set the name of this Hierarchy

        **********************************************************************/

        @property final void name (const(char[]) name)
        {
                name_ = name;
        }

        /**********************************************************************

                Return the address of this Hierarchy. This is typically
                attached when sending events to remote monitors.

        **********************************************************************/

        @property final const const(char)[] address ()
        {
                return address_;
        }

        /**********************************************************************

                Set the address of this Hierarchy. The address is attached
                used when sending events to remote monitors.

        **********************************************************************/

        @property final void address (const(char[]) address)
        {
                address_ = address;
        }

        /**********************************************************************

                Return the diagnostic context.  Useful for setting an
                override logging level.

        **********************************************************************/

        @property final Logger.Context context ()
        {
        	return context_;
        }

        /**********************************************************************

                Set the diagnostic context.  Not usually necessary, as a
                default was created.  Useful when you need to provide a
                different implementation, such as a ThreadLocal variant.

        **********************************************************************/

        @property final void context (Logger.Context context)
        {
        	context_ = context;
        }

        /***********************************************************************

                Return the root node.

        ***********************************************************************/

        @property final Logger root ()
        {
                return root_;
        }

        /***********************************************************************

                Return the instance of a Logger with the provided label. If
                the instance does not exist, it is created at this time.

                Note that an empty label is considered illegal, and will be
                ignored.

        ***********************************************************************/

        final Logger lookup (const(char[]) label)
        {
                if (label.length)
                    return inject (label, (const(char[]) name)
                                          {return new Logger (this, name);});
                return null;
        }

        /***********************************************************************

                traverse the set of configured loggers

        ***********************************************************************/

        final int opApply (scope int delegate(ref Logger) dg)
        {
                int ret;

                for (auto log=root; log; log = log.next)
                     if ((ret = dg(log)) != 0)
                          break;
                return ret;
        }

        /***********************************************************************

                Return the instance of a Logger with the provided label. If
                the instance does not exist, it is created at this time.

        ***********************************************************************/

        private Logger inject (const(char[]) label, scope Logger delegate(const(char[]) name) dg)
        {
                synchronized(this)
                {
                    // try not to allocate unless you really need to
                    char[255] stack_buffer;
                    char[] buffer = stack_buffer;

                    if (buffer.length < label.length + 1)
                        buffer.length = label.length + 1;

                    buffer[0 .. label.length] = label[];
                    buffer[label.length] = '.';

                    auto name = buffer[0 .. label.length + 1]; 
                    auto l = name in loggers;

                    if (l is null)
                       {
                       // don't use the stack allocated buffer
                       if (name.ptr is stack_buffer.ptr)
                           name = name.dup;
                       // create a new logger
                       auto li = dg(name);
                       l = &li;

                       // insert into linked list
                       insert (li);

                       // look for and adjust children. Don't force 
                       // property inheritance on existing loggers
                       update (li);

                       // insert into map
                       loggers [name.idup] = li;
                       }

                    return *l;
                }
        }

        /***********************************************************************

                Loggers are maintained in a sorted linked-list. The order
                is maintained such that the shortest name is at the root,
                and the longest at the tail.

                This is done so that updateLoggers() will always have a
                known environment to manipulate, making it much faster.

        ***********************************************************************/

        private void insert (Logger l)
        {
                Logger prev,
                       curr = root;

                while (curr)
                      {
                      // insert here if the new name is shorter
                      if (l.name.length < curr.name.length)
                          if (prev is null)
                              throw new IllegalElementException ("invalid hierarchy");
                          else
                             {
                             l.next = prev.next;
                             prev.next = l;
                             return;
                             }
                      else
                         // find best match for parent of new entry
                         // and inherit relevant properties (level, etc)
                         propagate (l, curr, true);

                      // remember where insertion point should be
                      prev = curr;
                      curr = curr.next;
                      }

                // add to tail
                prev.next = l;
        }

        /***********************************************************************

                Propagate hierarchical changes across known loggers.
                This includes changes in the hierarchy itself, and to
                the various settings of child loggers with respect to
                their parent(s).

        ***********************************************************************/

        private void update (Logger changed, bool force=false)
        {
                foreach (logger; this)
                         propagate (logger, changed, force);
        }

        /***********************************************************************

                Propagate changes in the hierarchy downward to child Loggers.
                Note that while 'parent' is always changed, the adjustment of
                'level' is selectable.

        ***********************************************************************/

        private void propagate (Logger logger, Logger changed, bool force=false)
        {
                // is the changed instance a better match for our parent?
                if (logger.isCloserAncestor (changed))
                   {
                   // update parent (might actually be current parent)
                   logger.parent = changed;

                   // if we don't have an explicit level set, inherit it
                   // Be careful to avoid recursion, or other overhead
                   if (force)
                       logger.level_ = changed.level();
                   }
        }
}



/*******************************************************************************

        Contains all information about a logging event, and is passed around
        between methods once it has been determined that the invoking logger
        is enabled for output.

        Note that Event instances are maintained in a freelist rather than
        being allocated each time, and they include a scratchpad area for
        EventLayout formatters to use.

*******************************************************************************/

package struct LogEvent
{
        private const(char)[]   msg_,
                                name_;
        private Time            time_;
        private Level           level_;
        private Hierarchy       host_;

        /***********************************************************************

                Set the various attributes of this event.

        ***********************************************************************/

        void set (Hierarchy host, Level level, const(char[]) msg, const(char[]) name)
        {
                time_ = Log.time;
                level_ = level;
                host_ = host;
                name_ = name;
                msg_ = msg;
        }

        /***********************************************************************

                Return the message attached to this event.

        ***********************************************************************/

        const const(char)[] toString ()
        {
                return msg_;
        }

        /***********************************************************************

                Return the name of the logger which produced this event

        ***********************************************************************/

        @property const const(char)[] name ()
        {
                return name_;
        }

        /***********************************************************************

                Return the logger level of this event.

        ***********************************************************************/

        @property const Level level ()
        {
                return level_;
        }

        /***********************************************************************

                Return the hierarchy where the event was produced from

        ***********************************************************************/

        @property Hierarchy host ()
        {
                return host_;
        }

        /***********************************************************************

                Return the time this event was produced, relative to the
                start of this executable

        ***********************************************************************/

        @property const TimeSpan span ()
        {
                return time_ - Log.beginTime;
        }

        /***********************************************************************

                Return the time this event was produced relative to Epoch

        ***********************************************************************/

        @property const const(Time) time ()
        {
                return time_;
        }

        /***********************************************************************

                Return time when the executable started

        ***********************************************************************/

        @property const(Time) started ()
        {
                return Log.beginTime;
        }

        /***********************************************************************

                Return the logger level name of this event.

        ***********************************************************************/

        @property const(char)[] levelName ()
        {
                return Log.LevelNames[level_];
        }

        /***********************************************************************

                Convert a time value (in milliseconds) to ascii

        ***********************************************************************/

        static char[] toMilli (char[] s, TimeSpan time)
        {
                assert (s.length > 0);
                long ms = time.millis;

                size_t len = s.length;
                do {
                   s[--len] = cast(char)(ms % 10 + '0');
                   ms /= 10;
                   } while (ms && len);
                return s[len..s.length];
        }
}


/*******************************************************************************

        Base class for all Appenders. These objects are responsible for
        emitting messages sent to a particular logger. There may be more
        than one appender attached to any logger. The actual message is
        constructed by another class known as an EventLayout.

*******************************************************************************/

public class Appender
{
        alias int Mask;

        private Appender        next_;
        private Level           level_;
        private Layout          layout_;
        private static __gshared Layout   generic;

        /***********************************************************************

                Interface for all logging layout instances

                Implement this method to perform the formatting of
                message content.

        ***********************************************************************/

        interface Layout
        {
                void format (LogEvent event, scope size_t delegate(const(void)[]) dg);
        }

        /***********************************************************************

                Return the mask used to identify this Appender. The mask
                is used to figure out whether an appender has already been
                invoked for a particular logger.

        ***********************************************************************/

        @property abstract const Mask mask ();

        /***********************************************************************

                Return the name of this Appender.

        ***********************************************************************/

        @property abstract const const(char)[] name ();

        /***********************************************************************

                Append a message to the output.

        ***********************************************************************/

        abstract void append (LogEvent event);

        /***********************************************************************

              Create an Appender and default its layout to LayoutSimple.

        ***********************************************************************/

        this ()
        {
                layout_ = generic;
        }

        /***********************************************************************

              Create an Appender and default its layout to LayoutSimple.

        ***********************************************************************/

        shared static this ()
        {
                generic = new LayoutTimer;
        }

        /***********************************************************************

                Return the current Level setting

        ***********************************************************************/

        @property final Level level ()
        {
                return level_;
        }

        /***********************************************************************

                Return the current Level setting

        ***********************************************************************/

        @property final Appender level (Level l)
        {
                level_ = l;
                return this;
        }

        /***********************************************************************

                Static method to return a mask for identifying the Appender.
                Each Appender class should have a unique fingerprint so that
                we can figure out which ones have been invoked for a given
                event. A bitmask is a simple an efficient way to do that.

        ***********************************************************************/

        protected Mask register (const(char)[] tag)
        {
                static Mask mask = 1;
                static Mask[immutable(char)[]] registry;

                Mask* p = tag in registry;
                if (p)
                    return *p;
                else
                   {
                   auto ret = mask;
                   registry [tag] = mask;

                   if (mask < 0)
                       throw new IllegalArgumentException ("too many unique registrations");

                   mask <<= 1;
                   return ret;
                   }
        }

        /***********************************************************************

                Set the current layout to be that of the argument, or the
                generic layout where the argument is null

        ***********************************************************************/

        @property void layout (Layout how)
        {
                layout_ = how ? how : generic;
        }

        /***********************************************************************

                Return the current Layout

        ***********************************************************************/

        @property Layout layout ()
        {
                return layout_;
        }

        /***********************************************************************

                Attach another appender to this one

        ***********************************************************************/

        @property void next (Appender appender)
        {
                next_ = appender;
        }

        /***********************************************************************

                Return the next appender in the list

        ***********************************************************************/

        @property Appender next ()
        {
                return next_;
        }

        /***********************************************************************

                Close this appender. This would be used for file, sockets,
                and such like.

        ***********************************************************************/

        void close ()
        {
        }
}


/*******************************************************************************

        An appender that does nothing. This is useful for cutting and
        pasting, and for benchmarking the tango.log environment.

*******************************************************************************/

public class AppendNull : Appender
{
        private Mask mask_;

        /***********************************************************************

                Create with the given Layout

        ***********************************************************************/

        this (Layout how = null)
        {
                mask_ = register (name);
                layout (how);
        }

        /***********************************************************************

                Return the fingerprint for this class

        ***********************************************************************/

        @property override final const Mask mask ()
        {
                return mask_;
        }

        /***********************************************************************

                Return the name of this class

        ***********************************************************************/

        @property override final const const(char)[] name ()
        {
                return this.classinfo.name;
        }

        /***********************************************************************

                Append an event to the output.

        ***********************************************************************/

        override final void append (LogEvent event)
        {
                layout.format (event, (const(void)[]){return cast(size_t) 0;});
        }
}


/*******************************************************************************

        Append to a configured OutputStream

*******************************************************************************/

public class AppendStream : Appender
{
        private Mask            mask_;
        private bool            flush_;
        private OutputStream    stream_;

        /***********************************************************************

                Create with the given stream and layout

        ***********************************************************************/

        this (OutputStream stream, bool flush = false, Appender.Layout how = null)
        {
                assert (stream);

                mask_ = register (name);
                stream_ = stream;
                flush_ = flush;
                layout (how);
        }

        /***********************************************************************

                Return the fingerprint for this class

        ***********************************************************************/

        @property override final const Mask mask ()
        {
                return mask_;
        }

        /***********************************************************************

                Return the name of this class

        ***********************************************************************/

        @property override const const(char)[] name ()
        {
                return this.classinfo.name;
        }

        /***********************************************************************

                Append an event to the output.

        ***********************************************************************/

        override final void append (LogEvent event)
        {
                version(Win32)
                        immutable char[] Eol = "\r\n";
                   else
                       immutable char[] Eol = "\n";

                synchronized (stream_)
                             {
                             layout.format (event, (const(void)[] content){return stream_.write(content);});
                             stream_.write (Eol);
                             if (flush_)
                                 stream_.flush();
                             }
        }
}

/*******************************************************************************

        A simple layout comprised only of time(ms), level, name, and message

*******************************************************************************/

public class LayoutTimer : Appender.Layout
{
        /***********************************************************************

                Subclasses should implement this method to perform the
                formatting of the actual message content.

        ***********************************************************************/

        void format (LogEvent event, scope size_t delegate(const(void)[]) dg)
        {
                char[20] tmp = void;

                dg (event.toMilli (tmp, event.span));
                dg (" ");
                dg (event.levelName);
                dg (" [");
                dg (event.name);
                dg ("] ");
                dg (event.host.context.label);
                dg ("- ");
                dg (event.toString());
        }
}


/*******************************************************************************

*******************************************************************************/

debug (Log)
{
        import tango.io.Console;

        void main()
        {
                Log.config (Cerr.stream);
                auto log = Log.lookup ("fu.bar");
                log.level = log.Trace;
                // traditional usage
                log.trace ("hello {}", "world");

                char[100] buf;
                log (log.Trace, log.format(buf, "hello {}", "world"));

                // formatted output
/*                /
                auto format = Log.format;
                log.info (format ("blah{}", 1));

                // snapshot
                auto snap = Log.snapshot (log, Level.Error);
                snap.format ("arg{}; ", 1);
                snap.format ("arg{}; ", 2);
                //log.trace (snap.format ("error! arg{}", 3));
                snap.flush;
*/
        }
}
