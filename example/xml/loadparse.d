import tango.io.device.File;
import tango.io.Stdout;
import tango.text.Util;
import tango.text.xml.Document;

/******************************************************************************

  From http://www.dsource.org/projects/tango/wiki/TutXmlPath

  Free for any use, without warranty, by Sean Kerr

******************************************************************************/

void main () {
    // load our xml document
    auto file = new File("xpath.xml");
    auto xml  = new char[file.length];

    // read the file content into the xml buffer
    file.input.read(xml);

    Stdout.format("The length of the XML document is {} bytes", file.length).newline;

    // create document
    auto doc = new Document!(char);

    doc.parse(xml);
}
