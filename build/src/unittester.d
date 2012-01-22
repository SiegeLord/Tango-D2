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
Copyright (C) 2012 Pavel Sountsov.

Usage: unittester [OPTION]... [FILES]...
Example: unittester -c dmd -d .unittest -o "-unittest -debug=UnitTest" tango/text/Util.d
`;

void main(const(char)[][] args)
{
	const(char)[] compiler = "dmd";
	const(char)[] compiler_options = "-unittest -L-ltango -debug=UnitTest";
	const(char)[] directory = ".unittest";
	
	auto arguments = new Arguments;
	arguments("compiler").aliased('c').params(1).bind(
		(const(char)[] arg)
		{
			compiler = arg;
			return null;
		});
	arguments("options").aliased('o').params(1).bind(
		(const(char)[] arg)
		{
			compiler_options = arg;
			return null;
		});
	arguments("directory").aliased('d').params(1).bind(
		(const(char)[] arg)
		{
			directory = arg;
			return null;
		});
	arguments("help").aliased('h').halt;
	arguments(null).params(0, 1024);
	
	if(!arguments.parse(args[1..$]) || arguments("help").set)
	{
		Stdout(arguments.errors(&Stdout.layout.sprint));
		Stdout.formatln("{}", Help);
		return;
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
	
	{
		auto dummy_file = new File(dummy_file_fp.cString, File.WriteCreate);
		scope(exit) dummy_file.close;
		dummy_file.write(DummyFileContent);
	}
	
	/*
	 * Set up compiler business
	 */
	auto output_fp = new FilePath(directory.dup);
	output_fp.append("out");
	auto proc_raw_arguments = compiler ~ " " ~ compiler_options ~ " -of" ~ output_fp.cString[0..$-1] ~ " " ~ dummy_file_fp.cString[0..$-1];
	auto compiler_proc = new Process(true, proc_raw_arguments);
	compiler_proc.setRedirect(Redirect.All | Redirect.ErrorToOutput);
	auto proc_arguments = compiler_proc.args[1..$].dup;
	
	auto test_proc = new Process(true, output_fp.cString[0..$-1]);
	test_proc.setRedirect(Redirect.All | Redirect.ErrorToOutput);
	
	auto test_mutex = new Mutex;
	auto test_condition = new Condition(test_mutex);
	
	auto thread_pool = new ThreadPool!()(1);
	
	size_t skipped = 0;
	size_t total = 0;
	size_t pass = 0;
	size_t compile_error = 0;
	
	foreach(file; arguments(null).assigned)
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
		
		auto new_args = proc_arguments ~ file;
		compiler_proc.setArgs(compiler, new_args).execute;
		Stdout.copy(compiler_proc.stdout).flush;
		auto result = compiler_proc.wait;
		
		if(result.status != 0)
		{
			Stdout("COMPILEERROR").nl;
			Stdout(result.toString).nl;
			compile_error++;
			continue;
		}
		
		Stdout("Testing...").nl;

		Process.Result test_result;

		void test_thread()
		{
			synchronized(test_mutex)
			{
				if(!test_condition.wait(10))
				{
					test_proc.kill;
				}
			}
		}

		thread_pool.assign(&test_thread);
		
		test_proc.execute;
		Stdout.copy(test_proc.stdout).flush;
		test_result = test_proc.wait();
		
		test_condition.notify;
		
		thread_pool.wait;
		
		if(test_result.reason == Process.Result.Exit && test_result.status == 0)
		{
			Stdout("PASS").nl;
			pass++;
		}
		else if(test_result.reason == Process.Result.Signal)
		{
			Stdout("TIMEDOUT").nl;
			Stdout(result.toString).nl;
		}
		else
		{
			Stdout("FAIL").nl;
			Stdout(result.toString).nl;
		}
	}
	
	Stdout.nl;
	Stdout.formatln("Testing complete. {} out of {} passed.\n{} failed to compile. {} skipped.", pass, total, compile_error, skipped);
}
