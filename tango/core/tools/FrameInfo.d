module tango.core.tools.FrameInfo;

version (D_Version2):

package:

struct FrameInfo
{
    /// line number in the source of the most likely start adress (0 if not available)
    long line;
    /// number of the stack frame (starting at 0 for the top frame)
    size_t iframe;
    /// offset from baseSymb: within the function, or from the closest symbol
    ptrdiff_t offsetSymb;
    /// adress of the symbol in this execution
    size_t baseSymb;
    /// offset within the image (from this you can use better methods to get line number
    /// a posteriory)
    ptrdiff_t offsetImg;
    /// base adress of the image (will be dependent on randomization schemes)
    size_t baseImg;
    /// adress of the function, or at which the ipc will return
    /// (which most likely is the one after the adress where it started)
    /// this is the raw adress returned by the backtracing function
    size_t address;
    /// file (image) of the current adress
    const(char)[] file;
    /// name of the function, if possible demangled
    char[] func;
    /// extra information (for example calling arguments)
    const(char)[] extra;
    /// if the address is exact or it is the return address
    bool exactAddress;
    /// if this function is an internal functions (for example the backtracing function itself)
    /// if true by default the frame is not printed
    bool internalFunction;
    alias void function(FrameInfo*,void delegate(in char[])) FramePrintHandler;
    /// the default printing function
    static FramePrintHandler defaultFramePrintingFunction;
    /// writes out the current frame info
    void writeOut(void delegate(in char[])sink){

        if (defaultFramePrintingFunction){
            defaultFramePrintingFunction(&this,sink);
        } else {
            char[26] buf;
            //auto len=snprintf(buf.ptr,26,"[%8zx]",address);
            //sink(buf[0..len]);
            //len=snprintf(buf.ptr,26,"%8zx",baseImg);
            //sink(buf[0..len]);
            //len=snprintf(buf.ptr,26,"%+td ",offsetImg);
            //sink(buf[0..len]);
            //while (++len<6) sink(" ");
            if (func.length) {
                sink(func);
            } else {
                sink("???");
            }
            for (size_t i=func.length;i<80;++i) sink(" ");
            //len=snprintf(buf.ptr,26," @%zx",baseSymb);
            //sink(buf[0..len]);
            //len=snprintf(buf.ptr,26,"%+td ",offsetSymb);
            //sink(buf[0..len]);
            if (extra.length){
                sink(extra);
                sink(" ");
            }
            sink(file);
            sink(":");
            sink(ulongToUtf8(buf, line));
        }
    }
    /// clears the frame information stored
    void clear()
    {
        line=0;
        iframe=-1;
        offsetImg=0;
        baseImg=0;
        offsetSymb=0;
        baseSymb=0;
        address=0;
        exactAddress=true;
        internalFunction=false;
        file=null;
        func=null;
        extra=null;
    }
}

const(char)[] ulongToUtf8 (char[] tmp, ulong val)
in {
     assert (tmp.length > 19, "atoi buffer should be more than 19 chars wide");
     }
body
{
        char* p = tmp.ptr + tmp.length;

        do {
             *--p = cast(char)((val % 10) + '0');
             } while (val /= 10);

        return tmp [cast(size_t)(p - tmp.ptr) .. $];
}