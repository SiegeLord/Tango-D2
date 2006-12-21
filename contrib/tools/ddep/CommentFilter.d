/**
 * A reader that removes comments from D files
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

module ddep.CommentFilter;

import tango.io.protocol.Reader;

class CommentFilter : Reader
{
    alias next opCall;

    private uint nestinglvl = 0;

    public CommentFilter peek(inout char c)
    {
		c = (cast(char[])getBuffer.get(1,false))[0];
        return this;
    }
	
	public this (IConduit conduit){
		super(conduit);
	}

    public CommentFilter next(inout char c)
    {
        char cc;
        char pc;
        get(cc);
        if (cc == '/') {
            peek(pc);
            switch (pc) {
                case '/':
                    get(cc);    
                    do {
                       get(cc); 
                    } while (cc != '\n');
                    break;
                case '*':
                    get(cc);    
                    do {
                        get(cc);
                        while (cc == '*') 
                            get(cc);
                    } while (cc != '/')
                    get(cc);
                    break;
                case '+':
                    get(cc);    
                    nestinglvl++;                     
                    NESTING:
                    do {
                        get(cc);
                        while (cc == '/') {
                            get(cc);
                            if (cc == '+') {
                                nestinglvl++;
                                goto NESTING;
                            }
                        }
                        while (cc == '+')
                            get(cc);
                    } while (cc != '/')
                    nestinglvl--;
                    if (nestinglvl)
                        goto NESTING;
                    get(cc);
                    break;
                default: // Not a comment
                    c = cc;
                    return this;
            }
        }
        c = cc;
        return this;
    }
}
