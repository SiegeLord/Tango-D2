/**
 * Module to track the compiler version.
 *
 * Copyright: Copyright (C) 2013 Pavel Sountsov.  All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Pavel Sountsov
 */
module tango.core.Compiler;

version(SDC)
{
	enum DMDFE_Version = 0;
}
else
{
	enum DMDFE_Version = __VERSION__;
}
