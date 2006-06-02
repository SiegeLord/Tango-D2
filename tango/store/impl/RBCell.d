/*
 File: RBCell.d

 Originally written by Doug Lea and released into the public domain. 
 Thanks for the assistance and support of Sun Microsystems Labs, Agorics 
 Inc, Loral, and everyone contributing, testing, and using this code.

 History:
 Date     Who                What
 24Sep95  dl@cs.oswego.edu   Create from store.d  working file

*/


module tango.store.impl.RBCell;

private import tango.store.impl.Cell;
private import tango.store.model.Iterator;
private import tango.store.model.Comparator;
private import tango.store.model.ImplementationCheckable;

/**
 * RBCellT implements basic capabilities of Red-Black trees,
 * an efficient kind of balanced binary tree. The particular
 * algorithms used are adaptations of those in Corman,
 * Lieserson, and Rivest's <EM>Introduction to Algorithms</EM>.
 * This class was inspired by (and code cross-checked with) a 
 * similar class by Chuck McManis. The implementations of
 * rebalancings during insertion and deletion are
 * a little trickier than those versions since they
 * don't swap CellT contents or use a special dummy nilnodes. 
 * <P>
 * It is a pure implementation class. For harnesses, see:
 * @see RBTree
 * @author Doug Lea
 * @version 0.93
 *
 * <P> For an introduction to this package see <A HREF="index.html"> Overview </A>.
 *
**/




public class RBCellT(T) : CellT!(T), ImplementationCheckable
{
        alias ComparatorT!(T) Comparator;


        static bool RED = false;
        static bool BLACK = true;

        /**
         * The node color (RED, BLACK)
        **/

        package bool color_;

        /**
         * Pointer to left child
        **/

        package RBCellT left_;

        /**
         * Pointer to right child
        **/

        package RBCellT right_;

        /**
         * Pointer to parent (null if root)
        **/

        private RBCellT parent_;

        /**
         * Make a new CellT with given element, null links, and BLACK color.
         * Normally only called to establish a new root.
        **/

        public this (T element)
        {
                super(element);
                left_ = null;
                right_ = null;
                parent_ = null;
                color_ = BLACK;
        }

        /**
         * Return a new RBCellT with same element and color as self,
         * but with null links. (Since it is never OK to have
         * multiple identical links in a RB tree.)
        **/ 
        //  protected T clone() {
        protected RBCellT duplicate()
        {
                RBCellT t = new RBCellT(element());
                t.color_ = color_;
                return t;
        }


        /**
         * Return left child (or null)
        **/

        public final RBCellT left()
        {
                return left_;
        }

        /**
         * Return right child (or null)
        **/

        public final RBCellT right()
        {
                return right_;
        }

        /**
         * Return parent (or null)
        **/
        public final RBCellT parent()
        {
                return parent_;
        }


        /**
         * @see store.ImplementationCheckable.checkImplementation.
        **/
        public override void checkImplementation()
        {

                // It's too hard to check the property that every simple
                // path from node to leaf has same number of black nodes.
                // So restrict to the following

                assert(parent_ is null ||
                       this is parent_.left_ ||
                       this is parent_.right_);

                assert(left_ is null ||
                       this is left_.parent_);

                assert(right_ is null ||
                       this is right_.parent_);

                assert(color_ is BLACK ||
                       (colorOf(left_) is BLACK) && (colorOf(right_) is BLACK));

                if (left_ !is null)
                        left_.checkImplementation();
                if (right_ !is null)
                        right_.checkImplementation();
        }

        /+
        /**
         * Implements store.ImplementationCheckable.assert.
         * @see store.ImplementationCheckable#assert
        **/
        public final void assert(bool pred)
        {
                ImplementationError.assert(this, pred);
        }
        +/

        /**
         * Return the minimum element of the current (sub)tree
        **/

        public final RBCellT leftmost()
        {
                RBCellT p = this;
                for ( ; p.left_ !is null; p = p.left_)
                    {}
                return p;
        }

