/*
 * This file covers all unittest
 */
import core.stdc.stdio;
import tango.io.Stdout;
import tango.io.Console;
import tango.text.convert.Integer;
import tango.text.convert.Layout;

/*
 * inside this unittest we call all other unittests
 */
unittest
{
	uint countFailed = 0;
	uint countTotal = 1;

	Stdout("This is the tango unittest module.").newline;
	Stdout("NOTE: This is still fairly rudimentary, and will only report the").newline;
	Stdout("    first error per module.").newline;

	foreach(m; ModuleInfo) {
		if(m.unitTest) {
			Stdout.format ("{}. Executing unittests in '{}' ", countTotal, m.name).flush;
			countTotal++;
			try {
				m.unitTest();
			}
			catch (Exception e) {
				countFailed++;
				Stdout(" - Unittest failed.").newline;
				continue;
			}
			Stdout(" - Success.").newline;
		}
	}
	
	Stdout.format ("{} out of {} tests failed.", countFailed, countTotal - 1).newline;
}

/*
 *  main is empty, because all unittest will be executed before main
 */
int main(char[][] args)
{
	return 0;
}
