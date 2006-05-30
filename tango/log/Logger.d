/*******************************************************************************

        @file Logger.d

        Copyright (c) 2004 Kris Bell
        
        This software is provided 'as-is', without any express or implied
        warranty. In no event will the authors be held liable for damages
        of any kind arising from the use of this software.
        
        Permission is hereby granted to anyone to use this software for any 
        purpose, including commercial applications, and to alter it and/or 
        redistribute it freely, subject to the following restrictions:
        
        1. The origin of this software must not be misrepresented; you must 
           not claim that you wrote the original software. If you use this 
           software in a product, an acknowledgment within documentation of 
           said product would be appreciated but is not required.

        2. Altered source versions must be plainly marked as such, and must 
           not be misrepresented as being the original software.

        3. This notice may not be removed or altered from any distribution
           of the source.

        4. Derivative works are permitted, but they must carry this notice
           in full and credit the original source.


                        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

      
        @version        Initial version, May 2004
        @author         Kris


*******************************************************************************/

module tango.log.Logger;

private import  tango.log.Manager,
                tango.log.Appender;

public  import  tango.log.model.ILogger;

/*******************************************************************************

        This is the primary API to the log package. Use the two static 
        methods to access and/or create Logger instances, and the other
        methods to modify specific Logger attributes. 
        
        @code
        Logger myLogger = Logger.getLogger ("my.logger");

        myLogger.info  ("an informational message");
        myLogger.error ("an exception message: " ~ exception.toString);

        etc ...
        @endcode

        Messages passed to a Logger are assumed to be pre-formatted. You 
        may find that the TextFormat class is handy for collating various 
        components of the message. 
        
        @code
        TextFormat tf = new TextFormat (256);

        myLogger.warn (tf.format("temperature is %d degrees!", 101));
        @endcode

        You may also need to use one of the two classes BasicConfigurator 
        and PropertyConfigurator, along with the various Layout & Appender 
        implementations to support your exact rendering needs.
        
        tango.log closely follows both the API and the behaviour as documented 
        at the official Log4J site, where you'll find a good tutorial. Those 
        pages are hosted over 
        <A HREF="http://logging.apache.org/log4j/docs/documentation.html">here</A>.

*******************************************************************************/

public class Logger : ILogger
{
        /***********************************************************************

                Return the root Logger instance. This is the ancestor of
                all loggers and, as such, can be used to manipulate the 
                entire hierarchy. For instance, setting the root 'level' 
                attribute will affect all other loggers in the tree.

        ***********************************************************************/

        static Logger getRootLogger ()
        {
                return Manager.getRootLogger ();
        }

        /***********************************************************************

                Return an instance of the named logger. Names should be
                hierarchical in nature, using dot notation (with '.') to 
                seperate each name section. For example, a typical name 
                might be something like "tango.io.Buffer".

                If the logger does not currently exist, it is created and
                inserted into the hierarchy. A parent will be attached to
                it, which will be either the root logger or the closest
                ancestor in terms of the hierarchical name space.

        ***********************************************************************/

        static Logger getLogger (char[] name)
        {
                return Manager.getLogger (name);
        }

        /***********************************************************************

                Add a trace messages. This is called 'debug' in Log4J but
                that is a  reserved word in the D language. This needs some
                more thought.
                
        ***********************************************************************/

        abstract void trace (char[] msg);

        /***********************************************************************
                
                Add an info message

        ***********************************************************************/

        abstract void info (char[] msg);

        /***********************************************************************

                Add a warning message

        ***********************************************************************/

        abstract void warn (char[] msg);

        /***********************************************************************

                Add an error message

        ***********************************************************************/

        abstract void error (char[] msg);

        /***********************************************************************

                Add a fatal message

        ***********************************************************************/

        abstract void fatal (char[] msg);

        /***********************************************************************
        
                Return the name of this Logger

        ***********************************************************************/

        abstract char[] getName ();

        /***********************************************************************

                Return the current level assigned to this logger

        ***********************************************************************/

        abstract Level getLevel ();

        /***********************************************************************

                Set the activity level of this logger. Levels control how
                much information is emitted during runtime, and relate to
                each other as follows:

                    Trace < Info < Warn < Error < Fatal < None

                That is, if the level is set to Error, only calls to the
                error() and fatal() methods will actually produce output:
                all others will be inhibited.

                Note that Log4J is a hierarchical environment, and each
                logger defaults to inheriting a level from its parent.


        ***********************************************************************/

        abstract void setLevel (Level level);

        /***********************************************************************
        
                same as setLevel (Level), but with additional control over 
                whether the children are forced to accept the changed level
                or not. If 'force' is false, then children adopt the parent
                level only if they have their own level set to Level.None

        ***********************************************************************/

        abstract void setLevel (Level level, bool force);

        /***********************************************************************
        
                Is this logger enabled for the provided level?

        ***********************************************************************/

        abstract bool isEnabled (Level level);

        /***********************************************************************

                Return whether this logger uses additive appenders or not. 
                See setAdditive().

        ***********************************************************************/

        abstract bool isAdditive ();

        /***********************************************************************

                Specify whether or not this logger has additive behaviour.
                This is enabled by default, and causes a logger to invoke
                all appenders within its ancestry (until an ancestor is
                found with an additive attribute of false).

        ***********************************************************************/

        abstract void setAdditive (bool enabled);

        /***********************************************************************
        
                Remove all appenders from this logger.

        ***********************************************************************/

        abstract void clearAppenders ();

        /***********************************************************************

                Add an appender to this logger. You may add multiple
                appenders to appropriate loggers, and each of them 
                will be invoked for that given logger, and for each
                of its child loggers (assuming isAdditive() is true
                for those children). Note that multiple instances
                of the same appender, regardless of where they may
                reside within the tree, are not invoked at runtime.
                That is, only one from a set of identical loggers 
                will execute.

                Use clearAttributes() to remove all from a given logger.
                        
        ***********************************************************************/

        abstract void addAppender (Appender appender);

        /***********************************************************************
        
                Get number of milliseconds since this application started

        ***********************************************************************/

        abstract ulong getRuntime ();
}
