/**
 * An minimal implementation of the deprecated octal literals
 *
 * Copyright: Copyright (C) 2011 Pavel Sountsov.  All rights reserved.
 * License:   BSD style: $(LICENSE)
 * Authors:   Pavel Sountsov
 */ 
module tango.core.Octal;

T toOctal(T)(T decimal)
{
    T ret = 0;
    uint power = 0;
    int sign = 1;
    if(decimal < 0)
    {
        decimal = -decimal;
        sign = -1;
    }
    while(decimal > 0)
    {
        int digit = decimal % 10;
        assert(digit < 8, "Only digits [0..7] are allowed in octal literals");
        ret += digit << power;
        
        decimal /= 10;
        power += 3;
    }
    
    return ret * sign;
}

template octal(int decimal)
{
    enum octal = toOctal(decimal);
}

template octalU(uint decimal)
{
    enum octal = toOctal(decimal);
}

template octalL(long decimal)
{
    enum octal = toOctal(decimal);
}

template octalUL(ulong decimal)
{
    enum octal = toOctal(decimal);
}

debug(UnitTest)
{
    unittest
    {
        assert(octal!(764) == 500);
        assert(octal!(1) == 1);
        assert(octal!(0) == 0);
        assert(octal!(-10) == -8);
    }
}
