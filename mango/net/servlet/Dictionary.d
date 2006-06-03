/*******************************************************************************

        @file Dictionary.d
        
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

        
        @version        Initial version, April 2004      
        @author         Kris


*******************************************************************************/

module mango.net.servlet.Dictionary;

/******************************************************************************
        
        Houses the content of a Dictionary entry

******************************************************************************/

struct DElement
{
        char[]  name,
                value;
}

/******************************************************************************

        Implements a dictionary for mapping names to values. This is
        really just a hashmap with support for certain domain-specific 
        idioms. Note that there is no notion of thread-safety whatsoever;
        you are expected to ensure multiple threads do not contend over
        the content therein. In particular, iterating over the content
        is an unknown quantity in terms of time (from the perspective 
        of this module) so you ought to consider that in a multi-threaded
        environment.

******************************************************************************/

class Dictionary
{
        private char[][char[]] dictionary;

        /**********************************************************************

                Return the dictionary entry with the given name, or null
                if there is no such name.

        **********************************************************************/

        char[] get (char[] name)
        {
                if (name in dictionary)
                    return dictionary[name];
                return null;
        }

        /**********************************************************************

                Perform some post population optimization.

        **********************************************************************/

        void optimize ()
        {
                dictionary.rehash;
        }

        /**********************************************************************

                Iterate over the entire dictionary

        **********************************************************************/

        int opApply (int delegate(inout DElement element) dg)
        {
                DElement        element;
                int             result = 0;
                char[][]        keys = dictionary.keys;

                for (int i=0; i < keys.length; ++i)
                    {
                    element.name = keys[i];
                    element.value = dictionary[element.name];

                    result = dg (element);
                    if (result)
                        break;
                    }
                return result;
        }
}


/******************************************************************************

        Implements a dictionary for mapping names to values. This is
        really just a hashmap with support for certain domain-specific 
        idioms. Note that there is no notion of thread-safety whatsoever;
        you are expected to ensure multiple threads do not contend over
        the content therein. In particular, iterating over the content
        is an unknown quantity in terms of time (from the perspective 
        of this module) so you ought to consider that in a multi-threaded
        environment.

******************************************************************************/

class MutableDictionary : Dictionary
{
        /**********************************************************************

                Place a name/value pair into the dictionary. If the name
                already exists, the prior value is replaced.

        **********************************************************************/

        void put (char[] name, char[] value)
        {
                dictionary[name] = value;
        }

        /**********************************************************************

                Delete the named entry from the dictionary
                
        **********************************************************************/

        void remove (char[] name)
        {
                dictionary[name] = null;
                dictionary.remove(name);
        }

        /**********************************************************************

                Clear all dictionary entries
                                
        **********************************************************************/

        void reset ()
        {
                void*[] tmp;

                // allocate array of void*
                tmp.length = 0;     

                //  Ben Hinkle's wizardry (reprise)
                dictionary = cast(char[][char[]]) tmp; 
        }

        /**********************************************************************

                loader for use with Properties.load ()

        **********************************************************************/

        void loader (char[] name, char[] value)
        {
                put (name, value);
        }
}


