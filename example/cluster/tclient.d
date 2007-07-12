/*******************************************************************************


*******************************************************************************/

import tango.io.Stdout;

import tango.util.time.StopWatch;

import tango.util.log.Configurator;

import tango.net.cluster.tina.Cluster;

import Add;

/*******************************************************************************


*******************************************************************************/

void main (char[][] args)
{
        StopWatch w;

        auto cluster = (new Cluster).join;
        auto channel = cluster.createChannel ("rpc.channel");

        auto add = new Add;
        while (true)
              {
              w.start;
              for (int i=20000; i--;)
                   add (1, 2, channel);
        
              Stdout.formatln ("{} calls/s", 20000/w.stop);
              }
}

