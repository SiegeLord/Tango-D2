module unittester;

import tango.core.ThreadPool;
import tango.io.Stdout;
import Path = tango.io.Path;
import tango.io.FilePath;
import tango.io.device.File;
import tango.text.Arguments;
import tango.sys.Process;
import tango.core.sync.Condition;
import tango.core.sync.Mutex;

enum immutable(char)[] DummyFileContent = "void main() {}";
enum immutable(char)[] Help = 
`
unittester - TangoD2's unittest utility
Copyright (C) 2012-2014 Pavel Sountsov.

Usage: unittester [OPTION]... [FILES]...
Example: unittester -c dmd -d .unittest -a "-m32" tango/text/Util.d

FILES is a list of files you want to run unittests in. This program essentially
compiles each of the passed files individually along with a dummy main file.
Then it runs the resultant executable to see if it's unittests run.
Additionally, if the unittest runs longer than 5 seconds, it is aborted.

Options:
  -a,  --additional=OPTIONS   what additional options to pass the compiler. 
                              These are appended after the options specified by
                              the --options option.
  -c,  --compiler=COMPILER    what compiler to use when compiling the unittests
                              Default: dmd
  -d,  --directory=DIRECTORY  what directory to use to write the test 
                              executables to. Note that this directory is not
                              removed after the program finishes.
                              Default: .unittest
  -h,  --help                 print this help text
  -o,  --options=OPTIONS      what options to pass to the compiler.
                              Default if compiler is dmd: 
                                  -unittest -L-ltango -debug=UnitTest
                              Default if compiler is ldc2: 
                                  -unittest -L-ltango -d-debug=UnitTest
`;

void main(const(char[])[] args)
{
	const(char)[] compiler = "dmd";
	const(char)[] compiler_options;
	const(char)[] directory = ".unittest";
	const(char)[] additional_options;
	
	const(char)[] null_str = null; /* DMD bug*/
	
	auto arguments = new Arguments;
	arguments("compiler").aliased('c').params(1).bind(
		(const(char)[] arg)
		{
			compiler = arg;
			return null_str;
		});
	arguments("options").aliased('o').params(1).bind(
		(const(char)[] arg)
		{
			compiler_options = arg;
			return null_str;
		});
	arguments("additional").aliased('a').params(1).bind(
		(const(char)[] arg)
		{
			additional_options = arg;
			return null_str;
		});
	arguments("directory").aliased('d').params(1).bind(
		(const(char)[] arg)
		{
			directory = arg;
			return null_str;
		});
	arguments("help").aliased('h').halt();
	arguments(null).params(0, 1024);
	
	if(!arguments.parse(args[1..$]) || arguments("help").set)
	{
		Stdout(arguments.errors(&Stdout.layout.sprint));
		return;
	}
	
	if(compiler_options == "")
	{
		version(Windows)
		{
			compiler_options = "-unittest libtango-dmd.lib -debug=UnitTest";
		}
		else
		{
			auto compiler_path = Path.parse(compiler);
			switch(compiler_path.name)
			{
				case "dmd":
					compiler_options = "-unittest -L-ltango-dmd -debug=UnitTest";
					break;
				case "ldc2":
					compiler_options = "-unittest -L-ltango-ldc -d-debug=UnitTest";
					break;
				default:
					assert(0, "Unsupported compiler.");
			}
		}
	}
	
	/*
	 * Set up files and directories
	 */
	if(!Path.exists(directory))
		Path.createFolder(directory);
	
	auto dummy_file_fp = new FilePath(directory.dup);
	if(dummy_file_fp.isFile)
	{
		throw new Exception("'" ~ directory.idup ~ "' already exists and is a file!");
	}
	dummy_file_fp.append("dummy.d");
	dummy_file_fp.native;
	
	{
		auto dummy_file = new File(dummy_file_fp.cString()[0..$-1], File.WriteCreate);
		scope(exit) dummy_file.close();
		dummy_file.write(DummyFileContent);
	}
	
	/*
	 * Set up compiler business
	 */
	auto output_fp = new FilePath(directory.dup);
	output_fp.append("out");
	output_fp.native;
	auto proc_raw_arguments = compiler ~ " " ~ compiler_options ~ " " ~ 
	                          additional_options ~ " -of" ~ output_fp.cString()[0..$-1] ~ " " ~ 
	                          dummy_file_fp.cString()[0..$-1];
	auto compiler_proc = new Process(true, proc_raw_arguments);
	compiler_proc.setRedirect(Redirect.All | Redirect.ErrorToOutput);
	auto proc_arguments = compiler_proc.args().dup;
	
	auto test_proc = new Process(true, output_fp.cString()[0..$-1]);
	test_proc.setRedirect(Redirect.All | Redirect.ErrorToOutput);
	
	auto test_mutex = new Mutex;
	auto test_condition = new Condition(test_mutex);
	
	auto thread_pool = new ThreadPool!()(1);
	
	size_t skipped = 0;
	size_t total = 0;
	size_t pass = 0;
	size_t fail = 0;
	size_t timeout = 0;
	size_t compile_error = 0;
	
	foreach(file; arguments(null).assigned())
	{
		if(Path.parse(file).ext != "d")
		{
			Stdout.formatln("Skipping '{}'... Not a D file.", file);
			skipped++;
			continue;
		}
		if(!Path.exists(file))
		{
			Stdout.formatln("Skipping '{}'... Doesn't exist.", file);
			skipped++;
			continue;
		}
		
		total++;
		
		Stdout.formatln("Compiling '{}'", file);
		
		auto file_fp = new FilePath(file.dup);
		file_fp.native;
		auto new_args = proc_arguments ~ file_fp.cString()[0..$-1];
		compiler_proc.setArgs(compiler, new_args).execute();
		Stdout.copy(compiler_proc.stdout).flush();
		auto result = compiler_proc.wait();
		
		if(result.status != 0)
		{
			Stdout("COMPILEERROR").nl;
			Stdout(result.toString()).nl;
			compile_error++;
			continue;
		}
		
		Stdout("Testing...").nl;

		Process.Result test_result;
		bool killed;

		void test_thread()
		{
			synchronized(test_mutex)
			{
				if(!test_condition.wait(10))
				{
					killed = true;
					test_proc.kill();
				}
			}
		}

		thread_pool.assign(&test_thread);
		
		test_proc.execute();
		Stdout.copy(test_proc.stdout).flush();
		test_result = test_proc.wait();
		
		test_condition.notify();
		
		thread_pool.wait();
		
		if(test_result.reason == Process.Result.Exit && test_result.status == 0)
		{
			Stdout("PASS").nl;
			pass++;
		}
		else if(test_result.reason == Process.Result.Signal && killed)
		{
			Stdout("TIMEDOUT").nl;
			Stdout(result.toString()).nl;
			timeout++;
		}
		else
		{
			Stdout("FAIL").nl;
			Stdout(result.toString()).nl;
			fail++;
		}
	}
	
	Stdout.nl;
	Stdout.formatln("{} tested. {} skipped.", total, skipped);
	Stdout.formatln("PASS: {}", pass);
	Stdout.formatln("FAIL: {}", fail);
	Stdout.formatln("TIMEDOUT: {}", timeout);
	Stdout.formatln("COMPILEERROR: {}", compile_error);
}
