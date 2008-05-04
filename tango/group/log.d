/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Dec 2007: Initial release

        author:         Kris

        Convenience module to import tango.util.log modules 

*******************************************************************************/

module tango.group.log;

pragma (msg, "Please post your usage of tango.group to this ticket: http://dsource.org/projects/tango/ticket/1013");

public import tango.util.log.Log;
public import tango.util.log.LayoutDate;
public import tango.util.log.LayoutChainsaw;
public import tango.util.log.AppendFile;
public import tango.util.log.AppendMail;
public import tango.util.log.AppendSocket;
public import tango.util.log.AppendFiles;
                

