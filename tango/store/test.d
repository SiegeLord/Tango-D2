import tango.store.TreeBag;
import tango.store.LinkSeq;
import tango.store.LinkMap;
import tango.store.TreeMap;
import tango.store.HashSet;
import tango.store.HashMap;
import tango.store.ArraySeq;
import tango.store.ArrayBag;
import tango.store.CircularSeq;

import tango.io.Console;


void main()
{
///        if (false)
        {
        auto seq = new ArraySeqT!(float);
        seq.append (1.1);
        seq.append (2.2);
        seq.append (3.3);
        float x = seq.get (0);
        Cout (seq.toString).newline;

        auto seq1 = seq.duplicate();
        Cout (seq1.toString).newline;
        }
//        else
        {
        auto seq = new ArraySeqT!(int);
        seq.append (1);
        seq.append (2);
        seq.append (3);
        seq.append (4);
        seq.append (5);
        Cout (seq.toString).newline;

        auto seq1 = seq.duplicate();
        Cout (seq1.toString).newline;
        }

        auto t0 = new TreeMapT!(char[], int);
        auto t1 = new TreeBagT!(int);
        auto t2 = new LinkSeqT!(int);
        auto t3 = new LinkMapT!(char[], int);
        auto t4 = new HashSetT!(int);
        auto t5 = new HashMapT!(wchar[], float);
        auto t6 = new CircularSeqT!(int);
        auto t7 = new ArrayBagT!(int);
}
