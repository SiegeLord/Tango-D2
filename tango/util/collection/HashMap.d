/*******************************************************************************

        File: HashMap.d

        Originally written by Doug Lea and released into the public domain. 
        Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
        Inc, Loral, and everyone contributing, testing, and using this code.

        History:
        Date     Who                What
        24Sep95  dl@cs.oswego.edu   Create from collection.d  working file
        13Oct95  dl                 Changed protection statuses
        21Oct95  dl                 fixed error in removeAt
        9Apr97   dl                 made Serializable
        14Dec06  kb                 Converted, templated & reshaped for Tango
        
********************************************************************************/

module tango.util.collection.HashMap;

private import  tango.util.collection.Exception;

private import  tango.io.protocol.model.IReader,
                tango.io.protocol.model.IWriter;

private import  tango.util.collection.model.HashParams,
                tango.util.collection.model.GuardIterator;

private import  tango.util.collection.impl.LLCell,
                tango.util.collection.impl.LLPair,
                tango.util.collection.impl.MapCollection,
                tango.util.collection.impl.AbstractIterator;

/*******************************************************************************

         Hash table implementation of Map
		
         author: Doug Lea
		@version 0.94

         <P> For an introduction to this package see <A HREF="index.html"
         > Overview </A>.

********************************************************************************/


public class HashMap(K, V) : MapCollection!(K, V), HashParams
{
        alias LLCell!(V)                LLCellT;
        alias LLPair!(K, V)             LLPairT;

        // instance variables

        /***********************************************************************

		The table. Each entry is a list. Null if no table allocated

        ************************************************************************/
  
        private LLPairT table[];

        /***********************************************************************

		The threshold load factor

        ************************************************************************/

        private float loadFactor;


        // constructors

        /***********************************************************************

		Make a new empty map to use given element screener.
        
	************************************************************************/

        public this (Predicate screener = null)
        {
                this(screener, defaultLoadFactor);
        }

        /***********************************************************************

		Special version of constructor needed by clone()
        
	************************************************************************/

        protected this (Predicate s, float f)
        {
                super(s);
                table = null;
                loadFactor = f;
        }

        /***********************************************************************

		Make an independent copy of the table. Elements themselves
                are not cloned.
        
	************************************************************************/

        public final HashMap!(K, V) duplicate()
        {
                auto c = new HashMap (screener, loadFactor);

                if (count !is 0)
                   {
                   int cap = 2 * cast(int)((count / loadFactor)) + 1;
                   if (cap < defaultInitialBuckets)
                       cap = defaultInitialBuckets;

                   c.buckets(cap);

                   for (int i = 0; i < table.length; ++i)
                        for (LLPairT p = table[i]; p !is null; p = cast(LLPairT)(p.next()))
                             c.add (p.key(), p.element());
                   }
                return c;
        }


        // HashParams methods

        /***********************************************************************

		Implements util.collection.HashParams.buckets.
		Time complexity: O(1).
                
		@see util.collection.HashParams#buckets.
        
	************************************************************************/

        public final int buckets()
        {
                return (table is null) ? 0 : table.length;
        }

        /***********************************************************************

		Implements util.collection.HashParams.buckets.
		Time complexity: O(n).
                
		@see util.collection.HashParams#buckets.
        
	************************************************************************/

        public final void buckets(int newCap)
        {
                if (newCap is buckets())
                    return ;
                else
                   if (newCap >= 1)
                       resize(newCap);
                   else
                      throw new IllegalArgumentException("Invalid Hash table size");
        }

        /***********************************************************************

		Implements util.collection.HashParams.thresholdLoadfactor
		Time complexity: O(1).
                
		@see util.collection.HashParams#thresholdLoadfactor
        
	************************************************************************/

        public final float thresholdLoadFactor()
        {
                return loadFactor;
        }

        /***********************************************************************

		Implements util.collection.HashParams.thresholdLoadfactor
		Time complexity: O(n).
                
		@see util.collection.HashParams#thresholdLoadfactor
        
	************************************************************************/

        public final void thresholdLoadFactor(float desired)
        {
                if (desired > 0.0)
                   {
                   loadFactor = desired;
                   checkLoadFactor();
                   }
                else
                   throw new IllegalArgumentException("Invalid Hash table load factor");
        }



        // View methods

        /***********************************************************************

		Implements util.collection.View.contains.
		Time complexity: O(1) average; O(n) worst.
                
		@see util.collection.View#contains
        
	************************************************************************/
        
        public final bool contains(V element)
        {
                if (!isValidArg(element) || count is 0)
                    return false;

                for (int i = 0; i < table.length; ++i)
                    {
                    LLPairT hd = table[i];
                    if (hd !is null && hd.find(element) !is null)
                        return true;
                    }
                return false;
        }

