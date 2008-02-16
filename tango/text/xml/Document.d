/*******************************************************************************

        Copyright: Copyright (C) 2007-2008 Aaron Craelius, Kris Bell.  
                   All rights reserved.

        License:   BSD Style
        Authors:   Aaron Craelius, Kris

*******************************************************************************/

module tango.text.xml.Document;

private import tango.text.xml.PullParser;

/*******************************************************************************

*******************************************************************************/

class Document(T) : PullParser!(T)
{
        public alias NodeImpl*  Node;

        public  Node            root;
        private NodeImpl[]      list;
        private int             index;
        private uint[T[]]       namespaceURIs;
        
        static const T[] xmlnsURI = "http://www.w3.org/2000/xmlns/";
        static const T[] xmlURI = "http://www.w3.org/XML/1998/namespace";

        /***********************************************************************
        
        ***********************************************************************/

        this (uint nodes = 1000)
        {
                super (null);
                namespaceURIs[xmlURI] = 1;
                namespaceURIs[xmlnsURI] = 2;
                list = new NodeImpl [nodes];
        }

        /***********************************************************************
        
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
        
        ***********************************************************************/
        
        final Node data (T[] data)
        {
                auto node = allocate;
                node.type = XmlNodeType.Data;
                node.rawValue = data;
                return node;
        }
        
        /***********************************************************************
        
        ***********************************************************************/
        
        final Node cdata (T[] cdata)
        {
                auto node = allocate;
                node.type = XmlNodeType.CData;
                node.rawValue = cdata;
                return node;
        }
        
        /***********************************************************************
        
        ***********************************************************************/
        
        final Node pi (T[] pi)
        {
                auto node = allocate;
                node.type = XmlNodeType.PI;
                node.rawValue = pi;
                return node;
        }
        
        /***********************************************************************
        
        ***********************************************************************/
        
        final Node doctype (T[] doctype)
        {
                auto node = allocate;
                node.type = XmlNodeType.Doctype;
                node.rawValue = doctype;
                return node;
        }
        
        /***********************************************************************
        
        ***********************************************************************/
        
        final Node comment (T[] comment)
        {
                auto node = allocate;
                node.type = XmlNodeType.Comment;
                node.rawValue = comment;
                return node;
        }
        
        /***********************************************************************
        
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
        
        ***********************************************************************/
        
        final void parse(T[] xml)
        {
                static T[] xmlns = "xmlns";
        
                index = 0;
                reset (xml);
                auto cur = root = allocate;
                cur.type = XmlNodeType.Document;

                uint defNamespace;
                uint[T[]] inscopeNSs;
                inscopeNSs["xml"] = 1;
                inscopeNSs["xmlns"] = 2;        
                
                while (super.next) 
                      {
                      switch (super.type) 
                             {
                             case XmlTokenType.Data:
                                  auto node = allocate;
                                  node.type = XmlNodeType.Data;
                                  node.rawValue = super.rawValue;
                                  cur.append (node);
                                  break;
        
                             case XmlTokenType.EndElement:
                                  if (! cur.hasChildren) 
                                        cur.append (data(null));
        
                                  assert (cur.parent_);
                                  cur = cur.parent_;                      
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
                                         cur.appendAttribute (attr, *pURI);
                                     else 
                                        {
                                        debug (XmlNamespaces) 
                                               assert (false, "Unresolved namespace prefix:" ~ super.prefix);
                                        cur.appendAttribute (attr, 0);
                                        }
                                     }
                                  else 
                                     cur.appendAttribute (attr, defNamespace);
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
        }
        
        
        /***********************************************************************
        
        ***********************************************************************/
        
        private struct Visitor
        {
                private Node node;
        
                /***************************************************************
                
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
                
                ***************************************************************/
        
                Node parent() { return parent_; }
        
                /***************************************************************
                
                ***************************************************************/
        
                Node firstChild() { return firstChild_; }
        
                /***************************************************************
                
                ***************************************************************/
        
                Node lastChild() { return lastChild_; }
        
                /***************************************************************
                
                ***************************************************************/
        
                Node prevSibling() { return prevSibling_; }
        
                /***************************************************************
                
                ***************************************************************/
        
                Node nextSibling() { return nextSibling_; }
        
                /***************************************************************
                
                ***************************************************************/
        
                bool hasChildren() {return firstChild_ !is null;}
                
                /***************************************************************
                
                ***************************************************************/
        
                bool hasAttr() {return firstAttr_ !is null;}
                               
                /***************************************************************
                
                ***************************************************************/
        
                T[] name()
                {
                        static T[] colon = ":";
        
                        if (prefix.length)
                            return prefix ~ colon ~ localName;
                        return localName;
                }
                
                /***************************************************************
                
                ***************************************************************/
        
                T[] value()
                {
                        return rawValue;
                }
                
                /***************************************************************
                
                ***************************************************************/
        
                void value(T[] val)
                {
                        rawValue = val; 
                }
                
                /***************************************************************
                
                ***************************************************************/
        
                Visitor children() 
                {
                        Visitor v = {firstChild_};
                        return v;
                }
        
                /***************************************************************
                
                ***************************************************************/
        
                Visitor attributes() 
                {
                        Visitor v = {firstAttr_};
                        return v;
                }
        
                /***************************************************************
                
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
                
                ***************************************************************/
        
                void appendAttribute (Node node, uint uriID = 0)
                {
                        assert (node.parent is null);
                        node.parent_ = this;
        
                        node.uriID = uriID;
                        node.type = XmlNodeType.Attribute;
        
                        if (firstAttr_) 
                           {
                           lastAttr_.nextSibling_ = node;
                           node.prevSibling_ = lastAttr_;
                           lastAttr_ = node;
                           }
                        else 
                           {
                           firstAttr_ = node;
                           lastAttr_ = node;
                           }
                }
        
                /***************************************************************
                
                ***************************************************************/
        
                void remove()
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
        
        *******************************************************************************/
        
        T[] print()
        {
                return print (this.root);
        }
        
        /*******************************************************************************
        
        *******************************************************************************/
        
        T[] print (Node root)
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
