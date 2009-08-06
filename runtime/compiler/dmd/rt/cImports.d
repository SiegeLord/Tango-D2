module rt.cImports;
import tango.stdc.config: c_ulong;

// tango.stdc.stdlib
enum:int{
    EXIT_SUCCESS  = 0,
    EXIT_FAILURE  = 1,
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
    
    // others
    void onOutOfMemoryError();

}

version( Win32 ){
    // tango.stdc.string
    import tango.stdc.stddef: wchar_t;
    extern(C) size_t   wcslen(wchar_t* s);
}

// this is needed only by rt.cover
version(Windows){
    //    public import tango.sys.win32.UserGdi: HANDLE,THANDLE,LPCWSTR,DWORD,POINTER,LPVOID,SECURITY_ATTRIBUTES,
    //        LPSECURITY_ATTRIBUTES,WINBOOL,GENERIC_READ,FILE_SHARE_READ,FILE_SHARE_WRITE,
    //        OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,FILE_FLAG_SEQUENTIAL_SCAN,INVALID_HANDLE_VALUE,
    //        OVERLAPPED,POVERLAPPED,CreateFileW,CloseHandle,ReadFile;
} else {
    // tango.stdc.fcntl
    extern (C) int open(in char*, int, ...);
    extern (C) int close(int);
    extern (C) size_t read(int, void*, size_t);
    extern extern (C) int fcntl_O_RDONLY();
}

