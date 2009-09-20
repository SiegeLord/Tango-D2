/**
 *   Linux Stacktracing
 *
 *   Functions to parse the ELF format and create a symbolic trace
 *
 *   The core Elf handling was taken from Thomas Kühne flectioned,
 *   with some minor pieces taken from someone whose name I forgot
 *   and that should announce himself to get credit.
 *   But the routines and flow have been (sometime heavily) changed
 *
 *  Copyright: 2009 Fawzi, Thomas Kühne
 *  License:   tango license
 *  Authors:   Fawzi Mohamed
 */
module tango.core.stacktrace.LinuxStackTrace;

version(linux){
    import tango.stdc.stdlib;
    import tango.stdc.stdio;
    import tango.stdc.string : strcmp, strlen,memcmp;
    import tango.stdc.signal;
    import tango.stdc.errno: errno, EFAULT;
    import tango.stdc.posix.unistd: access;
    import tango.text.Util : delimit;
    import tango.core.Array : find, rfind;

    class SymbolException:Exception {
        this(char[]msg,char[]file,long lineNr,Exception next=null){
            super(msg,file,lineNr,next);
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
        const EI_NIDENT = 16;

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
        char[] stringTable;
        Elf_Sym[] sym;
        char[] fileName;
        void* mmapBase;
        size_t mmapLen;
        /// initalizer
        static StaticSectionInfo opCall(Elf_Ehdr header, char[] stringTable, Elf_Sym[] sym,
            char[] fileName, void* mmapBase=null, size_t mmapLen=0) {
            StaticSectionInfo newV;
            newV.header=header;
            newV.stringTable=stringTable;
            newV.sym=sym;
            newV.fileName=fileName;
            newV.mmapBase=mmapBase;
            newV.mmapLen=mmapLen;
            return newV;
        }
        
        // stores the global sections
        const MAX_SECTS=5;
        static StaticSectionInfo[MAX_SECTS] _gSections;
        static size_t _nGSections,_nFileBuf;
        static char[MAX_SECTS*256] _fileNameBuf;
        
        /// loops on the global sections
        static int opApply(int delegate(ref StaticSectionInfo) loop){
            for (size_t i=0;i<_nGSections;++i){
                auto res=loop(_gSections[i]);
                if (res) return res;
            }
            return 0;
        }
        /// loops on the static symbols
        static int opApply(int delegate(ref char[]sNameP,ref size_t startAddr,
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
                    char *sName;
                    if (symb.st_name<sec.stringTable.length) {
                        sName=&(sec.stringTable[symb.st_name]);
                    } else {
                        debug(elf) printf("symbol name out of bounds %p\n",symb.st_value);
                    }
                    char[] symbName=sName[0..(sName?strlen(sName):0)];
                    size_t endAddr=symb.st_value+symb.st_size;
                    auto res=loop(symbName,symb.st_value,endAddr,isPublic);
                    if (res) return res;
                }
            }
            return 0;
        }
        /// returns a new section to fill out
        static StaticSectionInfo *addGSection(Elf_Ehdr header,char[] stringTable, Elf_Sym[] sym,
            char[] fileName,void *mmapBase=null, size_t mmapLen=0){
            if (_nGSections>=MAX_SECTS){
                throw new Exception("too many static sections",__FILE__,__LINE__);
            }
            auto len=fileName.length;
            char[] newFileName;
            if (_fileNameBuf.length< _nFileBuf+len) {
                newFileName=fileName[0..len].dup;
            } else {
                _fileNameBuf[_nFileBuf.._nFileBuf+len]=fileName[0..len];
                newFileName=_fileNameBuf[_nFileBuf.._nFileBuf+len];
                _nFileBuf+=len;
            }
            _gSections[_nGSections]=StaticSectionInfo(header,stringTable,sym,newFileName,
                                                      mmapBase,mmapLen);
            _nGSections++;
            return &(_gSections[_nGSections-1]);
        }
    }
    
    private void scan_static(char *file){
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
                throw new SymbolException("read failure in file "~file[0..strlen(file)],__FILE__,__LINE__);
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
                            fprintf(stderr,"section '%d' has invalid address, relocated?\n",i);
                        } else {
                            sectionStrs=(cast(char*)section.sh_addr)[0..section.sh_size];
                        }
                    }
                    sectionStrs.length = section.sh_size;
                    read(sectionStrs.ptr, sectionStrs.length);
                    char* p=&(sectionStrs[section.sh_name]);
                    if (strcmp(p,".shstrtab")==0) break;
                }
            }
        }
        if (sectionStrs) {
            char* p=&(sectionStrs[section.sh_name]);
            if (strcmp(p,".shstrtab")!=0) {
                sectionStrs="\0";
            } else {
                debug(elf) printf("found .shstrtab\n");
            }
        } else {
            sectionStrs="\0";
        }

  
        /* find sections */
        char[] string_table;
        Elf_Sym[] symbs;
        for(ptrdiff_t i = header.e_shnum - 1; i > -1; i--){
            seek(header.e_shoff + i * header.e_shentsize);
            read(&section, section.sizeof);
            debug(none) printf("[%i] %i\n", i, section.sh_type);

            if (section.sh_name>=sectionStrs.length) {
                fprintf(stderr,"could not find name for ELF section at %d\n",
                        section.sh_name);
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
                            fprintf(stderr,"section '%s' has invalid address, relocated?\n",
                                    &(sectionStrs[section.sh_name]));
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
                            fprintf(stderr,"section '%s' has invalid address, relocated?\n",
                                    &(sectionStrs[section.sh_name]));
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
            }
            
            if (string_table && symbs) {
                StaticSectionInfo.addGSection(header,string_table,symbs,file[0..strlen(file)]);
                string_table=null;
                symbs=null;
            }
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
            char[] tmp;
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
                char[][] tok = delimit(tmp, " \t");
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
            char[] addr = tok[0] ~ "\u0000";
            char[] source = tok[$-1] ~ "\u0000";
            const char[] marker = "\x7FELF"c;

            void* start, end;
            if(2 != sscanf(addr.ptr, "%zX-%zX", &start, &end)){
                continue;
            }
            if(cast(size_t)end - cast(size_t)start < 4){
                continue;
            }
            if(!may_read(cast(size_t)start)){
                fprintf(stderr, "got invalid start ptr from %s\n",source.ptr);
                fprintf(stderr, "ignoring error in %*s:%ld\n",__FILE__.length,__FILE__.ptr,__LINE__);
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
                fprintf(stderr, "failed reading symbols from %s\n", source.ptr);
                fprintf(stderr, "ignoring error in %*s:%ld\n",__FILE__.length,__FILE__.ptr,__LINE__);
                e.writeOut((char[]s){
                        fprintf(stderr,"%*s",s.length,s.ptr);
                        fflush(stderr);
                    });
                return;
            }
                
        }
    }

    static this() {
        find_symbols();
    }

    version(none){
        size_t dmd_AddrBacktrace(TraceContext* context, TraceContext* contextOut,
            size_t* trace_buf, size_t buf_length, int* flags)
        {
            size_t depth;
            size_t regebp;

            asm {
                mov regebp, EBP ;
            }

            for (;;) {
                size_t retaddr;
                regebp = dmd__eh_find_caller(regebp, &retaddr);

                if (!regebp)
                    break;

                if (depth == buf_length)
                    break;

                trace_buf[depth] = retaddr;

                depth++;

                if (sym_contains_address(g_stop_traceback_at, retaddr))
                    break;
            }

            return depth;
        }

        //borrowed from Phobos' internal/deh2.d
        //slightly modified (uint -> size_t, comments, abort())
        size_t dmd__eh_find_caller(size_t regbp, size_t *pretaddr) {
            size_t bp = *cast(size_t*)regbp;

            if (bp) {
                if (bp <= regbp) {
                    //fprintf(stderr, "%.*sbacktrace error, stop.\n", MODULE_PREFIX);
                    //abort();
                    return 0;
                }
                *pretaddr = *cast(size_t*)(regbp + size_t.sizeof);
            }

            return bp;
        }
    }
}
