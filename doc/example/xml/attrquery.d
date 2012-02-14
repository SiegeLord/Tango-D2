import tango.io.device.File;
import tango.io.Stdout;
import tango.text.xml.Document;

/******************************************************************************

  From http://www.dsource.org/projects/tango/wiki/TutXmlPath

  Free for any use, without warranty, by Sean Kerr

******************************************************************************/

void main () {
    // load our xml document
    auto xml  = cast(char[])File.get("xpath.xml");

    // create document
    auto doc = new Document!(char);
    doc.parse(xml);

    // get the root element
    auto root = doc.elements;

    // query the doc for all country elements with an id attribute (all of them)
    auto result = root.query().descendant("country").attribute("id");

    foreach (e; result) {
        Stdout(e.value).newline;
    }
}
