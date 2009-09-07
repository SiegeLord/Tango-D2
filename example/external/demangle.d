module demangle;
import tango.core.stacktrace.Demangler;
import tango.io.Stdout;

void usage(){
    Stdout("demangle [--help] [--level 0-9] mangledName1 [mangledName2...]").newline;
}

int main(char[][]args){
    uint start=1;
    if (args.length>1) {
        if (args[start]=="--help"){
            usage();
            ++start;
        }
        if (args[start]=="--level"){
            ++start;
            if (args.length==start || args[start].length!=1 || args[start][0]<'0' || 
                args[start][0]>'9') {
                Stdout("invalid level '")((args.length==start)?"*missing*":args[start])
                    ("' (must be 0-9)").newline;
                usage();
                return 2;
            }
            demangler.verbosity=args[start+1][0]-'0';
            ++start;
        }
    } else {
        usage();
        return 0;
    }
    foreach (n;args[start..$]){
        Stdout(demangler.demangle(n)).newline;
    }
    return 0;
}