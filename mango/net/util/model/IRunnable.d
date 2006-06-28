/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module mango.net.util.model.IRunnable;

/******************************************************************************

        Contract to be fulfilled by all Runnable classes

******************************************************************************/

interface IRunnable
{
        /**********************************************************************

                Execute until done

        **********************************************************************/

        void execute ();
}


