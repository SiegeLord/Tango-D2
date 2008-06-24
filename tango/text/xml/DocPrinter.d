/*******************************************************************************

        Copyright: Copyright (C) 2008 Kris Bell.  All rights reserved.

        License:   BSD style: $(LICENSE)

        version:   Initial release: March 2008      

        Authors:   Kris

*******************************************************************************/

module tango.text.xml.DocPrinter;

private import tango.text.xml.Document;

/*******************************************************************************

        Simple Document printer, with support for serialization caching 
        where the latter avoids having to generate unchanged sub-trees

*******************************************************************************/

class DocPrinter(T) : IXmlPrinter!(T)
{
        /***********************************************************************
        
                Generate a text representation of the document tree

        ***********************************************************************/
        
        final T[] print (Doc doc)
        {       
                T[] content;

                print (doc.root, (T[][] s...){foreach(t; s) content ~= t;});
                return content;
        }
        
        /***********************************************************************
        
                Generate a representation of the given node-subtree 

        ***********************************************************************/
        
        final void print (Node root, void delegate(T[][]...) emit)
        {
                T[256] tmp;
                T[256] spaces = ' ';

                // ignore whitespace from mixed-model values
                T[] rawValue (Node node)
                {
                        foreach (c; node.rawValue)
                                 if (c > 32)
                                     return node.rawValue;
                        return null;
                }

                void printNode (Node node, uint indent)
                {
                        // check for cached output
                        if (node.end)
                           {
                           auto p = node.start;
                           auto l = node.end - p;
                           // nasty hack to retain whitespace while
                           // dodging prior EndElement instances
                           if (*p is '>')
                               ++p, --l;
                           emit (p[0 .. l]);
                           }
                        else
                        switch (node.type)
                               {
                               case XmlNodeType.Document:
                                    foreach (n; node.children)
                                             printNode (n, indent);
                                    break;
        
                               case XmlNodeType.Element:
                                    emit ("\r\n", spaces[0..indent], "<", node.name(tmp));
                                    foreach (attr; node.attributes)
                                             emit (` `, attr.name, `="`, attr.rawValue, `"`);  

                                    auto value = rawValue (node);
                                    if (node.hasChildren)
                                       {
                                       emit (">");
                                       if (value.length)
                                           emit (value);
                                       foreach (child; node.children)
                                                printNode (child, indent + 2);
                                        
                                       // inhibit newline if we're closing Data
                                       if (node.lastChild_.type != XmlNodeType.Data)
                                           emit ("\r\n", spaces[0..indent]);
                                       emit ("</", node.name(tmp), ">");
                                       }
                                    else 
                                       if (value.length)
                                           emit (">", value, "</", node.name(tmp), ">");
                                       else
                                          emit ("/>");      
                                    break;
        
                                    // ingore whitespace data in mixed-model
                                    // <foo>
                                    //   <bar>blah</bar>
                                    //
                                    // a whitespace Data instance follows <foo>
                               case XmlNodeType.Data:
                                    auto value = rawValue (node);
                                    if (value.length)
                                        emit (node.rawValue);
                                    break;
        
                               case XmlNodeType.Comment:
                                    emit ("<!--", node.rawValue, "-->");
                                    break;
        
                               case XmlNodeType.PI:
                                    emit ("<?", node.rawValue, "?>");
                                    break;
        
                               case XmlNodeType.CData:
                                    emit ("<![CDATA[", node.rawValue, "]]>");
                                    break;
        
                               case XmlNodeType.Doctype:
                                    emit ("<!DOCTYPE ", node.rawValue, ">");
                                    break;

                               default:
                                    emit ("<!-- unknown node type -->");
                                    break;
                               }
                }
        
                printNode (root, 0);
        }
}


debug (DocPrinter)
{
        import tango.io.Stdout;
        import tango.text.xml.Document;

        void main()
        {
                char[] document = "<blah><xml>foo</xml></blah>";

                auto doc = new Document!(char);
                doc.parse (document);

                void test (char[][] s...){foreach (t; s) Stdout(t).flush;}

                auto print = new DocPrinter!(char);
                print(doc.root.firstChild.firstChild, &test);
        }
}
