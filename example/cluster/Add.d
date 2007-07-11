/*******************************************************************************

*******************************************************************************/

private import tango.net.cluster.NetworkCall;

/*******************************************************************************

*******************************************************************************/

class Add : NetworkCall
{
        double  a,
                b,
                result;

        double opCall (double a, double b, IChannel channel = null)
        {
                this.a = a;
                this.b = b;
                send (channel);
                return result;
        }

        override void execute ()
        {
                result = a + b;
        }

        override void read  (IReader input)  {input  (a) (b) (result);}

        override void write (IWriter output) {output (a) (b) (result);}
}
