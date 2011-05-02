// D programming language runtime library
// Public Domain
// written by Walter Bright, Digital Mars
// www.digitalmars.com

// This is written in C because nobody has written a pthreads interface
// to D yet.


#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

#if _WIN32
#elif linux || __APPLE__ || __FreeBSD__ || __sun&&__SVR4
#define USE_PTHREADS    1
#else
#endif

#if _WIN32
#include <windows.h>
#endif

#if USE_PTHREADS
#include <pthread.h>
#endif

#include "mars.h"

// This is what the monitor reference in Object points to
typedef struct Monitor
{
    void* impl; // for user-level monitors
    Array devt; // for internal monitors

#if _WIN32
    CRITICAL_SECTION mon;
#endif

#if USE_PTHREADS
    pthread_mutex_t mon;
#endif
} Monitor;

#define MONPTR(h)       (&((Monitor *)(h)->monitor)->mon)

static volatile int inited;

/* =============================== Win32 ============================ */

#if _WIN32

static CRITICAL_SECTION _monitor_critsec;

void _STI_monitor_staticctor()
{
    if (!inited)
    {   InitializeCriticalSection(&_monitor_critsec);
        inited = 1;
    }
}

void _STD_monitor_staticdtor()
{
    if (inited)
    {   inited = 0;
        DeleteCriticalSection(&_monitor_critsec);
    }
}

void _d_monitor_create(Object *h)
{
    /*
     * NOTE: Assume this is only called when h->monitor is null prior to the
     * call.  However, please note that another thread may call this function
     * at the same time, so we can not assert this here.  Instead, try and
     * create a lock, and if one already exists then forget about it.
     */

    //printf("+_d_monitor_create(%p)\n", h);
    assert(h);
    Monitor *cs = NULL;
    EnterCriticalSection(&_monitor_critsec);
    if (!h->monitor)
    {
        cs = (Monitor *)calloc(sizeof(Monitor), 1);
        assert(cs);
        InitializeCriticalSection(&cs->mon);
        h->monitor = (void *)cs;
        cs = NULL;
    }
    LeaveCriticalSection(&_monitor_critsec);
    if (cs)
        free(cs);
    //printf("-_d_monitor_create(%p)\n", h);
}

void _d_monitor_destroy(Object *h)
{
    //printf("+_d_monitor_destroy(%p)\n", h);
    assert(h && h->monitor && !(((Monitor*)h->monitor)->impl));
    DeleteCriticalSection(MONPTR(h));
    free((void *)h->monitor);
    h->monitor = NULL;
    //printf("-_d_monitor_destroy(%p)\n", h);
}

int _d_monitor_lock(Object *h)
{
    //printf("+_d_monitor_acquire(%p)\n", h);
    assert(h && h->monitor && !(((Monitor*)h->monitor)->impl));
    EnterCriticalSection(MONPTR(h));
    //printf("-_d_monitor_acquire(%p)\n", h);
}

void _d_monitor_unlock(Object *h)
{
    //printf("+_d_monitor_release(%p)\n", h);
    assert(h && h->monitor && !(((Monitor*)h->monitor)->impl));
    LeaveCriticalSection(MONPTR(h));
    //printf("-_d_monitor_release(%p)\n", h);
}


/* =============================== linux ============================ */

#elif USE_PTHREADS

// Includes attribute fixes from David Friedman's GDC port
#ifndef HAVE_PTHREAD_MUTEX_RECURSIVE
#define PTHREAD_MUTEX_RECURSIVE PTHREAD_MUTEX_RECURSIVE_NP
#endif

static pthread_mutex_t _monitor_critsec;
static pthread_mutexattr_t _monitors_attr;

void _STI_monitor_staticctor()
{
    if (!inited)
    {
#ifndef PTHREAD_MUTEX_ALREADY_RECURSIVE
        pthread_mutexattr_init(&_monitors_attr);
        pthread_mutexattr_settype(&_monitors_attr, PTHREAD_MUTEX_RECURSIVE);
#endif
        pthread_mutex_init(&_monitor_critsec, &_monitors_attr);
        inited = 1;
    }
}

void _STD_monitor_staticdtor()
{
    if (inited)
    {   inited = 0;
#ifndef PTHREAD_MUTEX_ALREADY_RECURSIVE
        pthread_mutex_destroy(&_monitor_critsec);
        pthread_mutexattr_destroy(&_monitors_attr);
#endif
    }
}

void _d_monitor_create(Object *h)
{
    /*
     * NOTE: Assume this is only called when h->monitor is null prior to the
     * call.  However, please note that another thread may call this function
     * at the same time, so we can not assert this here.  Instead, try and
     * create a lock, and if one already exists then forget about it.
     */

    //printf("+_d_monitor_create(%p)\n", h);
    assert(h);
    Monitor *cs = NULL;
    pthread_mutex_lock(&_monitor_critsec);
    if (!h->monitor)
    {
        cs = (Monitor *)calloc(sizeof(Monitor), 1);
        assert(cs);
#ifndef PTHREAD_MUTEX_ALREADY_RECURSIVE
        pthread_mutex_init(&cs->mon, & _monitors_attr);
#else
	pthread_mutex_init(&cs->mon, NULL);
#endif
        h->monitor = (void *)cs;
        cs = NULL;
    }
    pthread_mutex_unlock(&_monitor_critsec);
    if (cs)
        free(cs);
    //printf("-_d_monitor_create(%p)\n", h);
}

void _d_monitor_destroy(Object *h)
{
    //printf("+_d_monitor_destroy(%p)\n", h);
    assert(h && h->monitor && !(((Monitor*)h->monitor)->impl));
    pthread_mutex_destroy(MONPTR(h));
    free((void *)h->monitor);
    h->monitor = NULL;
    //printf("-_d_monitor_destroy(%p)\n", h);
}

int _d_monitor_lock(Object *h)
{
    //printf("+_d_monitor_acquire(%p)\n", h);
    assert(h && h->monitor && !(((Monitor*)h->monitor)->impl));
    pthread_mutex_lock(MONPTR(h));
    //printf("-_d_monitor_acquire(%p)\n", h);
}

void _d_monitor_unlock(Object *h)
{
    //printf("+_d_monitor_release(%p)\n", h);
    assert(h && h->monitor && !(((Monitor*)h->monitor)->impl));
    pthread_mutex_unlock(MONPTR(h));
    //printf("-_d_monitor_release(%p)\n", h);
}

/* ================================= No System ============================ */

#else

void _STI_monitor_staticctor() { }
void _STD_monitor_staticdtor() { }

void _d_monitor_create(Object *h)
{
    Monitor *cs = NULL;
    if (!h->monitor)
    {
        cs = (Monitor *)calloc(sizeof(Monitor), 1);
        assert(cs);
        h->monitor = (void *)cs;
        cs = NULL;
    }
}

int _d_monitor_lock(Object *h)
{
}

void _d_monitor_unlock(Object *h)
{
}

void _d_monitor_destroy(Object *h)
{
    if (h->monitor)
    {
        free((void *)h->monitor);
        h->monitor = NULL;
    }
}

#endif
