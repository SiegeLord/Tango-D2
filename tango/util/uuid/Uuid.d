/**
 * A UUID is a Universally Unique Identifier.
 * It is a 128-bit number generated either randomly or according to some
 * inscrutable algorithm, depending on the UUID version used.
 *
 * Here, we implement a data structure for holding and formatting UUIDs.
 * To generate a UUID, use one of the other modules in the UUID package.
 * You can also create a UUID by parsing a string containing a textual
 * representation of a UUID, or by providing the constituent bytes.
 */
module tango.util.uuid.Uuid;

import tango.core.Exception;
import Integer = tango.text.convert.Integer;

private union UuidData
{
        uint[4] ui;
        ubyte[16] ub;
} 

/** This struct represents a UUID. It offers static members for creating and
 * parsing UUIDs.
 * 
 * This struct treats a UUID as an opaque type. The specification has fields
 * for time, version, client MAC address, and several other data points, but
 * these are meaningless for most applications and means of generating a UUID.
 *
 * There are versions of UUID generation involving the system time and MAC 
 * address. These are not used for several reasons:
 *      - One version contains identifying information, which is undesirable.
 *      - Ensuring uniqueness between processes requires inter-process 
 *              communication. This would be unreasonably slow and complex.
 *      - Obtaining the MAC address is a system-dependent operation and beyond
 *              the scope of this module.
 *      - Using Java and .NET as a guide, they only implement randomized creation
 *              of UUIDs, not the MAC address/time based generation.
 *
 * When generating a random UUID, use a carefully seeded random number 
 * generator. A poorly chosen seed may produce undesirably consistent results.
 */
struct Uuid
{
        private UuidData _data;

        /** Copy the givent bytes into a UUID. If you supply more or fewer than
          * 16 bytes, throws an IllegalArgumentException. */
        public static Uuid opCall(const(ubyte[]) data)
        {
                if (data.length != 16)
                {
                        throw new IllegalArgumentException("A UUID is 16 bytes long.");
                }
                Uuid u;
                u._data.ub[] = data[];
                return u;
        }

        /** Attempt to parse the representation of a UUID given in value. If the
          * value is not in the correct format, throw IllegalArgumentException.
          * If the value is in the correct format, return a UUID representing the
          * given value. 
          *
          * The following is an example of a UUID in the expected format:
          *     67e55044-10b1-426f-9247-bb680e5fe0c8 
          */
        public static Uuid parse(const(char[]) value)
        {
                Uuid u;
                if (!tryParse(value, u))
                        throw new IllegalArgumentException("'" ~ value.idup ~ "' is not in the correct format for a UUID");
                return u;
        }

        /** Attempt to parse the representation of a UUID given in value. If the
          * value is not in the correct format, return false rather than throwing
          * an exception. If the value is in the correct format, set uuid to 
          * represent the given value. 
          *
          * The following is an example of a UUID in the expected format:
          *     67e55044-10b1-426f-9247-bb680e5fe0c8 
          */
        public static bool tryParse(const(char[]) value, out Uuid uuid)
        {
                if (value.length != 36 ||
                        value[8] != '-' ||
                        value[13] != '-' ||
                        value[18] != '-' ||
                        value[23] != '-')
                {
                        return false;
                }
                int hyphens = 0;
                foreach (i, v; value)
                {
                        if ('a' <= v && 'f' >= v) continue;
                        if ('A' <= v && 'F' >= v) continue;
                        if ('0' <= v && '9' >= v) continue;
                        if (v == '-') 
                        {
                                hyphens++;
                                continue;
                        }
                        // illegal character
                        return false;
                }
                if (hyphens != 4) 
                {
                        return false;
                }

                with (uuid._data)
                {
                        // This is verbose, but it's simple, and it gets around endian
                        // issues if you try parsing an integer at a time.
                        ub[0] = cast(ubyte) Integer.parse(value[0..2], 16);
                        ub[1] = cast(ubyte) Integer.parse(value[2..4], 16);
                        ub[2] = cast(ubyte) Integer.parse(value[4..6], 16);
                        ub[3] = cast(ubyte) Integer.parse(value[6..8], 16);

                        ub[4] = cast(ubyte) Integer.parse(value[9..11], 16);
                        ub[5] = cast(ubyte) Integer.parse(value[11..13], 16);

                        ub[6] = cast(ubyte) Integer.parse(value[14..16], 16);
                        ub[7] = cast(ubyte) Integer.parse(value[16..18], 16);

                        ub[8] = cast(ubyte) Integer.parse(value[19..21], 16);
                        ub[9] = cast(ubyte) Integer.parse(value[21..23], 16);

                        ub[10] = cast(ubyte) Integer.parse(value[24..26], 16);
                        ub[11] = cast(ubyte) Integer.parse(value[26..28], 16);
                        ub[12] = cast(ubyte) Integer.parse(value[28..30], 16);
                        ub[13] = cast(ubyte) Integer.parse(value[30..32], 16);
                        ub[14] = cast(ubyte) Integer.parse(value[32..34], 16);
                        ub[15] = cast(ubyte) Integer.parse(value[34..36], 16);
                }

                return true;
        }
        
