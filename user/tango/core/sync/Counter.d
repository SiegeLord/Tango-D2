/**
 * Implements a fast global counters
 *
 * Copyright: Copyright (C) 2009 Fawzi Mohamed.  All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Fawzi Mohamed
 */
module tango.core.sync.Counter;
import tango.core.sync.Atomic;
import tango.core.sync.Mutex;

static if (LockVersion){
    /// fast unique number (that handles well the absence of atomic ops)
    struct UniqueNumber(T){
        T _val;
        Mutex m;
        
        /// creates a unique number object with the given initial value
        static UniqueNumber opCall(T firstVal=cast(T)0){
            UniqueNumber res;
            res._val=firstVal;
            res.m=new Mutex();
            return res;
        }
        
        /// returns the next unique value
        T next(){
            if (m is null){
                synchronized{
                    if (m is null){
                        m=new Mutex();
                    }
                }
            }
            T oldVal;
            synchronized(m){
                oldVal=_val;
                ++_val;
            }
            return oldVal;
        }
    }
} else {
    /// fast unique number (that handles well the absence of atomic ops)
    struct UniqueNumber(T){
        T _val;
        
        /// creates a unique number object with the given initial value
        static UniqueNumber opCall(T firstVal=cast(T)0){
            UniqueNumber res;
            res._val=firstVal;
            return res;
        }

        /// returns the next unique value
        T next(){
            return nextValue(_val);
        }
        
    }
}

static if (LockVersion){
    /// Flag that can be used to communicate that data is ready between threads
    /// (handles well the absence of atomic ops)
    struct Flag(T){
        T _val;
        Mutex m;
        
        /// creates a unique number object with the given initial value
        static Flag opCall(T firstVal){
            Flag res;
            res._val=firstVal;
            res.m=new Mutex();
            return res;
        }
        
        private Mutex m(){
            if (_m is null){
                synchronized{
                    if (_m is null){
                        _m=new Mutex();
                    }
                }
            }
            return _m;
        }
        
        static if (is(typeof(T.init+T.init))){
            /// adds to the flag
            T opAddAssign(T incV=cast(T)1){
                T oldVal;
                synchronized(m){
                    oldVal=_val;
                    _val+=incV;
                }
                return oldVal;
            }

            /// subtracts from the flag
            T opSubAssign(T incV=cast(T)1){
                T oldVal;
                synchronized(m){
                    oldVal=_val;
                    _val-=incV;
                }
                return oldVal;
            }
        }
        
        /// sets the value of the flag
        T opAssign(T val){
            T oldVal;
            synchronized(m){
                oldVal=_val;
                _val+=incV;
            }
            return oldVal;
        }

        /// gets the value of the flag
        T opCall(){
            T oldVal;
            synchronized(m){
                oldVal=_val;
            }
            return oldVal;
        }
        
        /// applies a pure function to the flag, returns the old value
        T opCall(T delegate(T)op){
            T oldVal;
            synchronized(m){
                oldVal=_val;
                _val=op(oldVal);
            }
            return oldVal;
        }
    }
} else {
    /// Flag that can be used to communicate that data is ready between threads
    /// (handles well the absence of atomic ops)
    struct Flag(T){
        T _val;
        
        /// creates a unique number object with the given initial value
        static Flag opCall(T firstVal){
            Flag res;
            res._val=firstVal;
            return res;
        }
        
        static if (is(typeof(T.init+T.init))){
            /// adds to the flag
            T opAddAssign(T incV=cast(T)1){
                return flagAdd(_val,incV);
            }
            /// subtracts from the flag
            T opSubAssign(T incV=cast(T)1){
                return flagAdd(_val,-incV);
            }
        }
        
        /// sets the value of the flag
        T opAssign(T newVal){
            return flagSet(_val,newVal);
        }

        /// gets the value of the flag
        T opCall(){
            return flagGet(_val);
        }
        
        /// applies a pure function to the flag, returns the old value
        T opCall(T delegate(T)op){
            return flagOp(_val,op);
        }
    }
}

