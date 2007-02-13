/*******************************************************************************

        copyright:      Copyright (c) 2007 Deewiant & Maxter. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Feb 2007: Initial release

        author:         Deewiant & Maxter

*******************************************************************************/

module tango.sys.Environment;

import tango.sys.Common;

import tango.core.Exception;

version (Windows)
{
        import tango.text.convert.Utf;

        pragma (lib, "kernel32.lib");

        extern (Windows)
        {
                void* GetEnvironmentStringsW();
                bool FreeEnvironmentStringsW(wchar**);
        }
        extern (Windows)
        {
                int SetEnvironmentVariableW(wchar*, wchar*);
                uint GetEnvironmentVariableW(wchar*, wchar*, uint);
                const int ERROR_ENVVAR_NOT_FOUND = 203;
        }
}
else
{
    import tango.stdc.posix.stdlib;
    import tango.stdc.string;
}

version (Win32)
{
        /**********************************************************************

        **********************************************************************/

        // Returns null if the variable does not exist
        char[] getEnv (char[] variable)
        {
                wchar[] var = toUtf16(variable) ~ "\0";

                uint size = GetEnvironmentVariableW(var.ptr, cast(wchar*)null, 0);
                if (size == 0)
                   {
                   if (SysError.lastCode == ERROR_ENVVAR_NOT_FOUND)
                       return null;
                   else
                      throw new PlatformException (SysError.lastMsg);
                   }

                auto buffer = new wchar[size];
                size = GetEnvironmentVariableW(var.ptr, buffer.ptr, size);
                if (size == 0)
                    throw new PlatformException (SysError.lastMsg);

                return toUtf8 (buffer[0 .. size]);
        }

        /**********************************************************************

        **********************************************************************/

        // Undefines the variable, if value is null or empty string
        void setEnv (char[] variable, char[] value = null)
        {
                wchar * var, val;

                var = (toUtf16 (variable) ~ "\0").ptr;

                if (value.length > 0)
                    val = (toUtf16 (value) ~ "\0").ptr;

                if (! SetEnvironmentVariableW(var, val))
                      throw new PlatformException (SysError.lastMsg);
        }

        /**********************************************************************

        **********************************************************************/

        char[][char[]] environment ()
        {
                char[][char[]] arr;

                wchar[] key = new wchar[20],
                        value = new wchar[40];

                wchar** env = cast(wchar**) GetEnvironmentStringsW();
                scope (exit) 
                       FreeEnvironmentStringsW (env);

                for (wchar* str = cast(wchar*) env; *str; ++str)
                    {
                    size_t k = 0, v = 0;

                    while (*str != '=')
                          {
                          key[k++] = *str++;
        
                          if (k == key.length)
                              key.length = 2 * key.length;
                          }       

                    ++str;

                    while (*str)
                          {
                          value [v++] = *str++;
        
                          if (v == value.length)
                              value.length = 2 * value.length;
                          }       

                    arr [toUtf8(key[0 .. k])] = toUtf8(value[0 .. v]);
                    }

                return arr;
        }
}
else // POSIX
{
        extern (C) extern char** environ;

        /**********************************************************************

        **********************************************************************/

        // Returns null if the variable does not exist
        char[] getEnv (char[] variable)
        {
                char* ptr = getenv (variable.ptr);

                if (ptr is null)
                    return null;

                return ptr[0 .. strlen(ptr)].dup;
        }

        /**********************************************************************

        **********************************************************************/

        // Undefines the variable, if value is null or empty string
        void setEnv (char[] variable, char[] value = null)
        {
                int result;

                if (value.length == 0)
                    unsetenv ((variable ~ '\0').ptr);
                else
                   result = setenv ((variable ~ '\0').ptr, (value ~ '\0').ptr, 1);

                if (result != 0)
                    throw new PlatformException (SysError.lastMsg);
        }

        /**********************************************************************

        **********************************************************************/

        char[][char[]] environment ()
        {
                char[] key;
                char[][char[]] arr;

                for (char** p = environ; *p; ++p)
                    {
                    size_t k = 0;
                    char* str = *p;

                    while (*str++ != '=')
                           ++k;
                    key = (*p)[0..k];

                    while (*str++)
                           ++k;

                    arr [key] = (*p)[key.length+1 .. k];
                    }

                return arr;
        }
}


debug (Test)
{
        import tango.io.Console;


        void main()
        {
        const char[] VAR = "TESTENVVAR";
        const char[] VAL1 = "VAL1";
        const char[] VAL2 = "VAL2";

        assert(getEnv(VAR) is null);

        setEnv(VAR, VAL1);
        assert(getEnv(VAR) == VAL1);

        setEnv(VAR, VAL2);
        assert(getEnv(VAR) == VAL2);

        setEnv(VAR, null);
        assert(getEnv(VAR) is null);

        setEnv(VAR, VAL1);
        setEnv(VAR, "");

        assert(getEnv(VAR) is null);

        foreach (key, value; environment)
                 Cout (key) ("=") (value).newline;
        }
}

