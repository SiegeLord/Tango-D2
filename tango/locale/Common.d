/**
 * Contains modules providing information about specific locales.
 */
module tango.locale.Common;

// Issues: does not compile with "-cov" because of a circular dependency.
// tango.locale.Core and tango.locale.format need to import each other.

import  tango.locale.Constants,
        tango.locale.Core,
        tango.locale.Collation,
        tango.locale.Format,
        tango.locale.Parse;