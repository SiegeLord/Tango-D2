/*******************************************************************************

        copyright:      Copyright (c) 2009 Tango. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Oct 2009: Initial release

        author:         larsivi, sleets, kris

*******************************************************************************/
module bob;

private import tango.text.Util;
private import tango.io.Stdout;
private import tango.sys.Process;
private import tango.io.FilePath;
private import Path = tango.io.Path;
private import tango.io.device.Array;
private import tango.io.device.File;
private import tango.text.Arguments;
private import tango.sys.Environment;

/*******************************************************************************
      
*******************************************************************************/

void main (immutable(char)[][] arg)
{
        Args args;

        if (args.populate (arg[1..$]))
           {
           try {
               Path.remove (args.lib);
               }catch (Throwable o){}
           new Linux (args);
           new MacOSX (args);
           new FreeBSD (args);
           new Solaris (args);
           new Windows (args);
           Stdout.formatln ("{} files", FileFilter.builder(args.os, args.compiler)());
           }
}

/*******************************************************************************
      
*******************************************************************************/

class Windows : FileFilter
{
        this (ref Args args)
        {
                super (args);
                exclude ("tango/stdc/posix");
                include ("tango/sys/win32");
                register ("windows", "dmd", &dmd);
                register ("windows", "ldc2", &ldc2);
        }

        int dmd ()
        {
                void compile (const(char)[] cmd, FilePath file)
                {
                        auto temp = objname (file);
                        if (args.quick is false || isOverdue (file, temp))
                            exec (cmd~temp~" "~file.toString());
                        addToLib (temp);
                }

                auto dmd = "dmd -c -I"~args.root~" "~args.flags~" -of";
                libs ("-c -n -p256\n"~args.lib~"\n");

                foreach (file; scan(".d"))
                         compile (dmd, file);

                foreach (file; scan(".c"))
                         compile ("dmc -c -mn -6 -r -o", file);

                File.set("tango.lsp", libs.slice());
                exec ("lib @tango.lsp");

                // retain obj files only when -q is specified
                if (args.quick)
                    exec ("cmd /q /c del tango.lsp");
                else
                    exec ("cmd /q /c del tango.lsp *.obj");
                return count;
        }

        int ldc2 ()
        {
                char[] compile (FilePath file, const(char)[] cmd)
                {
                        auto temp = objname (file, ".o");
                        if (args.quick is false || isOverdue (file, temp))
                            exec (cmd~temp~" "~file.toString());
                        return temp;
                }

                auto gcc = "gcc -c -o";
                auto ldc2 = "ldc2 -c -I"~args.root~" "~args.flags~" -of";
                foreach (file; scan(".d")) {
                         auto obj = compile (file, ldc2);
                         addToLib(obj);
                }

                File.set("tango.lsp", libs.slice());
                exec ("ar -r "~args.lib~" @tango.lsp");
                exec ("cmd /q /c del tango.lsp");

                // retain object files only when -q is specified
                if (!args.quick)
                    exec ("cmd /q /c del *.o");

                return count;
        }
}

/*******************************************************************************
      
*******************************************************************************/

class Linux : FileFilter
{
        this (ref Args args)
        {
                super (args);
                include ("tango/sys/linux");
                register ("linux", "dmd", &dmd);
                register ("linux", "ldc2", &ldc2);
                register ("linux", "gdc", &gdc);
        }

        private char[] compile (FilePath file, const(char)[] cmd)
        {
                auto temp = objname (file, ".o");
                if (args.quick is false || isOverdue(file, temp))
                    exec (split(cmd~temp~" "~file.toString(), " "), Environment.get(), null);
                return temp;
        }

        private auto gcc00 = "gcc -c -o";
        private auto gcc32 = "gcc -c -m32 -o";
        private auto gcc64 = "gcc -c -m64 -o";

