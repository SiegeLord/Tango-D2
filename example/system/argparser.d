/*******************************************************************************

        Illustrates use of the tango.util.ArgParser class. It shows the
        different ways of binding parameters, and also shows some more
        advanced use by loading arguments from a file using tango.io.

        Put into to public domain by Lars Ivar Igesund

*******************************************************************************/

import tango.io.File;
import tango.io.Stdout;
import tango.util.ArgParser;
import Text = tango.text.Util;

void main(char[][] args)
{
    char[][] fileList;
    char[] responseFile = null;
    char[] varx = null;
    bool coolAction = false;
    bool displayHelp = false;
    char[] helpText = "Available options:\n -h\t\tthis help\n -cool\t\tdo cool things to your files\n @filename\tuse filename as a response file with extra arguments\n\n all other arguments are treated as files to do cool things with";

    ArgParser parser = new ArgParser((char[] value,uint ordinal){
        Stdout.format("Added file number {0} to list of files", ordinal).newline;
		fileList ~= value;
	});

	parser.bind("-", "h",{
		displayHelp=true;
	});

	parser.bind("-", "cool",{
		coolAction=true;
	});

    parser.bind("-", "X=",(char[] value){
        varx = value;
    });
	
    parser.bindDefault("@",(char[] value, uint ordinal){
        if (ordinal > 0) {
            throw new Exception("Only one response file can be given.");
        }
        responseFile = value;
    });

    if (args.length < 2) {
        Stdout (helpText).newline;
        return;
    }
    parser.parse(args[1..$]);

    if (displayHelp) {
        Stdout (helpText).newline;
    }
    else {
        if (responseFile !is null) {
            char[][] arguments;
            auto file = new File(responseFile);

            // process file one line at a time
            foreach (line; Text.lines(cast(char[]) file.read)) {
                     arguments ~= line;
            }
            parser.parse(arguments);
        }
        if (coolAction) {
            Stdout ("Listing the files to be actioned in a cool way.").newline;
            foreach (id, file; fileList) {
                Stdout.format("{0}. {1}", id + 1, file).newline;
            }
            Stdout ("Cool and secret action performed.").newline;
        }
        if (varx !is null) {
            Stdout.format("User set the X factor to \"{0}\".", varx).newline;
        }
    }	
}
