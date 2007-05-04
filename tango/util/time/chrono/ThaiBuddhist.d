/*******************************************************************************

        copyright:      Copyright (c) 2005 John Chapman. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Mid 2005: Initial release
                        Apr 2007: reshaped                        

        author:         John Chapman, Kris

******************************************************************************/

module tango.util.time.chrono.ThaiBuddhist;

private import tango.util.time.chrono.GregorianBased;


/**
 * $(ANCHOR _ThaiBuddhistCalendar)
 * Represents the Thai Buddhist calendar.
 */
public class ThaiBuddhistCalendar : GregorianBasedCalendar {
  /**
   * $(I Property.) Overridden. Retrieves the identifier associated with the current calendar.
   * Returns: An integer representing the identifier of the current calendar.
   */
  public override int id() {
    return THAI;
  }

}
