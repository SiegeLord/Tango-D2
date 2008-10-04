/**
  *
  * Copyright:  Copyright (C) 2008 Chris Wright.  All rights reserved.
  * License:    BSD style: $(LICENSE)
  * Version:    Oct 2008: Initial release
  * Author:     Chris Wright, aka dhasenan
  *
  */

module tango.util.container.more.Heap;

private import tango.core.Exception;

/** A heap is a data structure where you can insert items in random order and extract them in sorted order. 
  * Pushing an element into the heap takes O(lg n) and popping the top of the heap takes O(lg n). Heaps are 
  * thus popular for sorting, among other things.
  * 
  * No opApply is provided, since most people would expect this to return the contents in sorted order,
  * not do significant heap allocation, not modify the collection, and complete in linear time. This
  * combination is not possible with a heap. */

struct Heap (T, bool Min)
{
        alias pop       remove;
        alias push      opCatAssign;

        // The actual data.
        private T[]     heap;
        
        // The index of the cell into which the next element will go.
        private uint    next;


        /** Inserts the given element into the heap. */
        void push (T t)
        {
                while (heap.length <= next)
                {
                        heap.length = 2 * heap.length + 32;
                }
                heap[next] = t;
                fixup (next);
                next++;
        }

        /** Inserts all elements in the given array into the heap. */
        void push (T[] array)
        {
                while (heap.length < next + array.length)
                {
                        heap.length = 2 * heap.length + 32;
                }
                foreach (t; array) push (t);
        }

        /** Removes the top of this heap and returns it. */
        T pop ()
        {
                if (next == 0)
                {
                        throw new NoSuchElementException ("Heap :: no elements to pop");
                }
                next--;
                auto t = heap[0];
                heap[0] = heap[next];
                fixdown(0);
                return t;
        }

        /** Gets the value at the top of the heap without removing it. */
        T peek ()
        {
                assert (next > 0);
                return heap[0];
        }

        /** Returns the number of elements in this heap. */
        uint size ()
        {
                return next;
        }

        /** Reset this heap. */
        void clear ()
        {
                next = 0;
        }

        /** Get the reserved capacity of this heap. */
        uint capacity ()
        {
                return heap.length;
        }

        /** Reserve enough space in this heap for value elements. The reserved space is truncated or extended as necessary. If the value is less than the number of elements already in the heap, throw an exception. */
        uint capacity (uint value)
        {
                if (value < next)
                {
                        throw new IllegalArgumentException ("Heap :: illegal truncation");
                }
                heap.length = value;
                return value;
        }

        /** Return a shallow copy of this heap. */
        Heap clone ()
        {
                Heap other;
                other.heap = this.heap.dup;
                other.next = this.next;
                return other;
        }

        // Get the index of the parent for the element at the given index.
        private uint parent (uint index)
        {
                return (index - 1) / 2;
        }

        // Having just inserted, restore the heap invariant (that a node's value is greater than its children)
        private void fixup (uint index)
        {
                if (index == 0) return;
                uint par = parent (index);
                if (!comp(heap[par], heap[index]))
                {
                swap (par, index);
                fixup (par);
                }
        }

        // Having just removed and replaced the top of the heap with the last inserted element,
        // restore the heap invariant.
        private void fixdown (uint index)
        {
                uint left = 2 * index + 1;
                uint down;
                if (left >= next)
                {
                        return;
                }

                if (left == next - 1)
                {
                        down = left;
                }
                else if (comp (heap[left], heap[left + 1]))
                {
                        down = left;
                }
                else
                {
                        down = left + 1;
                }

                if (!comp(heap[index], heap[left]))
                {
                        swap (index, down);
                        fixdown (down);
                }
        }

        // Swap two elements in the array.
        private void swap (uint a, uint b)
        {
                auto t = heap[a];
                heap[a] = heap[b];
                heap[b] = t;
        }

        private bool comp (T parent, T child)
        {
                static if (Min == true)
                           return parent <= child;
                else
                           return parent >= child;
        }
}


/** A minheap implementation. This will have the smallest item as the top of the heap. */

template MinHeap(T)
{
        alias Heap!(T, true) MinHeap;
}

/** A maxheap implementation. This will have the largest item as the top of the heap. */

template MaxHeap(T)
{
        alias Heap!(T, false) MaxHeap;
}


unittest
{
        MinHeap!(uint) h;
        assert (h.size is 0);
        h ~= 1;
        h ~= 3;
        h ~= 2;
        h ~= 4;
        assert (h.size is 4);

        assert (h.peek is 1);
        assert (h.peek is 1);
        assert (h.size is 4);
        h.pop;
        assert (h.peek is 2);
        assert (h.size is 3);
}

unittest
{
        MinHeap!(uint) h;
        assert (h.size is 0);
        h ~= 1;
        h ~= 3;
        h ~= 2;
        h ~= 4;
        assert (h.size is 4);

        assert (h.pop is 1);
        assert (h.size is 3);
        assert (h.pop is 2);
        assert (h.size is 2);
        assert (h.pop is 3);
        assert (h.size is 1);
        assert (h.pop is 4);
        assert (h.size is 0);
}

unittest
{
        MaxHeap!(uint) h;
        h ~= 1;
        h ~= 3;
        h ~= 2;
        h ~= 4;

        assert (h.pop is 4);
        assert (h.pop is 3);
        assert (h.pop is 2);
        assert (h.pop is 1);
}

unittest
{
        MaxHeap!(uint) h;
        h ~= 1;
        h ~= 3;
        h ~= 2;
        h ~= 4;
        auto other = h.clone;

        assert (other.pop is 4);
        assert (other.pop is 3);
        assert (other.pop is 2);
        assert (other.pop is 1);
        assert (h.size is 4, "cloned heap shares data with original heap");
        assert (h.pop is 4, "cloned heap shares data with original heap");
        assert (h.pop is 3, "cloned heap shares data with original heap");
        assert (h.pop is 2, "cloned heap shares data with original heap");
        assert (h.pop is 1, "cloned heap shares data with original heap");
}

void main(){}
