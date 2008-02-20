/*******************************************************************************

        Copyright: Copyright (C) 2007-2008 Kris. All rights reserved.

        License:   BSD Style
        Authors:   Kris

*******************************************************************************/

module tango.text.xml.XmlQuery;

private import tango.text.xml.Document;

/*******************************************************************************

*******************************************************************************/

class XmlQuery(T)
{       
        public alias Document!(T) Doc;          /// the typed document
        public alias Doc.Node Node;             /// generic document node
        public alias start opCall;              /// shortcut to start
         
        private Node[]          freelist;
        private uint            freeIndex,
                                markIndex;
        private uint            recursion;

        /***********************************************************************
        
        ***********************************************************************/
        
        this ()
        {  
                freelist.length = 256;     
        }

        /***********************************************************************
        
        ***********************************************************************/
        
        final NodeSet start (Doc doc)
        {       
                return start (doc.root);
        }
        
        /***********************************************************************
        
        ***********************************************************************/
        
        final NodeSet start (Node root)
        {
                if (recursion is 0)
                    freeIndex = 0;

                NodeSet set = {this};
                auto mark = freeIndex;
                allocate(root);
                return set.assign (mark);

        }

        /***********************************************************************
        
        ***********************************************************************/
        
        struct NodeSet
        {
                private XmlQuery host;
                private Node[]   members;

                public alias nth opIndex;       /// shortcut to nth

                /***************************************************************
        
                ***************************************************************/
        
                uint count ()
                {
                        return members.length;
                }

                /***************************************************************
        
                ***************************************************************/
        
                NodeSet first ()
                {
                        return nth (0);
                }

                /***************************************************************
        
                ***************************************************************/
        
                NodeSet last ()
                {       
                        auto i = members.length;
                        if (i > 0)
                            --i;
                        return nth (i);
                }

                /***************************************************************
        
                ***************************************************************/
        
                NodeSet nth (uint index)
                {
                        NodeSet set = {host};
                        auto mark = host.mark;
                        if (index < members.length)
                            host.allocate (members [index]);
                        return set.assign (mark);
                }

                /***************************************************************
        
                ***************************************************************/
        
                NodeSet child ()
                {
                        return child ((Node node)
                                      {return node.type is XmlNodeType.Element;});
                }

                /***************************************************************
        
                ***************************************************************/
        
                NodeSet child (T[] name)
                {
                        return child ((Node node)
                                      {return node.type is XmlNodeType.Element && node.name == name;});
                }

                /***************************************************************
        
                ***************************************************************/
        
                NodeSet text ()
                {
                        return child ((Node node)
                                      {return node.type is XmlNodeType.Data;});
                }

                /***************************************************************
        
                ***************************************************************/
        
                NodeSet text (T[] name)
                {
                        return child ((Node node)
                                      {return node.type is XmlNodeType.Data && node.name == name;});
                }

                /***************************************************************
        
                ***************************************************************/
        
                NodeSet attribute ()
                {
                        return attributes ((Node node)
                                          {return node.type is XmlNodeType.Attribute;});
                }

                /***************************************************************
        
                ***************************************************************/
        
                NodeSet attribute (T[] name)
                {
                        return attributes ((Node node)
                                           {return node.type is XmlNodeType.Attribute && node.name == name;});
                }

                /***************************************************************
        
                ***************************************************************/
        
                NodeSet descendent ()
                {
                        return descendent ((Node node)
                                           {return node.type is XmlNodeType.Element;});
                }

                /***************************************************************
        
                ***************************************************************/
        
                NodeSet descendent (T[] name)
                {
                        return descendent ((Node node)
                                           {return node.type is XmlNodeType.Element && node.name == name;});
                }

                /***************************************************************
        
                        Construct a filtered Nodeset

                ***************************************************************/
        
                NodeSet predicate (bool delegate(Node) filter)
                {
                        NodeSet set = {host};
                        auto mark = host.mark;
                        foreach (member; members)
                                 test (filter, member);
                        return set.assign (mark);
                }

