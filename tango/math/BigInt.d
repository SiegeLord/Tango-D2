deprecated("tango.math.BigInt is deprecated. Please use std.bigint instead.") module tango.math.BigInt;

version(NoPhobos)
{

}
else
{
	public import std.bigint;
}
