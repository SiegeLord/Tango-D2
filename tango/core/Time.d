/**
 * A lightweight alternative to core.time that avoids all templates
 *
 * Copyright: Copyright (C) 2012 Pavel Sountsov.  All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Pavel Sountsov
 */
module tango.core.Time;

static import core.time;

/**
 * Returns a Duration struct that represents secs seconds.
 */
core.time.Duration seconds(double secs)
{
	struct DurationClone
	{
		long hnsecs;
	}

	return cast(core.time.Duration)(DurationClone(cast(long)(secs * 10_000_000)));
}
