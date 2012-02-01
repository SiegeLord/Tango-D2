/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: April 2004      
        
        author:         Kris, John Reimer

*******************************************************************************/

module tango.net.http.HttpStack;

private import  tango.core.Exception;

/******************************************************************************

        Unix doesn't appear to have a memicmp() ... JJR notes that the
        strncasecmp() is available instead.

******************************************************************************/

version (Win32)
        {
        extern (C) int memicmp (const(char) *, const(char) *, size_t);
        }

version (Posix) 
        {
        extern (C) int strncasecmp (const(char) *, const(char)*, size_t);
        }

extern (C) void* memmove (void* dst, const(void)* src, int n);


/******************************************************************************

        Internal representation of a token

******************************************************************************/

class Token
{
        private const(char)[] value;

        Token set (const(char)[] value)
        {
                this.value = value;
                return this;
        }

        override string toString ()
        {
                return value.idup;
        }
}

/******************************************************************************

        A stack of Tokens, used for capturing http headers. The tokens
        themselves are typically mapped onto the content of a Buffer, 
        or some other external content, so there's minimal allocation 
        involved (typically zero).

******************************************************************************/

class HttpStack
{
        private int     depth;
        private Token[] tokens;

        private static const int MaxHttpStackSize = 256;

        /**********************************************************************

                Construct a HttpStack with the specified initial size. 
                The stack will later be resized as necessary.

        **********************************************************************/

        this (int size = 10)
        {
                tokens = new Token[0];
                resize (tokens, size);
        }

        /**********************************************************************

                Clone this stack of tokens

        **********************************************************************/

        HttpStack clone ()
        {
                // setup a new HttpStack of the same depth
                HttpStack clone = new HttpStack(depth);
                
                clone.depth = depth;

                // duplicate the content of each original token
                for (int i=0; i < depth; ++i)
                     clone.tokens[i].set (tokens[i].toString());

                return clone;
        }

        /**********************************************************************

                Iterate over all tokens in stack

        **********************************************************************/

        int opApply (scope int delegate(ref Token) dg)
        {
                int result = 0;

                for (int i=0; i < depth; ++i)
                     if ((result = dg (tokens[i])) != 0)
                          break;
                return result;
        }

        /**********************************************************************

                Pop the stack all the way back to zero

        **********************************************************************/

        final void reset ()
        {
                depth = 0;
        }

        /**********************************************************************

                Scan the tokens looking for the first one with a matching
                name. Returns the matching Token, or null if there is no
                such match.

        **********************************************************************/

        final Token findToken (const(char)[] match)
        {
                Token tok;

                for (int i=0; i < depth; ++i)
                    {
                    tok = tokens[i];
                    if (isMatch (tok, match))
                        return tok;
                    }
                return null;
        }

        /**********************************************************************

                Scan the tokens looking for the first one with a matching
                name, and remove it. Returns true if a match was found, or
                false if not.

        **********************************************************************/

        final bool removeToken (const(char)[] match)
        {
                for (int i=0; i < depth; ++i)
                     if (isMatch (tokens[i], match))
                        {
                        tokens[i].value = null;
                        return true;
                        }
                return false;
        }

        /**********************************************************************

                Return the current stack depth

        **********************************************************************/

        @property final int size ()
        {       
                return depth;
        }

        /**********************************************************************

                Push a new token onto the stack, and set it content to 
                that provided. Returns the new Token.

        **********************************************************************/

        final Token push (const(char)[] content)
        {
                return push().set (content);  
        }

        /**********************************************************************

                Push a new token onto the stack, and set it content to 
                be that of the specified token. Returns the new Token.

        **********************************************************************/

        final Token push (ref Token token)
        {
                return push (token.toString());  
        }

        /**********************************************************************

                Push a new token onto the stack, and return it.

        **********************************************************************/

        final Token push ()
        {
                if (depth == tokens.length)
                    resize (tokens, depth * 2);
                return tokens[depth++];
        }

        /**********************************************************************

                Pop the stack by one.

        **********************************************************************/

        final void pop ()
        {
                if (depth)
                    --depth;
                else
                   throw new IOException ("illegal attempt to pop Token stack");
        }

        /**********************************************************************

                See if the given token matches the specified text. The 
                two must match the minimal extent exactly.

        **********************************************************************/

        final static bool isMatch (ref Token token, const(char)[] match)
        {
                const(char)[] target = token.toString();

                size_t length = target.length;
                if (length > match.length)
                    length = match.length;

                if (length is 0)
                    return false;

                version (Win32)
                         return memicmp (target.ptr, match.ptr, length) is 0;
                version (Posix)
                         return strncasecmp (target.ptr, match.ptr, length) is 0;
        }
        
        /**********************************************************************

                Resize this stack by extending the array.

        **********************************************************************/

        final static void resize (ref Token[] tokens, int size)
        {
                size_t i = tokens.length;

                // this should *never* realistically happen 
                if (size > MaxHttpStackSize)
                    throw new IOException ("Token stack exceeds maximum depth");

                for (tokens.length=size; i < tokens.length; ++i)
                     tokens[i] = new Token();
        }
}
