module rt.cImports;

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
    //c_ulong strtoul(in char*, char**, int);
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