        /** Generate a UUID based on the given random number generator.
          * The generator must have a method 'uint natural()' that returns
          * a random number. The generated UUID conforms to version 4 of the
          * specification. */
        public static Uuid random(Random)(Random generator)
        {
                Uuid u;
                with (u)
                {
                        _data.ui[0] = generator.natural();
                        _data.ui[1] = generator.natural();
                        _data.ui[2] = generator.natural();
                        _data.ui[3] = generator.natural();

                        // v4: 7th bytes' first half is 0b0100: 4 in hex
                        _data.ub[6] &= 0b01001111;
                        _data.ub[6] |= 0b01000000;

                        // v4: 9th byte's 1st half is 0b1000 to 0b1011: 8, 9, A, B in hex
                        _data.ub[8] &= 0b10111111;
                        _data.ub[8] |= 0b10000000;
                }
                return u;
        }

        /* Generate a UUID based on the given namespace and name. This conforms to 
         * versions 3 and 5 of the standard -- version 3 if you use MD5, or version
         * 5 if you use SHA1.
         *
         * You should pass 3 as the value for uuidVersion if you are using the
         * MD5 hash, and 5 if you are using the SHA1 hash. To do otherwise is an
         * Abomination Unto Nuggan.
         *
         * This method is exposed mainly for the convenience methods in 
         * tango.util.uuid.*. You can use this method directly if you prefer.
         */
        public static Uuid byName(Digest)(Uuid namespace, const(char[]) name, Digest digest,
                                                                              ubyte uuidVersion)
        {
                /* o  Compute the hash of the name space ID concatenated with the name.
                   o  Set octets zero through 15 to octets zero through 15 of the hash.
                   o  Set the four most significant bits (bits 12 through 15) of octet
                          6 to the appropriate 4-bit version number from Section 4.1.3.
                   o  Set the two most significant bits (bits 6 and 7) of octet 8 to 
                          zero and one, respectively.  */
                auto nameBytes = namespace.toBytes();
                nameBytes ~= cast(ubyte[])name;
                digest.update(nameBytes);
                nameBytes = digest.binaryDigest();
                nameBytes[6] = cast(ubyte)((uuidVersion << 4) | (nameBytes[6] & 0b1111));
                nameBytes[8] |= 0b1000_0000;
                nameBytes[8] &= 0b1011_1111;
                return Uuid(nameBytes[0..16]);
        }

        /** Return an empty UUID (with all bits set to 0). This doesn't conform
          * to any particular version of the specification. It's equivalent to
          * using an uninitialized UUID. This method is provided for clarity. */
        @property public static Uuid empty()
        {
                Uuid uuid;
                uuid._data.ui[] = 0;
                return uuid;
        }

        /** Get a copy of this UUID's value as an array of unsigned bytes. */
        public const ubyte[] toBytes()
        {
                return _data.ub.dup;
        }

