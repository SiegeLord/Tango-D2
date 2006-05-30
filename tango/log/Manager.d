/*******************************************************************************

        @file Manager.d

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

      
        @version        Initial version; May 2004
                        Hierarchy moved due to circular dependencies; Oct 2004

        @author         Kris


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