        int dmd ()
        {
                const(char)[] march;

                if (args.march.length)
                {
                    march = (args.march == "64") ? " -m64" : " -m32";
                }

                auto dmd = "dmd -c -I"~args.root~march~" "~args.flags~" -of";
                foreach (file; scan(".d")) {
                         auto obj = compile (file, dmd);
                         addToLib(obj);
                }

                makeLib(args.march == "32");
                return count;
        }

        int ldc2 ()
        {
                const(char)[] march;

                if (args.march.length)
                {
                    march = (args.march == "64") ? " -m64" : " -m32";
                }

                auto ldc2 = "ldc2 -c " ~ march ~ " -I"~args.root~" "~args.flags~" -of";
                foreach (file; scan(".d")) {
                         auto obj = compile (file, ldc2);
                         addToLib(obj);
                }

                makeLib(args.march == "32");
                return count;
        }

        int gdc ()
        {
                const(char)[] march;

                if (args.march.length)
                {
                    march = (args.march == "64") ? " -m64" : " -m32";
                }

                auto gdc = "gdc -c -I"~args.root ~ march ~ " "~args.flags~" -o";
                foreach (file; scan(".d")) {
                         auto obj = compile (file, gdc);
                         addToLib(obj);
                }

                makeLib(args.march == "32");
                return count;
        }


}

/*******************************************************************************
      
*******************************************************************************/

class MacOSX : FileFilter
{
        this (ref Args args)
        {
                super (args);
                include ("tango/sys/darwin");
                register ("osx", "dmd", &dmd);
                register ("osx", "ldc2", &ldc2);
                register ("osx", "gdc", &gdc);
        }

        private char[] compile (FilePath file, const(char)[] cmd)
        {
                auto temp = objname (file, ".o");
                if (args.quick is false || isOverdue(file, temp))
                    exec (split(cmd~temp~" "~file.toString(), " "), Environment.get(), null);
                return temp;
        }

        int dmd ()
        {
                auto dmd = "dmd -c -I"~args.root~" "~args.flags~" -of";
                foreach (file; scan(".d")) {
                         auto obj = compile (file, dmd);
                         addToLib(obj);
                }

                makeLib(true);
                return count;
        }

        int ldc2 ()
        {
                auto ldc2 = "ldc2 -c -I"~args.root~" "~args.flags~" -of";
                foreach (file; scan(".d")) {
                         auto obj = compile (file, ldc2);
                         addToLib(obj);
                }

                makeLib;
                return count;
        }

        int gdc ()
        {
                auto gdc = "gdc -c -I"~args.root~" "~args.flags~" -o";
                foreach (file; scan(".d")) {
                         auto obj = compile (file, gdc);
                         addToLib(obj);
                }

                makeLib;
                return count;
        }
}

/*******************************************************************************
      
*******************************************************************************/

class FreeBSD : FileFilter
{
        this (ref Args args)
        {
                super (args);
                include ("tango/sys/freebsd");
                register ("freebsd", "dmd", &dmd);
                register ("freebsd", "ldc2", &ldc2);
                register ("freebsd", "gdc", &gdc);
        }

        private char[] compile (FilePath file, const(char)[] cmd)
        {
                auto temp = objname (file, ".o");
                if (args.quick is false || isOverdue(file, temp))
                    exec (split(cmd~temp~" "~file.toString(), " "), Environment.get(), null);
                return temp;
        }

        private auto gcc = "gcc -c -o";
        private auto gcc32 = "gcc -c -m32 -o";

        int dmd ()
        {
                auto dmd = "dmd -version=freebsd -c -I"~args.root~" "~args.flags~" -of";
                foreach (file; scan(".d")) {
                         auto obj = compile (file, dmd);
                         addToLib(obj);
                }

                makeLib(true);
                return count;
        }

        int ldc2 ()
        {
                auto ldc2 = "ldc2 -c -I"~args.root~" "~args.flags~" -of";
                foreach (file; scan(".d")) {
                         auto obj = compile (file, ldc2);
                         addToLib(obj);
                }

                makeLib;
                return count;
        }

