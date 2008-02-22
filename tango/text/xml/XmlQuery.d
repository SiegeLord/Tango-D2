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
        
                NodeSet parent (T[] name = null)
                {
                        return parent ((Node node)
                                      {return name.ptr is null || node.name == name;});
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
        
                ***************************************************************/
        
                NodeSet ancestor (T[] name = null)
                {
                        return ancestor ((Node node)
                                         {return name.ptr is null || node.name == name;});
                }

                /***************************************************************
        
                ***************************************************************/
        
                NodeSet prev (T[] name = null)
                {
                        return prev ((Node node)
                                     {return name.ptr is null || node.name == name;});
                }

                /***************************************************************
        
                ***************************************************************/
        
                NodeSet next (T[] name = null)
                {
                        return next ((Node node)
                                     {return name.ptr is null || node.name == name;});
                }

                /***************************************************************
        
                        Construct a filtered Nodeset

                ***************************************************************/
        
                NodeSet filter (bool delegate(Node) filter)
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
        
                NodeSet parent (bool delegate(Node) filter)
                {
                        NodeSet set = {host};
                        auto mark = host.mark;
                        foreach (member; members)
                                {
                                auto p = member.parent;
                                if (p && p.type != XmlNodeType.Document)
                                   test (filter, p);
                                }
                        return set.assign (mark);
                }

                /***************************************************************
        
                ***************************************************************/
        
                NodeSet attributes (bool delegate(Node) filter)
                {
                        NodeSet set = {host};
                        auto mark = host.mark;
                        foreach (member; members)
                                 foreach (attr; member.attributes)
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

                        foreach (member; members)
                                 traverse (member);

                        return set.assign (mark);
                }

                /***************************************************************
        
                ***************************************************************/
        
                NodeSet ancestor (bool delegate(Node) filter)
                {
                        void traverse (Node child)
                        {
                                auto p = child.parent_;
                                if (p && p.type != XmlNodeType.Document)
                                   {
                                   test (filter, p);
                                   traverse (p);
                                   }
                        }

                        NodeSet set = {host};
                        auto mark = host.mark;

                        foreach (member; members)
                                 traverse (member);

                        return set.assign (mark);
                }

                /***************************************************************
        
                ***************************************************************/
        
                NodeSet next (bool delegate(Node) filter)
                {
                        NodeSet set = {host};
                        auto mark = host.mark;
                        foreach (member; members)
                                {
                                auto p = member.nextSibling_;
                                while (p)
                                      {
                                      test (filter, p);
                                      p = p.nextSibling_;
                                      }
                                }
                        return set.assign (mark);
                }

                /***************************************************************
        
                ***************************************************************/
        
                NodeSet prev (bool delegate(Node) filter)
                {
                        NodeSet set = {host};
                        auto mark = host.mark;
                        foreach (member; members)
                                {
                                auto p = member.prevSibling_;
                                while (p)
                                      {
                                      test (filter, p);
                                      p = p.prevSibling_;
                                      }
                                }
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


