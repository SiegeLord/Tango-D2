/*
 File: Function.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 22Oct95  dl@cs.oswego.edu   Created.

*/


module tango.store.model.Function;

/**
 *
 * Function is a common interface for classes with an arbitrary 
 * function of one Object argument that returns another Object,
 * without throwing any kind of user exception.
 * @author Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
 *
**/


public interface FunctionT(T)
{

        /**
         * Execute some function of the argument.
        **/

        public T func (T t);
}


alias FunctionT!(Object) Function;