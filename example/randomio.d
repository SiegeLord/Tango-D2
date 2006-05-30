
private import  tango.io.Reader,
                tango.io.Writer,
                tango.io.FileConduit;

/*******************************************************************************

       Create a file for random access. Write some stuff to it, rewind to
       file start and read back.

*******************************************************************************/

void main()
{
        // open a file for reading
        FileConduit fc = new FileConduit ("random.bin", FileStyle.ReadWriteCreate);

        // construct (binary) reader & writer upon this conduit
        Reader read  = new Reader (fc);
        Writer write = new Writer (fc);

        int x=10, y=20;

        // write some data and flush output since IO is buffered
        write (x) (y) ();

        // rewind to file start
        fc.seek (0);

        // read data back again, but swap destinations
        read (y) (x);

        assert (y==10);
        assert (x==20);

        fc.close();
}
