import tango.io.Console;

import tango.io.FilePath;

void main(){
    Cout ((new FilePath(r"d:\path\foo.bat".dup)).name).newline;
    Cout ((new FilePath(r"d:\path.two\bar".dup)).name).newline;
    Cout ((new FilePath("/home/user.name/bar.".dup)).name).newline;
    Cout ((new FilePath(r"d:\path.two\bar".dup)).name).newline;
    Cout ((new FilePath("/home/user/.resource".dup)).name).newline;
}
