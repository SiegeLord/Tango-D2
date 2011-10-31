/*******************************************************************************
 * 
 *      copyright:      Copyright (c) unknown. All rights reserved
 *
 *      license:        BSD style: $(LICENSE)
 * 
 *      version         Initial release
 * 
 *      author          unknown
 * 
 * This file is part of the tango software library. Distributed under the terms
 * of the Boost Software License, Version 1.0. See LICENSE.TXT for more info.
 *******************************************************************************/
module ThreadFiberGCStress;

private import  tango.io.Stdout,
                tango.core.Thread,
                tango.text.Stringz;
                
private import  core.stdc.stdio,
                core.sync.mutex,
                core.memory;

Mutex tttt;

void printESP(const(char)[] name){
    size_t esp;
    esp=cast(size_t)&esp;
    synchronized(tttt){ // here one can also use synchronized(tttt)
    	printf("%s %p %p\n", toStringz(name),esp,esp & 0xF);
    }
}

class Tr{
    int count;
    Mutex m;
    char[1] s;
    Fiber[] fibers;
    int nfib;
    this(){
        count=500;
        m=new Mutex();
        s[0]='0';
        fibers=[new Fiber(&fib1,1024*1024),new Fiber(&fib2,1024*1024)];
        nfib=2;
    }
    void fib1(){
        while(1){
            workers2("f1");
            Fiber.yield();
        }
    }
    void fib2(){
        while(1){
            workers2("f2");
            Fiber.yield();
        }
    }
    void workers(){
		printESP("workers "~Thread.getThis().name);
        try{
            while(count>0){
                Fiber ff;
                synchronized(m){
                    --count;
                    assert(nfib>0);
                    s[0]=cast(char)(Thread.getThis().name[0]);
                    GC.collect();
                    assert(s[0]==cast(char)(Thread.getThis().name[0]),"error");
                    ff=fibers[0];
                    fibers[0]=fibers[1];
                    --nfib;
                    fibers[1]=null;
                }
                ff.call;
                synchronized(m){
                    fibers[nfib]=ff;
                    nfib++;
                }
                Thread.yield();
            }
        } catch (Exception e){
            Stdout("\nERROR, failing").newline;
            Stdout(e).newline;
        }
		printESP("workers "~Thread.getThis().name~"end");
    }
    void workers2(const(char)[] fName){
		printESP(fName~Thread.getThis().name);
        try{
            synchronized(m){
                s[0]=cast(char)(Thread.getThis().name[0]+2);
                GC.collect();
                assert(s[0]==cast(char)(Thread.getThis().name[0]+2),"error");
            }
        } catch (Exception e){
            Stdout("\nERROR, failing").newline;
            Stdout(e).newline;
        }
		printESP(fName~Thread.getThis().name~"end");
        
    }
}

void main(){
    tttt=new Mutex();
	printESP("main");
    Tr glob=new Tr();
    Thread ta=new Thread(&glob.workers,1024*1024);
    ta.name="a";
    Thread tb=new Thread(&glob.workers,1024*1024);
    tb.name="b";
    ta.start();
    tb.start();
    
    ta.join();
    tb.join();
	printESP("mainEnd");
	synchronized(tttt){
        printf("End!\n");
    }
}

