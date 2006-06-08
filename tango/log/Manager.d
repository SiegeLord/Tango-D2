/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: see doc/license.txt for details
      
        version:        Initial release: May 2004
        version:        Hierarchy moved due to circular dependencies; Oct 2004
        
        author:         Kris

*******************************************************************************/

module tango.log.Manager;

private import  tango.log.Event,
                tango.log.Hierarchy;

/*******************************************************************************

        Manager for routing Logger calls to the default hierarchy. Note 
        that you may have multiple hierarchies per application, but must
        access the hierarchy directly for getRootLogger() and getLogger()
        methods within each additional instance.

*******************************************************************************/

class Manager 
{
        static private Hierarchy base;

        /***********************************************************************
        
                This is a singleton, so hide the constructor.

        ***********************************************************************/

        private this ()
        {
        }

        /***********************************************************************
        
                Initialize the base hierarchy.                
              
        ***********************************************************************/

        static this ()
        {
                base = new Hierarchy ("mango");
                Event.initialize ();
        }

        /***********************************************************************
        
                Return the singleton root

        ***********************************************************************/

        static LoggerInstance getRootLogger ()
        {
                return base.getRootLogger ();
        }

        /***********************************************************************
        
                Return a named Logger within the singleton hierarchy

        ***********************************************************************/

        static LoggerInstance getLogger (char[] name)
        {
                return base.getLogger (name);
        }

        /***********************************************************************
        
                Return the singleton hierarchy.

        ***********************************************************************/

        static Hierarchy getHierarchy ()
        {
                return base;
        }
}
