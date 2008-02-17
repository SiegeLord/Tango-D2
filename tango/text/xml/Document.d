/*******************************************************************************

        Copyright: Copyright (C) 2007-2008 Aaron Craelius, Kris Bell.  
                   All rights reserved.

        License:   BSD Style
        Authors:   Aaron Craelius, Kris

*******************************************************************************/

module tango.text.xml.Document;

private import tango.text.xml.PullParser;

/*******************************************************************************

        Implements a DOM atop of the XML parser supporting document 
        parsing, tree traversal, and ad-hoc tree manipulation.

        The DOM API is non-conformant, yet simple and functional in 
        style - locate a tree node of interest and operate upon or 
        around it. In all cases you will need a document instance to 
        begin, whereupon it may be populated either by parsing an 
        existing document or via API manipulation.

        This particular DOM employs a simple free-list to allocate
        each of the tree nodes, making it rather efficient at parsing
        XML documents. The tradeoff with such a scheme is that copying
        nodes from one document to another requires a little more care
        than otherwise. We felt this was a reasonable tradeoff, given
        the throughput gains vs the relative infrequency of grafting
        operations. Use node.dup and node.clone for these purposes.

        Another simplification is related to entity transcoding. This
        is not performed internally, and becomes the responsibility
        of the client. That is, the client should perform appropriate
        entity transcoding as necessary. Paying the (high) transcoding 
        cost for all documents doesn't seem appropriate.

        Note that the parser is templated for char, wchar or dchar.

        Parse example:
        ---
        auto doc = new Document!(char);
        doc.parse (content);

        Stdout(doc.print).newline;
        ---

        API example:
        ---
        auto doc = new Document!(char);

        // create an element
        auto elem = doc.element (null, "element");

        // add an attribute to it
        elem.attribute (doc.attribute (null, "attrib", "value"));

        // append element to document
        doc.root.append (elem);

        // traverse some nodes
        foreach (node; doc.root.children)
                {
                Stdout (node.name).newline;
                foreach (attr; node.attributes)
                         Stdout (attr.name).newline;
                }
        ---

*******************************************************************************/

class Document(T) : private PullParser!(T)
{
        public alias NodeImpl*  Node;

        public  Node            root;
        private NodeImpl[]      list;
        private int             index;
        private uint[T[]]       namespaceURIs;
        
        static const T[] xmlns = "xmlns";
        static const T[] xmlnsURI = "http://www.w3.org/2000/xmlns/";
        static const T[] xmlURI = "http://www.w3.org/XML/1998/namespace";

        /***********************************************************************
        
                Construct a DOM instance. The optional parameter indicates
                the initial number of nodes assigned to the freelist

        ***********************************************************************/

        this (uint nodes = 1000)
        {
                assert (nodes);

                super (null);
                namespaceURIs[xmlURI] = 1;
                namespaceURIs[xmlnsURI] = 2;
                list = new NodeImpl [nodes];

                root = allocate;
                root.type = XmlNodeType.Document;
        }

        /***********************************************************************
        
                Reset the freelist. Subsequent allocation of document nodes 
                will overwrite prior instances.

        ***********************************************************************/
        
        final Document collect ()
        {
                index = 1;
                return this;
        }
        
        /***********************************************************************
        
                Creates and returns an ELEMENT node

        ***********************************************************************/
        
        final Node element (T[] prefix, T[] localName)
        {
                auto node = allocate;
                node.type = XmlNodeType.Element;
                node.localName = localName;
                node.prefix = prefix;
                return node;
        }
        
        /***********************************************************************
        
                Creates and returns a DATA node

        ***********************************************************************/
        
        final Node data (T[] data)
        {
                auto node = allocate;
                node.type = XmlNodeType.Data;
                node.rawValue = data;
                return node;
        }
        
        /***********************************************************************
        
                Creates and returns a CDATA node

        ***********************************************************************/
        
        final Node cdata (T[] cdata)
        {
                auto node = allocate;
                node.type = XmlNodeType.CData;
                node.rawValue = cdata;
                return node;
        }
        