        /**
         * Return the maximum element of the current (sub)tree
        **/
        public final RBCellT rightmost()
        {
                RBCellT p = this;
                for ( ; p.right_ !is null; p = p.right_)
                    {}
                return p;
        }

        /**
         * Return the root (parentless node) of the tree
        **/
        public final RBCellT root()
        {
                RBCellT p = this;
                for ( ; p.parent_ !is null; p = p.parent_)
                    {}
                return p;
        }

        /**
         * Return true if node is a root (i.e., has a null parent)
        **/

        public final bool isRoot()
        {
                return parent_ is null;
        }


        /**
         * Return the inorder successor, or null if no such
        **/

        public final RBCellT successor()
        {
                if (right_ !is null)
                        return right_.leftmost();
                else
                {
                        RBCellT p = parent_;
                        RBCellT ch = this;
                        while (p !is null && ch is p.right_)
                        {
                                ch = p;
                                p = p.parent_;
                        }
                        return p;
                }
        }

        /**
         * Return the inorder predecessor, or null if no such
        **/

        public final RBCellT predecessor()
        {
                if (left_ !is null)
                        return left_.rightmost();
                else
                {
                        RBCellT p = parent_;
                        RBCellT ch = this;
                        while (p !is null && ch is p.left_)
                        {
                                ch = p;
                                p = p.parent_;
                        }
                        return p;
                }
        }

        /**
         * Return the number of nodes in the subtree
        **/
        public final int size()
        {
                int c = 1;
                if (left_ !is null)
                        c += left_.size();
                if (right_ !is null)
                        c += right_.size();
                return c;
        }


        /**
         * Return node of current subtree containing element as element(), 
         * if it exists, else null. 
         * Uses Comparator cmp to find and to check equality.
        **/

        public RBCellT find(T element, Comparator cmp)
        {
                RBCellT t = this;
                for (;;)
                    {
                    int diff = cmp.compare(element, t.element());
                    if (diff is 0)
                        return t;
                    else
                       if (diff < 0)
                           t = t.left_;
                       else
                          t = t.right_;
                    if (t is null)
                        break;
                    }
                return null;
        }


        /**
         * Return number of nodes of current subtree containing element.
         * Uses Comparator cmp to find and to check equality.
        **/
        public int count(T element, Comparator cmp)
        {
                int c = 0;
                RBCellT t = this;
                while (t !is null)
                {
                        int diff = cmp.compare(element, t.element());
                        if (diff is 0)
                        {
                                ++c;
                                if (t.left_ is null)
                                        t = t.right_;
                                else
                                        if (t.right_ is null)
                                                t = t.left_;
                                        else
                                        {
                                                c += t.right_.count(element, cmp);
                                                t = t.left_;
                                        }
                        }
                        else
                                if (diff < 0)
                                        t = t.left_;
                                else
                                        t = t.right_;
                }
                return c;
        }




        /**
         * Return a new subtree containing each element of current subtree
        **/

        public final RBCellT copyTree()
        {
                RBCellT t = null;
                //      t = cast(RBCellT)(clone());
                t = cast(RBCellT)(duplicate());

                if (left_ !is null)
                {
                        t.left_ = left_.copyTree();
                        t.left_.parent_ = t;
                }
                if (right_ !is null)
                {
                        t.right_ = right_.copyTree();
                        t.right_.parent_ = t;
                }
                return t;
        }


        /**
         * There's no generic element insertion. Instead find the
         * place you want to add a node and then invoke insertLeft
         * or insertRight.
         * <P>
         * Insert CellT as the left child of current node, and then
         * rebalance the tree it is in.
         * @param CellT the CellT to add
         * @param root, the root of the current tree
         * @return the new root of the current tree. (Rebalancing
         * can change the root!)
        **/


