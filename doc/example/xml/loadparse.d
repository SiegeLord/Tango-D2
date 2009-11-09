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

    Stdout.format("The length of the XML document is {} bytes", xml.length).newline;

    // create document
    auto doc = new Document!(char);

    doc.parse(xml);
}
