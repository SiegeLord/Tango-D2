private import  tango.io.Buffer;

private import  tango.io.PickleWriter,
                tango.io.PickleReader,
                tango.io.PickleRegistry;

/*******************************************************************************

        Use interfaces to make any class serializable. This will be used
        by tango.server to move class-instances around the network. Each 
        class is effectively a factory for itself.

        Note that this is not the same as Java; you can't ship code with
        the data ... one might perhaps use dll's or something to do that.

*******************************************************************************/

void pickle1()
{
        // define a pickled class (via interface)
        class Foo : IPickle, IPickleFactory
        {
                private int x = 11;
                private int y = 112;

                void write(IWriter output)
                {
                        output (x) (y);
                }

                void read(IReader input)
                {
                        input (x) (y);
                        assert (x == 11 && y == 112);
                }

                Object create (IReader input)
                {
                        Foo foo = new Foo;
                        input (foo);
                        return foo;
                }

                char[] getGuid ()
                {
                        return "foo";
                }
        }

        // construct a Bar
        Foo foo = new Foo;

        // tell registry about this object
        PickleRegistry.enroll (foo);

        // setup for serialization
        Buffer buf = new Buffer (256);
        PickleWriter w = new PickleWriter (buf);
        PickleReader r = new PickleReader (buf);

        // serialize it
        w.freeze (foo);
        
        // create a new instance and populate. This just shows the basic
        // concept, not a fully operational implementation
        Object obj = r.thaw ();
}


/*******************************************************************************

        Split the class out such that object resurrection is performed by a 
        proxy function instead. You must ensure that the guid used to enroll
        the proxy is identical to the one provided by the IPickle instance.

*******************************************************************************/

void pickle2()
{
        // define a pickled class (using IPickle only!) 
        static class Wumpus : IPickle
        {
                private int x = 11;
                private int y = 112;

                void write (IWriter write)
                {
                        write (x) (y);
                }

                void read (IReader read)
                {
                        read (x) (y);
                        assert (x == 11 && y == 112);
                }

                char[] getGuid ()
                {
                        return "wumpus";
                }

                // note that this is a static method, as opposed to
                // the IPickleFactory method of the same name
                static Object create (IReader read)
                {
                        Wumpus w = new Wumpus;
                        read (w);
                        return w;
                }
        }

        // tell registry about the proxy function
        PickleRegistry.enroll (&Wumpus.create, "wumpus");

        // setup for serialization
        Buffer buf = new Buffer (256);
        PickleWriter w = new PickleWriter (buf);
        PickleReader r = new PickleReader (buf);

        // serialize it
        w.freeze (new Wumpus);
        
        // create a new instance and populate
        Object obj = r.thaw ();
}


/*******************************************************************************

*******************************************************************************/

void main()
{
        pickle1 ();
        pickle2 ();
}

