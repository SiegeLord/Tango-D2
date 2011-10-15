module xmlsax;

private import  tango.io.Stdout,
                tango.io.File;

private import  tango.time.StopWatch;

private import  tango.text.xml.SaxParser;

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

        elapsed.start;
        for (auto i=0; ++i < iterations;)
            {
            parser.parse;
            parser.reset;
            }
        Stdout.formatln ("{} MB/s", (content.length * iterations) / (elapsed.stop * (1024 * 1024)));
}

private class LengthHandler(T = char) : SaxHandler!(T) {

        public uint elm;
        public uint att;
        public uint txt;
        public uint elmlen;
        public uint attlen;
        public uint txtlen;
        
        public override void startElement(const(T)[] uri, const(T)[] localName, const(T)[] qName, Attribute!(T)[] atts) {
                elm++;
                elmlen += localName.length;
                foreach (ref attr; atts) {
                        att++;
                        attlen += attr.localName.length;
                }
        }
        
        public override void characters(const(T)[] ch) {
                txt++;
                txtlen += ch.length;
        } 
}

