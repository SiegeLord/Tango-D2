/// common functions of the runtime
module rt.CommonFunct;
import cImports=rt.cImports;

extern (C) void tango_abort(){
    cImports.abort();
}

extern (C) void tango_exit(int code){
    cImports.exit(code);
}
