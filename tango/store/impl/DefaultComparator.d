/*
 File: DefaultComparator.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from store.d  working file

*/


module tango.store.impl.DefaultComparator;

private import tango.store.model.Comparator;
private import tango.store.model.Keyed;


/**
 *
 *
 * DefaultComparator provides a general-purpose but slow compare
 * operation. 
 * 
        author: Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
**/

public class DefaultComparatorT(T) : ComparatorT!(T)
{

        /**
         * Try various downcasts to find a basis for
         * comparing two elements. If all else fails, just compare
         * hashCodes(). This can be effective when you are
         * using an ordered implementation data structure like trees,
         * but don't really care about ordering.
         *
         * @param fst first argument
         * @param snd second argument
         * @return a negative number if fst is less than snd; a
         * positive number if fst is greater than snd; else 0
        **/

        public final int compare(T fst, T snd)
        {
                T a = fst;
                T b = snd;

                if (a is b)
                    return 0;
                else
                   if (a == b)
                       return 0;
                   else
                      return typeid(T).getHash(&a) - typeid(T).getHash(&b);
/+

                if (cast(Keyed) fst)
                    a = (cast(Keyed)(fst)).key();

                if (cast(Keyed) snd)
                    b = (cast(Keyed)(snd)).key();

                if (a is b)
                    return 0;

                    else if ((cast(String) a) && (cast(String) b)) {
                      return (cast(String)cast(a)).compareTo(cast(String)cast(b));
                    }
                    else if ((cast(Number) a) && (cast(Number) b)) {
                      double diff = (cast(Number)cast(a)).doubleValue() - 
                        (cast(Number)cast(b)).doubleValue();
                      if (diff < 0.0) return -1; 
                      else if (diff > 0.0) return 1; 
                      else return 0;
                    }
+/
        }
}

alias DefaultComparatorT!(Object) DefaultComparator;