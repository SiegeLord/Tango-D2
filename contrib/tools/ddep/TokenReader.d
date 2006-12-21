/**
 * A token reader geared towards dependency checking for D
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

module ddep.TokenReader;

import ddep.CommentFilter;

import tango.io.protocol.Reader;
import tango.io.protocol.Writer;
import tango.io.Buffer;
import tango.io.GrowBuffer;
import tango.io.FileConduit;

import tango.text.Text;

class TokenReader {

    private Buffer buf;
    private Writer write;
    private CommentFilter read;
    private char c; // current character
    private bool charread;

    alias next opCall;

    this(char[] filename)
    {
        this.read = new CommentFilter(new FileConduit(filename));
        buf = new GrowBuffer(32, 32);
        write = new Writer(buf);
        charread = false;
    }
	
    TokenReader next(out char[] token)
    {
        if (!charread) {
            read(c);
        }
        charread = false;

        while (Text.isSpace(c))
            read(c);

        switch (c) {
       	case ';': token = ";"; return this;
		case ',': token = ","; return this;
		case ':': token = ":"; return this;
        case '{': token = "{"; return this;
        case '}': token = "}"; return this;
        case '(': token = "("; return this;
        case ')': token = ")"; return this;
        case '=': token = "="; return this;
        default: break;
        }

        buf.clear();

        void str(char sq)
        {
    		write(c);
            do {
                read(c); write(c);
                if (c == '\\') {
                    read(c); write(c);
                    continue;
                }
            } while (c != sq)
        }

        bool endToken(char c)
        {
            switch (c) {
                case ';', ',', '}', '{', '(', ')', ':', '=':
                    return true;
                default:
                    return false;
            }
            return false;
        }

        switch (c) {
        case 'r':
            char pc;
            read.peek(pc);
            if (pc == '"') {
                write(c); read(c);
            }
            else goto default;
        case '"':
        case '\'':
        case '`':
            str(c); 
            token = cast(char[])buf.slice();
            return this;
        default:
			write(c);
            while (true) {
                read(c);
                if (Text.isSpace(c) || endToken(c)) {
                    charread = true;
                    break;
                }
                write(c);
            }
            token = cast(char[])buf.slice();
            return this;
        }
        
    }

}