        public final RBCellT insertLeft(RBCellT CellT, RBCellT root)
        {
                left_ = CellT;
                CellT.parent_ = this;
                return CellT.fixAfterInsertion(root);
        }

        /**
         * Insert CellT as the right child of current node, and then
         * rebalance the tree it is in.
         * @param CellT the CellT to add
         * @param root, the root of the current tree
         * @return the new root of the current tree. (Rebalancing
         * can change the root!)
        **/

        public final RBCellT insertRight(RBCellT CellT, RBCellT root)
        {
                right_ = CellT;
                CellT.parent_ = this;
                return CellT.fixAfterInsertion(root);
        }


        /**
         * Delete the current node, and then rebalance the tree it is in
         * @param root the root of the current tree
         * @return the new root of the current tree. (Rebalancing
         * can change the root!)
        **/


        public final RBCellT remove (RBCellT root)
        {

                // handle case where we are only node
                if (left_ is null && right_ is null && parent_ is null)
                        return null;

                // if strictly internal, swap places with a successor
                if (left_ !is null && right_ !is null)
                {
                        RBCellT s = successor();
                        // To work nicely with arbitrary subclasses of RBCellT, we don't want to
                        // just copy successor's fields. since we don't know what
                        // they are.  Instead we swap positions _in the tree.
                        root = swapPosition(this, s, root);
                }

                // Start fixup at replacement node (normally a child).
                // But if no children, fake it by using self

                if (left_ is null && right_ is null)
                {

                        if (color_ is BLACK)
                                root = this.fixAfterDeletion(root);

                        // Unlink  (Couldn't before since fixAfterDeletion needs parent ptr)

                        if (parent_ !is null)
                        {
                                if (this is parent_.left_)
                                        parent_.left_ = null;
                                else
                                        if (this is parent_.right_)
                                                parent_.right_ = null;
                                parent_ = null;
                        }

                }
                else
                {
                        RBCellT replacement = left_;
                        if (replacement is null)
                                replacement = right_;

                        // link replacement to parent
                        replacement.parent_ = parent_;

                        if (parent_ is null)
                                root = replacement;
                        else
                                if (this is parent_.left_)
                                        parent_.left_ = replacement;
                                else
                                        parent_.right_ = replacement;

                        left_ = null;
                        right_ = null;
                        parent_ = null;

                        // fix replacement
                        if (color_ is BLACK)
                                root = replacement.fixAfterDeletion(root);

                }

                return root;
        }

        /**
         * Swap the linkages of two nodes in a tree.
         * Return new root, in case it changed.
        **/

        static final RBCellT swapPosition(RBCellT x, RBCellT y, RBCellT root)
        {

                /* Too messy. TODO: find sequence of assigments that are always OK */

                RBCellT px = x.parent_;
                bool xpl = px !is null && x is px.left_;
                RBCellT lx = x.left_;
                RBCellT rx = x.right_;

                RBCellT py = y.parent_;
                bool ypl = py !is null && y is py.left_;
                RBCellT ly = y.left_;
                RBCellT ry = y.right_;

                if (x is py)
                {
                        y.parent_ = px;
                        if (px !is null)
                                if (xpl)
                                        px.left_ = y;
                                else
                                        px.right_ = y;
                        x.parent_ = y;
                        if (ypl)
                        {
                                y.left_ = x;
                                y.right_ = rx;
                                if (rx !is null)
                                        rx.parent_ = y;
                        }
                        else
                        {
                                y.right_ = x;
                                y.left_ = lx;
                                if (lx !is null)
                                        lx.parent_ = y;
                        }
                        x.left_ = ly;
                        if (ly !is null)
                                ly.parent_ = x;
                        x.right_ = ry;
                        if (ry !is null)
                                ry.parent_ = x;
                }
                else
                        if (y is px)
                        {
                                x.parent_ = py;
                                if (py !is null)
                                        if (ypl)
                                                py.left_ = x;
                                        else
                                                py.right_ = x;
                                y.parent_ = x;
                                if (xpl)
                                {
                                        x.left_ = y;
                                        x.right_ = ry;
                                        if (ry !is null)
                                                ry.parent_ = x;
                                }
                                else
                                {
                                        x.right_ = y;
                                        x.left_ = ly;
                                        if (ly !is null)
                                                ly.parent_ = x;
                                }
                                y.left_ = lx;
                                if (lx !is null)
                                        lx.parent_ = y;
                                y.right_ = rx;
                                if (rx !is null)
                                        rx.parent_ = y;
                        }
                        else
                        {
                                x.parent_ = py;
                                if (py !is null)
                                        if (ypl)
                                                py.left_ = x;
                                        else
                                                py.right_ = x;
                                x.left_ = ly;
                                if (ly !is null)
                                        ly.parent_ = x;
                                x.right_ = ry;
                                if (ry !is null)
                                        ry.parent_ = x;

                                y.parent_ = px;
                                if (px !is null)
                                        if (xpl)
                                                px.left_ = y;
                                        else
                                                px.right_ = y;
                                y.left_ = lx;
                                if (lx !is null)
                                        lx.parent_ = y;
                                y.right_ = rx;
                                if (rx !is null)
                                        rx.parent_ = y;
                        }

                bool c = x.color_;
                x.color_ = y.color_;
                y.color_ = c;

                if (root is x)
                        root = y;
                else
                        if (root is y)
                                root = x;
                return root;
        }



