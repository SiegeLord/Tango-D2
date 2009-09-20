module rt.cImports;

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
    int sprintf(char* s,in char * format, ...); // snprintf not always available

    // others
    void onOutOfMemoryError();

}

version( Win32 ){
    // tango.stdc.stddef
    alias wchar wchar_t;
}

