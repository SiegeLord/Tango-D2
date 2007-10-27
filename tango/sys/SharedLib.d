/**
 * The shared library module provides a basic layer around the native functions
 * used to load symbols from shared libraries.
 *
 * Copyright: Copyright (C) 2007 Tomasz Stachowiak
 * License:   BSD style: $(LICENSE)
 * Authors:   Tomasz Stachowiak, Anders Bergh
 */

module tango.sys.SharedLib;


private {
    version (Windows) {
        alias void* HINSTANCE, HMODULE;
        alias int BOOL;
        
        extern (Windows) {
            void* GetProcAddress(HINSTANCE, char*);
            HINSTANCE LoadLibraryA(char*);
            BOOL FreeLibrary(HMODULE);
        }
    }
    else version (Posix) {
        const int RTLD_LAZY = 1;
        const int RTLD_NOW = 2;

        extern (C) {
            void* dlopen(char*, int);
            char* dlerror();
            void* dlsym(void*, char*);
            int dlclose(void*);
        }
    }
    else {
        static assert (false, "No support for this platform");
    }
    
    version (SharedLibVerbose) import tango.util.log.Trace;
}


/**
    SharedLib is an interface to system-specific shared libraries, such
    as ".dll", ".so" or ".dylib" files. It provides a simple interface to obtain
    symbol addresses (such as function pointers) from these libraries.
    
    Example:
    ----

    void main() {
        if (auto lib = SharedLib.load("c:\windows\system32\opengl32.dll")) {
            Trace.formatln("Library successfully loaded");

            void* ptr = lib.getSymbol("glClear");
            if (ptr) {
                Trace.formatln("Symbol glClear found. Address = 0x{:x}", ptr);
            } else {
                Trace.formatln("Symbol glClear not found");
            }
            
            lib.unload();
        } else {
            Trace.formatln("Could not load the library");
        }
        
        assert (0 == SharedLib.numLoadedLibs);
    }

    ----

    This implementation uses reference counting, thus a library is not loaded
    again if it has been loaded before and not unloaded by the user.
    Unloading a SharedLib decreases its reference count. When it reaches 0,
    the shared library associated with it is unloaded and the SharedLib instance
    is deleted. Please do not delete SharedLib instances manually, unload() will
    take care of it.

    Note:
    SharedLib is thread-safe.
  */
final class SharedLib {
    
    /**
        Loads an OS-specific shared library.
        
        Note:
        Please use this function instead of the constructor, which is private.

        Params:
            path = The path to a shared library to be loaded

        Returns:
            A SharedLib instance being a handle to the library, or null if it
            could not be loaded.
      */
    static SharedLib load(char[] path) {
        SharedLib res;
        
        synchronized (mutex) {
            auto lib = path in loadedLibs;
            if (lib) {
                version (SharedLibVerbose) Trace.formatln("SharedLib found in the hashmap");
                res = *lib;
            }
            else {
                version (SharedLibVerbose) Trace.formatln("Creating a new instance of SharedLib");
                res = new SharedLib(path);
                loadedLibs[path] = res;
            }

            ++res.refCnt;
        }

        bool delRes = false;
        
        synchronized (res) {
            if (!res.loaded) {
                version (SharedLibVerbose) Trace.formatln("Loading the SharedLib");
                res.load_();
            }

            if (res.loaded) {
                version (SharedLibVerbose) Trace.formatln("SharedLib successfully loaded, returning");
                return res;
            } else {
                synchronized (mutex) {
                    if (path in loadedLibs) {
                        version (SharedLibVerbose) Trace.formatln("Removing the SharedLib from the hashmap");
                        loadedLibs.remove(path);
                    }
                }
            }
            
            // make sure that only one thread will delete the object
            if (0 == --res.refCnt) {
                delRes = true;
            }
        }
        
        if (delRes) {
            version (SharedLibVerbose) Trace.formatln("Deleting the SharedLib");
            delete res;
        }
        
        version (SharedLibVerbose) Trace.formatln("SharedLib not loaded, returning null");
        return null;
    }
    

    /**
        Unloads the OS-specific shared library associated with this SharedLib instance.

        Note:
        It's invalid to use the object after unload() has been called, as unload()
        will delete it if it's not referenced any more.
      */
    void unload() {
        bool deleteThis = false;

        synchronized (this) {
            assert (loaded);
            assert (refCnt > 0);
            
            synchronized (mutex) {
                if (--refCnt <= 0) {
                    version (SharedLibVerbose) Trace.formatln("Unloading the SharedLib");
                    unload_();
                    assert ((path in loadedLibs) !is null);
                    loadedLibs.remove(path);

                    deleteThis = true;
                }
            }
        }
        if (deleteThis) {
            version (SharedLibVerbose) Trace.formatln("Deleting the SharedLib");
            delete this;
        }
    }
    

    /**
        Returns the path to the OS-specific shared library associated with this object.
      */
    char[] path() {
        return this.path_;
    }
    

    /**
        Obtains the address of a symbol within the shared library

        Params:
            name = The name of the symbol; must be a null-terminated C string

        Returns:
            A pointer to the symbol or null if it's not present in the library
      */
    void* getSymbol(char* name) {
        assert (loaded);
        return getSymbol_(name);
    }
    


    /**
        Returns the total number of libraries currently loaded by SharedLib
      */
    static uint numLoadedLibs() {
        return loadedLibs.keys.length;
    }
    
    
    private {
        version (Windows) {
            HMODULE handle;
            
            void load_() {
                handle = LoadLibraryA((this.path_ ~ \0).ptr);
            }

            void* getSymbol_(char* name) {
                return GetProcAddress(handle, name);
            }
            
            void unload_() {
                FreeLibrary(handle);
            }
        }
        else version (Posix) {
            void* handle;
            
            void load_() {
                handle = dlopen((this.path_ ~ \0).ptr, RTLD_NOW);
            }
        
            void* getSymbol_(char* name) {
                return dlsym(handle, name);
            }

            void unload_() {
                dlclose(handle);
            }
        }
        else {
            static assert (false, "No support for this platform");
        }
        
        
        char[] path_;
        int refCnt = 0;
        
        
        bool loaded() {
            return handle !is null;
        }


        this(char[] path) {
            this.path_ = path.dup;
        }
    }
    
    
    private static {
        SharedLib[char[]] loadedLibs;
        Object mutex;
    }


    static this() {
        mutex = new Object;
    }
}

