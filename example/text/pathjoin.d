import tango.io.FilePath;
import tango.text.Path;
import tango.io.Stdout;

void main(){

version (Windows) {
    FilePath fp1 = new FilePath(r"c:\foo");
    FilePath fp2 = new FilePath("bar");
    Stdout(join(fp1, fp2)).newline;
    Stdout(join(fp2, fp1)).newline;

    Stdout(join("foo", r"d:\bar")).newline;
    Stdout(join(r"d:\bar", "foo")).newline;

}
version (Posix) {
    FilePath fp3 = new FilePath("/foo/bar");
    FilePath fp4 = new FilePath("joe/bar");
    Stdout(join(fp3, fp4)).newline;
    Stdout(join(fp4, fp3)).newline;

    FilePath fp5 = new FilePath("/bar");
    Stdout(join(fp5, fp3)).newline;

    Stdout(join("foo", "/bar")).newline;
    Stdout(join("/bar", "foo")).newline;
}
}
