/*******************************************************************************

        @file Iterator.d
        
        Copyright (c) 2004 Kris Bell
        
        This software is provided 'as-is', without any express or implied
        warranty. In no event will the authors be held liable for damages
        of any kind arising from the use of this software.
        
        Permission is hereby granted to anyone to use this software for any 
        purpose, including commercial applications, and to alter it and/or 
        redistribute it freely, subject to the following restrictions:
        
        1. The origin of this software must not be misrepresented; you must 
           not claim that you wrote the original software. If you use this 
           software in a product, an acknowledgment within documentation of 
           said product would be appreciated but is not required.

        2. Altered source versions must be plainly marked as such, and must 
           not be misrepresented as being the original software.

        3. This notice may not be removed or altered from any distribution
           of the source.

        4. Derivative works are permitted, but they must carry this notice
           in full and credit the original source.


                        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


        @version        Initial version, December 2005      

        @author         Kris


*******************************************************************************/

module tango.text.Iterator;

public  import tango.io.Buffer;

private import tango.text.Text;

/*******************************************************************************

        The base class for a set of pattern tokenizers. 

        There are two types of tokenizers supported ~ exclusive and 
        inclusive. The former are the more common kind, where a token
        is delimited by elements that are considered foreign. Examples
        include space, comma, and end-of-line delineation. Inclusive
        tokens are just the opposite: they look for patterns in the
        text that should be part of the token itself ~ everything else
        is considered foreign. Currently the only inclusive token type
        is exposed by RegexToken; everything else is of the exclusive
        variety.

        The content provided to Tokenizers is supposed to be entirely
        read-only. All current tokenizers abide by this rule, but it's
        possible a user could mutate the content through a token slice.
        To enforce the desired read-only aspect, the code would have to 
        introduce redundant copying or the compiler would have to support 
        read-only arrays.

        See LineToken, CharToken, RegexToken, QuotedToken, and SetToken.

*******************************************************************************/

class IteratorT(T)
{
        protected T[]           slice;
        protected IBuffer       buffer;

        /***********************************************************************
        
                The pattern scanner, implemented via subclasses

        ***********************************************************************/

        abstract protected uint scan (void[] data);

        /***********************************************************************
        
                Uninitialized instance ~ use set() to configure input

        ***********************************************************************/

        this () {}

        /***********************************************************************
        
                Instantiate with a buffer

        ***********************************************************************/

        this (IBuffer buffer)
        {
                set (buffer);
        }

        /***********************************************************************
        
                Instantiate with a conduit

        ***********************************************************************/

        this (IConduit conduit)
        {
                set (conduit);
        }

        /***********************************************************************
        
                Instantiate with a string

        ***********************************************************************/

        this (T[] string)
        {
               set (string);
        }

        /***********************************************************************
        
                Set the provided string as the scanning source

        ***********************************************************************/

        final void set (T[] string)
        {
                if (buffer is null)
                    buffer = new Buffer (string, string.length);
                else
                   buffer.setValidContent(string).setConduit(null);
        }

        /***********************************************************************
        
                Set the provided conduit as the scanning source

        ***********************************************************************/

        final void set (IConduit conduit)
        {
                if (buffer is null)
                    buffer = new Buffer (conduit);
                else
                   buffer.clear.setConduit (conduit);
        }

        /***********************************************************************
        
                Set the current buffer to scan

        ***********************************************************************/

        final void set (IBuffer buffer)
        {
                this.buffer = buffer;
        }

        /***********************************************************************
        
                Return the current token as a slice of the content
        
        ***********************************************************************/

        final T[] get ()
        {
                return slice;
        }

        /***********************************************************************
 
                Trim spaces from the left and right of the current token.
                Note that this is done in-place on the current slice. The
                content itself is not affected
        
        ***********************************************************************/

        IteratorT trim ()
        {
                slice = TextT!(T).trim (slice);
                return this;
        }

        /***********************************************************************
                
                Return the associated buffer. This can be provided to
                a Reader or another Iterator ~ each will stay in synch
                with one another

        ***********************************************************************/

        final IBuffer getBuffer ()
        {
                return buffer;
        }

        /**********************************************************************

                Iterate over the set of tokens. This should really
                provide read-only access to the tokens, but D does
                not support that at this time

        **********************************************************************/

        int opApply (int delegate(inout T[]) dg)
        {
                int result = 0;

                while (next)
                      {
                      T[] t = get ();
                      result = dg (t);
                      if (result)
                          break;
                      }
                return result;
        }

        /**********************************************************************

                Iterate over the set of tokens. This should really
                provide read-only access to the tokens, but D does
                not support that at this time

        **********************************************************************/

        int opApply (int delegate(inout uint, inout T[]) dg)
        {
                int result = 0;
		uint count = 0;

                while (next)
                      {
		      count++;
                      T[] t = get ();
                      result = dg (count, t);
                      if (result)
                          break;
                      }
                return result;
        }

        /**********************************************************************

                Visit each token by passing them to the provided delegate

        **********************************************************************/

        bool visit (bool delegate(T[]) dg)
        {
                while (next)
                       if (! dg (get))
                             return false;
                return true;
        }

        /***********************************************************************

                Locate the next token. 

                Returns true if a token is found; false otherwise
                
        ***********************************************************************/

        final bool next ()
        {       
                return buffer.next (&scan) || slice.length > 0;
        }

        /***********************************************************************
        
                Set the content of the current slice

        ***********************************************************************/

        protected final uint set (T* content, uint start, uint end)
        {       
                slice = content [start .. end];
                return end;
        }

        /***********************************************************************
        
                Convert void[] from buffer into an appropriate array

        ***********************************************************************/

        protected final T[] convert (void[] data)
        {       
                return cast(T[]) data [0 .. data.length & ~(T.sizeof-1)];
        }

        /***********************************************************************
        
                Called when a scanner fails to find a matching pattern. 
                This may cause more content to be loaded, and a rescan
                initiated

        ***********************************************************************/

        protected final uint notFound (T[] content)
        {       
                slice = content;
                return IConduit.Eof;
        }

        /***********************************************************************
        
                Invoked when a scanner matches a pattern. The provided
                value should be the index of the last element of the 
                matching pattern, which is converted back to a void[]
                index.

        ***********************************************************************/

        protected final uint found (uint i)
        {       
                return (i + 1) * T.sizeof;
        }

        /***********************************************************************
        
                See if set of characters holds a particular instance

        ***********************************************************************/

        protected bool has (T[] set, T match)
        {
                foreach (T c; set)
                         if (match is c)
                             return true;
                return false;
        }
}

alias IteratorT!(char) Iterator;