        /**
         * Return color of node p, or BLACK if p is null
         * (In the CLR version, they use
         * a special dummy `nil' node for such purposes, but that doesn't
         * work well here, since it could lead to creating one such special
         * node per real node.)
         *
        **/

        static final bool colorOf(RBCellT p)
        {
                return (p is null) ? BLACK : p.color_;
        }

        /**
         * return parent of node p, or null if p is null
        **/
        static final RBCellT parentOf(RBCellT p)
        {
                return (p is null) ? null : p.parent_;
        }

        /**
         * Set the color of node p, or do nothing if p is null
        **/

        static final void setColor(RBCellT p, bool c)
        {
                if (p !is null)
                        p.color_ = c;
        }

        /**
         * return left child of node p, or null if p is null
        **/

        static final RBCellT leftOf(RBCellT p)
        {
                return (p is null) ? null : p.left_;
        }

        /**
         * return right child of node p, or null if p is null
        **/

        static final RBCellT rightOf(RBCellT p)
        {
                return (p is null) ? null : p.right_;
        }


        /** From CLR **/
        protected final RBCellT rotateLeft(RBCellT root)
        {
                RBCellT r = right_;
                right_ = r.left_;
                if (r.left_ !is null)
                        r.left_.parent_ = this;
                r.parent_ = parent_;
                if (parent_ is null)
                        root = r;
                else
                        if (parent_.left_ is this)
                                parent_.left_ = r;
                        else
                                parent_.right_ = r;
                r.left_ = this;
                parent_ = r;
                return root;
        }

        /** From CLR **/
        protected final RBCellT rotateRight(RBCellT root)
        {
                RBCellT l = left_;
                left_ = l.right_;
                if (l.right_ !is null)
                        l.right_.parent_ = this;
                l.parent_ = parent_;
                if (parent_ is null)
                        root = l;
                else
                        if (parent_.right_ is this)
                                parent_.right_ = l;
                        else
                                parent_.left_ = l;
                l.right_ = this;
                parent_ = l;
                return root;
        }


