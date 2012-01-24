/*
 * Written by Sean Kelly
 * Placed into Public Domain
 */

module tango.sys.win32.Process;


private
{
    import tango.stdc.stdint;
    import tango.stdc.stddef;
}

extern (C):

enum
{
    P_WAIT,
    P_NOWAIT,
    P_OVERLAY,
    P_NOWAITO,
    P_DETACH,
}

enum
{
    WAIT_CHILD,
    WAIT_GRANDCHILD,
}

private
{
    extern (C) alias void function(void*) bt_fptr;
    extern (Windows) alias uint function(void*) btex_fptr;
}

uintptr_t _beginthread(bt_fptr, uint, void*);
void _endthread();
uintptr_t _beginthreadex(void*, uint, btex_fptr, void*, uint, uint *);
void _endthreadex(uint);

void abort();
void exit(int);
void _exit(int);
void _cexit();
void _c_exit();

intptr_t cwait(int*, intptr_t, int);
intptr_t wait(int*);

int getpid();
int system(const(char)*);

intptr_t spawnl(int, const(char)*, const(char)*, ...);
intptr_t spawnle(int, const(char)*, const(char)*, ...);
intptr_t spawnlp(int, const(char)*, const(char)*, ...);
intptr_t spawnlpe(int, const(char)*, const(char)*, ...);
intptr_t spawnv(int, const(char)*, const(char)**);
intptr_t spawnve(int, const(char)*, const(char)**, const(char)**);
intptr_t spawnvp(int, const(char)*, const(char)**);
intptr_t spawnvpe(int, const(char)*, const(char)**, const(char)**);

intptr_t execl(const(char)*, const(char)*, ...);
intptr_t execle(const(char)*, const(char)*, ...);
intptr_t execlp(const(char)*, const(char)*, ...);
intptr_t execlpe(const(char)*, const(char)*, ...);
intptr_t execv(const(char)*, const(char)**);
intptr_t execve(const(char)*, const(char)**, const(char)**);
intptr_t execvp(const(char)*, const(char)**);
intptr_t execvpe(const(char)*, const(char)**, const(char)**);

int _wsystem(const(wchar_t)*);

intptr_t _wspawnl(int, const(wchar_t)*, const(wchar_t)*, ...);
intptr_t _wspawnle(int, const(wchar_t)*, const(wchar_t)*, ...);
intptr_t _wspawnlp(int, const(wchar_t)*, const(wchar_t)*, ...);
intptr_t _wspawnlpe(int, const(wchar_t)*, const(wchar_t)*, ...);
intptr_t _wspawnv(int, const(wchar_t)*, const(wchar_t)**);
intptr_t _wspawnve(int, const(wchar_t)*, const(wchar_t)**, const(wchar_t)**);
intptr_t _wspawnvp(int, const(wchar_t)*, const(wchar_t)**);
intptr_t _wspawnvpe(int, const(wchar_t)*, const(wchar_t)**, const(wchar_t)**);

intptr_t _wexecl(const(wchar_t)*, const(wchar_t)*, ...);
intptr_t _wexecle(const(wchar_t)*, const(wchar_t)*, ...);
intptr_t _wexeclp(const(wchar_t)*, const(wchar_t)*, ...);
intptr_t _wexeclpe(const(wchar_t)*, const(wchar_t)*, ...);
intptr_t _wexecv(const(wchar_t)*, const(wchar_t)**);
intptr_t _wexecve(const(wchar_t)*, const(wchar_t)**, const(wchar_t)**);
intptr_t _wexecvp(const(wchar_t)*, const(wchar_t)**);
intptr_t _wexecvpe(const(wchar_t)*, const(wchar_t)**, const(wchar_t)**);
