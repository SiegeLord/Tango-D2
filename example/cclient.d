
private import  tango.sys.System;

private import  tango.log.Logger,
                tango.log.Configurator;

private import  tango.cache.PlainCache;

private import  tango.cluster.CacheInvalidator,
                tango.cluster.CacheInvalidatee;

private import  tango.cluster.qos.socket.Cluster;

/*******************************************************************************

        Directive to include the winsock2 library

*******************************************************************************/

version (Win32)
         pragma (lib, "wsock32");

/*******************************************************************************

        Contrived example of network cache manipulation. We wrap a cache
        instance within a network listener, create a network aware cache
        entry invalidator, and invalidate a specific key.

        Note that the invalidatee and invalidator are on a common channel.
        If they were on different channels, the invalidatee would ignore
        the request (wouldn't even receive it).

	Note also that this does not use the clustered cache or queue at 
	all since there's some site-specific configuration that should be 
	provided in a properties file (the host names within the network).

*******************************************************************************/

void main ()
{
        // create a logger instance for the cluster to use
        BasicConfigurator.configure ();
        Logger logger = Logger.getLogger ("example.cclient");

        // instantiate a socket-oriented cluster
        Cluster cluster = new Cluster (logger);

        // create an invalidatee, listening on the specified channel
        CacheInvalidatee dst = new CacheInvalidatee (cluster, "my.cache.channel", new PlainCache);

        // create an invalidator on the specified channel
        CacheInvalidator src = new CacheInvalidator (cluster, "my.cache.channel");

        // invalidate a channel/key combination across the entire local network
        logger.info ("making network cache entries coherent ...");
        src.invalidate ("some key");

        // wait for user input
        logger.info ("message sent - press <ctrl-c> to exit");

        System.sleep ();
}
