#include <time.h>
#include "config.h"

time_t _d_gnu_cbridge_tza()
{
    time_t t;
    struct tm * p_tm;
    
    time(&t);    
    p_tm = localtime(&t);	/* this will set timezone */

#ifdef HAVE_TM_GMTOFF_AND_ZONE
    return p_tm->tm_gmtoff;
#elif defined(HAVE_TIMEZONE)
    return timezone;
#elif defined(HAVE__TIMEZONE)
    return _timezone;
#else
    return (time_t) 0;
#endif
}
