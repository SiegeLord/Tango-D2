/**************************************************************

    Example that use FileFolder and Regex as a filter.

    Put into public domain by Lars Ivar Igesund

**************************************************************/

import tango.io.Stdout,
       tango.text.Regex;

import  tango.io.vfs.FileFolder;

void main(char[][] args) 
{
    if (args.length < 2) 
       {
       Stdout("Please pass a directory to search").newline;
       return;
       }

    scope regex =  Regex(r"\.(d|obj)$");
    scope scan = new FileFolder (args[1]);

    auto tree = scan.tree;
    auto catalog = tree.catalog (delegate bool(VfsInfo info){return regex.test(info.name);});

    foreach (file; catalog)
             Stdout(file).newline;

    Stdout.formatln("Found {} matches in {} entries", catalog.files, tree.files);
}

