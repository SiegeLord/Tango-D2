
private import  tango.log.Logger,
                tango.log.Configurator;

private import  tango.sys.System;

private import  tango.io.Console,
                tango.io.FileConduit;

private import  tango.cluster.Message,
                tango.cluster.TaskServer,
                tango.cluster.NetworkQueue;

private import  tango.cluster.qos.socket.Cluster;


/*******************************************************************************

        Directive to include the winsock2 library

*******************************************************************************/

version (Win32)
         pragma (lib, "wsock32");


/*******************************************************************************

        An example Task. We'll use this for illustrative purposes.

*******************************************************************************/

class MyTask : Task
{
        private char[] name;

        /**********************************************************************

                Create an instance with the given name

        **********************************************************************/

        this (char[] name)
        {       
                this.name = name;
        }

        /**********************************************************************
        
                Recover attributes from the provided reader

        **********************************************************************/

        override void read (IReader reader)
        {
                super.read (reader);
                reader.get (name);
        }

        /**********************************************************************

                Emit attributes to the provided writer

        **********************************************************************/

        override void write (IWriter writer)
        {
                super.write (writer);
                writer.put (name);
        }

        /**********************************************************************

                Execute this task. We just print the name

        **********************************************************************/

        override void execute ()
        {
                Cout ("executing MyTask '"c);
                Cout (name);
                Cout ("'\n"c);
        }

        /**********************************************************************

                Overridable create method to instantiates a new instance. 
                Might be used to allocate subclassses from a freelist

        **********************************************************************/

        override Object create ()
        {
                return new MyTask ("no name");
        }

        /**********************************************************************

                Return the guid for this payload. This should be unique
                per payload class if said class is used in conjunction
                with the clustering facilities. Inspected by the Pickle
                utilitiy classes.
                
        **********************************************************************/

        override char[] getGuid ()
        {
                return this.classinfo.name;
        }

}


/*******************************************************************************

        How to instantiate a task server

*******************************************************************************/

class MyTaskServer : TaskServer
{
        /**********************************************************************

                Configure our Task server with the names of the potential
                cluster members. We can also configure an HttpServer with
                the Admin servlet for adjusting logger settings; setting
                the port number to something valid will enable the servlet.

        **********************************************************************/

	this (ILogger logger, char[] filename, int adminPort = 0)
	{
		auto FileConduit config = new FileConduit (filename);
		super (new Cluster (logger, config), adminPort);
	}

        /**********************************************************************

                Callback to enroll all tasks we can execute. For now we
                configure it to execute only one kind. The superclass uses
                the task-guid as the name for a queue dedicated to each
                particular task class. 

        **********************************************************************/

	override void enroll (ILogger logger)
	{
                // Note that we ask for our task to be 'enrolled' also; 
                // this particular instance will be called upon to create 
                // all subsequent instances that arrive over the network.
                // There are several ways to register a class: this is 
                // just one of them
		addConsumer (new MyTask("host"), true);
	}
}


/*******************************************************************************

        Create a logger instance, create our task server, and send some
        example tasks into the cluster to be competed over.

*******************************************************************************/

void main ()
{
        // configure the main logger
        BasicConfigurator.configure ();
        ILogger logger = Logger.getLogger ("my.task.server");

        // create the Task server (note that we elected not to enable the
        // logger Admin servlet)
	MyTaskServer mts = new MyTaskServer (logger, "cluster.properties");

        // and start it ...
	mts.start ();
        logger.info ("awaiting tasks: press <ctrl-c> to quit");



        // now send a couple of tasks into the cluster, and compete for them
        // with other task servers listening on the same channel
        try {
            System.sleep (3 * System.Interval.Second);

            // create a few tasks ...
            MyTask foo = new MyTask ("foo");
            MyTask bar = new MyTask ("bar");
            MyTask wumpus = new MyTask ("wumpus");
            MyTask gronk = new MyTask ("gronk");
            MyTask rupture = new MyTask ("rupture");

            // gain access to the cluster queues, using the Task guid as Q name
            NetworkTask nt = new NetworkTask (mts.getCluster(), foo.getGuid());

            logger.info ("publishing tasks ...");

            // send tasks to the cluster ...
            nt.put (foo);
            nt.put (bar);
            nt.put (wumpus);
            nt.put (gronk);
            nt.put (rupture);

            } catch (Exception x)
                     logger.error (x.toString);
            
        System.sleep ();
}
