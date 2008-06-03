/*******************************************************************************


*******************************************************************************/

import tango.io.Stdout;

import tango.util.log.Log,
       tango.util.log.Config;

import tango.time.StopWatch;

import tango.net.cluster.NetworkCache;

import tango.net.cluster.tina.Cluster;

import Integer = tango.text.convert.Integer;

/*******************************************************************************


*******************************************************************************/

void main (char[][] args)
{
        StopWatch w;
        
        if (args.length > 1)
           {
           auto cluster = (new Cluster).join (args[1..$]);
           auto cache   = new NetworkCache (cluster, "my.cache.channel");

           char[64] tmp;
           while (true)
                 {
                 w.start;
                 for (int i=10000; i--;)
                     {
                     auto key = Integer.format (tmp, i);
                     cache.put (key, cache.EmptyMessage);
                     }

                 Stdout.formatln ("{} put/s", 10000/w.stop);

                 w.start;
                 for (int i=10000; i--;)
                     {
                     auto key = Integer.format (tmp, i);
                     cache.get (key);
                     }
        
                 Stdout.formatln ("{} get/s", 10000/w.stop);
                 }
           }
        else
           Stdout.formatln ("usage: cache cachehost:port ...");
}

