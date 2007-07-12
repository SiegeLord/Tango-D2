/*******************************************************************************

        Illustrates usage of cluster tasks

*******************************************************************************/

import Add;

import tango.io.Stdout;

void main (char[][] args)
{
        scope add = new NetCall!(add);

        Stdout.formatln ("cluster expression of 3.0 + 4.0 = {}", add(3, 4));
}

