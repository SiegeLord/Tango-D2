import tango.io.FilePath;
import tango.io.Stdout;

void main(){
    Stdout((new FilePath(r"d:\path\foo.bat")).getName()).newline;
    Stdout((new FilePath(r"d:\path.two\bar")).getName()).newline;
    Stdout((new FilePath("/home/user.name/bar.")).getName()).newline;
    Stdout((new FilePath(r"d:\path.two\bar")).getName()).newline;
    Stdout((new FilePath("/home/user/.resource")).getName()).newline;
}
