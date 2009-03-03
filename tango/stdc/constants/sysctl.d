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

version(autoConf){
    public import tango.stdc.constants.autoConf.sysctl;
} else version (windows) {
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
    } else version (PPC) {
        public import tango.stdc.constants.darwin.sysctl;
    } else {
        mixin undefinedConsts!("mac on non X86 or PPC CPU",__FILE__,__LINE__);
    }
} else version (linux) {
    version (X86_CPU) {
        public import tango.stdc.constants.linuxIntel.sysctl;
    } else version (PPC) {
        pragma(msg,"constants not confirmed, please help out")
        public import tango.stdc.constants.linuxPPC.sysctl;
    } else{
        mixin undefinedConsts!("linux on non X86 or PPC CPU",__FILE__,__LINE__);
    }
} else version (freebsd) {
    version (X86) {
        public import tango.stdc.constants.freebsdIntel.sysctl;
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
