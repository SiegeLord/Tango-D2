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
        auto cluster = (new Cluster).join;
        auto channel = cluster.createChannel ("rpc.channel");

        // an explicit task instance
        auto add = new Add;

        // an implicit task instance
        auto mul = new NetCall!(multiply);

        StopWatch w;
        while (true)
              {
              w.start;
              for (int i=10000; i--;)
                  {
                  // both tasks are used in the same manner
                  add (1, 2, channel);
                  mul (1, 2, channel);
                  }
              Stdout.formatln ("{} calls/s", 20000/w.stop);
              }
}