        /** Gets the version of this UUID. 
          * RFC 4122 defines five types of UUIDs:
          *     -       Version 1 is based on the system's MAC address and the current time.
          *     -       Version 2 uses the current user's userid and user domain in 
          *                     addition to the time and MAC address.
          * -   Version 3 is namespace-based, as generated by the NamespaceGenV3
          *                     module. It uses MD5 as a hash algorithm. RFC 4122 states that
          *                     version 5 is preferred over version 3.
          * -   Version 4 is generated randomly.
          * -   Version 5 is like version 3, but uses SHA-1 rather than MD5. Use
          *                     the NamespaceGenV5 module to create UUIDs like this.
          *
          * The following additional versions exist:
          * -   Version 0 is reserved for backwards compatibility.
          * -   Version 6 is a non-standard Microsoft extension.
          * -   Version 7 is reserved for future use.
          */
        public const ubyte format()
        {
                return cast(ubyte) (_data.ub[6] >> 4);
        }

        /** Get the canonical string representation of a UUID.
          * The canonical representation is in hexidecimal, with hyphens inserted
          * after the eighth, twelfth, sixteenth, and twentieth digits. For example:
          *     67e55044-10b1-426f-9247-bb680e5fe0c8
          * This is the format used by the parsing functions.
          */
        public const(char[]) toString()
        {
                // Look, only one allocation.
                char[] buf = new char[36];
                buf[8] = '-';
                buf[13] = '-';
                buf[18] = '-';
                buf[23] = '-';
                with (_data)
                {
                        // See above with tryParse: this ignores endianness.
                        // Technically, it's sufficient that the conversion to string
                        // matches the conversion from string and from byte array. But
                        // this is the simplest way to make sure of that. Plus you can
                        // serialize and deserialize on machines with different endianness
                        // without a bunch of strange conversions, and with consistent
                        // string representations.
                        Integer.format(buf[0..2], ub[0], "x2");
                        Integer.format(buf[2..4], ub[1], "x2");
                        Integer.format(buf[4..6], ub[2], "x2");
                        Integer.format(buf[6..8], ub[3], "x2");
                        Integer.format(buf[9..11], ub[4], "x2");
                        Integer.format(buf[11..13], ub[5], "x2");
                        Integer.format(buf[14..16], ub[6], "x2");
                        Integer.format(buf[16..18], ub[7], "x2");
                        Integer.format(buf[19..21], ub[8], "x2");
                        Integer.format(buf[21..23], ub[9], "x2");
                        Integer.format(buf[24..26], ub[10], "x2");
                        Integer.format(buf[26..28], ub[11], "x2");
                        Integer.format(buf[28..30], ub[12], "x2");
                        Integer.format(buf[30..32], ub[13], "x2");
                        Integer.format(buf[32..34], ub[14], "x2");
                        Integer.format(buf[34..36], ub[15], "x2");
                }
                return buf;
        }

        /** Determines if this UUID has the same value as another. */
        public const bool opEquals(ref const(Uuid) other)
        {
                return 
                        _data.ui[0] == other._data.ui[0] &&
                        _data.ui[1] == other._data.ui[1] &&
                        _data.ui[2] == other._data.ui[2] &&
                        _data.ui[3] == other._data.ui[3];
        }

        /** Get a hash code representing this UUID. */
        public const hash_t toHash() nothrow @safe
        {
                with (_data)
                {
                        // 29 is just a convenient prime number
                        return (((((ui[0] * 29) ^ ui[1]) * 29) ^ ui[2]) * 29) ^ ui[3];
                }
        }
}


