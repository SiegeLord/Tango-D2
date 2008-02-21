/*******************************************************************************

        Copyright: Copyright (C) 2007-2008 Aaron Craelius, Kris Bell.  
                   All rights reserved.

        License:   BSD Style
        Authors:   Aaron, Kris

*******************************************************************************/

module tango.text.xml.Document;

package import tango.text.xml.PullParser;

version = NameSpace;

/*******************************************************************************

        Implements a DOM atop the XML parser, supporting document 
        parsing, tree traversal and ad-hoc tree manipulation.

        The DOM API is non-conformant, yet simple and functional in 
        style - locate a tree node of interest and operate upon or 
        around it. In all cases you will need a document instance to 
        begin, whereupon it may be populated either by parsing an 
        existing document or via API manipulation.

        This particular DOM employs a simple free-list to allocate
        each of the tree nodes, making it quite efficient at parsing
        XML documents. The tradeoff with such a scheme is that copying
        nodes from one document to another requires a little more care
        than otherwise. We felt this was a reasonable tradeoff, given
        the throughput gains vs the relative infrequency of grafting
        operations. For grafting within or across documents, please
        use the move() and copy() methods.

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

        auto print = new XmlPrinter!(char);
        Stdout(print(doc)).newline;
         ---

        API example:
        ---
        auto doc = new Document!(char);

        // attach an xml header
        doc.header;

        // attach an element with some attributes, plus 
        // a child element with an attached data value
        doc.root.element   (null, "element")
                .attribute (null, "attrib1", "value")
                .attribute (null, "attrib2")
                .element   (null, "child", "value");

        auto print = new XmlPrinter!(char);
        Stdout(print(doc)).newline;
        ---

*******************************************************************************/

class Document(T) : private PullParser!(T)
{
        public alias NodeImpl*  Node;

        public  Node            root;
        private NodeImpl[]      list;
        private NodeImpl[][]    lists;
        private int             index,
                                chunks,
                                freelists;
        private uint[T[]]       namespaceURIs;
        
        static const T[] xmlns = "xmlns";
        static const T[] xmlnsURI = "http://www.w3.org/2000/xmlns/";
        static const T[] xmlURI = "http://www.w3.org/XML/1998/namespace";

        /***********************************************************************
        
                Construct a DOM instance. The optional parameter indicates
                the initial number of nodes assigned to the freelist

        ***********************************************************************/

        this (uint nodes = 5000)
        {
                assert (nodes > 50);
                super (null);
                namespaceURIs[xmlURI] = 1;
                namespaceURIs[xmlnsURI] = 2;

                chunks = nodes;
                newlist;
                root = allocate;
                root.type = XmlNodeType.Document;
        }

        /***********************************************************************
        
                Reset the freelist. Subsequent allocation of document nodes 
                will overwrite prior instances.

        ***********************************************************************/
        
        final Document collect ()
        {
                root.lastChild_ = 
                root.firstChild_ = null;
                freelists = 0;
                index = 1;
                freelists = 0;          // needed to align the codegen!
                return this;
        }

        /***********************************************************************
        
               Add an XML header to the document root

        ***********************************************************************/
        