        /***********************************************************************

		Implements util.collection.View.instances.
		Time complexity: O(n).
                
		@see util.collection.View#instances
        
	************************************************************************/
        
        public final int instances(V element)
        {
                if (!isValidArg(element) || count is 0)
                    return 0;
    
                int c = 0;
                for (int i = 0; i < table.length; ++i)
                    {
                    LLPairT hd = table[i];
                    if (hd !is null)
                        c += hd.count(element);
                    }
                return c;
        }

        /***********************************************************************

		Implements util.collection.View.elements.
		Time complexity: O(1).
                
		@see util.collection.View#elements
        
	************************************************************************/
        
        public final GuardIterator!(V) elements()
        {
                return keys();
        }


        // Map methods

        /***********************************************************************

		Implements util.collection.Map.containsKey.
		Time complexity: O(1) average; O(n) worst.
                
		@see util.collection.Map#containsKey
        
	************************************************************************/
        
        public final bool containsKey(K key)
        {
                if (!isValidKey(key) || count is 0)
                    return false;

                LLPairT p = table[hashOf(key)];
                if (p !is null)
                    return p.findKey(key) !is null;
                else
                   return false;
        }

        /***********************************************************************

		Implements util.collection.Map.containsPair
		Time complexity: O(1) average; O(n) worst.
                
		@see util.collection.Map#containsPair
        
	************************************************************************/
        
        public final bool containsPair(K key, V element)
        {
                if (!isValidKey(key) || !isValidArg(element) || count is 0)
                    return false;

                LLPairT p = table[hashOf(key)];
                if (p !is null)
                    return p.find(key, element) !is null;
                else
                   return false;
        }

        /***********************************************************************

		Implements util.collection.Map.keys.
		Time complexity: O(1).
                
		@see util.collection.Map#keys
        
	************************************************************************/
        
        public final PairIterator!(K, V) keys()
        {
                return new MapIterator!(K, V)(this);
        }

        /***********************************************************************

		Implements util.collection.Map.get.
		Time complexity: O(1) average; O(n) worst.
                
		@see util.collection.Map#at
        
	************************************************************************/
        
        public final V get(K key)
        {
                checkKey(key);
                if (count !is 0)
                   {
                   LLPairT p = table[hashOf(key)];
                   if (p !is null)
                      {
                      LLPairT c = p.findKey(key);
                      if (c !is null)
                          return c.element();
                      }
                   }
                throw new NoSuchElementException("no matching key");
        }


        /***********************************************************************

		Return the element associated with Key key. 
		@param key a key
		@return whether the key is contained or not
        
	************************************************************************/

        public bool get(K key, inout V element)
        {
                checkKey(key);
                if (count !is 0)
                   {
                   LLPairT p = table[hashOf(key)];
                   if (p !is null)
                      {
                      LLPairT c = p.findKey(key);
                      if (c !is null)
                         {
                         element = c.element();
                         return true;
                         }
                      }
                   }
                return false;
        }



        /***********************************************************************

		Implements util.collection.Map.keyOf.
		Time complexity: O(n).
                
		@see util.collection.Map#akyOf
        
	************************************************************************/
        
        public final K keyOf(V element)
        {
                if (!isValidArg(element) || count is 0)
                    return K.init;

                // for (int i = 0; i < table._length; ++i) {
                for (int i = 0; i < table.length; ++i)
                    { 
                    LLPairT hd = table[i];
                    if (hd !is null)
                       {
                       LLPairT p = (cast(LLPairT)(hd.find(element)));
                       if (p !is null)
                           return p.key();
                       }
                    }
                return K.init;
        }


        // Collection methods

        /***********************************************************************

		Implements util.collection.Collection.clear.
		Time complexity: O(1).
                
		@see util.collection.Collection#clear
        
	************************************************************************/
        
        public final void clear()
        {
                setCount(0);
                table = null;
        }

        /***********************************************************************

		Implements util.collection.Collection.removeAll.
		Time complexity: O(n).
                
		@see util.collection.Collection#removeAll
        
	************************************************************************/
        
        public final void removeAll (V element)
        {
                remove_(element, true);
        }


        /***********************************************************************

		Implements util.collection.Collection.removeOneOf.
		Time complexity: O(n).
                
		@see util.collection.Collection#removeOneOf
        
	************************************************************************/
        
        public final void remove (V element)
        {
                remove_(element, false);
        }


        /***********************************************************************

		Implements util.collection.Collection.replaceOneOf.
		Time complexity: O(n).
                
		@see util.collection.Collection#replaceOneOf
        
	************************************************************************/