                /***************************************************************
        
                ***************************************************************/
        
                NodeSet child (bool delegate(Node) filter)
                {
                        NodeSet set = {host};
                        auto mark = host.mark;
                        foreach (parent; members)
                                 foreach (child; parent.children)
                                          test (filter, child);
                        return set.assign (mark);
                }

                /***************************************************************
        
                ***************************************************************/
        
                NodeSet attributes (bool delegate(Node) filter)
                {
                        NodeSet set = {host};
                        auto mark = host.mark;
                        foreach (parent; members)
                                 foreach (attr; parent.attributes)
                                          test (filter, attr);
                        return set.assign (mark);
                }

                /***************************************************************
        
                ***************************************************************/
        
                NodeSet descendent (bool delegate(Node) filter)
                {
                        void traverse (Node parent)
                        {
                                 foreach (child; parent.children)
                                         {
                                         test (filter, child);
                                         traverse (child);
                                         }                                                
                        }

                        NodeSet set = {host};
                        auto mark = host.mark;

                        foreach (parent; members)
                                 traverse (parent);

                        return set.assign (mark);
                }

                /***************************************************************
                
                        traverse members

                ***************************************************************/
        
                int opApply (int delegate(inout Node) dg)
                {
                        int ret;
                        foreach (member; members)
                                 if ((ret = dg (member)) != 0) 
                                      break;
                        return ret;
                }

                /***************************************************************
        
                ***************************************************************/
        
                private NodeSet assign (uint mark)
                {
                        members = host.slice (mark);
                        return *this;
                }

                /***************************************************************
        
                ***************************************************************/
        
                private void test (bool delegate(Node) filter, Node node)
                {
                        ++host.recursion;
                        auto pop = host.freeIndex;
                        auto add = filter (node);
                        host.freeIndex = pop;
                        --host.recursion;
                        if (add)
                            host.allocate (node);
                }
        }

        /***********************************************************************
        
        ***********************************************************************/
        
        private uint mark ()
        {       
                return freeIndex;
        }

        /***********************************************************************
        
        ***********************************************************************/
        
        private Node[] slice (uint mark)
        {
                assert (mark <= freeIndex);
                return freelist [mark .. freeIndex];
        }

        /***********************************************************************
        
        ***********************************************************************/
        
        private uint allocate (Node node)
        {
                if (freeIndex >= freelist.length)
                    freelist.length = freelist.length + freelist.length / 2;

                freelist[freeIndex] = node;
                return ++freeIndex;
        }
 }


/*******************************************************************************

*******************************************************************************/

import tango.io.Stdout;
import tango.time.StopWatch;
import tango.text.xml.XmlPrinter;

void main()
{
        auto doc = new Document!(char);

        // attach an xml header
        doc.header;

        // attach an element with some attributes, plus 
        // a child element with an attached data value
        doc.root.element   (null, "element")
                .attribute (null, "attrib1", "value")
                .attribute (null, "attrib2")
                .element   (null, "child", "value")
                .parent
                .parent
                .element   (null, "second");

        // emit document
        auto print = new XmlPrinter!(char);
        Stdout(print(doc)).newline;

        StopWatch w;
        auto query = new XmlQuery!(char);
        auto set = query(doc);

        // simple lookup
        w.start;
        for (uint i = 5000000; --i;)
             set = query(doc).child("element").child("child");

        Stdout.formatln("{} generic lookups per ms", 5000.0/w.stop);
        foreach (element; set)
                 Stdout.formatln ("selected '{}'", element.name);

        // recursive lookup
        w.start;
        for (uint i = 5000000; --i;)
             set = query(doc).descendent.predicate((query.Node n){return query(n).attribute.count > 0;});

        Stdout.formatln("{} recursive lookups per ms", 5000.0/w.stop);
        foreach (element; set)
                 Stdout.formatln ("selected '{}'", element.name);

}