        final Document header (T[] encoding = "UTF-8")
        {
                root.prepend (root.create(XmlNodeType.PI, `xml version="1.0" encoding="`~encoding~`"`));
                return this;
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
                
                while (true) 
                      {
                      switch (super.next) 
                             {
                             case XmlTokenType.EndElement:
                             case XmlTokenType.EndEmptyElement:
                                  assert (cur.parent_);
                                  cur = cur.parent_;                      
                                  break;
        
                             case XmlTokenType.Data:
                                  if (cur.rawValue.length is 0)
                                      cur.rawValue = super.rawValue;
                                  else
                                     // multiple data sections
                                     cur.data (super.rawValue);
                                  break;
        
                             case XmlTokenType.StartElement:
                                  auto node = allocate;
                                  node.parent_ = cur;
                                  node.prefix = super.prefix;
                                  node.type = XmlNodeType.Element;
                                  node.localName = super.localName;
                                
                                  // inline append
                                  if (cur.lastChild_) 
                                     {
                                     cur.lastChild_.nextSibling_ = node;
                                     node.prevSibling_ = cur.lastChild_;
                                     cur.lastChild_ = node;
                                     }
                                  else 
                                     {
                                     cur.firstChild_ = node;
                                     cur.lastChild_ = node;
                                     }
                                  cur = node;
version (NameSpace)
{
                                  if (node.prefix.length) 
                                     {
                                     auto pURI = node.prefix in inscopeNSs;
                                     if (pURI) 
                                         node.uriID = *pURI;
                                     else 
                                        {
                                        debug (XmlNamespaces) 
                                               assert (false, "Unresolved namespace prefix:" ~ node.prefix);
                                        node.uriID = 0;
                                        }
                                     }
                                  else 
                                     node.uriID = defNamespace;
}
                                  break;
        
                             case XmlTokenType.Attribute:
                                  auto attr = allocate;
                                  attr.prefix = super.prefix;
                                  attr.rawValue = super.rawValue;
                                  attr.localName = super.localName;
                                  attr.type = XmlNodeType.Attribute;
version (NameSpace)
{
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
                                         cur.attrib (attr, *pURI);
                                     else 
                                        {
                                        debug (XmlNamespaces) 
                                               assert (false, "Unresolved namespace prefix:" ~ super.prefix);
                                        cur.attrib (attr, 0);
                                        }
                                     }
                                  else 
                                     cur.attrib (attr, defNamespace);
}
else
                                     cur.attrib (attr, defNamespace);
                                  break;
        
                             case XmlTokenType.PI:
                                  cur.pi (super.rawValue);
                                  break;
        
                             case XmlTokenType.Comment:
                                  cur.comment (super.rawValue);
                                  break;
        
                             case XmlTokenType.CData:
                                  cur.cdata (super.rawValue);
                                  break;
        
                             case XmlTokenType.Doctype:
                                  cur.doctype (super.rawValue);
                                  break;
        
                             case XmlTokenType.Done:
                                  return;

                             default:
                                  break;
                             }
                      }
        }
        
        /***********************************************************************
        
                allocate a node from the freelist

        ***********************************************************************/

        private final Node allocate ()
        {
                if (index >= list.length)
                    newlist;

                auto p = &list[index++];
                p.document = this;
                p.parent_ =
                p.prevSibling_ = 
                p.nextSibling_ = 
                p.firstChild_ =
                p.lastChild_ = 
                p.firstAttr_ =
                p.lastAttr_ = null;
                p.rawValue = null;
                return p;
        }

        /***********************************************************************
        
                allocate a node from the freelist

        ***********************************************************************/

        private final void newlist ()
        {
                index = 0;
                if (freelists >= lists.length)
                   {
                   lists.length = lists.length + 1;
                   lists[$-1] = new NodeImpl [chunks];
                   }
                list = lists[freelists++];
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
                public uint             uriID;
                public T[]              prefix;
                public T[]              localName;
                public T[]              rawValue;
                
                private Node            parent_,
                                        prevSibling_,
                                        nextSibling_,
                                        firstChild_,
                                        lastChild_,
                                        firstAttr_,
                                        lastAttr_;
                private Document        document;

                /***************************************************************
                
                        Return the parent, which may be null

                ***************************************************************/
        
                Node parent () {return parent_;}
        
                /***************************************************************
                
                        Return the first child, which may be nul

                ***************************************************************/
        
                Node firstChild () {return firstChild_;}
        
                /***************************************************************
                
                        Return the last child, which may be null

                ***************************************************************/
        
                Node lastChild () {return lastChild_;}
        
                /***************************************************************
                
                        Return the prior sibling, which may be null

                ***************************************************************/
        
                Node prevSibling () {return prevSibling_;}
        
                /***************************************************************
                
                        Return the next sibling, which may be null

                ***************************************************************/
        
                Node nextSibling () {return nextSibling_;}
        
                /***************************************************************
                
                        Returns whether there are attributes present or not

                ***************************************************************/
        
                bool hasAttributes () {return firstAttr_ !is null;}
                               
                /***************************************************************
                
                        Returns whether there are children present or nor

                ***************************************************************/
        
                bool hasChildren () {return firstChild_ !is null;}
                
                /***************************************************************
                
                        Return the node name, which is a combination of
                        the prefix:local names

                ***************************************************************/
        
                T[] name ()
                {
                        if (prefix.length)
                            return prefix ~ ':' ~ localName;
                        return localName;
                }
                
                /***************************************************************
                
                        Return the raw data content, which may be null

                ***************************************************************/
        
                T[] value ()
                {
                        return rawValue;
                }
                
                /***************************************************************
                
                        Set the raw data content, which may be null

                ***************************************************************/
        
                void value (T[] val)
                {
                        rawValue = val; 
                }
                
                /***************************************************************
                
                        Locate the root of this node

                ***************************************************************/
        
                Node root ()
                {
                        return document.root;
                }

                /***************************************************************
                
                        Return an foreach iterator for node children

                ***************************************************************/
        
                Visitor children () 
                {
                        Visitor v = {firstChild_};
                        return v;
                }
        
                /***************************************************************
                
                        Return a foreach iterator for node attributes

                ***************************************************************/
        
                Visitor attributes () 
                {
                        Visitor v = {firstAttr_};
                        return v;
                }
        
                /***************************************************************
        
                        Creates a child Element

                        Returns a reference to the child

                ***************************************************************/
        
                Node element (T[] prefix, T[] local, T[] value = null)
                {
                        auto node = create (XmlNodeType.Element, value);
                        append (node.set (prefix, local));
                        return node;
                }
        
                /***************************************************************
        
                        Attaches an Attribute, and returns the host

                ***************************************************************/
        
                Node attribute (T[] prefix, T[] local, T[] value = null)
                {
                        auto node = create (XmlNodeType.Attribute, value);
                        attrib (node.set (prefix, local));
                        return this;
                }
        
                /***************************************************************
        
                        Attaches a Data node, and returns the host

                ***************************************************************/
        
                Node data (T[] data)
                {
                        append (create (XmlNodeType.Data, data));
                        return this;
                }
        
                /***************************************************************
        
                        Attaches a CData node, and returns the host

                ***************************************************************/
        
                Node cdata (T[] cdata)
                {
                        append (create (XmlNodeType.CData, cdata));
                        return this;
                }
        
                /***************************************************************
        
                        Attaches a Comment node, and returns the host

                ***************************************************************/
        
                Node comment (T[] comment)
                {
                        append (create (XmlNodeType.Comment, comment));
                        return this;
                }
        
                /***************************************************************
        
                        Attaches a PI node, and returns the host

                ***************************************************************/
        
                Node pi (T[] pi)
                {
                        append (create (XmlNodeType.PI, pi));
                        return this;
                }
        
                /***************************************************************
        
                        Attaches a Doctype node, and returns the host

                ***************************************************************/
        
                Node doctype (T[] doctype)
                {
                        append (create (XmlNodeType.Doctype, doctype));
                        return this;
                }
        
                /***************************************************************
                
                        Duplicate the given sub-tree into place as a child 
                        of this node. 
                        
                        Returns a reference to the subtree

                ***************************************************************/
        
                Node copy (Node tree)
                {
                        assert (tree);
                        tree = tree.clone;
                        tree.migrate (document);
                        append (tree);
                        return tree;
                }

                /***************************************************************
                
                        Relocate the given sub-tree into place as a child 
                        of this node. 
                        
                        Returns a reference to the subtree

                ***************************************************************/
        
                Node move (Node tree)
                {
                        tree.detach;
                        if (tree.document is document)
                            append (tree);
                        else
                           tree = copy (tree);
                        return tree;
                }

                /***************************************************************
                
                        Detach this node from its parent and siblings

                ***************************************************************/
        
                private Node detach()
                {
                        if (! parent_) 
                              return this;
                        
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
                        return this;
                }

version (tools)
{                
                /***************************************************************
                
                        Insert a node after this one. The given node cannot
                        have an existing parent.

                ***************************************************************/
        
                private void insertAfter (Node node)
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
        
                private void insertBefore (Node node)
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
}                
                /***************************************************************
                
                        Append an attribute to this node, The given attribute
                        cannot have an existing parent.

                ***************************************************************/
        
                private void attrib (Node node, uint uriID = 0)
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
                
                        Append a node to this one. The given node cannot
                        have an existing parent.

                ***************************************************************/
        
                private void append (Node node)
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
        
                private void prepend (Node node)
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
        
                        Configure node values
        
                ***************************************************************/
        
                private Node set (T[] prefix, T[] local)
                {
                        this.localName = local;
                        this.prefix = prefix;
                        return this;
                }
        
                /***************************************************************
        
                        Creates and returns a child Element node

                ***************************************************************/
        
                private Node create (XmlNodeType type, T[] value)
                {
                        auto node = document.allocate;
                        node.rawValue = value;
                        node.type = type;
                        return node;
                }
        
                /***************************************************************
                
                        Duplicate a single node

                ***************************************************************/
        
                private Node dup()
                {
                        return create(type, rawValue.dup).set(prefix.dup, localName.dup);
                }

                /***************************************************************
                
                        Duplicate a subtree

                ***************************************************************/
        
                private Node clone ()
                {
                        auto p = dup;

                        foreach (attr; attributes)
                                 p.attrib (attr.dup);
                        foreach (child; children)
                                 p.append (child.clone);
                        return p;
                }

                /***************************************************************

                        Reset the document host for this subtree

                ***************************************************************/
        
                private void migrate (Document host)
                {
                        this.document = host;
                        foreach (attr; attributes)
                                 attr.migrate (host);
                        foreach (child; children)
                                 child.migrate (host);
                }
        }
}


/*******************************************************************************

*******************************************************************************/

interface IXmlPrinter(T)
{
        public alias Document!(T) Doc;          /// the typed document
        public alias Doc.Node Node;             /// generic document node
        public alias print opCall;              /// alias for print method

        /***********************************************************************
        
                Generate a text representation of the document tree

        ***********************************************************************/
        
        T[] print (Doc doc);
        
        /***********************************************************************
        
                Generate a representation of the given node-subtree 

        ***********************************************************************/
        
        void print (Node root, void delegate(T[][]...) emit);
}
