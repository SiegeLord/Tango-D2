/*******************************************************************************

        copyright:      Copyright (c) 2009 Tango. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Oct 2009: Initial release

        author:         various

*******************************************************************************/

private import tango.text.Util;
private import tango.io.Stdout;
private import tango.sys.Process;
private import tango.io.FileScan;
private import tango.io.device.File;
private import tango.text.Arguments;

/*******************************************************************************
      
*******************************************************************************/

void main (char[][] arg)
{
        Args args;

        if (args.populate (arg[1..$]))
           {
           new Linux (args);
           new Windows (args);
           stdout.formatln ("{} files", FileFilter.builder(args.os, args.compiler)());
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
                include ("tango/stdc/constants/win");
                register ("windows", "dmd", &dmd);
        }

        int dmd ()
        {
                void compile (char[] cmd, FilePath file, File list)
                {
                        auto temp = objname (file);
                        exec (cmd~temp~" "~file.toString);
                        list.write (temp ~ "\n");
                }

                auto outf = new File ("tango.lsp", File.ReadWriteCreate);
                auto dmd = "dmd -c -I"~args.root~"/tango/core -I"~args.root~" "~args.flags~" -of";
                outf.write ("-c -n -p256\n"~args.lib~".lib\n");

                foreach (file; scan(".d"))
                         compile (dmd, file, outf);

                foreach (file; scan(".c"))
                         compile ("dmc -c -mn -6 -r -o", file, outf);

                if (args.core)
                    outf.write (args.root~"/tango/core/rt/compiler/dmd/minit.obj\n");
                outf.close;
                exec ("lib @tango.lsp");
                exec ("cmd /q /c del tango.lsp *.obj");
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
                include ("tango/stdc/constants/linux");
                //register ("linux", "dmd", &dmd);
        }

        int dmd ()
        {
                return count;
        }
}

/*******************************************************************************
      
*******************************************************************************/

class FileFilter : FileScan
{
        alias int delegate()    Builder;
        Args                    args;
        int                     count;
        char[]                  suffix;
        bool[char[]]            excluded;         
        static Builder[char[]]  builders;

        /***********************************************************************

        ***********************************************************************/

        static void register (char[] platform, char[] compiler, Builder builder)
        {
                builders [platform~compiler] = builder;
        }

        /***********************************************************************

        ***********************************************************************/

        static Builder builder (char[] platform, char[] compiler)
        {       
                auto s = platform~compiler;
                auto b = s in builders;
                if (b)
                    return *b;
                throw new Exception ("unsupported combination of "~platform~" and "~compiler);
        }

        /***********************************************************************

        ***********************************************************************/

        this (ref Args args)
        {
                this.args = args;

                if (args.core is false)
                    exclude ("tango/core");

                exclude ("tango/net/cluster");
                exclude ("tango/io/protocol");

                exclude ("tango/sys/win32");
                exclude ("tango/sys/darwin");
                exclude ("tango/sys/freebsd");
                exclude ("tango/sys/linux");
                exclude ("tango/sys/solaris");
                exclude ("tango/sys/unix");
                exclude ("tango/stdc/constants/win");
                exclude ("tango/stdc/constants/autoconf");
                exclude ("tango/stdc/constants/darwin");
                exclude ("tango/stdc/constants/freebsd");
                exclude ("tango/stdc/constants/linux");
                exclude ("tango/stdc/constants/solaris");

                exclude ("tango/core/rt/gc/stub");
                exclude ("tango/core/rt/compiler/dmd");
                exclude ("tango/core/rt/compiler/gdc");
                exclude ("tango/core/rt/compiler/ldc");
                include ("tango/core/rt/compiler/"~args.target);
        }
        
        /***********************************************************************

        ***********************************************************************/

        final int opApply (int delegate(ref FilePath) dg)
        {
                int result;
                foreach (path; super.files)  
                         if (args.user || containsPattern(path.folder, "core"))
                             if (++count, (result = dg(path)) != 0)
                                  break;
                return result;
        }

