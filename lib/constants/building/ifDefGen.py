#!/bin/env python
import sys

def writeConsts(inF,outF):
    cOld=""
    while 1:
        line=inF.readline()
        if not line: break
        if (line.isspace()):
            outF.write("\n");
        else:
            sLine=line.split();
            c=sLine[0];
            r=line.strip()[len(c):].strip()
            if (len(r)>0 and (r[0]=="," or r[0]==";")): r=r[1:].strip()
            if (len(r)>0 and r[0]!="/"):
                raise Exception("unexpected rest string:"+repr(r))
            if c==cOld: continue
            cOld=c
            outF.write("#ifdef ")
            outF.write(c)
            outF.write("\n")
            outF.write("  enum __XYX__")
            outF.write(c)
            outF.write(" = ")
            outF.write(c)
            outF.write("; ")
            outF.write(r)
            outF.write("\n")
            outF.write("#endif\n")

if __name__=="__main__":
    writeConsts(open(sys.argv[1],"r"),open(sys.argv[2],"w"))
