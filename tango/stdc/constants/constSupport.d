module tango.stdc.constants.constSupport;

/// compile time integer to string
char [] ctfe_i2a(long i){
    char[] digit="0123456789";
    char[] res="".dup;
    if (i==0){
        return "0".dup;
    }
    bool neg=false;
    if (i<0){
        neg=true;
        i=-i;
    }
    while (i>0) {
        res=digit[cast(size_t) (i%10)]~res;
        i/=10;
    }
    if (neg)
        return '-'~res;
    else
        return res;
}

template undefinedConsts(char[] what,char[] file,long line){
    pragma(msg,"undefined constants you can try to generate new ones running tango/lib/constants/dppAll.sh and then use -version=autoconf");
    pragma(msg,"please contact the tango team and help porting tango to your platform");
    static assert(0,"undefined constants for "~what~" in "~file~" at line "~ctfe_i2a(line));
}

// here is the basic structure of the basic const models
// just replace ConstModuleName with the correct name
// this is done explicitly instead of using a mixin to be friendly toward the build tools
/+module tango.stdc.constants.ConstModuleName;
import tango.stdc.constants.constSupport;

version(X86) {
    version=X86_CPU;
} else version(X86_64) {
    version=X86_CPU;
} else version ( PPC64 )
{
    version=PPC_CPU;
} else version ( PPC ) {
    version=PPC_CPU;
} else version(ARM){
} else version(SPARC){
} else {
    static assert(0,"unknown cpu family");
}

version(autoconf){
    public import tango.stdc.constants.autoconf.ConstModuleName;
} else version (Windows) {
    version (X86_CPU) {
        static if ((void*).sizeof==4)
            public import tango.stdc.constants.win.ConstModuleName;
        else {
            pragma(msg,"constants not confirmed, please help out");
            public import tango.stdc.constants.win.ConstModuleName;
        }
    } else {
        mixin undefinedConsts!("windows on non X86 CPU",__FILE__,__LINE__);
    }
} else version (darwin) {
    version (X86_CPU) {
        public import tango.stdc.constants.darwin.ConstModuleName;
    } else version (PPC_CPU) {
        public import tango.stdc.constants.darwin.ConstModuleName;
    } else {
        mixin undefinedConsts!("mac on non X86 or PPC CPU",__FILE__,__LINE__);
    }
} else version (linux) {
    version (X86_CPU) {
        public import tango.stdc.constants.linux.ConstModuleName;
    } else{
        mixin undefinedConsts!("linux on non X86 CPU",__FILE__,__LINE__);
    }
} else version (freebsd) {
    version (X86) {
        public import tango.stdc.constants.freebsd.ConstModuleName;
    } else {
        mixin undefinedConsts!("freebsd on non X86 ",__FILE__,__LINE__);
    }
} else version (solaris) {
    version (X86) {
        public import tango.stdc.constants.solaris.ConstModuleName;
    } else {
        mixin undefinedConsts!("solaris on non X86 ",__FILE__,__LINE__);
    }
}
+/