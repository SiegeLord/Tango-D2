/*******************************************************************************

        copyright:      Copyright (c) 2007 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Apr 2007: split away from utc

        author:         Kris

*******************************************************************************/

module tango.util.time.Wall;

private import  tango.sys.Common;

private import  tango.util.time.Utc;

/******************************************************************************

        Exposes Wall time relative to Jan 1st, 1 AD. These values are
        based upon a clock-tick of 100ns, giving them a span of greater
        than 10,000 years. Units of Time are the foundation of most time
        and date functionality in Tango.

*******************************************************************************/

struct Wall
{
        version (Win32)
        {
                /***************************************************************

                        Return the current local time

                ***************************************************************/

                static Time now ()
                {
                        int bias;
                        TIME_ZONE_INFORMATION tz = void;

                        switch (GetTimeZoneInformation (&tz))
                               {
                               default:
                                    bias = tz.Bias;
                                    break;
                               case 1:
                                    bias = tz.Bias + tz.StandardBias;
                                    break;
                               case 2:
                                    bias = tz.Bias + tz.DaylightBias;
                                    break;
                               }

                        return cast(Time) (Utc.now - (Time.TicksPerMinute * bias));
                }

                /***************************************************************

                        Return the timezone relative to GMT. The value is 
                        negative when west of GMT

                ***************************************************************/

                static Time zone ()
                {
                        TIME_ZONE_INFORMATION tz = void;

                        auto tmp = GetTimeZoneInformation (&tz);
                        return cast(Time) (-Time.TicksPerMinute * tz.Bias);
                }
        }

        version (Posix)
        {
                /***************************************************************

                        Return the current local time

                ***************************************************************/

                static Time now ()
                {
                        tm t = void;
                        timeval tv = void;
                        gettimeofday (&tv, null);
                        localtime_r (&tv.tv_sec, &t);
                        tv.tv_sec = timegm (&t);
                        return Utc.convert (tv);
                }

                /***************************************************************

                        Return the timezone relative to GMT. The value is 
                        negative when west of GMT

                ***************************************************************/

                static Time zone ()
                {
                        version (darwin)
                                {
                                timezone_t tz = void;
                                gettimeofday (null, &tz);
                                return cast(Time) (-Time.TicksPerMinute * tz.tz_minuteswest);
                                }
                             else
                                return cast(Time) (-Time.TicksPerSecond * timezone);
                }
        }
}


version (Posix)
{
    version (darwin) {}
    else
    {
        static this()
        {
            tzset();
        }
    }
}
