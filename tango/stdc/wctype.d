/**
 * D header file for C99.
 *
 * Copyright: Public Domain
 * License:   Public Domain
 * Authors:   Sean Kelly
 * Standards: ISO/IEC 9899:1999 (E)
 */
module tango.stdc.wctype;

private import tango.stdc.stddef;

extern (C):

int iswalnum(wint_t wc);
int iswalpha(wint_t wc);
int iswblank(wint_t wc);
int iswcntrl(wint_t wc);
int iswdigit(wint_t wc);
int iswgraph(wint_t wc);
int iswlower(wint_t wc);
int iswprint(wint_t wc);
int iswpunct(wint_t wc);
int iswspace(wint_t wc);
int iswupper(wint_t wc);
int iswxdigit(wint_t wc);

int       iswctype(wint_t wc, wctype_t desc);
wctype_t  wctype(in char* property);
wint_t    towlower(wint_t wc);
wint_t    towupper(wint_t wc);
wint_t    towctrans(wint_t wc, wctrans_t desc);
wctrans_t wctrans(in char* property);