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
 * 
 * This example shows how to use traits for enums.
*******************************************************************************/

private import  tango.core.Traits,
                tango.io.Stdout;

/**
 * Defines all Animals in an enum
 */
enum Animal
{
    Dog,
    Cat,
    Kangaroo,
    Bird,
    Foobar
};

/**
 * will print the animal in string form.
 */
void magic_printf(Animal animal)
{
    foreach(index, member; AllMembersOf!(Animal)) {
        if(index == animal) {
            Stdout("You have choosen a " ~ member).newline;
            break;
        }
    }
}

/**
 *  main
 */
void main()
{
    // print a single enum member
    Animal mine = Animal.Dog;
    magic_printf(mine);                         // You have choosen a Dog
    magic_printf(Animal.Cat);                   // You have choosen a Cat
    
    // print all members
    Stdout("There are a: ");
    Stdout(AllMembersOf!(Animal)).newline;      // There are a: Dog, Cat, Kangaroo, Bird, Foobar
}