        /** From CLR **/
        protected final RBCellT fixAfterInsertion(RBCellT root)
        {
                color_ = RED;
                RBCellT x = this;

                while (x !is null && x !is root && x.parent_.color_ is RED)
                {
                        if (parentOf(x) is leftOf(parentOf(parentOf(x))))
                        {
                                RBCellT y = rightOf(parentOf(parentOf(x)));
                                if (colorOf(y) is RED)
                                {
                                        setColor(parentOf(x), BLACK);
                                        setColor(y, BLACK);
                                        setColor(parentOf(parentOf(x)), RED);
                                        x = parentOf(parentOf(x));
                                }
                                else
                                {
                                        if (x is rightOf(parentOf(x)))
                                        {
                                                x = parentOf(x);
                                                root = x.rotateLeft(root);
                                        }
                                        setColor(parentOf(x), BLACK);
                                        setColor(parentOf(parentOf(x)), RED);
                                        if (parentOf(parentOf(x)) !is null)
                                                root = parentOf(parentOf(x)).rotateRight(root);
                                }
                        }
                        else
                        {
                                RBCellT y = leftOf(parentOf(parentOf(x)));
                                if (colorOf(y) is RED)
                                {
                                        setColor(parentOf(x), BLACK);
                                        setColor(y, BLACK);
                                        setColor(parentOf(parentOf(x)), RED);
                                        x = parentOf(parentOf(x));
                                }
                                else
                                {
                                        if (x is leftOf(parentOf(x)))
                                        {
                                                x = parentOf(x);
                                                root = x.rotateRight(root);
                                        }
                                        setColor(parentOf(x), BLACK);
                                        setColor(parentOf(parentOf(x)), RED);
                                        if (parentOf(parentOf(x)) !is null)
                                                root = parentOf(parentOf(x)).rotateLeft(root);
                                }
                        }
                }
                root.color_ = BLACK;
                return root;
        }



        /** From CLR **/
        protected final RBCellT fixAfterDeletion(RBCellT root)
        {
                RBCellT x = this;
                while (x !is root && colorOf(x) is BLACK)
                {
                        if (x is leftOf(parentOf(x)))
                        {
                                RBCellT sib = rightOf(parentOf(x));
                                if (colorOf(sib) is RED)
                                {
                                        setColor(sib, BLACK);
                                        setColor(parentOf(x), RED);
                                        root = parentOf(x).rotateLeft(root);
                                        sib = rightOf(parentOf(x));
                                }
                                if (colorOf(leftOf(sib)) is BLACK && colorOf(rightOf(sib)) is BLACK)
                                {
                                        setColor(sib, RED);
                                        x = parentOf(x);
                                }
                                else
                                {
                                        if (colorOf(rightOf(sib)) is BLACK)
                                        {
                                                setColor(leftOf(sib), BLACK);
                                                setColor(sib, RED);
                                                root = sib.rotateRight(root);
                                                sib = rightOf(parentOf(x));
                                        }
                                        setColor(sib, colorOf(parentOf(x)));
                                        setColor(parentOf(x), BLACK);
                                        setColor(rightOf(sib), BLACK);
                                        root = parentOf(x).rotateLeft(root);
                                        x = root;
                                }
                        }
                        else
                        {
                                RBCellT sib = leftOf(parentOf(x));
                                if (colorOf(sib) is RED)
                                {
                                        setColor(sib, BLACK);
                                        setColor(parentOf(x), RED);
                                        root = parentOf(x).rotateRight(root);
                                        sib = leftOf(parentOf(x));
                                }
                                if (colorOf(rightOf(sib)) is BLACK && colorOf(leftOf(sib)) is BLACK)
                                {
                                        setColor(sib, RED);
                                        x = parentOf(x);
                                }
                                else
                                {
                                        if (colorOf(leftOf(sib)) is BLACK)
                                        {
                                                setColor(rightOf(sib), BLACK);
                                                setColor(sib, RED);
                                                root = sib.rotateLeft(root);
                                                sib = leftOf(parentOf(x));
                                        }
                                        setColor(sib, colorOf(parentOf(x)));
                                        setColor(parentOf(x), BLACK);
                                        setColor(leftOf(sib), BLACK);
                                        root = parentOf(x).rotateRight(root);
                                        x = root;
                                }
                        }
                }
                setColor(x, BLACK);
                return root;
        }
}


alias RBCellT!(Object) RBCell;