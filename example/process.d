/*******************************************************************************
  copyright:   Copyright (c) 2006 Juan Jose Comellas. All rights reserved
  license:     BSD style: $(LICENSE)
  author:      Juan Jose Comellas <juanjo@comellas.com.ar>
*******************************************************************************/

private import tango.io.Stdout;
private import tango.sys.Process;
private import tango.text.LineIterator;


/**
 * Example program for the tango.sys.Process class.
 */
void main()
{
    version (Windows)
        char[] command = "dir";
    else version (Posix)
        char[] command = "ls -l";
    else
        assert(false, "Unsupported platform");

    try
    {
        auto p = new Process(command, null);

        Stdout.formatln("Executing {0}", p.toUtf8());
        p.execute();

        Stdout.formatln("Output from process: {0} (pid {1})\n---",
                        p.programName, p.pid);

        foreach (line; new LineIterator(p.stdout))
        {
            Stdout.formatln("{0}", line);
        }

        Stdout.print("---\n");

        auto result = p.wait();

        Stdout.formatln("Process '{0}' ({1}) exited with reason {2}, status {3}",
                        p.programName, p.pid, cast(int) result.reason, result.status);
    }
    catch (ProcessException e)
    {
        Stdout.formatln("Process execution failed: {0}", e.toUtf8());
    }
}
