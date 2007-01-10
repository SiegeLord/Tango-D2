/**
 * A simple D parser to extract imports, module names, etc
 * 
 * Authors:
 *  Lars Ivar Igesund
 * 
 * License:
 *  Copyright (c) 2006  Lars Ivar Igesund
 *  
 *  Permission is hereby granted, free of charge, to any person obtaining a
 *  copy of this software and associated documentation files (the "Software"),
 *  to deal in the Software without restriction, including without limitation
 *  the rights to use, copy, modify, merge, publish, distribute, sublicense,
 *  and/or sell copies of the Software, and to permit persons to whom the
 *  Software is furnished to do so, subject to the following conditions:
 *  
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.
 *  
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *  DEALINGS IN THE SOFTWARE.
 */

module ddep.DParser;

import tango.io.Stdout;

import ddep.TokenReader;
import Integer = tango.text.convert.Integer;


class DParser
{
    alias void delegate(char[]) CharArrDg;
    alias void delegate(bool) BoolDg;

    private CharArrDg depvisitor;
    private CharArrDg modnamedg;
    private BoolDg maindg;
    private bool[char[]] versions;
    private int vernum;
    private bool[char[]] debugs;
    private int debugnum; 
    private bool debugset;

    public void dependency(CharArrDg depvis)
    {
        depvisitor = depvis; 
    }

    public void moduleName(CharArrDg modnamedg)
    {
        this.modnamedg = modnamedg; 
    }

    public void hasMain(BoolDg maindg)
    {
        this.maindg = maindg;
    }

    public void setVersions(bool[char[]] verids)
    {
        versions = verids;
    }

    public void setDebugs(bool[char[]] debugids)
    {
        debugs = debugids;
    }

    public void setVersionNum(int num)
    {
        vernum = num;
    }

    public void setDebugNum(int num)
    {
        debugnum = num;
    }

    public void setDebug()
    {
        debugset = true;
    }

    private bool setVerNumber(char[] t)
    {
        if (isNumber(t)) {
            int num = cast(int) Integer.parse(t);
            vernum = num;
            return true;
        }

        return false;
    }

    private bool isNumber(char[] t)
    {
        Stdout("Checking if number: ")(t).newline;
        bool isnum = true;
        foreach (c; t) {
            if (!(c <= '9' && c >= '0')) {
                isnum = false;
                break;
            }
        }

        if (isnum) Stdout("It was a number.").newline;
        return isnum;
    }

    private bool setDebugNumber(char[] t)
    {
        if (isNumber(t)) {
            int num = cast(int) Integer.parse(t);
            debugnum = num;
            return true;
        }

        return false;
    }

    private bool versionSet(char[] t)
    {
        if (t == "none") return false;
        if (t == "all") return true;
        if (isNumber(t)) {
            int num = cast(int) Integer.parse(t);
            if (num >= vernum) { return true; }
            else return false;
        }
        return false;
    }

    private bool debugSet(char[] t)
    {
        if (t == "none") return false;
        if (t == "all") return true;
        if (isNumber(t)) {
            int num = cast(int) Integer.parse(t);
            Stdout("Found debug number: ")(num).newline;
            if (debugnum >= num) { return true; }
            else return false;
        }
        return false;
    }

    private bool debugSet()
    {
        return debugset;
    }

    public void parse(char[] filename)
    {
        auto tokens = new TokenReader(filename);
        char[] t;
        bool enterelse;

        void endBlock()
        {
            char[] t;
            int lvl = 1;

            do {
                tokens(t);
                if (t == "{") lvl++;
                else if (t == "}") lvl--;
            } while (lvl > 0);
        }

        void endCondition()
        {
            tokens(t);
            switch (t) {
            case "{":
                endBlock();
                enterelse = true;
                break;
            case ":":
                endBlock();
            default:
                tokens(t);
                while (t != ";") tokens(t);
                enterelse = true;
                break;
            }
        }

        while(true) {
            tokens(t);
            switch(t) {
            case "else":
                if (!enterelse) {
                    tokens(t);
                    if (t == "{") endBlock();
                    else while (t != ";") tokens(t);
                    break;
                }

            case "module":
                tokens(t);
                modnamedg(t);
                tokens(t); assert (t == ";");
                break;

            case "import":
                do {
                    tokens(t);
                    char[] mod = t;
                    tokens(t);
                    if (t == "," || t == ";" || t == ":")
                        depvisitor(mod);
                    else if (t == "=") {
                        tokens(t);
                        depvisitor(t);
                        tokens(t);
                    }
                    if (t == ":") while (t != ";") tokens(t);
                } while (t == ",")
                assert (t == ";");
                break;

            case "version":
                tokens(t);
                if (t == "=") {
                    tokens(t);
                    if (!setVerNumber(t))                        
                        versions[t] = true;
                    tokens(t); assert (t == ";");
                    break;
                }

                assert(t == "(");
                tokens(t);
                if (!versionSet(t)) {
                    tokens(t); assert (t == ")");
                    endCondition();
                }

                break;

            case "debug":
                tokens(t);
                if (t == "=") {
                    tokens(t);
                    if (!setDebugNumber(t))
                        debugs[t] = true;
                    tokens(t); assert (t == ";");
                    break;
                }

                if (t != "(" && !debugSet())
                    endCondition();
                else if (t == "(") {
                    tokens(t);
                    if(!debugSet(t)) {
                        tokens(t); assert (t == ")");
                        endCondition();
                    }
                }
                
                break;

            case "main":
                maindg(true);
                break;
            default:
                break;
            }
        }
    }
}
