module tango.stdc.constants.sysctl;
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
    public import tango.stdc.constants.autoconf.sysctl;
} else version (Windows) {
    version (X86_CPU) {
        static if ((void*).sizeof==4)
            public import tango.stdc.constants.win.sysctl;
        else {
            pragma(msg,"constants not confirmed, please help out");
            public import tango.stdc.constants.win.sysctl;
        }
    } else {
        mixin undefinedConsts!("windows on non X86 CPU",__FILE__,__LINE__);
    }
} else version (darwin) {
    version (X86_CPU) {
        public import tango.stdc.constants.darwin.sysctl;
    } else version (PPC_CPU) {
        public import tango.stdc.constants.darwin.sysctl;
    } else {
        mixin undefinedConsts!("mac on non X86 or PPC CPU",__FILE__,__LINE__);
    }
} else version (linux) {
    version (X86_CPU) {
        public import tango.stdc.constants.linux.sysctl;
    } else version (PPC_CPU) {
        public import tango.stdc.constants.linux.sysctl;
    } else{
        mixin undefinedConsts!("linux on non X86 or PPC CPU",__FILE__,__LINE__);
    }
} else version (freebsd) {
    version (X86) {
        public import tango.stdc.constants.freebsd.sysctl;
    } else {
        mixin undefinedConsts!("freebsd on non X86 ",__FILE__,__LINE__);
    }
} else version (solaris) {
    version (X86) {
        public import tango.stdc.constants.solaris.sysctl;
    } else {
        mixin undefinedConsts!("solaris on non X86 ",__FILE__,__LINE__);
    }
}
