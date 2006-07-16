/*******************************************************************************
        Illustrates use of the tango.text.ArgParser class. It shows the
        different ways of binding parameters, and also shows some more
        advanced use by loading arguments from a file using tango.io.

*******************************************************************************/

import tango.text.ArgParser;
import tango.io.Stdout;
import tango.io.FileConduit;
import tango.text.LineIterator;

void main(char[][] args)
{
    char[][] fileList;
    char[] responseFile = null;
    bool coolAction = false;
    bool displayHelp = false;
    char[] helpText = "Available options:\n\t\t-h\tthis help\n\t\t-cool-option\tdo cool things to your files\n\t\t@filename\tuse filename as a response file with extra arguments\n\t\tall other arguments are handled as files to do cool things with.";

    ArgParser parser = new ArgParser(delegate uint(char[] value,uint ordinal){
        Stdout.format("Added file number {0} to list of files", ordinal).newline;
		fileList ~= value;
		return value.length;
	});

	parser.bind("-", "h",delegate void(){
		displayHelp=true;
	});

	parser.bind("-", "cool-action",delegate void(){
		coolAction=true;
	});
	
    parser.bindDefault("@",delegate uint(char[] value, uint ordinal){
        if (ordinal > 0) {
            throw new Exception("Only one response file can be given.");
        }
        responseFile = value;
        return value.length;
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
            auto file = new FileConduit(responseFile);
            // create an iterator and bind it to the file
            auto lines = new LineIterator(file);
            // process file one line at a time
            char[][] arguments;
            foreach (line; lines) {
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
    }	
}
