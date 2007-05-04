/*******************************************************************************

        copyright:      Copyright (c) 2005 John Chapman. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Mid 2005: Initial release
                        Apr 2007: reshaped                        

        author:         John Chapman, Kris

******************************************************************************/

module tango.util.time.chrono.Japanese;

private import tango.util.time.chrono.GregorianBased;


/**
 * $(ANCHOR _JapaneseCalendar)
 * Represents the Japanese calendar.
 */
public class JapaneseCalendar : GregorianBasedCalendar 
{
  /**
   * $(I Property.) Overridden. Retrieves the identifier associated with the current calendar.
   * Returns: An integer representing the identifier of the current calendar.
   */
  public override int id() {
    return JAPAN;
  }

}