        int gdc ()
        {
                auto gdc = "gdc -fversion=freebsd -c -I"~args.root~"/tango/core -I"~args.root~" "~args.flags~" -o";
                foreach (file; scan(".d")) {
                         auto obj = compile (file, gdc);
                         addToLib(obj);
                }

                makeLib;
                return count;
        }


}

class Solaris : FileFilter
{
        this (ref Args args)
        {
                super (args);
                include ("tango/sys/solaris");
                register ("solaris", "dmd", &dmd);
                register ("solaris", "ldc2", &ldc2);
                register ("solaris", "gdc", &gdc);
        }

        private char[] compile (FilePath file, const(char)[] cmd)
        {
                auto temp = objname (file, ".o");
                if (args.quick is false || isOverdue(file, temp))
                    exec (split(cmd~temp~" "~file.toString(), " "), Environment.get(), null);
                return temp;
        }

        private auto gcc = "gcc -c -o";
        private auto gcc32 = "gcc -c -m32 -o";

        int dmd ()
        {
                auto dmd = "dmd -version=solaris -c -I"~args.root~" "~args.flags~" -of";
                foreach (file; scan(".d")) {
                         auto obj = compile (file, dmd);
                         addToLib(obj);
                }

                makeLib(true);
                return count;
        }

        int ldc2 ()
        {
                auto ldc2 = "ldc2 -c -I"~args.root~" "~args.flags~" -of";
                foreach (file; scan(".d")) {
                         auto obj = compile (file, ldc2);
                         addToLib(obj);
                }

                makeLib;
                return count;
        }

        int gdc ()
        {
                auto gdc = "gdc -fversion=solaris -c -I"~args.root~" "~args.flags~" -o";
                foreach (file; scan(".d")) {
                         auto obj = compile (file, gdc);
                         addToLib(obj);
                }

                makeLib;
                return count;
        }
}


/*******************************************************************************
      
*******************************************************************************/

class FileFilter
{
        alias int delegate()    Builder;

        Array                   libs;
        Args                    args;
        int                     count;
        const(char)[]                  suffix;
        bool[char[]]            excluded;         
        static Builder[char[]]  builders;

        /***********************************************************************

        ***********************************************************************/

        static void register (const(char)[] platform, const(char)[] compiler, Builder builder)
        {
                builders [platform~compiler] = builder;
        }

        /***********************************************************************

        ***********************************************************************/

        static Builder builder (const(char)[] platform, const(char)[] compiler)
        {       
                auto s = platform~compiler;
                auto b = s in builders;
                if (b)
                    return *b;
                throw new Exception ("unsupported combination of "~platform.idup~" and "~compiler.idup);
        }

        /***********************************************************************

        ***********************************************************************/

        this (ref Args args)
        {
                this.args = args;

                libs = new Array (0, 1024 * 16);

                exclude ("tango/sys/win32");
                exclude ("tango/sys/darwin");
                exclude ("tango/sys/freebsd");
                exclude ("tango/sys/linux");
                exclude ("tango/sys/solaris");
        }

        /***********************************************************************

        ***********************************************************************/

        final FilePath[] scan (const(char)[] suffix)
        {
                this.suffix = suffix;
                auto files = sweep (FilePath(args.root~"/tango"));
                foreach(file; files)
                    if(args.user || containsPattern(file.folder, "core"))
                        this.count++;
                return files;
        }
        
        /***********************************************************************

        ***********************************************************************/

        final FilePath[] sweep(FilePath root)
        {
            FilePath[] files;
            FilePath[] folders;
            
            foreach (path; root.toList(&filter))
            {
                if(path.isFolder)
                    folders ~= path;
                else
                    files ~= path;
            }
            
            foreach(folder; folders)
            {
                files ~= sweep(folder);
            }
            
            return files;
        }
        
        /***********************************************************************

        ***********************************************************************/

