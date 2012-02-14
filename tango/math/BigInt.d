module tango.math.BigInt;

pragma(msg, "tango.math.BigInt is deprecated. Please use std.bigint instead.");

version(NoPhobos)
{
	
}
else
{
	deprecated:

	public import std.bigint; 
}
