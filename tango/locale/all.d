module tango.locale.all;

// Issues: does not compile with "-cov" because of a circular dependency.
// tango.locale.core and tango.locale.format need to import each other.

import tango.locale.constants,
  tango.locale.core,
  tango.locale.collation,
  tango.locale.format,
  tango.locale.parse;