        final void exclude (const(char)[] path)
        {
                assert(Path.exists(Path.join(args.root, path)), "FileFilter.exclude: Path does not exist: " ~ path);
                assert(path[$-1] != '/', "FileFilter.exclude: Inconsistent path syntax, no trailing '/' allowed: " ~ path);
                excluded[path] = true;
        }

        /***********************************************************************

        ***********************************************************************/

        final void include (const(char)[] path)
        {
                assert(path in excluded, "FileFilter.include: Path need to be excluded first: " ~ path);
                excluded.remove (path);
        }

        /***********************************************************************

        ***********************************************************************/

        private bool filter (FilePath fp, bool isDir)
        {
                if (isDir)
                   {    
                   auto tango = locatePatternPrior (fp.path, "tango");
                   if (tango < fp.path.length)
                       return ! (fp.toString()[tango..$] in excluded);
                   return false;
                   }

                return fp.suffix == suffix;
        }

        /***********************************************************************
              
        ***********************************************************************/
        
        private char[] objname (FilePath fp, const(char)[] ext=".obj")
        {
                auto tmp = fp.folder [args.root.length+1 .. $] ~ fp.name ~ args.flags;
                foreach (i, ref c; tmp)
                         if (c is '.' || c is '/' || c is '=' || c is ' ' || c is '"')
                             c = '-';  
                return tmp ~ ext ;
        }

        /***********************************************************************
              
        ***********************************************************************/
        
        private bool isOverdue (FilePath fp, const(char)[] objfile)
        {
                if (! Path.exists (objfile))
                      return true;

                auto src = fp.timeStamps().modified;
                auto obj = Path.modified (objfile);
                return src >= obj;
        }
        
        /***********************************************************************

        ***********************************************************************/

        private void addToLib (const(char)[] obj)
        {
                version (Windows)
                         const Eol = "\r\n";
                else
                         const Eol = " ";
                if (Path.exists (obj))
                    libs (obj)(Eol);
        }

        /***********************************************************************

        ***********************************************************************/

        @property private void makeLib (bool use32bit = false)
        {
                if (libs.readable > 2)
                   {
                   auto files = cast(char[]) libs.slice() [0..$-1];
                   
                   if (args.dynamic)
                   {
                       version (osx)
                       {
                           auto path = Path.parse(args.lib);
                           auto name = path.file;
                           auto options = "-dynamiclib -install_name @rpath/" ~ name ~ " -Xlinker -headerpad_max_install_names";
                           auto gcc = use32bit ? "gcc -m32 " : "gcc ";
                           exec (gcc ~ options ~ " -o " ~ args.lib ~ " " ~ files ~ " -lz -lbz2");                        
                       }
                       
                   }
                   
                   else
                       exec ("ar -r "~args.lib~" "~ files);        
        
                   if (args.quick is false)
                       // TODO: remove the list of filenames in 'files' 
                      {}
                   }
        }

        /***********************************************************************
              
        ***********************************************************************/
        
        void exec (const(char)[] cmd)
        {
                exec (split(cmd, " "), null, null);
        }
        
        /***********************************************************************
              
        ***********************************************************************/
        
        void exec (const(char[])[] cmd, const(char[])[char[]] env, const(char)[] workDir)
        {
                if (args.verbose)
                   {
                   foreach (str; cmd)
                            Stdout (str)(' ');
                   Stdout.newline;
                   }  
                         
                if (! args.inhibit)
                   {
                   scope proc = new Process (cmd, env);
                   scope (exit) proc.close();
                   if (workDir) 
                       proc.workDir = workDir;
                   if (env is null)
                       proc.copyEnv (true);

                   proc.execute();
                   Stdout.stream.copy (proc.stderr);
                   Stdout.stream.copy (proc.stdout);
                   auto result = proc.wait();
                   if (result.status != 0 || result.reason != Process.Result.Exit)
                       throw new Exception (result.toString().idup);
                   }
        }
}


