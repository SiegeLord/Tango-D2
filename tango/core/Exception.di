// D import file generated from 'core\Exception.d'
module tango.core.Exception;
private
{
    alias void(* assertHandlerType)(char[] file, uint line, char[] msg = null);
    alias bool(* collectHandlerType)(Object obj);
    assertHandlerType assertHandler = null;
    collectHandlerType collectHandler = null;
}
class ArrayBoundsException : Exception
{
    this(char[] file, size_t line)
{
super("Array index out of bounds",file,line);
}
}
class AssertException : Exception
{
    this(char[] file, size_t line)
{
super("Assertion failure",file,line);
}
    this(char[] msg, char[] file, size_t line)
{
super(msg,file,line);
}
}
class FinalizeException : Exception
{
    ClassInfo info;
    this(ClassInfo c, Exception e = null)
{
super("Finalization error",e);
info = c;
}
    char[] toString()
{
return "An exception was thrown while finalizing an instance of class " ~ info.name;
}
}
class OutOfMemoryException : Exception
{
    this(char[] file, size_t line)
{
super("Memory allocation failed",file,line);
}
    char[] toString()
{
return msg ? super.toString() : "Memory allocation failed";
}
}
class SwitchException : Exception
{
    this(char[] file, size_t line)
{
super("No appropriate switch clause found",file,line);
}
}
class UnicodeException : Exception
{
    size_t idx;
    this(char[] msg, size_t idx)
{
super(msg);
this.idx = idx;
}
}
void setAssertHandler(assertHandlerType h)
{
assertHandler = h;
}
void setCollectHandler(collectHandlerType h)
{
collectHandler = h;
}
extern (C) 
{
    void onAssertError(char[] file, uint line);
}
extern (C) 
{
    void onAssertErrorMsg(char[] file, uint line, char[] msg);
}
extern (C) 
{
    bool onCollectResource(Object obj);
}
extern (C) 
{
    void onArrayBoundsError(char[] file, size_t line);
}
extern (C) 
{
    void onFinalizeError(ClassInfo info, Exception ex);
}
extern (C) 
{
    void onOutOfMemoryError();
}
extern (C) 
{
    void onSwitchError(char[] file, size_t line);
}
extern (C) 
{
    void onUnicodeError(char[] msg, size_t idx);
}