        /***********************************************************************
        
                Creates and returns a PI node

        ***********************************************************************/
        
        final Node pi (T[] pi)
        {
                auto node = allocate;
                node.type = XmlNodeType.PI;
                node.rawValue = pi;
                return node;
        }
        
        /***********************************************************************
        
                Creates and returns a DOCTYPE node

        ***********************************************************************/
        
        final Node doctype (T[] doctype)
        {
                auto node = allocate;
                node.type = XmlNodeType.Doctype;
                node.rawValue = doctype;
                return node;
        }
        
        /***********************************************************************
        
                Creates and returns a COMMENT node

        ***********************************************************************/
        
        final Node comment (T[] comment)
        {
                auto node = allocate;
                node.type = XmlNodeType.Comment;
                node.rawValue = comment;
                return node;
        }
        
        /***********************************************************************
        
                Creates and returns an ATTRIBUTE node

        ***********************************************************************/
        
        final Node attribute (T[] prefix, T[] localName, T[] value)
        {
                auto attr = allocate;
                attr.prefix = prefix;
                attr.rawValue = value;
                attr.localName = localName;
                attr.type = XmlNodeType.Attribute;
                return attr;
        }
        
        /***********************************************************************
        
                Parse the given xml content, which will reuse any existing 
                node within this document. The resultant tree is retrieved
                via the document 'root' attribute

        ***********************************************************************/
        
        final void parse(T[] xml)
        {
                collect;
                reset (xml);
                auto cur = root;

                uint defNamespace;
                uint[T[]] inscopeNSs;
                inscopeNSs["xml"] = 1;
                inscopeNSs["xmlns"] = 2;        
                
                while (super.next) 
                      {
                      switch (super.type) 
                             {
                             case XmlTokenType.EndElement:
                                  if (! cur.hasChildren) 
                                        cur.append (data(null));
        
                                  assert (cur.parent_);
                                  cur = cur.parent_;                      
                                  break;
        
                             case XmlTokenType.Data:
                                  auto node = allocate;
                                  node.type = XmlNodeType.Data;
                                  node.rawValue = super.rawValue;
                                  cur.append (node);
                                  break;
        
                             case XmlTokenType.StartElement:
                                  auto node = allocate;
                                  node.prefix = super.prefix;
                                  node.type = XmlNodeType.Element;
                                  node.localName = super.localName;
                                  node.parent_ = cur;
                                
                                  if (super.prefix.length) 
                                     {
                                     auto pURI = super.prefix in inscopeNSs;
                                     if (pURI) 
                                         node.uriID = *pURI;
                                     else 
                                        {
                                        debug (XmlNamespaces) 
                                               assert (false, "Unresolved namespace prefix:" ~ super.prefix);
                                        node.uriID = 0;
                                        }
                                     }
                                  else 
                                     node.uriID = defNamespace;
                                
                                  if (cur.lastChild_ is null) 
                                     {
                                     cur.firstChild_ = node;
                                     cur.lastChild_ = node;
                                     }
                                  else 
                                     {
                                     cur.lastChild_.nextSibling_ = node;
                                     node.prevSibling_ = cur.lastChild_;
                                     cur.lastChild_ = node;
                                     }
                                  cur = node;
                                  break;
        
                             case XmlTokenType.Attribute:
                                  auto attr = attribute (super.prefix, super.localName, super.rawValue);
                                  if (super.prefix.length) 
                                     {
                                     if (super.prefix == xmlns) 
                                        {
                                        uint uri;
                                        if (super.rawValue.length) 
                                           {
                                           auto pURI = (super.rawValue in namespaceURIs);
                                           if (pURI is null) 
                                              {
                                              uri = namespaceURIs.length + 1;
                                              namespaceURIs[super.rawValue] = uri;
                                              }
                                           else 
                                              uri = *pURI;
                                           }
                                        else 
                                           uri = 0;
                                                
                                        if (super.localName.length is 0) 
                                            defNamespace = uri;
                                        else 
                                           inscopeNSs[super.localName] = uri;
                                        }
                                     
                                     auto pURI = super.prefix in inscopeNSs;
                                     if (pURI) 
                                         cur.attribute (attr, *pURI);
                                     else 
                                        {
                                        debug (XmlNamespaces) 
                                               assert (false, "Unresolved namespace prefix:" ~ super.prefix);
                                        cur.attribute (attr, 0);
                                        }
                                     }
                                  else 
                                     cur.attribute (attr, defNamespace);
                                  break;
        
                             case XmlTokenType.EndEmptyElement:
                                  assert (cur.parent_);
                                  cur = cur.parent_;
                                  break;
        
                             case XmlTokenType.Comment:
                                  cur.append (comment(super.rawValue));
                                  break;
        
                             case XmlTokenType.PI:
                                  cur.append (pi (super.rawValue));
                                  break;
        
                             case XmlTokenType.CData:
                                  cur.append (cdata (super.rawValue));
                                  break;
        
                             case XmlTokenType.Doctype:
                                  cur.append (doctype (super.rawValue));
                                  break;
        
                             default:
                                  break;
                             }
                      }
                      //return this;
        }
        
