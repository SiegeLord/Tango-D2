/**

  First build the zlib:
  cd phobos/etc/c/zlib/
  make -f linux.mak
  cd <tangohome>
  build-3.02 example/test_phobos.d -Tt -op -Mphobos -L-ldl phobos/etc/c/zlib/zlib.a

 */
module example.test_phobos;

import phobos.array;
import phobos.asserterror;
import phobos.base64;
import phobos.bitarray;
import phobos.boxer;
import phobos.c.fenv;
import phobos.c.math;
import phobos.c.process;
import phobos.c.stdarg;
import phobos.c.stddef;
import phobos.c.stdio;
import phobos.c.stdlib;
import phobos.c.string;
import phobos.c.time;
import phobos.conv;
import phobos.cover;
import phobos.cstream;
import phobos.ctype;
import phobos.date;
import phobos.dateparse;
import phobos.demangle;
import phobos.file;
import phobos.format;
import phobos.intrinsic;
import phobos.loader;
import phobos.math;
import phobos.math2;
import phobos.md5;
import phobos.mmfile;
import phobos.openrj;
import phobos.outbuffer;
import phobos.outofmemory;
import phobos.path;
import phobos.perf;
import phobos.process;
import phobos.random;
import phobos.regexp;
import phobos.socket;
import phobos.socketstream;
import phobos.stdarg;
import phobos.stdint;
import phobos.stdio;
import phobos.stream;
import phobos.string;
import phobos.switcherr;
import phobos.syserror;
import phobos.system;
import phobos.thread;
import phobos.uni;
import phobos.uri;
import phobos.utf;
import phobos.zip;
import phobos.zlib;
import phobos.compiler;

version(Windows){
    import phobos.c.windows.com;
    import phobos.c.windows.windows;
    import phobos.c.windows.winsock;
    import phobos.windows.charset;
    import phobos.windows.iunknown;
    import phobos.windows.registry;
    import phobos.windows.syserror;
}
version( Posix ){
    import phobos.c.linux.linux;
    import phobos.c.linux.linuxextern;
    import phobos.c.linux.socket;
}


void main(){
   return;
}








