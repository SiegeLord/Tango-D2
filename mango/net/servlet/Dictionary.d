/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: April 2004      
        
        author:         Kris

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
                auto ptr = name in dictionary;
                if (ptr)
                    return *ptr;
                return null;
        }

        /**********************************************************************

                Perform some post population optimization.

        **********************************************************************/

        void optimize ()
        {
                dictionary.rehash;

                foreach (key, value; dictionary)
                        {}
        }

        /**********************************************************************

                Iterate over the entire dictionary

        **********************************************************************/

        int opApply (int delegate(inout char[] key, inout char[] value) dg)
        {
                int result;
                
                foreach (key, value; dictionary)
                         if ((result = dg (key, value)) != 0)
                              break;
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
                //dictionary[name] = null;
                dictionary.remove(name);
        }
/+
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
+/
        /**********************************************************************

                loader for use with Properties.load ()

        **********************************************************************/

        void loader (char[] name, char[] value)
        {
                put (name, value);
        }
}