        /***********************************************************************
        
                allocate a node from the freelist

        ***********************************************************************/

        private final Node allocate()
        {
                if (index >= list.length)
                    list.length = list.length + list.length/2;

                auto p = &list[index++];
                p.prevSibling_ = p.nextSibling_ = p.firstChild_ 
                               = p.lastChild_   = p.firstAttr_
                               = p.lastAttr_    = p.parent_ = null;
                return p;
        }


        /***********************************************************************
        
                opApply support for nodes

        ***********************************************************************/
        
        private struct Visitor
        {
                private Node node;
        
                /***************************************************************
                
                        traverse sibling nodes

                ***************************************************************/
        
                int opApply (int delegate(inout Node) dg)
                {
                        int ret;
                        auto cur = node;
                        while (cur)
                              {
                              if ((ret = dg (cur)) != 0) 
                                   break;
                              cur = cur.nextSibling_;
                              }
                        return ret;
                }
        }
        
        
        /***********************************************************************
        
                The node implementation

        ***********************************************************************/
        
        private struct NodeImpl
        {
                public XmlNodeType      type;
                public T[]              prefix;
                public T[]              localName;
                public T[]              rawValue;
                public uint             uriID;
                
                private Node            parent_,
                                        prevSibling_,
                                        nextSibling_,
                                        firstChild_,
                                        lastChild_,
                                        firstAttr_,
                                        lastAttr_;
                
                /***************************************************************
                
                        Return the parent, which may be null

                ***************************************************************/
        
                Node parent() { return parent_; }
        
                /***************************************************************
                
                        Return the first child, which may be nul

                ***************************************************************/
        
                Node firstChild() { return firstChild_; }
        
                /***************************************************************
                
                        Return the last child, which may be null

                ***************************************************************/
        
                Node lastChild() { return lastChild_; }
        
                /***************************************************************
                
                        Return the prior sibling, which may be null

                ***************************************************************/
        
                Node prevSibling() { return prevSibling_; }
        
                /***************************************************************
                
                        Return the next sibling, which may be null

                ***************************************************************/
        
                Node nextSibling() { return nextSibling_; }
        
                /***************************************************************
                
                        Returns whether there are attributes present or not

                ***************************************************************/
        
                bool hasAttr() {return firstAttr_ !is null;}
                               
                /***************************************************************
                
                        Returns whether there are children present or nor

                ***************************************************************/
        
                bool hasChildren() {return firstChild_ !is null;}
                
                /***************************************************************
                
                        Return the node name, which is a combination of
                        the prefix:local names

                ***************************************************************/
        
                T[] name()
                {
                        static T[] colon = ":";
        
                        if (prefix.length)
                            return prefix ~ colon ~ localName;
                        return localName;
                }
                
