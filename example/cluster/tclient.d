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

        // an implicit task instance
        auto add = new NetCall!(add);

        // an explicit task instance
        auto sub = new Subtract;

        StopWatch w;
        while (true)
              {
              w.start;
              for (int i=10000; i--;)
                  {
                  // both tasks are used in the same manner
                  add (1, 2, channel);
                  sub (3, 4, channel);
                  }
              Stdout.formatln ("{} calls/s", 20000/w.stop);
              }
}

