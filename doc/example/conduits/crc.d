import tango.io.Stdout;
import tango.io.device.File;
import tango.util.digest.Crc32;
import tango.util.digest.Digest;
import tango.io.stream.Digester;

char[] digestOfFile (Digest digest, const(char)[] path)
{
        auto input = new DigestInput(new File(path), digest);
        input.slurp.close;
	return digest.hexDigest;
}


void main(char[][] args)
{
        const(char)[] name = "crc.d";
        if (args.length > 1)
            name = args[1];
            
	Stdout.formatln("crc: {}", digestOfFile (new Crc32, name));
}