/*******************************************************************************
      
*******************************************************************************/

struct Args
{
        bool    user,
                quick,
                inhibit,
                verbose,
                dynamic;

        const(char)[]  os,
                       lib,
                       root,
                       flags,
                       compiler,
                       march;
                

        const(char)[]  usage = "Bob is a build tool for the sole purpose to compile the Tango library.\n"
                               "Usage: bob <options> tango-path\n"
                               "Arguments:\n"
                               "\t[-v]\t\t\tverbose output\n"
                               "\t[-q]\t\t\tquick execution\n"
                               "\t[-i]\t\t\tinhibit execution\n"
                               "\t[-u]\t\t\tinclude user modules\n"
                               "\t[-d]\t\t\tbuild Tango as a dynamic/shared library\n"
                               "\t[-m=64|32]\tCompile for 32/64 bit\n"
                               "\t[-c=dmd|gdc|ldc2]\tspecify a compiler to use\n"                        
                               "\t[-g=basic|cdgc|stub]\tspecify the GC implementation to include in the runtime\n"
                               "\t[-o=\"options\"]\t\tspecify D compiler options\n"
                               "\t[-l=libname]\t\tspecify lib name (sans .ext)\n"
                               "\t[-p=sysname]\t\tdetermines package filtering (windows|linux|osx|freebsd|solaris)\n\n"
                               "Example: .\\build\\bin\\win32\\bob.exe -vu -c=dmd .\n\n";

        bool populate (const(char[])[] arg)
        {       
                auto args = new Arguments;
                auto q = args('q');
                auto u = args('u');
                auto i = args('i');
                auto v = args('v');
                auto l = args('l').smush().params(1);
                auto p = args('p').smush().params(1);
                auto o = args('o').smush().params(1).defaults("-release");
                auto c = args('c').smush().params(1).defaults("dmd").restrict("dmd", "gdc", "ldc2");
                auto n = args(null).params(1).required.title("tango-path");
                auto h = args("help").aliased('h').aliased('?').halt();
                auto d = args('d');
                auto m = args('m').params(1).restrict("64", "32");

                version (Windows)
                         p.defaults("windows");
                else
                version (linux)
                         p.defaults("linux");
                else
                version (osx)
                         p.defaults("osx");
                else
                version (freebsd)
                         p.defaults("freebsd");
                else
                version (solaris)
                         p.defaults("solaris");
                else
                   p.required;

                if (args.parse (arg))
                   {
                   user = u.set;
                   quick = q.set;
                   inhibit = i.set;
                   verbose = v.set;
                   dynamic = d.set;
                   os = p.assigned()[0];
                   root = n.assigned()[0];
                   flags = o.assigned()[0];
                   compiler = c.assigned()[0];
                   march = m.assigned().length > 0 ? m.assigned()[0] : "";
                   
                   if(l.assigned().length == 0)
                   {
                        lib = "libtango-";
                        switch(c.assigned()[0])
                        {
                            case "dmd":
                                lib ~= "dmd";
                                break;
                            case "gdc":
                                lib ~= "gdc";
                                break;
                            case "ldc2":
                                lib ~= "ldc";
                                break;
                            default:
                                assert(0);
                        }
                   }
                   else
                   {
                       lib = l.assigned()[0];
                   }
                       
                    if(compiler == "gdc" && flags == "-release")
                        flags = "-frelease";
                   
                   if (dynamic)
                   {
                       version (osx)
                           lib ~= ".dylib";
                       else
                           throw new Exception("Building Tango as a dynamic library is currently only supported on Mac OS X", __FILE__, __LINE__);
                   }
                   else
                   {
                       version (Windows)
                           lib ~= ".lib";
                       else
                           lib ~= ".a";
                   }
                   
                   return true;
                   }

                stdout (usage);
                if (! h.set)
                      stdout (args.errors (&stdout.layout.sprint));
                return false;
        }
}

