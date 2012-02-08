module tango.math.BigInt;

version(NoPhobos)
{
	
}
else
{
	pragma(msg, "tango.math.BigInt is deprecated. Please use std.bigint instead.");

	deprecated:

	public import std.bigint; 
}
