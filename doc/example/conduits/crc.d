private import  tango.io.Stdout,
                tango.io.File,
                tango.io.stream.Digester;
                
private import  tango.util.digest.Crc32,
                tango.util.digest.Digest;


/*
 *  creates a digest of a particular file/path. digestOfFile(new  Crc32, "foobar.txt");
 */
char[] digestOfFile (Digest digest, const(char)[] filename)
{
    auto file = new File(filename);
    auto input = new DigestInput(file, digest);
    input.slurp.close;
    return digest.hexDigest;
}

/*
 * main
 */
void main(char[][] args)
{
    // take first arg as filename or crc.d
    const(char)[] filename = "crc.d";
    if(args.length > 1)
        filename = args[1];
    
    // formatln output
    Stdout.formatln("File: {0} crc: {1}", filename, digestOfFile (new Crc32, filename));
}

