/*******************************************************************************

        copyright:      Copyright (c) 2011 Kris Bell. All rights reserved
        license:        BSD style: $(LICENSE)
        version:        Initial release: Aug 2011     
        author:         Kris

*******************************************************************************/

module tango.io.model.ISelectable;

/*******************************************************************************

        Describes how to make an IO entity usable with selectors.
        Let your classes inherit from ISelectable to make them useable
        in the selecor classes of tango.

*******************************************************************************/
interface ISelectable
{     
        version (Windows) 
            alias void* Handle;             /// opaque OS file-handle         
        else
            typedef int Handle = -1;        /// opaque OS file-handle        

        /***********************************************************************

                Models a handle-oriented device. 

                TODO: figure out how to avoid exposing this in the general
                case

        ***********************************************************************/

        Handle handle();
}
