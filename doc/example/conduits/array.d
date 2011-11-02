/*******************************************************************************
 * 
 *      copyright:      Copyright (c) 2011 mta`chrono. All rights reserved
 *
 *      license:        BSD style: $(LICENSE)
 * 
 *      version         Okt 2011: Initial release
 * 
 *      author          mta`chrono
 * 
 * This file is part of the tango software library. Distributed under the terms
 * of the Boost Software License, Version 1.0. See LICENSE.TXT for more info.
 *******************************************************************************/
private import  tango.io.Stdout,
                tango.io.device.Array;

void main()
{
    // ------ Example 1 ------------------------------------------------------------
    
    // create a buffer
    auto buffer = new Array(256);
    
    // write some text to it
    buffer.write("hello");
    buffer.write("_");
    buffer.write("world!");
    
    // copy all to stdout
    Stdout.copy(buffer);        // hello_world!
    Stdout.newline;
    
    // set to the beginning
    buffer.seek(0);
    
    // read to foobar
    char[] foobar = new char[100];
    size_t bytes = buffer.read(foobar);     // bytes: 12 and foobar: Hello__World!
    Stdout.formatln("Read {} bytes from buffer: {}", bytes, foobar[0..bytes]);
    
    // delete buffer
    delete buffer;
    
    // ------ Example 2 ------------------------------------------------------------
    
    // create a __very small__ buffer
    buffer = new Array(10);
    
    // write more than 10 bytes
    buffer.write("I'm writing 34 bytes to the buffer");     // will write nothing!
    
    // how to check if write failes
    if(buffer.write("Is this too much for you?") == Array.Eof)  // will be true
        Stdout("Yes it's too much").newline;
    
    // wirte 10 bytes
    buffer.write("1234567890");     // this will work
    
    // copy 3 bytes to Stdout
    Stdout.copy(buffer, 3);         // prints 123
    Stdout.newline;
    
    // write 3 bytes
    buffer.write("abc");            // this will not work!
    buffer.seek(0);                 // go to begin
    buffer.write("abc");            // this will work
    
    // print all
    Stdout.copy(buffer);
    Stdout.newline;
}
