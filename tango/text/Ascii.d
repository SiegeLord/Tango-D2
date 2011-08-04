/*******************************************************************************

        copyright:      Copyright (c) 2006 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)

        version:        Dec 2006: Initial release

        author:         Kris

        Placeholder for a selection of ASCII utilities. These generally will
        not work with utf8, and cannot be easily extended to utf16 or utf32
        
*******************************************************************************/

module tango.text.Ascii;

version (Win32)
        {
        private extern (C) int memicmp (in char *, in char *, uint);
        private extern (C) int memcmp (in char *, in char *, uint);
        }

version (Posix)
        {
        private extern (C) int memcmp (in char *, in char *, uint);
        private extern (C) int strncasecmp (in char *, in char*, uint);
        private alias strncasecmp memicmp;
        }

/******************************************************************************

        Convert to lowercase in-place.

******************************************************************************/

char[] toLower (char[] src)
{
        foreach (ref c; src)
                 if (c>= 'A' && c <= 'Z')
                     c = cast(char)(c + 32);
        return src;
}

/******************************************************************************

        Convert to lowercase. Returns the converted content in dst.

******************************************************************************/

char[] toLower (const(char[]) src, char[] dst)
{
        assert (dst.length >= src.length);
        dst[0 .. src.length] = src [0 .. $];

        return toLower(dst [0  .. src.length]);
}

/******************************************************************************

        Convert to uppercase in-place.

******************************************************************************/

char[] toUpper (char[] src)
{
        foreach (ref c; src)
                 if (c>= 'a' && c <= 'z')
                     c = cast(char)(c - 32);
        return src;
}

/******************************************************************************

        Convert to uppercase. Returns the converted content in dst.

******************************************************************************/

char[] toUpper (const(char[]) src, char[] dst)
{
        assert (dst.length >= src.length);
        dst[0 .. src.length] = src [0 .. $];

        return toUpper(dst [0  .. src.length]);
}

/******************************************************************************

        Compare two char[] ignoring case. Returns 0 if equal
        
******************************************************************************/

size_t icompare (const(char[]) s1, const(char[]) s2)
{
        size_t len = s1.length;
        if (s2.length < len)
            len = s2.length;

        size_t result = cast(size_t)memicmp (s1.ptr, s2.ptr, cast(uint)len);

        if (result is 0)
            result = cast(int)s1.length - cast(int)s2.length;
        return result;
}


/******************************************************************************

        Compare two char[] with case. Returns 0 if equal
        
******************************************************************************/

size_t compare (const(char[]) s1, const(char[]) s2)
{
        auto len = s1.length;
        if (s2.length < len)
            len = s2.length;

        size_t result = cast(size_t)memcmp (s1.ptr, s2.ptr, cast(uint)len);

        if (result is 0)
            result = s1.length - s2.length;
        return result;
}



/******************************************************************************

        Return the index position of a text pattern within src, or
        src.length upon failure.

        This is a case-insensitive search (with thanks to Nietsnie)
        
******************************************************************************/

size_t isearch (in char[] src, in char[] pattern)
{
        enum  char[] _caseMap = 
                [ 
                '\000','\001','\002','\003','\004','\005','\006','\007',
                '\010','\011','\012','\013','\014','\015','\016','\017',
                '\020','\021','\022','\023','\024','\025','\026','\027',
                '\030','\031','\032','\033','\034','\035','\036','\037',
                '\040','\041','\042','\043','\044','\045','\046','\047',
                '\050','\051','\052','\053','\054','\055','\056','\057',
                '\060','\061','\062','\063','\064','\065','\066','\067',
                '\070','\071','\072','\073','\074','\075','\076','\077',
                '\100','\141','\142','\143','\144','\145','\146','\147',
                '\150','\151','\152','\153','\154','\155','\156','\157',
                '\160','\161','\162','\163','\164','\165','\166','\167',
                '\170','\171','\172','\133','\134','\135','\136','\137',
                '\140','\141','\142','\143','\144','\145','\146','\147',
                '\150','\151','\152','\153','\154','\155','\156','\157',
                '\160','\161','\162','\163','\164','\165','\166','\167',
                '\170','\171','\172','\173','\174','\175','\176','\177',
                '\200','\201','\202','\203','\204','\205','\206','\207',
                '\210','\211','\212','\213','\214','\215','\216','\217',
                '\220','\221','\222','\223','\224','\225','\226','\227',
                '\230','\231','\232','\233','\234','\235','\236','\237',
                '\240','\241','\242','\243','\244','\245','\246','\247',
                '\250','\251','\252','\253','\254','\255','\256','\257',
                '\260','\261','\262','\263','\264','\265','\266','\267',
                '\270','\271','\272','\273','\274','\275','\276','\277',
                '\300','\341','\342','\343','\344','\345','\346','\347',
                '\350','\351','\352','\353','\354','\355','\356','\357',
                '\360','\361','\362','\363','\364','\365','\366','\367',
                '\370','\371','\372','\333','\334','\335','\336','\337',
                '\340','\341','\342','\343','\344','\345','\346','\347',
                '\350','\351','\352','\353','\354','\355','\356','\357',
                '\360','\361','\362','\363','\364','\365','\366','\367',
                '\370','\371','\372','\373','\374','\375','\376','\377',
                ];  


        assert(src.ptr);
        assert(pattern.ptr);

        for (int i1=0, i2; i1 <= cast(int)(src.length - pattern.length); ++i1)
            {   
            for (i2=0; i2 < pattern.length; ++i2)
                 if (_caseMap[src[i1 + i2]] != _caseMap[pattern[i2]])
                     break;

            if (i2 is pattern.length)
                return i1;
            }   
        return src.length;
}



/******************************************************************************

******************************************************************************/

debug (UnitTest)
{       
        unittest
        {
        char[20] tmp;
        
        assert (toLower("1bac", tmp) == "1bac");
        assert (toLower("1BAC", tmp) == "1bac");
        assert (toUpper("1bac", tmp) == "1BAC");
        assert (toUpper("1BAC", tmp) == "1BAC");
        assert (icompare ("ABC", "abc") is 0);
        assert (icompare ("abc", "abc") is 0);
        assert (icompare ("abcd", "abc") > 0);
        assert (icompare ("abc", "abcd") < 0);
        assert (icompare ("ACC", "abc") > 0);

        assert (isearch ("ACC", "abc") is 3);
        assert (isearch ("ACC", "acc") is 0);
        assert (isearch ("aACC", "acc") is 1);
        }
}

debug (Ascii)
{
        void main() {}
}
