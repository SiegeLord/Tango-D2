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
private import tango.util.ArgParser;

/*******************************************************************************
      
*******************************************************************************/

void main (char[][] arg)
{
        if (arg.length < 2)
            Stdout.formatln ("usage: compile TangoImportPath [-user] [-core] [-list] [-quiet] [-lib=outputname] "
                             "[-os=windows|linux] [-for=dmd|gdc|ldc] [-flags=\"options\"]");
        else
           {
           Args args;
           switch (args.populate(arg[1..$]).os)
                  {
                  case "windows":
                       (new Windows(args)).build;
                       break;

                  case "linux":
                       (new Linux(args)).build;
                       break;

                  default:
                      assert (false, "unsupported O/S: "~args.os);
                  }
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
        }

        override void build ()
        {
                void compile (FilePath file, File list, char[] cmd)
                {
                        auto temp = objname (file);
                        exec (cmd~temp~" "~file.toString);
                        list.write (temp ~ "\n");
                }

                auto dmc = "dmc -c -mn -6 -r -o";
                auto dmd = "dmd -c -I"~args.root~"/tango/core -I"~args.root~" "~args.flags~" -of";

                auto outf = new File ("tango.lsp", File.ReadWriteCreate);
                outf.write ("-c -n -p256\n"~args.lib~".lib\n");

                foreach (file; scan(".d"))
                         compile (file, outf, dmd);
                if (args.core)
                   {
                   foreach (file; scan(".c"))
                            compile (file, outf, dmc);
                   outf.write (args.root~"/tango/core/rt/compiler/dmd/minit.obj\n");
                   }
                outf.close;
                exec ("lib @tango.lsp");
                exec ("cmd /q /c del tango.lsp *.obj");
                Stdout.formatln ("{} files processed", count);
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
        }

        override void build ()
        {       
                Stdout("not implemented").newline;
        }
}

/*******************************************************************************
      
*******************************************************************************/

class FileFilter : FileScan
{
        Args            args;
        int             count;
        char[]          suffix;
        bool[char[]]    excluded;         

        /***********************************************************************

        ***********************************************************************/

        abstract void build ();

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
                super.sweep (args.root~"/tango", &execute);
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

        private bool execute (FilePath fp, bool isDir)
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
                if (! args.quiet)
                   {
                   foreach (str; cmd)
                            Stdout (str)(' ');
                   Stdout.newline;
                   }        
                if (! args.list)
                   {
                   scope proc = new Process (cmd, env);
                   if (workDir) 
                       proc.workDir = workDir;
        
                   proc.execute();
                   Stdout.stream.copy (proc.stdout);
                   Stdout.stream.copy (proc.stderr);
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
        bool            core,
                        user,
                        list,
                        quiet;
        char[]          root,
                        os = "windows",
                        lib = "tango",
                        flags = "-g",
                        target = "dmd";

        Args* populate (char[][] arg)
        {
                root = arg[0];

                auto args = new ArgParser;
                args.bind ("-", "core", {core=true;});
                args.bind ("-", "user", {user=true;});
                args.bind ("-", "list", {list=true;});
                args.bind ("-", "quiet", {quiet=true;});
                args.bind ("-", "flags", (char[] v){assert(v[0] is '='); flags=v[1..$];});
                args.bind ("-", "for", (char[] v){assert(v[0] is '='); target=v[1..$];});
                args.bind ("-", "lib", (char[] v){assert(v[0] is '='); lib=v[1..$];});
                args.bind ("-", "os", (char[] v){assert(v[0] is '='); os=v[1..$];});
                args.parse (arg[1..$]);

                // default to everything
                if (core is false && user is false)
                    core = user = true;

                assert (target == "ldc" || target == "dmd" || target == "gdc");
                return this;
        }
}

