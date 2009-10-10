module rt.compiler.cImports;

static if ((void*).sizeof==4){
    alias uint c_ulong;
} else {
    alias ulong c_ulong;
}
// tango.stdc.stdlib
enum:int{
    EXIT_SUCCESS  = 0,
    EXIT_FAILURE  = 1,
}
// tango.stdc.stdio
alias void* FILE_P;
enum :int{
    EOF=-1,
}
extern(C){

    // tango.stdc.string
    int   memcmp(in void* s1, in void* s2, size_t n);
    void* memcpy(void* s1, in void* s2, size_t n);
    void* memmove(void* s1, in void* s2, size_t n);
    void* memset(void* s, int c, size_t n);
    size_t strlen(char *s);

    // tango.stdc.stdlib
    void*   malloc(size_t size);
    void*   calloc(size_t nmemb, size_t size);
    void*   realloc(void* ptr, size_t size);
    void    free(void* ptr);
    void* alloca(size_t size);
    c_ulong strtoul(in char*, char**, int);
    ulong   strtoull(in char*, char**, int);
    //
    void    abort();
    void    exit(int status);
    //
    void qsort(void *base, size_t nel, size_t width,int function(void *,void *) compar);

    // tango.stdc.ctypes
    int isalnum(int c);
    int isalpha(int c);
    int isblank(int c);
    int iscntrl(int c);
    int isdigit(int c);
    int isgraph(int c);
    int islower(int c);
    int isprint(int c);
    int ispunct(int c);
    int isspace(int c);
    int isupper(int c);
    int isxdigit(int c);
    int tolower(int c);
    int toupper(int c);
    
    // tango.stdc.stdio
    int printf(char*,...);
    FILE_P fopen(in char* filename, in char* mode);
    int   fclose(FILE_P stream);
    int fprintf(FILE_P stream, in char* format, ...);
    int fgetc(FILE_P stream);
    int sprintf(char * s,char * format, ...); // snprintf not always available

    // others
    void onOutOfMemoryError();

}

version( Win32 ){
    // tango.stdc.stddef
    alias wchar wchar_t;
    // tango.stdc.string
    extern(C) size_t   wcslen(wchar_t* s);
}

// this is needed only by rt.cover
version(Windows){
    // tango.sys.win32.UserGdi;
    alias void* HANDLE;
    alias HANDLE THANDLE;
    alias wchar* LPCWSTR;
    alias uint DWORD;
    alias void* POINTER;
    alias POINTER LPVOID;
    struct SECURITY_ATTRIBUTES
    {
        DWORD nLength;
        LPVOID lpSecurityDescriptor;
        WINBOOL bInheritHandle;
    }
    alias SECURITY_ATTRIBUTES* LPSECURITY_ATTRIBUTES;
    alias int WINBOOL;
    alias WINBOOL BOOL;
    enum : DWORD {
        GENERIC_READ = (0x80000000),
        FILE_SHARE_READ = (1),
        FILE_SHARE_WRITE = (2),
        OPEN_EXISTING = (3),
        FILE_ATTRIBUTE_NORMAL = (128),
        FILE_FLAG_SEQUENTIAL_SCAN = (134217728),
    }
    const HANDLE INVALID_HANDLE_VALUE = cast(HANDLE) -1;
    struct OVERLAPPED
    {
        DWORD Internal;
        DWORD InternalHigh;
        DWORD Offset;
        DWORD OffsetHigh;
        HANDLE hEvent;
    }
    alias OVERLAPPED* POVERLAPPED;
    extern(Windows){
        HANDLE CreateFileW(LPCWSTR, DWORD, DWORD, LPSECURITY_ATTRIBUTES, DWORD, DWORD, HANDLE);
        WINBOOL CloseHandle(HANDLE);
        BOOL ReadFile(THANDLE, void*, DWORD, DWORD*, POVERLAPPED);
    }
} else {
    // tango.stdc.fcntl
    extern (C) int open(in char*, int, ...);
    extern (C) int close(int);
    extern (C) size_t read(int, void*, size_t);
    extern extern (C) int fcntl_O_RDONLY();
}