                /***************************************************************
                
                        Return the raw data content, which may be null

                ***************************************************************/
        
                T[] value()
                {
                        return rawValue;
                }
                
                /***************************************************************
                
                        Set the raw data content, which may be null

                ***************************************************************/
        
                void value(T[] val)
                {
                        rawValue = val; 
                }
                
                /***************************************************************
                
                        Return an foreach iterator for node children

                ***************************************************************/
        
                Visitor children() 
                {
                        Visitor v = {firstChild_};
                        return v;
                }
        
                /***************************************************************
                
                        Return a foreach iterator for node attributes

                ***************************************************************/
        
                Visitor attributes() 
                {
                        Visitor v = {firstAttr_};
                        return v;
                }
        
                /***************************************************************
                
                        Append a node to this one. The given node cannot
                        have an existing parent.

                ***************************************************************/
        
                void append (Node node)
                {
                        assert (node.parent is null);
                        node.parent_ = this;
                        if (lastChild_) 
                           {
                           lastChild_.nextSibling_ = node;
                           node.prevSibling_ = lastChild_;
                           lastChild_ = node;
                           }
                        else 
                           {
                           firstChild_ = node;
                           lastChild_ = node;                  
                           }
                }
                
                /***************************************************************
                
                        Prepend a node to this one. The given node cannot
                        have an existing parent.

                ***************************************************************/
        
                void prepend (Node node)
                {
                        assert (node.parent is null);
                        node.parent_ = this;
                        if (firstChild_) 
                           {
                           firstChild_.prevSibling_ = node;
                           node.nextSibling_ = firstChild_;
                           firstChild_ = node;
                           }
                        else 
                           {
                           firstChild_ = node;
                           lastChild_ = node;
                           }
                }
                
                /***************************************************************
                
                        Insert a node after this one. The given node cannot
                        have an existing parent.

                ***************************************************************/
        
                void insertAfter (Node node)
                {
                        assert (node.parent is null);
                        node.parent_ = parent_;
                        if (nextSibling_) 
                           {
                           nextSibling_.prevSibling_ = node;
                           node.nextSibling_ = nextSibling_;
                           node.prevSibling_ = this;
                           }
                        else 
                           {
                           node.prevSibling_ = this;
                           node.nextSibling_ = null;
                           }
                        nextSibling_ = node;
                }
                
                /***************************************************************
                
                        Insert a node before this one. The given node cannot
                        have an existing parent.

                ***************************************************************/
        
                void insertBefore (Node node)
                {
                        assert (node.parent is null);
                        node.parent_ = parent_;
                        if (prevSibling_) 
                           {
                           prevSibling_.nextSibling_ = node;
                           node.prevSibling_ = prevSibling_;
                           node.nextSibling_ = this;
                           }
                        else 
                           {
                           node.nextSibling_ = this;
                           node.prevSibling_ = null;
                           }
                        prevSibling_ = node;
                }
                
                /***************************************************************
                
                        Append an attribute to this node, The given attribute
                        cannot have an existing parent.

                ***************************************************************/
        
                void attribute (Node node, uint uriID = 0)
                {
                        assert (node.parent is null);
                        node.uriID = uriID;
                        node.parent_ = this;
                        node.type = XmlNodeType.Attribute;
        
                        if (lastAttr_) 
                           {
                           lastAttr_.nextSibling_ = node;
                           node.prevSibling_ = lastAttr_;
                           lastAttr_ = node;
                           }
                        else 
                           firstAttr_ = lastAttr_ = node;
                }
        
                /***************************************************************
                
                        Duplicate a single node

                ***************************************************************/
        
                Node dup()
                {
                        auto p = new NodeImpl;

                        p.prefix = prefix.dup;
                        p.rawValue = rawValue.dup;
                        p.localName = localName.dup;
                        p.type = type;
                        return p;
                }

                /***************************************************************
                
                        Duplicate a subtree

                ***************************************************************/
        
                Node clone ()
                {
                        auto p = dup;

                        foreach (node; attributes)
                                 p.attribute (node.dup);

                        foreach (node; children)
                                 p.append (node.clone);

                        return p;
                }