debug (UnitTest)
{
        import tango.math.random.Kiss;
        unittest
        {
                // Generate them in the correct format
                for (int i = 0; i < 20; i++)
                {
                        auto uu = Uuid.random(&Kiss.instance).toString();
                        auto c = uu[19];
                        assert (c == '9' || c == '8' || c == 'a' || c == 'b', uu);
                        auto d = uu[14];
                        assert (d == '4', uu);
                }

                // empty
                assert (Uuid.empty.toString() == "00000000-0000-0000-0000-000000000000", Uuid.empty.toString());

                ubyte[] bytes = [0x6b, 0xa7, 0xb8, 0x10, 0x9d, 0xad, 0x11, 0xd1, 
                                          0x80, 0xb4, 0x00, 0xc0, 0x4f, 0xd4, 0x30, 0xc8];
                Uuid u = Uuid(bytes.dup);
                auto str = "64f2ad82-5182-4c6a-ade5-59728ca0567b";
                auto u2 = Uuid.parse(str);

                // toString
                assert (Uuid(bytes) == u);
                assert (u2 != u);

                assert (u2.format() == 4);

                // tryParse
                Uuid u3;
                assert (Uuid.tryParse(str, u3));
                assert (u3 == u2);
        }

        unittest
        {
                Uuid fail;
                // contains 'r'
                assert (!Uuid.tryParse("fecr0a9b-4d5a-439e-8e4b-9d087ff49ba7", fail));
                // too short
                assert (!Uuid.tryParse("fec70a9b-4d5a-439e-8e4b-9d087ff49ba", fail));
                // hyphens matter
                assert (!Uuid.tryParse("fec70a9b 4d5a-439e-8e4b-9d087ff49ba7", fail));
                // hyphens matter (2)
                assert (!Uuid.tryParse("fec70a9b-4d5a-439e-8e4b-9d08-7ff49ba7", fail));
                // hyphens matter (3)
                assert (!Uuid.tryParse("fec70a9b-4d5a-439e-8e4b-9d08-ff49ba7", fail));
        }

        unittest
        {
                // contains 'r'
                try 
                {
                        Uuid.parse("fecr0a9b-4d5a-439e-8e4b-9d087ff49ba7"); assert (false);
                }
                catch (IllegalArgumentException) {}

                // too short
                try 
                {
                        Uuid.parse("fec70a9b-4d5a-439e-8e4b-9d087ff49ba"); assert (false);
                }
                catch (IllegalArgumentException) {}

                // hyphens matter
                try 
                {
                        Uuid.parse("fec70a9b 4d5a-439e-8e4b-9d087ff49ba7"); assert (false);
                }
                catch (IllegalArgumentException) {}

                // hyphens matter (2)
                try 
                {
                        Uuid.parse("fec70a9b-4d5a-439e-8e4b-9d08-7ff49ba7"); assert (false);
                }
                catch (IllegalArgumentException) {}

                // hyphens matter (3)
                try 
                {
                        Uuid.parse("fec70a9b-4d5a-439e-8e4b-9d08-ff49ba7"); assert (false);
                }
                catch (IllegalArgumentException) {}
        }

        import tango.util.digest.Sha1;
        unittest
        {
                auto namespace = Uuid.parse("15288517-c402-4057-9fc5-05711726df41");
                auto name = "hello";
                // This was generated with the uuid utility on linux/amd64. It might have different results on
                // a ppc processor -- the spec says something about network byte order, but it's using an array
                // of bytes at that point, so converting to NBO is a noop...
                auto expected = Uuid.parse("2b1c6704-a43f-5d43-9abb-b13310b4458a");
                auto generated = Uuid.byName(namespace, name, new Sha1, cast(ubyte)5);
                assert (generated == expected, "\nexpected: " ~ expected.toString() ~ "\nbut was:  " ~ generated.toString());
        }
        
        import tango.util.digest.Md5;
        unittest
        {
                auto namespace = Uuid.parse("15288517-c402-4057-9fc5-05711726df41");
                auto name = "hello";
                auto expected = Uuid.parse("31a2b702-85a8-349a-9b0e-213b1bd753b8");
                auto generated = Uuid.byName(namespace, name, new Md5, cast(ubyte)3);
                assert (generated == expected, "\nexpected: " ~ expected.toString() ~ "\nbut was:  " ~ generated.toString());
        }
        //void main(){}
}

/** A base interface for any UUID generator for UUIDs. That is,
  * this interface is specified so that you write your code dependent on a
  * UUID generator that takes an arbitrary random source, and easily switch
  * to a different random source. Since the default uses KISS, if you find
  * yourself needing more secure random numbers, you could trivially switch 
  * your code to use the Mersenne twister, or some other PRNG.
  *
  * You could also, if you wish, use this to switch to deterministic UUID
  * generation, if your needs require it.
  */
interface UuidGen
{
        Uuid next();
}

/** Given a random number generator conforming to Tango's standard random
  * interface, this will generate random UUIDs according to version 4 of
  * RFC 4122. */
class RandomGen(TRandom) : UuidGen
{
        TRandom random;
        this (TRandom random)
        {
                this.random = random;
        }

        Uuid next()
        {
                return Uuid.random(random);
        }
}

