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
else version(LDC)
{
	/* Some sort of bug */
	static if(__VERSION__ < 2000)
		enum DMDFE_Version = __VERSION__ + 2000;
	else
		enum DMDFE_Version = __VERSION__;
}
else
{
	enum DMDFE_Version = __VERSION__;
}
