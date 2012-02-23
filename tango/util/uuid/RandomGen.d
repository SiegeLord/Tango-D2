/** Most people who want UUIDs will generate small numbers of them (maybe a 
  * few hundred thousand) and not require a huge amount of uniqueness (just
  * for this one application). This module provides a convenient way to obtain
  * that behavior. 
  *
  * To streamline your usage, this module publicly imports Uuid, so you can
  * import this module alone.
  *
  * To use this module, just:
  * ---
  * import tango.util.uuid.RandomGen;
  *
  * Uuid id = randUuid.next;
  * ---
  */
module tango.util.uuid.RandomGen;

public import tango.util.uuid.Uuid;
import tango.math.random.Twister;

/** The default random UUID generator. You can set this if you need to generate
  * UUIDs in another manner and already have code pointing to this module.
  *
  * This uses a unique PRNG instance. If you want repeatable results, you
  * should inject your own UUID generator and reseed it as necessary:
  * ---
  * auto rand = getRand();
  * randUuid = new RandomGen!(typeof(rand))(rand);
  * doStuff();
  * rand.reseed();
  * ---
  *
  * The default PRNG is the Mersenne twister. If you need speed, KISS is about
  * 30 times faster. I chose the Mersenne twister because it's reasonably fast
  * (I can generate 150,000 per second on my machine) and has a long period.
  * The KISS generator can produce 5 million per second on my machine.
  */
UuidGen randUuid;

shared static this ()
{
        Twister rand;
        rand.seed();
        randUuid = new RandomGen!(Twister)(rand);
}

