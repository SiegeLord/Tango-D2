
private import  tango.io.device.File;
private import  tango.io.stream.Data;

/*******************************************************************************

       Create a file for random access. Write some stuff to it, rewind to
       file start and read back.

*******************************************************************************/

void main()
{
        // open a file for reading
        auto file = new File ("random.bin", File.ReadWriteCreate);

        // construct (binary) reader & writer upon this conduit
        auto read  = new DataInput (file);
        auto write = new DataOutput (file);

        int x=10, y=20;

        // write some data and flush output since IO is buffered
        write.int32(x);
        write.int32(y);
        write.flush();

        // rewind to file start
        file.seek (0);

        // read data back again, but swap destinations
        y = read.int32();
        x = read.int32();

        assert (y is 10);
        assert (x is 20);

        file.close();
}
