import tango.io.device.File;
import tango.io.Stdout;
import tango.text.Util;
import tango.text.xml.Document;

/******************************************************************************

  From http://www.dsource.org/projects/tango/wiki/TutXmlPath

  Free for any use, without warranty, by Sean Kerr

******************************************************************************/

void main () {
    // create document
    auto doc = new Document!(char);

    // parse our xml
    doc.parse (cast(char[]) File.get("xpath.xml"));

    // get the root element
    auto root = doc.elements;

    // query the doc for all country elements with an id attribute that contains a 'B'
    auto result = root.query().descendant("country").filter((doc.Node node) {
        return contains!(char)(node.attributes.name(null, "id").value, 'B');
    });

    foreach (e; result) {
        Stdout.format("id = {}, name = {}", e.attributes.name(null, "id").value, e.value).newline;
    }
}