        /***********************************************************************

        ***********************************************************************/

        final FileFilter scan (char[] suffix)
        {
                this.suffix = suffix;
                super.sweep (args.root~"/tango", &filter);
                return this;
        }

        /***********************************************************************

        ***********************************************************************/

        final void exclude (char[] path)
        {
                excluded[path] = true;
        }

        /***********************************************************************

        ***********************************************************************/

        final void include (char[] path)
        {
                excluded.remove (path);
        }

        /***********************************************************************

        ***********************************************************************/

        private bool filter (FilePath fp, bool isDir)
        {
                if (isDir)
                   {    
                   auto tango = locatePattern (fp.path, "tango");
                   if (tango < fp.path.length)
                       return ! (fp.toString[tango..$] in excluded);
                   return false;
                   }
                return fp.suffix == suffix;
        }

        /***********************************************************************
              
        ***********************************************************************/
        
        private char[] objname (FilePath fp, char[] ext=".obj")
        {
                auto tmp = fp.folder ~ fp.name ~ ext;
                foreach (i, c; tmp)
                         if (c != '.' && c != '/')
                            return tmp[i..$].replace('/', '-');
                return null;
        }
        
        /***********************************************************************
              
        ***********************************************************************/
        
        void exec(char[] cmd)
        {
                exec (split(cmd, " "), null, null);
        }
        
        /***********************************************************************
              
        ***********************************************************************/
        
        void exec (char[][] cmd, char[][char[]] env, char[] workDir)
        {
                if (args.verbose)
                   {
                   foreach (str; cmd)
                            stdout (str)(' ');
                   stdout.newline;
                   }        
                if (! args.inhibit)
                   {
                   scope proc = new Process (cmd, env);
                   if (workDir) 
                       proc.workDir = workDir;
        
                   proc.execute();
                   stdout.stream.copy (proc.stdout);
                   stdout.stream.copy (proc.stderr);
                   auto result = proc.wait;
                   if (result.reason != Process.Result.Exit)
                       throw new Exception (result.toString);
                   }
        }
}

/*******************************************************************************
      
*******************************************************************************/

struct Args
{
        bool    core,
                user,
                inhibit,
                verbose;
        char[]  root,
                os = "windows",
                lib = "tango",
                flags = "-g",
                target = "dmd",
                compiler = "dmd";
        char[]  usage = "usage: compile tango-path\n"
                        "\t[-v]\t\t\tverbose output\n"
                        "\t[-i]\t\t\tinhibit execution\n"
                        "\t[-u]\t\t\tinclude user modules\n"
                        "\t[-r=dmd|gdc|ldc]\tinclude a runtime target\n"
                        "\t[-c=dmd|gdc|ldc]\tspecify a compiler to use\n"
                        "\t[-o=\"options\"]\t\tspecify D compiler options\n"
                        "\t[-l=libname]\t\tspecify lib name (sans .ext)\n"
                        "\t[-p=windows|linux]\tdetermines package filtering\n";

        bool populate (char[][] arg)
        {       
                auto args = new Arguments;
                args('u').bind({user=true;});
                args('i').bind({inhibit=true;});
                args('v').bind({verbose=true;});
                args('l').params(1).bind((char[] v){lib = v;});
                args('o').params(1).bind((char[] v){flags = v;});
                args('p').params(1).bind((char[] v){os = v;}).restrict("windows", "linux");
                args('c').params(1).bind((char[] v){compiler = v;}).restrict("dmd", "gdc", "ldc");
                args('r').params(1).bind((char[] v){target = v, core=true;}).restrict("dmd", "gdc", "ldc");
                args(null).required.params(1).title("tango path");
                args("help").aliased('h').aliased('?').halt;
                if (args.parse(arg))
                    return root = args(null).assigned[0], true;

                stdout (usage);
                if (! args("help").set)
                      stdout (args.errors (&stdout.layout.sprint));
                return false;
        }
}