                /***************************************************************
                
                        Detach this node from its parent and siblings. Note 
                        that it still remains in the freelist

                ***************************************************************/
        
                void detach()
                {
                        if (! parent_) 
                              return;
                        
                        if (prevSibling_ && nextSibling_) 
                           {
                           prevSibling_.nextSibling_ = nextSibling_;
                           nextSibling_.prevSibling_ = prevSibling_;
                           prevSibling_ = null;
                           nextSibling_ = null;
                           parent_ = null;
                           }
                        else 
                           if (nextSibling_)
                              {
                              debug assert(parent_.firstChild_ == this);
                              parent_.firstChild_ = nextSibling_;
                              nextSibling_.prevSibling_ = null;
                              nextSibling_ = null;
                              parent_ = null;
                              }
                           else 
                              if (type != XmlNodeType.Attribute)
                                 {
                                 if (prevSibling_)
                                    {
                                    debug assert(parent_.lastChild_ == this);
                                    parent_.lastChild_ = prevSibling_;
                                    prevSibling_.nextSibling_ = null;
                                    prevSibling_ = null;
                                    parent_ = null;
                                    }
                                 else
                                    {
                                    debug assert(parent_.firstChild_ == this);
                                    debug assert(parent_.lastChild_ == this);
                                    parent_.firstChild_ = null;
                                    parent_.lastChild_ = null;
                                    parent_ = null;
                                    }
                                 }
                              else
                                 {
                                 if (prevSibling_)
                                    {
                                    debug assert(parent_.lastAttr_ == this);
                                    parent_.lastAttr_ = prevSibling_;
                                    prevSibling_.nextSibling_ = null;
                                    prevSibling_ = null;
                                    parent_ = null;
                                    }
                                 else
                                    {
                                    debug assert(parent_.firstAttr_ == this);
                                    debug assert(parent_.lastAttr_ == this);
                                    parent_.firstAttr_ = null;
                                    parent_.lastAttr_ = null;
                                    parent_ = null;
                                    }
                                 }
                }
        }

        /*******************************************************************************
        
                Generate a text representation of the document tree

        *******************************************************************************/
        
        final T[] print()
        {
                return print (this.root);
        }
        
        /*******************************************************************************
        
                Generate a text representation of the given node-subtree 

        *******************************************************************************/
        
        final T[] print (Node root)
        {
                T[] res;
        
                void printNode (Node node)
                {
                        switch (node.type)
                               {
                               case XmlNodeType.Document:
                                    foreach (n; node.children)
                                             printNode (n);
                                    break;
        
                               case XmlNodeType.Element:
                                    res ~= "<" ~ node.name;
                                    foreach (attr; node.attributes)
                                             res ~= " " ~ print(attr);
        
                                    if (node.hasChildren)
                                       {
                                       res ~= ">";
                                       foreach (n; node.children)
                                                printNode(n);
                                       res ~= "</" ~ node.name ~ ">";
                                       }
                                    else 
                                       res ~= " />";      
                                    break;
        
                               case XmlNodeType.Data:
                                    res ~= node.rawValue;
                                    break;
        
                               case XmlNodeType.Attribute:
                                    res ~= node.name ~ "=\"" ~ node.rawValue ~ "\"";
                                    break;
        
                               case XmlNodeType.Comment:
                                    res ~= "<!--" ~ node.rawValue ~ "-->";
                                    break;
        
                               case XmlNodeType.PI:
                                    res ~= "<?" ~ node.rawValue ~ "?>";
                                    break;
        
                               case XmlNodeType.CData:
                                    res ~= "<![CDATA[" ~ node.rawValue ~ "]]>";
                                    break;
        
                               case XmlNodeType.Doctype:
                                    res ~= "<!DOCTYPE " ~ node.rawValue ~ ">";
                                    break;
        
                               default:
                                    break;
                               }
                }
        
                printNode (root);
                return res;
        }
}