        public final void replace (V oldElement, V newElement)
        {
                replace_(oldElement, newElement, false);
        }

        /***********************************************************************

		Implements util.collection.Collection.replaceOneOf.
		Time complexity: O(n).
                
		@see util.collection.Collection#replaceOneOf
        
	************************************************************************/

        public final void replaceAll (V oldElement, V newElement)
        {
                replace_(oldElement, newElement, true);
        }

        /***********************************************************************

		Implements util.collection.Collection.take.
		Time complexity: O(number of buckets).
                
		@see util.collection.Collection#take
        
	************************************************************************/
        
        public final V take()
        {
                if (count !is 0)
                   {
                   for (int i = 0; i < table.length; ++i)
                       {
                       if (table[i] !is null)
                          {
                          decCount();
                          auto v = table[i].element();
                          table[i] = cast(LLPairT)(table[i].next());
                          return v;
                          }
                       }
                   }
                checkIndex(0);
                return V.init; // not reached
        }

        // Map methods

        /***********************************************************************

		Implements util.collection.Map.add.
		Time complexity: O(1) average; O(n) worst.
                
		@see util.collection.Map#add
        
	************************************************************************/
        
        public final void add (K key, V element)
        {
                checkKey(key);
                checkElement(element);

                if (table is null)
                    resize (defaultInitialBuckets);

                int h = hashOf(key);
                LLPairT hd = table[h];
                if (hd is null)
                   {
                   table[h] = new LLPairT(key, element, hd);
                   incCount();
                   return;
                   }
                else
                   {
                   LLPairT p = hd.findKey(key);
                   if (p !is null)
                      {
                      if (p.element() != (element))
                         {
                         p.element(element);
                         incVersion();
                         }
                      }
                   else
                      {
                      table[h] = new LLPairT(key, element, hd);
                      incCount();
                      checkLoadFactor(); // we only check load factor on add to nonempty bin
                      }
                   }
        }


        /***********************************************************************

		Implements util.collection.Map.remove.
		Time complexity: O(1) average; O(n) worst.
                
		@see util.collection.Map#remove
        
	************************************************************************/
        
        public final void removeKey (K key)
        {
                if (!isValidKey(key) || count is 0)
                    return;

                int h = hashOf(key);
                LLPairT hd = table[h];
                LLPairT p = hd;
                LLPairT trail = p;

                while (p !is null)
                      {
                      LLPairT n = cast(LLPairT)(p.next());
                      if (p.key() == (key))
                         {
                         decCount();
                         if (p is hd)
                             table[h] = n;
                         else
                            trail.unlinkNext();
                         return;
                         }
                      else
                         {
                         trail = p;
                         p = n;
                         }
                      }
        }

        /***********************************************************************

		Implements util.collection.Map.replaceElement.
		Time complexity: O(1) average; O(n) worst.
                
		@see util.collection.Map#replaceElement
        
	************************************************************************/
        
        public final void replacePair (K key, V oldElement, V newElement)
        {
                if (!isValidKey(key) || !isValidArg(oldElement) || count is 0)
                    return;

                LLPairT p = table[hashOf(key)];
                if (p !is null)
                   {
                   LLPairT c = p.find(key, oldElement);
                   if (c !is null)
                      {
                      checkElement(newElement);
                      c.element(newElement);
                      incVersion();
                      }
                   }
        }

        // Helper methods

        /***********************************************************************

		Check to see if we are past load factor threshold. If so,
                resize so that we are at half of the desired threshold.
		Also while at it, check to see if we are empty so can just
		unlink table.
        
	************************************************************************/
        
        protected final void checkLoadFactor()
        {
                if (table is null)
                   {
                   if (count !is 0)
                       resize(defaultInitialBuckets);
                   }
                else
                   {
                   float fc = cast(float) (count);
                   float ft = table.length;

                   if (fc / ft > loadFactor)
                      {
                      int newCap = 2 * cast(int)(fc / loadFactor) + 1;
                      resize(newCap);
                      }
                   }
        }

        /***********************************************************************

		Mask off and remainder the hashCode for element
		so it can be used as table index
        
	************************************************************************/

        protected final int hashOf(K key)
        {
                return (typeid(K).getHash(&key) & 0x7FFFFFFF) % table.length;
        }


        /***********************************************************************

        ************************************************************************/

