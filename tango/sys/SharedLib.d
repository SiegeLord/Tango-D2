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
    import tango.stdc.stringz : fromStringz;

    version (Windows) {
        import tango.sys.Common : SysError;
        import tango.sys.win32.Types : HINSTANCE, HMODULE, BOOL;

        extern (Windows) {
            void* GetProcAddress(HINSTANCE, const(char)*);
            BOOL FreeLibrary(HMODULE);

            version (Win32SansUnicode)
                     HINSTANCE LoadLibraryA(const(char)*);
                else {
                   enum {CP_UTF8 = 65001}
                   HINSTANCE LoadLibraryW(const(wchar)*);
                   int MultiByteToWideChar(uint, uint, const(char)*, int, wchar*, int);
                }
        }
    }
    else version (Posix) {
        import tango.stdc.posix.dlfcn;
    }
    else {
        static assert (false, "No support for this platform");
    }

    version (SharedLibVerbose) import tango.util.log.Trace;
}

version (Posix) {
    version (freebsd) { } else { pragma (lib, "dl"); }
}


/**
    SharedLib is an interface to system-specific shared libraries, such
    as ".dll", ".so" or ".dylib" files. It provides a simple interface to obtain
    symbol addresses (such as function pointers) from these libraries.

    Example:
    ----

    void main() {
        if (auto lib = SharedLib.load(`c:\windows\system32\opengl32.dll`)) {
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
    /// Mapped from RTLD_NOW, RTLD_LAZY, RTLD_GLOBAL and RTLD_LOCAL
    enum LoadMode {
        Now = 0b1,
        Lazy = 0b10,
        Global = 0b100,
        Local = 0b1000
    }


    /**
        Loads an OS-specific shared library.

        Note:
        Please use this function instead of the constructor, which is private.

        Params:
            path = The path to a shared library to be loaded
            mode = Library loading mode. See LoadMode

        Returns:
            A SharedLib instance being a handle to the library, or throws
            SharedLibException if it could not be loaded
      */
    static SharedLib load(const(char)[] path, LoadMode mode = LoadMode.Now | LoadMode.Global) {
    	return loadImpl(path, mode, true);
    }



    /**
        Loads an OS-specific shared library.

        Note:
        Please use this function instead of the constructor, which is private.

        Params:
            path = The path to a shared library to be loaded
            mode = Library loading mode. See LoadMode

        Returns:
            A SharedLib instance being a handle to the library, or null if it
            could not be loaded
      */
    static SharedLib loadNoThrow(const(char)[] path, LoadMode mode = LoadMode.Now | LoadMode.Global) {
    	return loadImpl(path, mode, false);
    }


    private static SharedLib loadImpl(const(char)[] path, LoadMode mode, bool throwExceptions) {
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
        Exception exc;

        synchronized (res) {
            if (!res.loaded) {
                version (SharedLibVerbose) Trace.formatln("Loading the SharedLib");
                try {
                    res.load_(mode, throwExceptions);
                } catch (Exception e) {
                    exc = e;
                }
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

        if (exc !is null) {
            throw exc;
        }

        version (SharedLibVerbose) Trace.formatln("SharedLib not loaded, returning null");
        return null;
    }


    /**
        Unloads the OS-specific shared library associated with this SharedLib instance.

        Note:
        It's invalid to use the object after unload() has been called, as unload()
        will delete it if it's not referenced any more.

        Throws SharedLibException on failure. In this case, the SharedLib object is not deleted.
      */
    void unload() {
    	return unloadImpl(true);
    }


    /**
        Unloads the OS-specific shared library associated with this SharedLib instance.

        Note:
        It's invalid to use the object after unload() has been called, as unload()
        will delete it if it's not referenced any more.
      */
    void unloadNoThrow() {
    	return unloadImpl(false);
    }


    private void unloadImpl(bool throwExceptions) {
        bool deleteThis = false;

        synchronized (this) {
            assert (loaded);
            assert (refCnt > 0);

            synchronized (mutex) {
                if (--refCnt <= 0) {
                    version (SharedLibVerbose) Trace.formatln("Unloading the SharedLib");
                    try {
                        unload_(throwExceptions);
                    } catch (Exception e) {
                        ++refCnt;
                        throw e;
                    }

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
    @property const(char)[] path() {
        return this.path_;
    }


    /**
        Obtains the address of a symbol within the shared library

        Params:
            name = The name of the symbol; must be a null-terminated C string

        Returns:
            A pointer to the symbol or throws SharedLibException if it's
            not present in the library.
      */
    void* getSymbol(const(char)* name) {
       return getSymbolImpl(name, true);
    }


    /**
        Obtains the address of a symbol within the shared library

        Params:
            name = The name of the symbol; must be a null-terminated C string

        Returns:
            A pointer to the symbol or null if it's not present in the library.
      */
    void* getSymbolNoThrow(const(char)* name) {
       return getSymbolImpl(name, false);
    }


    private void* getSymbolImpl(const(char)* name, bool throwExceptions) {
        assert (loaded);
        return getSymbol_(name, throwExceptions);
    }



    /**
        Returns the total number of libraries currently loaded by SharedLib
      */
    static uint numLoadedLibs() {
        return cast(uint) loadedLibs.keys.length;
    }


    private {
        version (Windows) {
            HMODULE handle;

            void load_(LoadMode mode, bool throwExceptions) {
                version (Win32SansUnicode)
                         handle = LoadLibraryA((this.path_ ~ "\0").ptr);
                    else {
                         wchar[1024] tmp = void;
                         auto i = MultiByteToWideChar (CP_UTF8, 0,
                                                       path.ptr, path.length,
                                                       tmp.ptr, tmp.length-1);
                         if (i > 0)
                            {
                            tmp[i] = 0;
                            handle = LoadLibraryW (tmp.ptr);
                            }
                    }
                if (handle is null && throwExceptions) {
                    throw new SharedLibException("Couldn't load shared library '" ~ this.path_.idup ~ "' : " ~ SysError.lastMsg.idup);
                }
            }

            void* getSymbol_(const(char)* name, bool throwExceptions) {
                // MSDN: "Multiple threads do not overwrite each other's last-error code."
                auto res = GetProcAddress(handle, name);
                if (res is null && throwExceptions) {
                    throw new SharedLibException("Couldn't load symbol '" ~ fromStringz(name).idup ~ "' from shared library '" ~ this.path_.idup ~ "' : " ~ SysError.lastMsg.idup);
                } else {
                    return res;
                }
            }

            void unload_(bool throwExceptions) {
                if (0 == FreeLibrary(handle) && throwExceptions) {
                    throw new SharedLibException("Couldn't unload shared library '" ~ this.path_.idup ~ "' : " ~ SysError.lastMsg.idup);
                }
            }
        }
        else version (Posix) {
            void* handle;

            void load_(LoadMode mode, bool throwExceptions) {
                int mode_;
                if (mode & LoadMode.Now) mode_ |= RTLD_NOW;
                if (mode & LoadMode.Lazy) mode_ |= RTLD_LAZY;
                if (mode & LoadMode.Global) mode_ |= RTLD_GLOBAL;
                if (mode & LoadMode.Local) mode_ |= RTLD_LOCAL;

                handle = dlopen((this.path_ ~ "\0").ptr, mode_);
                if (handle is null && throwExceptions) {
                    throw new SharedLibException("Couldn't load shared library: " ~ fromStringz(dlerror()).idup);
                }
            }

            void* getSymbol_(const(char)* name, bool throwExceptions) {
                if (throwExceptions) {
                    synchronized (typeof(this).classinfo) { // dlerror need not be reentrant
                        auto err = dlerror();               // clear previous error condition
                        auto res = dlsym(handle, name);     // result of null does NOT indicate error
                        
                        err = dlerror();                    // check for error condition
                        if (err !is null) {
                            throw new SharedLibException("Couldn't load symbol: " ~ fromStringz(err).idup);
                        } else {
                            return res;
                        }
                    }
                } else {
                    return dlsym(handle, name);
                }
            }

            void unload_(bool throwExceptions) {
                if (0 != dlclose(handle) && throwExceptions) {
                    throw new SharedLibException("Couldn't unload shared library: " ~ fromStringz(dlerror()).idup);
                }
            }
        }
        else {
            static assert (false, "No support for this platform");
        }


        const(char)[] path_;
        int refCnt = 0;


        @property bool loaded() {
            return handle !is null;
        }


        this(const(char)[] path) {
            this.path_ = path;
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


class SharedLibException : Exception {
    this (immutable(char)[] msg) {
        super(msg);
    }
}




debug (SharedLib)
{
        void main()
        {       
                auto lib = new SharedLib("foo");
        }
}
