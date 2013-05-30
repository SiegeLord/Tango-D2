/**
 *   Linux Stacktracing
 *
 *   Functions to parse the ELF format and create a symbolic trace.
 *
 *   The core Elf handling was taken from Thomas Kühne flectioned,
 *   with some minor pieces taken from winterwar/wm4
 *   But the routines and flow have been (sometime heavily) changed.
 *
 *  Copyright: Copyright (C) 2009 Fawzi, Thomas Kühne, wm4
 *  License:   Tango License
 *  Author:    Fawzi Mohamed
 */
module tango.core.tools.LinuxStackTrace;

import tango.core.tools.FrameInfo;

version(TangoDoc)
{

}
else
{

version(D_Version2)
{
        private void ThWriteOut(Throwable th, void delegate(in char[])sink){
        if (th.file.length>0 || th.line!=0)
        {
            char[25]buf;
            sink(th.classinfo.name);
            sink("@");
            sink(th.file);
            sink("(");
            sink(ulongToUtf8(buf, th.line));
            sink("): ");
            sink(th.toString());
            sink("\n");
        }
        else
        {
           sink(th.classinfo.name);
           sink(": ");
           sink(th.toString());
           sink("\n");
        }
        if (th.info)
        {
            sink("----------------\n");
            th.info.opApply((ref const(char[]) msg){sink(msg); return 0;});
        }
        if (th.next){
            sink("\n++++++++++++++++\n");
            ThWriteOut(th, sink);
        }
    }
}


version(linux){
    import tango.stdc.stdlib;
    import tango.stdc.stdio : FILE, fopen, fread, fseek, fclose, SEEK_SET, fgets, sscanf;
    import tango.stdc.string : strcmp, strlen,memcmp;
    import tango.stdc.stringz : fromStringz;
    import tango.stdc.signal;
    import tango.stdc.errno: errno, EFAULT;
    import tango.stdc.posix.unistd: access;
    import tango.text.Util : delimit;
    import tango.core.Array : find, rfind;
    import tango.core.Runtime;

    class SymbolException:Exception {
        this(immutable(char)[] msg, immutable(char)[] file,long lineNr,Exception next=null){
            super(msg,file,cast(uint)lineNr,next);
        }
    }
    bool may_read(size_t addr){
        errno(0);
        access(cast(char*)addr, 0);
        return errno() != EFAULT;
    }

    private extern(C){
        alias ushort Elf32_Half;
        alias ushort Elf64_Half;
        alias uint Elf32_Word;
        alias int Elf32_Sword;
        alias uint Elf64_Word;
        alias int Elf64_Sword;
        alias ulong Elf32_Xword;
        alias long Elf32_Sxword;
        alias ulong Elf64_Xword;
        alias long Elf64_Sxword;
        alias uint Elf32_Addr;
        alias ulong Elf64_Addr;
        alias uint Elf32_Off;
        alias ulong Elf64_Off;
        alias ushort Elf32_Section;
        alias ushort Elf64_Section;
        alias Elf32_Half Elf32_Versym;
        alias Elf64_Half Elf64_Versym;

        struct Elf32_Sym{
            Elf32_Word  st_name;
            Elf32_Addr  st_value;
            Elf32_Word  st_size;
            ubyte st_info;
            ubyte st_other;
            Elf32_Section   st_shndx;
        }

        struct Elf64_Sym{
            Elf64_Word  st_name;
            ubyte       st_info;
            ubyte       st_other;
            Elf64_Section   st_shndx;
            Elf64_Addr  st_value;
            Elf64_Xword st_size;
        }

        struct Elf32_Phdr{
            Elf32_Word  p_type;
            Elf32_Off   p_offset;
            Elf32_Addr  p_vaddr;
            Elf32_Addr  p_paddr;
            Elf32_Word  p_filesz;
            Elf32_Word  p_memsz;
            Elf32_Word  p_flags;
            Elf32_Word  p_align;
        }

        struct Elf64_Phdr{
            Elf64_Word  p_type;
            Elf64_Word  p_flags;
            Elf64_Off   p_offset;
            Elf64_Addr  p_vaddr;
            Elf64_Addr  p_paddr;
            Elf64_Xword p_filesz;
            Elf64_Xword p_memsz;
            Elf64_Xword p_align;
        }

        struct Elf32_Dyn{
            Elf32_Sword d_tag;
            union{
                Elf32_Word d_val;
                Elf32_Addr d_ptr;
            }
        }

        struct Elf64_Dyn{
            Elf64_Sxword    d_tag;
            union{
                Elf64_Xword d_val;
                Elf64_Addr d_ptr;
            }
        }
        enum { EI_NIDENT = 16 }

        struct Elf32_Ehdr{
            char        e_ident[EI_NIDENT]; /* Magic number and other info */
            Elf32_Half  e_type;         /* Object file type */
            Elf32_Half  e_machine;      /* Architecture */
            Elf32_Word  e_version;      /* Object file version */
            Elf32_Addr  e_entry;        /* Entry point virtual address */
            Elf32_Off   e_phoff;        /* Program header table file offset */
            Elf32_Off   e_shoff;        /* Section header table file offset */
            Elf32_Word  e_flags;        /* Processor-specific flags */
            Elf32_Half  e_ehsize;       /* ELF header size in bytes */
            Elf32_Half  e_phentsize;        /* Program header table entry size */
            Elf32_Half  e_phnum;        /* Program header table entry count */
            Elf32_Half  e_shentsize;        /* Section header table entry size */
            Elf32_Half  e_shnum;        /* Section header table entry count */
            Elf32_Half  e_shstrndx;     /* Section header string table index */
        }

        struct Elf64_Ehdr{
            char        e_ident[EI_NIDENT]; /* Magic number and other info */
            Elf64_Half  e_type;         /* Object file type */
            Elf64_Half  e_machine;      /* Architecture */
            Elf64_Word  e_version;      /* Object file version */
            Elf64_Addr  e_entry;        /* Entry point virtual address */
            Elf64_Off   e_phoff;        /* Program header table file offset */
            Elf64_Off   e_shoff;        /* Section header table file offset */
            Elf64_Word  e_flags;        /* Processor-specific flags */
            Elf64_Half  e_ehsize;       /* ELF header size in bytes */
            Elf64_Half  e_phentsize;        /* Program header table entry size */
            Elf64_Half  e_phnum;        /* Program header table entry count */
            Elf64_Half  e_shentsize;        /* Section header table entry size */
            Elf64_Half  e_shnum;        /* Section header table entry count */
            Elf64_Half  e_shstrndx;     /* Section header string table index */
        }

        struct Elf32_Shdr{
            Elf32_Word  sh_name;        /* Section name (string tbl index) */
            Elf32_Word  sh_type;        /* Section type */
            Elf32_Word  sh_flags;       /* Section flags */
            Elf32_Addr  sh_addr;        /* Section virtual addr at execution */
            Elf32_Off   sh_offset;      /* Section file offset */
            Elf32_Word  sh_size;        /* Section size in bytes */
            Elf32_Word  sh_link;        /* Link to another section */
            Elf32_Word  sh_info;        /* Additional section information */
            Elf32_Word  sh_addralign;       /* Section alignment */
            Elf32_Word  sh_entsize;     /* Entry size if section holds table */
        }

        struct Elf64_Shdr{
            Elf64_Word  sh_name;        /* Section name (string tbl index) */
            Elf64_Word  sh_type;        /* Section type */
            Elf64_Xword sh_flags;       /* Section flags */
            Elf64_Addr  sh_addr;        /* Section virtual addr at execution */
            Elf64_Off   sh_offset;      /* Section file offset */
            Elf64_Xword sh_size;        /* Section size in bytes */
            Elf64_Word  sh_link;        /* Link to another section */
            Elf64_Word  sh_info;        /* Additional section information */
            Elf64_Xword sh_addralign;       /* Section alignment */
            Elf64_Xword sh_entsize;     /* Entry size if section holds table */
        }

        enum{
            PT_DYNAMIC  = 2,
            DT_STRTAB   = 5,
            DT_SYMTAB   = 6,
            DT_STRSZ    = 10,
            DT_DEBUG    = 21,
            SHT_SYMTAB  = 2,
            SHT_STRTAB  = 3,
            STB_LOCAL   = 0,
        }

    }

    ubyte ELF32_ST_BIND(ulong info){
        return  cast(ubyte)((info & 0xF0) >> 4);
    }

    static if(4 == (void*).sizeof){
        alias Elf32_Sym Elf_Sym;
        alias Elf32_Dyn Elf_Dyn;
        alias Elf32_Addr Elf_Addr;
        alias Elf32_Phdr Elf_Phdr;
        alias Elf32_Half Elf_Half;
        alias Elf32_Ehdr Elf_Ehdr;
        alias Elf32_Shdr Elf_Shdr;
    }else static if(8 == (void*).sizeof){
        alias Elf64_Sym Elf_Sym;
        alias Elf64_Dyn Elf_Dyn;
        alias Elf64_Addr Elf_Addr;
        alias Elf64_Phdr Elf_Phdr;
        alias Elf64_Half Elf_Half;
        alias Elf64_Ehdr Elf_Ehdr;
        alias Elf64_Shdr Elf_Shdr;
    }else{
        static assert(0);
    }

    struct StaticSectionInfo{
        Elf_Ehdr header;
        const(char)[] stringTable;
        Elf_Sym[] sym;
        ubyte[] debugLine;   //contents of the .debug_line section, if available
        const(char)[] fileName;
        void* mmapBase;
        size_t mmapLen;
        /// initalizer
        static StaticSectionInfo opCall(Elf_Ehdr header, const(char)[] stringTable, Elf_Sym[] sym,
            ubyte[] debugLine, const(char)[] fileName, void* mmapBase=null, size_t mmapLen=0) {
            StaticSectionInfo newV;
            newV.header=header;
            newV.stringTable=stringTable;
            newV.sym=sym;
            newV.debugLine = debugLine;
            newV.fileName=fileName;
            newV.mmapBase=mmapBase;
            newV.mmapLen=mmapLen;
            return newV;
        }

        // stores the global sections
        enum MAX_SECTS=5;
        static StaticSectionInfo[MAX_SECTS] _gSections;
        static size_t _nGSections,_nFileBuf;
        static char[MAX_SECTS*256] _fileNameBuf;

        /// loops on the global sections
        static int opApply(scope int delegate(ref StaticSectionInfo) loop){
            for (size_t i=0;i<_nGSections;++i){
                auto res=loop(_gSections[i]);
                if (res) return res;
            }
            return 0;
        }
        /// loops on the static symbols
        static int opApply(scope int delegate(ref const(char)[] sNameP,ref size_t startAddr,
            ref size_t endAddr, ref bool pub) loop){
            for (size_t isect=0;isect<_nGSections;++isect){
                StaticSectionInfo *sec=&(_gSections[isect]);
                for (size_t isym=0;isym<sec.sym.length;++isym) {
                    auto symb=sec.sym[isym];
                    if(!symb.st_name || !symb.st_value){
                        // anonymous || undefined
                        continue;
                    }

                    bool isPublic = true;
                    if(STB_LOCAL == ELF32_ST_BIND(symb.st_info)){
                        isPublic = false;
                    }
                    const(char) *sName;
                    if (symb.st_name<sec.stringTable.length) {
                        sName=&(sec.stringTable[symb.st_name]);
                    } else {
                        debug(elf) printf("symbol name out of bounds %p\n",symb.st_value);
                    }
                    const(char)[] symbName=sName[0..(sName?strlen(sName):0)];
                    size_t endAddr=symb.st_value+symb.st_size;
                    auto res=loop(symbName,symb.st_value,endAddr,isPublic);
                    if (res) return res;
                }
            }
            return 0;
        }
        /// returns a new section to fill out
        static StaticSectionInfo *addGSection(Elf_Ehdr header,const(char)[] stringTable, Elf_Sym[] sym,
            ubyte[] debugLine, const(char)[] fileName,void *mmapBase=null, size_t mmapLen=0){
            if (_nGSections>=MAX_SECTS){
                throw new Exception("too many static sections",__FILE__,__LINE__);
            }
            auto len=fileName.length;
            const(char)[] newFileName;
            if (_fileNameBuf.length< _nFileBuf+len) {
                newFileName=fileName[0..len].dup;
            } else {
                _fileNameBuf[_nFileBuf.._nFileBuf+len]=fileName[0..len];
                newFileName=_fileNameBuf[_nFileBuf.._nFileBuf+len];
                _nFileBuf+=len;
            }
            _gSections[_nGSections]=StaticSectionInfo(header,stringTable,sym,debugLine,newFileName,
                                                      mmapBase,mmapLen);
            _nGSections++;
            return &(_gSections[_nGSections-1]);
        }

        static void resolveLineNumber(ref FrameInfo info) {
            foreach (ref section; _gSections[0.._nGSections]) {
                //dwarf stores the directory component of filenames separately
                //dmd doesn't care, and directory components are in the filename
                //linked in gcc produced files still use them
                const(char)[] dir;
                //assumption: if exactAddress=false, it's a return address
                if (find_line_number(section.debugLine, info.address, !info.exactAddress, dir, info.file, info.line))
                    break;
            }
        }
    }

    private void scan_static(in char *file){
        // should try to use mmap,for this reason the "original" format is kept
        // if copying (as now) one could discard the unused strings, and pack the symbols in
        // a platform independent format, but the mmap approach is probably better
        /+auto fdesc=open(file,O_RDONLY);
        ptr_diff_t some_offset=0;
        size_t len=lseek(fdesc,0,SEEK_END);
        lseek(fdesc,0,SEEK_SET);
        address = mmap(0, len, PROT_READ, MAP_PRIVATE, fdesc, some_offset);+/
        FILE * fd=fopen(file,"r");
        bool first_symbol = true;
        Elf_Ehdr header;
        Elf_Shdr section;
        Elf_Sym sym;

        void read(void* ptr, size_t size){
            auto readB=fread(ptr, 1, size,fd);
            if(readB != size){
                throw new SymbolException("read failure in file "~file[0..strlen(file)].idup,__FILE__,__LINE__);
            }
        }

        void seek(ptrdiff_t offset){
            if(fseek(fd, offset, SEEK_SET) == -1){
                throw new SymbolException("seek failure",__FILE__,__LINE__);
            }
        }

        /* read elf header */
        read(&header, header.sizeof);
        if(header.e_shoff == 0){
            return;
        }
        const bool useShAddr=false;
        char[] sectionStrs;
        for(ptrdiff_t i = header.e_shnum - 1; i > -1; i--){
            seek(header.e_shoff + i * header.e_shentsize);
            read(&section, section.sizeof);
            debug(none) printf("[%i] %i\n", i, section.sh_type);

            if (section.sh_type == SHT_STRTAB) {
                /* read string table */
                debug(elf) printf("looking for .shstrtab, [%i] is STRING (size:%i)\n", i, section.sh_size);
                seek(section.sh_offset);
                if (section.sh_name<section.sh_size) {
                    if (useShAddr && section.sh_addr) {
                        if (!may_read(cast(size_t)section.sh_addr)){
                            Runtime.console.stderr("section '");
                            Runtime.console.stderr(i);
                            Runtime.console.stderr("' has invalid address, relocated?\n");
                        } else {
                            sectionStrs=(cast(char*)section.sh_addr)[0..section.sh_size];
                        }
                    }
                    sectionStrs.length = section.sh_size;
                    read(sectionStrs.ptr, sectionStrs.length);
                    char* p=&(sectionStrs[section.sh_name]);
                    if (strcmp(p,".shstrtab".ptr)==0) break;
                }
            }
        }
        if (sectionStrs) {
            char* p=&(sectionStrs[section.sh_name]);
            if (strcmp(p,".shstrtab".ptr)!=0) {
                sectionStrs="\0".dup;
            } else {
                debug(elf) printf("found .shstrtab\n");
            }
        } else {
            sectionStrs="\0".dup;
        }


        /* find sections */
        char[] string_table;
        Elf_Sym[] symbs;
        ubyte[] debug_line;
        for(ptrdiff_t i = header.e_shnum - 1; i > -1; i--){
            seek(header.e_shoff + i * header.e_shentsize);
            read(&section, section.sizeof);
            debug(none) printf("[%i] %i\n", i, section.sh_type);

            if (section.sh_name>=sectionStrs.length) {
                Runtime.console.stderr("could not find name for ELF section at ");
                Runtime.console.stderr(section.sh_name);
                Runtime.console.stderr("\n");
                continue;
            }
            debug(elf) printf("Elf section %s\n",sectionStrs.ptr+section.sh_name);
            if (section.sh_type == SHT_STRTAB && !string_table) {
                /* read string table */
                debug(elf) printf("[%i] is STRING (size:%i)\n", i, section.sh_size);
                if  (strcmp(sectionStrs.ptr+section.sh_name,".strtab")==0){
                    seek(section.sh_offset);
                    if (useShAddr && section.sh_addr){
                        if (!may_read(cast(size_t)section.sh_addr)){
                            Runtime.console.stderr("section '");
                            Runtime.console.stderr(fromStringz(&(sectionStrs[section.sh_name])));
                            Runtime.console.stderr("' has invalid address, relocated?\n");
                        } else {
                            string_table=(cast(char*)section.sh_addr)[0..section.sh_size];
                        }
                    } else {
                        string_table.length = section.sh_size;
                        read(string_table.ptr, string_table.length);
                    }
                }
            } else if(section.sh_type == SHT_SYMTAB) {
                /* read symtab */
                debug(elf) printf("[%i] is SYMTAB (size:%i)\n", i, section.sh_size);
                if (strcmp(sectionStrs.ptr+section.sh_name,".symtab")==0 && !symbs) {
                    if (useShAddr && section.sh_addr){
                        if (!may_read(cast(size_t)section.sh_addr)){
                            Runtime.console.stderr("section '");
                            Runtime.console.stderr(fromStringz(&(sectionStrs[section.sh_name])));
                            Runtime.console.stderr("' has invalid address, relocated?\n");
                        } else {
                            symbs=(cast(Elf_Sym*)section.sh_addr)[0..section.sh_size/Elf_Sym.sizeof];
                        }
                    } else {
                        if(section.sh_offset == 0){
                            continue;
                        }
                        auto p=malloc(section.sh_size);
                        if (p is null)
                            throw new Exception("failed alloc",__FILE__,__LINE__);
                        symbs=(cast(Elf_Sym*)p)[0..section.sh_size/Elf_Sym.sizeof];
                        seek(section.sh_offset);
                        read(symbs.ptr,symbs.length*Elf_Sym.sizeof);
                    }
                }
            } else if (strcmp(sectionStrs.ptr+section.sh_name,".debug_line")==0 && !debug_line) {
                seek(section.sh_offset);
                if (useShAddr && section.sh_addr){
                    if (!may_read(cast(size_t)section.sh_addr)){
                        Runtime.console.stderr("section '");
                        Runtime.console.stderr(fromStringz(&(sectionStrs[section.sh_name])));
                        Runtime.console.stderr("' has invalid address, relocated?\n");
                    } else {
                        debug_line=(cast(ubyte*)section.sh_addr)[0..section.sh_size];
                    }
                } else {
                    auto p=malloc(section.sh_size);
                    if (p is null)
                        throw new Exception("failed alloc",__FILE__,__LINE__);
                    debug_line=(cast(ubyte*)p)[0..section.sh_size];
                    seek(section.sh_offset);
                    read(debug_line.ptr,debug_line.length);
                }
            }
        }

        if (string_table.ptr && symbs.ptr) {
            StaticSectionInfo.addGSection(header,string_table,symbs,debug_line,file[0..strlen(file)]);
            string_table=null;
            symbs=null;
            debug_line=null;
        }
    }

    private void find_symbols(){
        // static symbols
        find_static();
        // dynamic symbols handled with dladdr
    }

    private void find_static(){
        FILE* maps;
        char[4096] buffer;

        maps = fopen("/proc/self/maps", "r");
        if(maps is null){
            debug{
                throw new SymbolException("couldn't read '/proc/self/maps'",__FILE__,__LINE__);
            }else{
                return;
            }
        }
        scope(exit) fclose(maps);

        buffer[] = 0;
        while(fgets(buffer.ptr, buffer.length - 1, maps)){
            scope(exit){
                buffer[] = 0;
            }
            const(char)[] tmp;
            cleanEnd: for(size_t i = buffer.length - 1; i >= 0; i--){
                switch(buffer[i]){
                    case 0, '\r', '\n':
                        buffer[i] = 0;
                        break;
                    default:
                        tmp = buffer[0 .. i+1];
                        break cleanEnd;
                }
            }

Lsplit:
            static if(is(typeof(split(""c)) == string[])){
                string[] tok = split(tmp);
                if(tok.length != 6){
                    // no source file
                    continue;
                }
            }else{
                const(char)[][] tok = delimit(tmp, " \t");
                if(tok.length < 6){
                    // no source file
                    continue;
                }
                const tok_len = 33;
            }
            if(find(tok[$-1], "[") == 0){
                // pseudo source
                continue;
            }
            if(rfind(tok[$-1], ".so") == tok[$-1].length - 3){
                // dynamic lib
                continue;
            }
            if(rfind(tok[$-1], ".so.") != tok[$-1].length ){
                // dynamic lib
                continue;
            }
            if(find(tok[1], "r") == -1){
                // no read
                continue;
            }
            if(find(tok[1], "x") == -1){
                // no execute
                continue;
            }
            const(char)[] addr = tok[0] ~ "\u0000";
            const(char)[] source = tok[$-1] ~ "\u0000";
            __gshared immutable immutable(char)[] marker = "\x7FELF"c;

            void* start, end;
            if(2 != sscanf(addr.ptr, "%zX-%zX", &start, &end)){
                continue;
            }
            if(cast(size_t)end - cast(size_t)start < 4){
                continue;
            }
            if(!may_read(cast(size_t)start)){
                Runtime.console.stderr("got invalid start ptr from '");
                Runtime.console.stderr(fromStringz(source.ptr));
                Runtime.console.stderr("'\n");
                Runtime.console.stderr("ignoring error in ");
                Runtime.console.stderr(__FILE__);
                Runtime.console.stderr(":");
                Runtime.console.stderr(__FILE__);
                Runtime.console.stderr("\n");
                return;
            }
            if(memcmp(start, marker.ptr, marker.length) != 0){
                // not an ELF file
                continue;
            }
            try{
                scan_static(source.ptr);
                debug(elfTable){
                    printf("XX symbols\n");
                    foreach(sName,startAddr,endAddr,pub;StaticSectionInfo){
                        printf("%p %p %d %*s\n",startAddr,endAddr,pub,sName.length,sName.ptr);
                    }
                    printf("XX symbols end\n");
                }
            } catch (Exception e) {
                Runtime.console.stderr("failed reading symbols from '");
                Runtime.console.stderr(fromStringz(source.ptr));
                Runtime.console.stderr("'\n");
                Runtime.console.stderr("ignoring error in ");
                Runtime.console.stderr(__FILE__);
                Runtime.console.stderr(":");
                Runtime.console.stderr(__FILE__);
                Runtime.console.stderr("\n");
                ThWriteOut(e, (in char[] s){ Runtime.console.stderr(s); });
                return;
            }
                
        }
    }

    shared static this() {
        find_symbols();
    }


    private void dwarf_error(const(char)[] msg) {
        Runtime.console.stderr("Tango stacktracer DWARF error: ");
        Runtime.console.stderr(msg);
        Runtime.console.stderr("\n");
    }

    alias short uhalf;

    struct DwarfReader {
        ubyte[] data;
        size_t read_pos;
        bool is_dwarf_64;

        @property size_t left() {
            return data.length - read_pos;
        }

        @property ubyte next() {
            ubyte r = data[read_pos];
            read_pos++;
            return r;
        }

        //read the length field, and set the is_dwarf_64 flag accordingly
        //return 0 on error
        size_t read_initial_length() {
            //64 bit applications normally use 32 bit DWARF information
            //this means on 64 bit, we have to handle both 32 bit and 64 bit infos
            //the 64 bit version seems to be rare, though
            //independent from this, 32 bit DWARF still uses some 64 bit types in
            //64 bit executables (at least the DW_LNE_set_address opcode does)
            auto initlen = read!(uint)();
            is_dwarf_64 = (initlen == 0xff_ff_ff_ff);
            if (is_dwarf_64) {
                //--can handle this, but need testing (this format seems to be uncommon)
                //--remove the following 2 lines to see if it works, and fix the code if needed
                dwarf_error("dwarf 64 detected, aborting");
                abort();
                //--
                static if (size_t.sizeof > 4) {
                    dwarf_error("64 bit DWARF in a 32 bit excecutable?");
                    return 0;
                }
                else return cast(size_t)read!(ulong)();
            } else {
                if (initlen >= 0xff_ff_ff_00) {
                    //see dwarf spec 7.5.1
                    dwarf_error("corrupt debugging information?");
                }
                return initlen;
            }
        }

        //adapted from example code in dwarf spec. appendix c
        //defined max. size is 128 bit; we provide up to 64 bit
        private ulong do_read_leb(bool sign_ext) {
            ulong res;
            int shift;
            ubyte b;
            do {
                b = next();
                res = res | ((b & 0x7f) << shift);
                shift += 7;
            } while (b & 0x80);
            if (sign_ext && shift < ulong.sizeof*8 && (b & 0x40))
                res = res - (1L << shift);
            return res;
        }
        ulong uleb128() {
            return do_read_leb(false);
        }
        long sleb128() {
            return do_read_leb(true);
        }

        T read(T)() {
            T r = *cast(T*)data[read_pos..read_pos+T.sizeof].ptr;
            read_pos += T.sizeof;
            return r;
        }

        size_t read_header_length() {
            if (is_dwarf_64) {
                return cast(size_t)read!(ulong)();
            } else {
                return cast(size_t)read!(uint)();
            }
        }

        //null terminated string
        const(char)[] str() {
            char* start = cast(char*)&data[read_pos];
            size_t len = strlen(start);
            read_pos += len + 1;
            return start[0..len];
        }
    }

    unittest {
        //examples from dwarf spec section 7.6
        ubyte[] bytes = [2,127,0x80,1,0x81,1,0x82,1,57+0x80,100,2,0x7e,127+0x80,0,
            0x81,0x7f,0x80,1,0x80,0x7f,0x81,1,0x7f+0x80,0x7e];
        ulong[] u = [2, 127, 128, 129, 130, 12857];
        long[] s = [2, -2, 127, -127, 128, -128, 129, -129];
        auto rd = DwarfReader(bytes);
        foreach (x; u)
            assert(rd.uleb128() == x);
        foreach (x; s)
            assert(rd.sleb128() == x);
    }

    //debug_line = contents of the .debug_line section
    //is_return_address = true if address is a return address (found by stacktrace)
    bool find_line_number(ubyte[] debug_line, size_t address, bool is_return_address,
        ref const(char)[] out_directory, ref const(char)[] out_file, ref long out_line)
    {
        DwarfReader rd = DwarfReader(debug_line);


        //NOTE:
        //  - instead of saving the filenames when the debug infos are first parsed,
        //    we only save a reference to the debug infos (with FileRef), and
        //    reparse the debug infos when we need the actual filenames
        //  - the same code is used for skipping over the debug infos, and for
        //    getting the filenames later
        //  - this is just for avoiding memory allocation

        struct FileRef {
            int file;           //file number
            size_t directories; //offset to directory info
            size_t filenames;   //offset to filename info
        }

        //include_directories
        void reparse_dirs(void delegate(int idx, const(char)[] d) entry) {
            int idx = 1;
            for (;;) {
                auto s = rd.str();
                if (!s.length)
                    break;
                if (entry)
                    entry(idx, s);
                idx++;
            }
        }
        //file_names
        void reparse_files(void delegate(int idx, int dir, const(char)[] fn) entry) {
            int idx = 1;
            for (;;) {
                auto s = rd.str();
                if (!s.length)
                    break;
                int dir = cast(int)rd.uleb128(); //directory index
                rd.uleb128();           //last modification time (unused)
                rd.uleb128();           //length of file (unused)
                if (entry)
                    entry(idx, dir, s);
                idx++;
            }
        }

        //associated with the found entry
        FileRef found_file;
        bool found = false;

        //the section is made up of independent blocks of line number programs
        blocks: while (rd.left > 0) {
            size_t unit_length = rd.read_initial_length();

            if (unit_length == 0)
                return false;

            size_t start = rd.read_pos;
            size_t end = start + unit_length;

            auto ver = rd.read!(uhalf)();
            auto header_length = rd.read_header_length();

            size_t header_start = rd.read_pos;

            auto min_instr_len = rd.read!(ubyte)();
            auto def_is_stmt = rd.read!(ubyte)();
            auto line_base = rd.read!(byte)();
            auto line_range = rd.read!(ubyte)();
            auto opcode_base = rd.read!(ubyte)();
            ubyte[256] sol_store; //to avoid heap allocation
            ubyte[] standard_opcode_lengths = sol_store[0..opcode_base-1];
            foreach (ref x; standard_opcode_lengths) {
                x = rd.read!(ubyte)();
            }

            size_t dirs_offset = rd.read_pos;
            reparse_dirs(null);
            size_t files_offset = rd.read_pos;
            reparse_files(null);

            rd.read_pos = header_start + header_length;

            //state machine registers
            struct LineRegs {
                bool valid() { return address != 0; }
                int file = 1;               //file index
                int line = 1;               //line number
                size_t address = 0;         //absolute address
                bool end_sequence = false;  //last row in a block
            }

            LineRegs regs;      //current row
            LineRegs regs_prev; //row before

            //append row to virtual line number table, using current register contents
            //NOTE: reg_address is supposed to be increased only (within  a block)
            //      reg_line can be increased or decreased randomly
            void append() {
                if (regs_prev.valid()) {
                    if (is_return_address) {
                        if (address >= regs_prev.address && address <= regs.address)
                            found = true;
                    } else {
                        //some special case *shrug*
                        if (regs_prev.address == address)
                            found = true;
                        //not special case
                        if (address >= regs_prev.address && address < regs.address)
                            found = true;
                    }

                    if (found) {
                        out_line = regs_prev.line;
                        found_file.file = regs_prev.file;
                        found_file.directories = dirs_offset;
                        found_file.filenames = files_offset;
                    }
                }

                regs_prev = regs;
            }

            //actual line number program
            loop: while (rd.read_pos < end) {
                ubyte cur = rd.next();

                if (found)
                    break blocks;

                //"special opcodes"
                if (cur >= opcode_base) {
                    int adj = cur - opcode_base;
                    long addr_inc = (adj / line_range) * min_instr_len;
                    long line_inc = line_base + (adj % line_range);
                    regs.address += addr_inc;
                    regs.line += line_inc;
                    append();
                    continue loop;
                }

                //standard opcodes
                switch (cur) {
                case 1: //DW_LNS_copy
                    append();
                    continue loop;
                case 2: //DW_LNS_advance_pc
                    regs.address += rd.uleb128() * min_instr_len;
                    continue loop;
                case 3: //DW_LNS_advance_line
                    regs.line += rd.sleb128();
                    continue loop;
                case 4: //DW_LNS_set_file
                    regs.file =  cast(int)rd.uleb128();
                    continue loop;
                case 8: //DW_LNS_const_add_pc
                    //add address increment according to special opcode 255
                    //sorry logic duplicated from special opcode handling above
                    regs.address += ((255-opcode_base)/line_range)*min_instr_len;
                    continue loop;
                case 9: //DW_LNS_fixed_advance_pc
                    regs.address += rd.read!(uhalf)();
                    continue loop;
                default:
                }

                //"unknown"/unhandled standard opcode, skip
                if (cur != 0) {
                    //skip parameters
                    auto count = standard_opcode_lengths[cur-1];
                    while (count--) {
                        rd.uleb128();
                    }
                    continue loop;
                }

                //extended opcodes
                size_t instr_len =  cast(size_t)rd.uleb128(); //length of this instruction
                cur = rd.next();
                switch (cur) {
                case 1: //DW_LNE_end_sequence
                    regs.end_sequence = true;
                    append();
                    //reset
                    regs = LineRegs.init;
                    regs_prev = LineRegs.init;
                    continue loop;
                case 2: //DW_LNE_set_address
                    regs.address = rd.read!(size_t)();
                    continue loop;
                case 3: //DW_LNE_define_file
                    //can't handle this lol
                    //would need to append the file to the file table, but to avoid
                    //memory allocation, we don't copy out and store the normal file
                    //table; only a pointer to the original dwarf file entries
                    //solutions:
                    //  - give up and pre-parse debugging infos on program startup
                    //  - give up and allocate heap memory (but: signal handlers?)
                    //  - use alloca or a static array on the stack
                    dwarf_error("can't handle DW_LNE_define_file yet");
                    return false;
                default:
                }

                //unknown extended opcode, skip
                rd.read_pos += instr_len;
                continue loop;
            }

            //ensure correct start of next block (?)
            assert(rd.read_pos == end);
        }

        if (!found)
            return false;

        //resolve found_file to the actual filename & directory strings
        int dir;
        rd.read_pos = found_file.filenames;
        reparse_files((int idx, int a_dir, const(char)[] a_file) {
            if (idx == found_file.file) {
                dir = a_dir;
                out_file = a_file;
            }
        });
        rd.read_pos = found_file.directories;
        reparse_dirs((int idx, const(char)[] a_dir) {
            if (idx == dir) {
                out_directory = a_dir;
            }
        });

        return true;
    }

}

}
