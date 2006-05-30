/*
 File: Procedure.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 22Oct95  dl@cs.oswego.edu   Created.
 9Apr97   dl                 made Serializable

*/


module tango.store.model.Procedure;

/**
 *
 * Procedure is a common interface for aclasses with an arbitrary void operation
 * of one argument that may throw any kind of exception.
 * @author Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
 *
**/


public interface ProcedureT(T)
{

        /**
         * Execute some procedure on obj.
         * Raise any Exception at all.
        **/
        public void procedure(T t);
}


alias ProcedureT!(Object) Procedure;