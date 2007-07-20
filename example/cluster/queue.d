private import  tango.core.Thread;

private import  tango.util.log.Configurator;

private import  tango.net.cluster.NetworkQueue;

private import  tango.net.cluster.tina.Cluster;

/*******************************************************************************

        Illustrates how to setup and use a Queue in both synchronous and
        asynchronous modes

*******************************************************************************/

void main ()
{
        // join the cluster 
        auto cluster = (new Cluster).join;

        // access a queue of the specified name
        auto queue = new NetworkQueue (cluster, "my.queue.channel");


        /***** synchronous operation ********/

        // stuff something into the queue
        queue.put (queue.EmptyMessage);

        // retrieve it synchronously
        auto msg = queue.get;



        /***** asynchronous operation ********/

        // listen for messages placed in my queue, via a delegate
        queue.createConsumer ((IEvent event) {queue.cluster.log.info ("received asynch msg on channel " ~ event.channel.name);});

        // stuff something into the queue
        queue.cluster.log.info ("sending three messages to the queue");
        queue.put (queue.EmptyMessage);
        queue.put (queue.EmptyMessage);
        queue.put (queue.EmptyMessage);

        // wait for asynchronous msgs to arrive ...
        Thread.sleep (1);
}
