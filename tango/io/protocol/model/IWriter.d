/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Initial release: March 2004      
        
        author:         Kris
                        Ivan Senji (the "alias put" idea)

*******************************************************************************/

module tango.io.protocol.model.IWriter;

public import tango.io.model.IBuffer;
private import tango.io.model.IConduit;


/*******************************************************************************

        Interface to make any class compatible with any IWriter.

*******************************************************************************/

interface IWritable
{
        abstract void write (IWriter input);
}

/*******************************************************************************

        Make a signature for IWritable classes to use when they wish to 
        avoid being processed by decorating writers, such as TextWriter.

*******************************************************************************/

abstract class IPhantomWriter : IWritable
{
        abstract void write (IWriter input);
}

/*******************************************************************************

        Make a signature for Newline classes

*******************************************************************************/

abstract class INewlineWriter : IPhantomWriter {}

/*******************************************************************************

        IWriter interface. IWriter provides the means to append formatted 
        data to an IBuffer, and exposes a convenient method of handling a
        variety of data types. In addition to writing native types such
        as integer and char[], writers also process any class which has
        implemented the IWritable interface (one method).

*******************************************************************************/

abstract class IWriter  // could be an interface, but that causes poor codegen
{
        // alias the put() methods for IOStream and Whisper styles
        alias newline   cr;
        alias put       opShl;
        alias put       opCall;

        /***********************************************************************
        
                These are the basic writer methods

        ***********************************************************************/

        abstract IWriter put (bool x);
        abstract IWriter put (ubyte x);
        abstract IWriter put (byte x);
        abstract IWriter put (ushort x);
        abstract IWriter put (short x);
        abstract IWriter put (uint x);
        abstract IWriter put (int x);
        abstract IWriter put (ulong x);
        abstract IWriter put (long x);
        abstract IWriter put (float x);
        abstract IWriter put (double x);
        abstract IWriter put (real x);
        abstract IWriter put (char x);
        abstract IWriter put (wchar x);
        abstract IWriter put (dchar x);

        abstract IWriter put (byte[] x);
        abstract IWriter put (short[] x);
        abstract IWriter put (int[] x);
        abstract IWriter put (long[] x);
        abstract IWriter put (ubyte[] x);
        abstract IWriter put (ushort[] x);
        abstract IWriter put (uint[] x);
        abstract IWriter put (ulong[] x);
        abstract IWriter put (float[] x);
        abstract IWriter put (double[] x);
        abstract IWriter put (real[] x);
        abstract IWriter put (char[] x);
        abstract IWriter put (wchar[] x);
        abstract IWriter put (dchar[] x);

        /***********************************************************************
        
                This is the mechanism used for binding arbitrary classes 
                to the IO system. If a class implements IWritable, it can
                be used as a target for IWriter put() operations. That is, 
                implementing IWritable is intended to transform any class 
                into an IWriter adaptor for the content held therein.

        ***********************************************************************/

        abstract IWriter put (IWritable);

        /***********************************************************************
        
                Bind an IEncoder to the writer. Encoders are intended to
                be used as a conversion mechanism between various character
                representations (encodings). Each writer may be configured 
                with a distinct encoder.

        ***********************************************************************/

        abstract void setEncoder (AbstractEncoder); 

        /***********************************************************************
        
                Return the current encoder type (Type.Raw if not set)

        ***********************************************************************/

        abstract int getEncoderType ();

        /***********************************************************************

                Output a newline. Do this indirectly so that it can be 
                intercepted by subclasses.
        
        ***********************************************************************/

        abstract IWriter newline ();

        /***********************************************************************
        
                Flush the output of this writer. Throws an IOException 
                if the operation fails. These are aliases for each other.

        ***********************************************************************/

        abstract IWriter put ();
        abstract IWriter flush ();

        /***********************************************************************
        
                Return the associated buffer

        ***********************************************************************/

        abstract IBuffer getBuffer ();
}

