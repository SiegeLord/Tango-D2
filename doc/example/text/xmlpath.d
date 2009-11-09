import tango.io.Stdout;
import tango.time.StopWatch;
import tango.text.xml.Document;
import tango.text.xml.DocPrinter;

/*******************************************************************************

*******************************************************************************/

void main()
{
        auto doc = new Document!(char);

        // attach an xml header
        doc.header;

        // attach an element with some attributes, plus 
        // a child element with an attached data value
        doc.tree.element   (null, "element")
                .element   (null, "sub")
                .attribute (null, "attrib1", "value")
                .attribute (null, "attrib2")
                .element   (null, "child", "value")
                .parent
                .element   (null, "second");

        // emit document
        auto print = new DocPrinter!(char);
        Stdout(print(doc)).newline;

        // time some queries
        StopWatch w;
        uint count = 1000000;
        auto set = doc.query;

        // simple lookup: locate a specific named element
        w.start;
        for (uint i = count; --i;)
             set = doc.query["element"]["sub"]["child"];
        result ("generic lookups/s", count/w.stop, set);

        // attribute lookup: select all attributes of 'sub'
        w.start;
        for (uint i = count; --i;)
             set = doc.query.child("element").child("sub").attribute;
        result ("attribute lookups/s", count/w.stop, set);

        // filtered lookup: locate all elements with text "value"
        w.start;
        for (uint i = count; --i;)
             set = doc.query.descendant.filter((doc.Node n) {return n.children.hasValue("value");});
        result ("text-filter lookups/s", count/w.stop, set);

        // filtered lookup: locate all elements with attribute name "attrib1"
        w.start;
        for (uint i = count; --i;)
             set = doc.query.descendant.filter((doc.Node n) {return n.attributes.hasName(null, "attrib1");});
        result ("attr-filter lookups/s", count/w.stop, set);

        // filtered lookup: locate all elements with more than 1 child
        w.start;
        for (uint i = count; --i;)
             set = doc.query.descendant.filter((doc.Node n) {return n.query.child.count > 1;});
        result ("recursive-filter lookups/s", count/w.stop, set);

}

void result (char[] msg, double time, XmlPath!(char).NodeSet set)
{
        Stdout.newline.formatln("{} {}", time, msg);
        foreach (element; set)
                 Stdout.formatln ("selected '{}'", element.name);
}
