module xmlsax;

import tango.io.device.File;
import tango.io.Stdout;
import tango.time.StopWatch;
import tango.text.xml.SaxParser;

void main() 
{       
        for (int i = 10; --i;)
            {
            auto parser = new SaxParser!(char);
            auto handler = new LengthHandler!(char);
            parser.setSaxHandler(handler);
            benchmark (2000, parser);
            }
}


void benchmark (int iterations, SaxParser!(char) parser) 
{       
        StopWatch elapsed;

        auto content = cast(char[]) File.get ("hamlet.xml");
        parser.setContent(content);

        elapsed.start();
        for (auto i=0; ++i < iterations;)
            {
            parser.parse();
            parser.reset();
            }
        Stdout.formatln ("{} MB/s", (content.length * iterations) / (elapsed.stop() * (1024 * 1024)));
}




private class EventsHandler(Ch = char) : SaxHandler!(Ch) {

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

        public override void startPrefixMapping(const(Ch)[] prefix, const(Ch)[] uri) {
                events++;
        }

        public override void endPrefixMapping(const(Ch)[] prefix) {
                events++;
        }                                               

        public override void startElement(const(Ch)[] uri, const(Ch)[] localName, const(Ch)[] qName, Attribute!(Ch)[] atts) {
                events++;
                foreach (ref attr; atts) {
                        events++;
                }
        }

        public override void endElement(const(Ch)[] uri, const(Ch)[] localName, const(Ch)[] qName) {
                events++;
        }

        public override void characters(const(Ch)[] ch) {
                events++;
        }

        public override void ignorableWhitespace(Ch[] ch) {
                events++;
        }

        public override void processingInstruction(const(Ch)[] target, const(Ch)[] data) {
                events++;
        }

        public override void skippedEntity(const(Ch)[] name) {
                events++;
        }       
}

private class LengthHandler(Ch = char) : SaxHandler!(Ch) {

        public uint elm;
        public uint att;
        public uint txt;
        public uint elmlen;
        public uint attlen;
        public uint txtlen;

        public override void setDocumentLocator(Locator!(Ch) locator) {

        }

        public override void startDocument() {
                
        }

        public override void endDocument() {
                
        }

        public override void startPrefixMapping(const(Ch)[] prefix, const(Ch)[] uri) {

        }

        public override void endPrefixMapping(const(Ch)[] prefix) {

        }                                               

        public override void startElement(const(Ch)[] uri, const(Ch)[] localName, const(Ch)[] qName, Attribute!(Ch)[] atts) {
                elm++;
                elmlen += localName.length;
                foreach (ref attr; atts) {
                        att++;
                        attlen += attr.localName.length;
                }
        }

        public override void endElement(const(Ch)[] uri, const(Ch)[] localName, const(Ch)[] qName) {
                
        }

        public override void characters(const(Ch)[] ch) {
                txt++;
                txtlen += ch.length;
        }

        public override void ignorableWhitespace(Ch[] ch) {

        }

        public override void processingInstruction(const(Ch)[] target, const(Ch)[] data) {

        }

        public override void skippedEntity(const(Ch)[] name) {

        }       
}

