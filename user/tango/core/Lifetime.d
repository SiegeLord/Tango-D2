/** 
* Lifetime related things, or the moment callbacks when destructors are called and weak pointers
*
* author: Fawzi Mohamed
* license: tango license
*/
module tango.core.Lifetime;
import tango.core.internal.runtimeInterface: rt_attachDisposeEvent,rt_detachDisposeEvent;
import tango.core.internal.gcInterface: gc_counter, gc_finishGCRun;
import tango.core.sync.Atomic;
import tango.core.Variant;

/// executes the given action when the first of a group of objects is collected
class OnFirstDestructor{
    size_t[] hiddenAddrs;
    void delegate(OnFirstDestructor) action;
    bool triggered;
    Variant actV;
    
    /// creates a new destructor callback
    this(void delegate() action,Object[] objs=null){
        hiddenAddrs.length=objs.length;
        foreach (i,obj;objs){
            hiddenAddrs[i]= ~(cast(size_t)(cast(void*)obj));
            rt_attachDisposeEvent(obj,&_destructorCallback);
        }
        actV=Variant(action);
        this.action=delegate void(OnFirstDestructor d){ d.actV.get!(void delegate())()(); };
        triggered=false;
    }
    
    /// ditto
    this(void delegate(OnFirstDestructor) action,Object[] objs=null){
        hiddenAddrs.length=objs.length;
        foreach (i,obj;objs){
            hiddenAddrs[i]= ~(cast(size_t)(cast(void*)obj));
            rt_attachDisposeEvent(obj,&_destructorCallback);
        }
        this.action=action;
        triggered=false;
    }
    
    /// ditto
    this(void function(Object[]) action,Object[] objs=null){
        hiddenAddrs.length=objs.length;
        foreach (i,obj;objs){
            hiddenAddrs[i]= ~(cast(size_t)(cast(void*)obj));
            rt_attachDisposeEvent(obj,&_destructorCallback);
        }
        actV=Variant(action);
        this.action=delegate void(OnFirstDestructor d){
                Object[] objss=new Object[d.hiddenAddrs.length];
                foreach (i,hiddenAddr;d.hiddenAddrs){
                    objss[i]= cast(Object)(cast(void*)(~ hiddenAddr));
                }
                d.actV.get!(void function(Object[]))()(objss);
            };
        triggered=false;
    }

    /// ditto
    this(void delegate(Object[]) action,Object[] objs=null){
        hiddenAddrs.length=objs.length;
        foreach (i,obj;objs){
            hiddenAddrs[i]= ~(cast(size_t)(cast(void*)obj));
            rt_attachDisposeEvent(obj,&_destructorCallback);
        }
        actV=Variant(action);
        this.action=delegate void(OnFirstDestructor d){
                Object[] objs=new Object[d.hiddenAddrs.length];
                foreach (i,hiddenAddr;d.hiddenAddrs){
                    objs[i]= cast(Object)(cast(void*)(~ hiddenAddr));
                }
                d.actV.get!(void delegate(Object[]))()(objs);
            };
        triggered=false;
    }
    
    /// removes the trigger if not yet triggered
    void nullify(){
        synchronized (this){
            if (!triggered) {
                triggered=true;
                foreach (hiddenAddr;hiddenAddrs){
                    auto obj=cast(Object)(cast(void*)(~hiddenAddr));
                    if (obj !is null){
                        rt_detachDisposeEvent(obj,&_destructorCallback);
                    }
                }
                hiddenAddrs=null;
            }
            action=null;
            actV.clear();
        }
    }
    
    /// adds an object to the one that trigger this action
    void addObject(Object obj){
        if (obj !is null){
            synchronized(this){
                hiddenAddrs ~= ~(cast(size_t)(cast(void*)obj));
                rt_attachDisposeEvent(obj,&_destructorCallback);
            }
        }
    }
    
    // internal destructor callback
    void _destructorCallback(Object o){
        // should o be passed on?
        synchronized (this){
            if (!triggered) {
                triggered=true;
                if (action) action(this);
                memoryBarrier!(true,true,true,true)(); // ensure effects of action are visible, skip?
                foreach (hiddenAddr;hiddenAddrs){
                    auto obj=cast(Object)(cast(void*)(~hiddenAddr));
                    if (obj !is null){
                        rt_detachDisposeEvent(obj,&_destructorCallback); // with some bookkeeping it would be possible to explicitly delete this object, but it is probably not worth it
                    }
                }
                hiddenAddrs=null;
            }
        }
    }
}

/// Implements a Weak pointer, it return null if the object pointed to was deallocated
class WeakPtr(T:Object){
    size_t hiddenAddr; // use only the pad addr?
    OnFirstDestructor pad;
    
    /// nullify the weakpointer
    void nullify(){
        T val=this.opCall();
        if (val !is null){
            hiddenAddr= ~(cast(size_t)0);
            if (pad)
                pad.nullify();
            pad=null;
        }
    }
    
    /// initializes a weak pointer (returns null if the object was deallocated in the meantime)
    this(T obj){
        hiddenAddr= ~(cast(size_t)(cast(void*)obj)); // to help when stored on the stack
        pad=new OnFirstDestructor(function void(Object[] objs){
                if (objs.length==2){
                    auto wp=cast(WeakPtr)objs[0];
                    if (wp !is null){
                        wp.hiddenAddr= ~cast(size_t)0;
                        wp.pad=null;
                    }
                }
            },[cast(Object)this,obj]);
    }
    
    /// dereferences the weak pointer (returns null if the object was deallocated in the meantime)
    T opCall(){
        auto gcCounter0=gc_counter();
        volatile T res =cast(T)(cast(void*)(~ hiddenAddr));
        auto gcCounter1=gc_counter();
        if (res !is null && (gcCounter0!=gcCounter1 || gcCounter0 & cast(size_t)1)){
            gc_finishGCRun();
            return cast(T)(cast(void*)(~ hiddenAddr));
        }
        return res;
    }
}

debug(UnitTest){
    class A{
        this(){}
    }
    unittest{
        auto a=new A();
        auto wpa=new WeakPtr!(A)(a);
        auto wpb=new WeakPtr!(A)(a);
        assert(a is wpa());
        wpa.nullify();
        assert(wpa() is null);
        assert(wpb() is a);
        delete a;
        assert(wpb() is null);
        auto b=new A();
        auto wpc=new WeakPtr!(A)(b);
        auto padc=wpc.pad;
        delete wpc;
        assert(padc.triggered);
    }
}