        protected final void resize(int newCap)
        {
                LLPairT newtab[] = new LLPairT[newCap];

                if (table !is null)
                   {
                   for (int i = 0; i < table.length; ++i)
                       {
                       LLPairT p = table[i];
                       while (p !is null)
                             {
                             LLPairT n = cast(LLPairT)(p.next());
                             int h = (p.keyHash() & 0x7FFFFFFF) % newCap;
                             p.next(newtab[h]);
                             newtab[h] = p;
                             p = n;
                             }
                       }
                   }
                table = newtab;
                incVersion();
        }

        // helpers

        /***********************************************************************

        ************************************************************************/

        private final void remove_(V element, bool allOccurrences)
        {
                if (!isValidArg(element) || count is 0)
                    return;

                for (int h = 0; h < table.length; ++h)
                    {
                    LLCellT hd = table[h];
                    LLCellT p = hd;
                    LLCellT trail = p;
                    while (p !is null)
                          {
                          LLPairT n = cast(LLPairT)(p.next());
                          if (p.element() == (element))
                             {
                             decCount();
                             if (p is table[h])
                                {
                                table[h] = n;
                                trail = n;
                                }
                             else
                                trail.next(n);
                             if (! allOccurrences)
                                   return;
                             else
                                p = n;
                             }
                          else
                             {
                             trail = p;
                             p = n;
                             }
                          }
                    }
        }

        /***********************************************************************

        ************************************************************************/

        private final void replace_(V oldElement, V newElement, bool allOccurrences)
        {
                if (count is 0 || !isValidArg(oldElement) || oldElement == (newElement))
                    return;

                for (int h = 0; h < table.length; ++h)
                    {
                    LLCellT hd = table[h];
                    LLCellT p = hd;
                    LLCellT trail = p;
                    while (p !is null)
                          {
                          LLPairT n = cast(LLPairT)(p.next());
                          if (p.element() == (oldElement))
                             {
                             checkElement(newElement);
                             incVersion();
                             p.element(newElement);
                             if (! allOccurrences)
                                   return ;
                             }
                          trail = p;
                          p = n;
                          }
                    }
        }


        // IReader & IWriter methods

        /***********************************************************************

        ************************************************************************/

        public override void read (IReader input)
        {
                int     len;
                K       key;
                V       element;
                
                input (len) (loadFactor) (count);
                table = (len > 0) ? new LLPairT[len] : null;

                for (len=count; len-- > 0;)
                    {
                    input (key) (element);
                    
                    int h = hashOf (key);
                    table[h] = new LLPairT (key, element, table[h]);
                    }
        }
                        
        /***********************************************************************

        ************************************************************************/

        public override void write (IWriter output)
        {
                output (table.length) (loadFactor) (count);

                if (table.length > 0)
                    foreach (key, value; keys)
                             output (key) (value);
        }
        

        // ImplementationCheckable methods

        /***********************************************************************

		Implements util.collection.ImplementationCheckable.checkImplementation.
                
		@see util.collection.ImplementationCheckable#checkImplementation
        
	************************************************************************/
                        
        public override void checkImplementation()
        {
                super.checkImplementation();

                assert(!(table is null && count !is 0));
                assert((table is null || table.length > 0));
                assert(loadFactor > 0.0f);

                if (table is null)
                    return;

                int c = 0;
                for (int i = 0; i < table.length; ++i)
                    {
                    for (LLPairT p = table[i]; p !is null; p = cast(LLPairT)(p.next()))
                        {
                        ++c;
                        assert(allows(p.element()));
                        assert(allowsKey(p.key()));
                        assert(containsKey(p.key()));
                        assert(contains(p.element()));
                        assert(instances(p.element()) >= 1);
                        assert(containsPair(p.key(), p.element()));
                        assert(hashOf(p.key()) is i);
                        }
                    }
                assert(c is count);


        }


        /***********************************************************************

        ************************************************************************/

        private static class MapIterator(K, V) : AbstractMapIterator!(K, V)
        {
                private int             row;
                private LLPairT         pair;
                private LLPairT[]       table;

                public this (HashMap map)
                {
                        super (map);
                        table = map.table;
                }

                public final V get(inout K key)
                {
                        auto v = get();
                        key = pair.key;
                        return v;
                }

                public final V get()
                {
                        decRemaining();

                        if (pair)
                            pair = cast(LLPairT) pair.next();

                        while (pair is null)
                               pair = table [row++];

                        return pair.element;
                }
        }
}


debug(Test)
{
void main()
{
        auto map = new HashMap!(char[], double);
        map.add ("foo", 3.14);
        
        foreach (key, value; map.keys) {typeof(key) x; x = key;}

        foreach (value; map.keys) {}

        foreach (value; map.elements) {}

        auto keys = map.keys();
        while (keys.more)
               auto v = keys.get();

        map.checkImplementation();
}
}
