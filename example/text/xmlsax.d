module xmlsax;

import tango.io.File;
import tango.io.Stdout;
import tango.time.StopWatch;

import tango.text.xml.Sax;

void benchmark (int iterations, char[] filename) 
{       
        char c1;
        static char c;
        StopWatch elapsed;

        auto file = new File (filename);
        auto content = cast(char[]) file.read;
        auto parser = new SaxParser!(char);
//      auto handler = new EventsHandler!(char);
        auto handler = new LengthHandler!(char);
        parser.setContentHandler(handler);
        parser.setContent(content);

        elapsed.start;
        for (auto i=0; ++i < iterations;)
        {
                parser.parse;
                parser.reset;
        }

        Stdout.formatln ("{} MB/s", (content.length * iterations) / (elapsed.stop * (1024 * 1024)));
}

void main() 
{       
        for (int i = 10; --i;)
                benchmark (5000, "soap_mid.xml");       
}

private class EventsHandler(Ch = char) : ContentHandler!(Ch) {

        public uint events;


        public void setDocumentLocator(Locator!(Ch) locator) {
                events++;
        }

        public void startDocument() {
                events++;
        }

        public void endDocument() {
                events++;
        }

        public void startPrefixMapping(Ch[] prefix, Ch[] uri) {
                events++;
        }

        public void endPrefixMapping(Ch[] prefix) {
                events++;
        }                                               

        public void startElement(Ch[] uri, Ch[] localName, Ch[] qName, Attribute!(Ch)[] atts) {
                events++;
                foreach (Attribute!(Ch) attr; atts) {
                        events++;
                }
        }

        public void endElement(Ch[] uri, Ch[] localName, Ch[] qName) {
                events++;
        }

        public void characters(Ch[] ch) {
                events++;
        }

        public void ignorableWhitespace(Ch[] ch) {
                events++;
        }

        public void processingInstruction(Ch[] target, Ch[] data) {
                events++;
        }

        public void skippedEntity(Ch[] name) {
                events++;
        }       
}

private class LengthHandler(Ch = char) : ContentHandler!(Ch) {

        public uint elm;
        public uint att;
        public uint txt;
        public uint elmlen;
        public uint attlen;
        public uint txtlen;

        public void setDocumentLocator(Locator!(Ch) locator) {

        }

        public void startDocument() {
                
        }

        public void endDocument() {
                
        }

        public void startPrefixMapping(Ch[] prefix, Ch[] uri) {

        }

        public void endPrefixMapping(Ch[] prefix) {

        }                                               

        public void startElement(Ch[] uri, Ch[] localName, Ch[] qName, Attribute!(Ch)[] atts) {
                elm++;
                elmlen += localName.length;
                foreach (Attribute!(Ch) attr; atts) {
                        att++;
                        attlen += attr.localName.length;
                }
        }

        public void endElement(Ch[] uri, Ch[] localName, Ch[] qName) {
                
        }

        public void characters(Ch[] ch) {
                txt++;
                txtlen += ch.length;
        }

        public void ignorableWhitespace(Ch[] ch) {

        }

        public void processingInstruction(Ch[] target, Ch[] data) {

        }

        public void skippedEntity(Ch[] name) {

        }       
}

