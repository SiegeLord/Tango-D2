private import  tango.core.System;

private import  tango.log.Logger,
                tango.log.Configurator;

private import  tango.cluster.NetworkAlert;

private import  tango.cluster.qos.socket.Cluster;

/*******************************************************************************

        Directive to include the winsock2 library

*******************************************************************************/

version (Win32)
         pragma (lib, "wsock32");

/*******************************************************************************

        How to send and recieve Alert messages using tango.cluster

*******************************************************************************/

void main()
{
        class Alert : IEventListener
        {
                private ILogger logger;

                /***************************************************************

                        Create an Alert consumer, and send it a message. 
                        The same message is send to all listeners across
                        the local network.

                ***************************************************************/

                this (ICluster cluster)
                {
                        logger = cluster.getLogger();

                        // hook into the Alert layer
                        NetworkAlert alert = new NetworkAlert (cluster, "my.kind.of.alert");

                        // listen for the reply (on this channel)
                        alert.createConsumer (this);

			// say what's going on
			logger.info ("broadcasting alert");

                        // and send everyone an empty alert (on this channel)
                        alert.broadcast ();
                }

                /***************************************************************

                        callback to consume messages

                ***************************************************************/

                void notify (IEvent event, IPayload payload)
                {
                        logger.info ("Recieved message on channel " ~ event.getChannel.getName);
                }
        }


        // configure the main logger
        BasicConfigurator.configure ();
        Logger logger = Logger.getLogger ("example.broadcast");
        logger.info ("press <ctrl-c> to quit");

        // hook into the cluster
        Cluster cluster = new Cluster (logger);

        // demonstrate alerts
        new Alert (cluster);

        // wait for it to arrive ...
        System.sleep ();
}
