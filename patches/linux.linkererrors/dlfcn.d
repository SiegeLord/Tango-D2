module tango.stdc.posix.dlfcn;

version( linux ){
    extern (C)
    {
        /* From <dlfcn.h>
         * See http://www.opengroup.org/onlinepubs/007908799/xsh/dlsym.html
         */

        const int RTLD_NOW = 0x00002;	// Correct for Red Hat 8

        void* dlopen(char* file, int mode);
        int   dlclose(void* handle);
        void* dlsym(void* handle, char* name);
        char* dlerror();
    }
}


