module tango.net.pop3.Util;

private import tango.net.pop3.Pop3Client;
private import tango.text.Util;
private import tango.io.Stdout;
private import tango.stdc.ctype : isspace;
// we parse the message according to RFC822 http://www.faqs.org/rfcs/rfc822.html

/*

Return-Path: <rebol-bounce@rebol.com>
Delivered-To: 4-charles@jwavro.com
Received: (qmail 10262 invoked from network); 3 Feb 2007 08:53:35 -0600
Received: from mail.rebol.net (209.167.34.210)
  by 72.32.141.52 with SMTP; 3 Feb 2007 08:53:35 -0600
Received: from mail.rebol.net (mail.rebol.net [209.167.34.210])
        by mail.rebol.net (Postfix) with ESMTP id EA5D14232;
        Sat,  3 Feb 2007 09:53:20 -0500 (EST)
Received: with ECARTIS (v1.0.0; list rebol); Sat, 03 Feb 2007 09:53:20 -0500 (EST)
X-Original-To: rebolist@rebol.net
Delivered-To: rebolist@rebol.net
Received: from gs5.inmotionhosting.com (www.rebol.com [216.193.197.238])
        by mail.rebol.net (Postfix) with ESMTP id DA5B94239
        for <rebolist@rebol.net>; Sat,  3 Feb 2007 09:53:19 -0500 (EST)
Received: from [24.93.47.40] (port=57022 helo=ms-smtp-01.texas.rr.com)
        by gs5.inmotionhosting.com with esmtp (Exim 4.63)
        (envelope-from <charles@jwavro.com>)
        id 1HDMGX-0004Sb-IW
        for rebolist@rebol.com; Sat, 03 Feb 2007 06:53:21 -0800
Received: from [192.168.1.2] (cpe-68-206-121-134.stx.res.rr.com [68.206.121.134])
        by ms-smtp-01.texas.rr.com (8.13.6/8.13.6) with ESMTP id l13ErDXD013839
        for <rebolist@rebol.com>; Sat, 3 Feb 2007 08:53:13 -0600 (CST)
Message-ID: <45C4A1D5.6000301@jwavro.com>
Date: Sat, 03 Feb 2007 08:53:09 -0600
From: Charles <charles@jwavro.com>
User-Agent: Thunderbird 1.5.0.9 (Windows/20061207)
MIME-Version: 1.0
To: rebolist@rebol.com
Subject: [REBOL] Re: Bug in Rebol or Romano's Decompact ?
References: <NOEDJEJPNBNKDKGDCALOEEFLDNAA.anton@wilddsl.net.au>
In-Reply-To: <NOEDJEJPNBNKDKGDCALOEEFLDNAA.anton@wilddsl.net.au>
Content-type: text/plain
X-Virus-Scanned: Symantec AntiVirus Scan Engine
X-AntiAbuse: This header was added to track abuse, please include it with any abuse report
X-AntiAbuse: Primary Hostname - gs5.inmotionhosting.com
X-AntiAbuse: Original Domain - rebol.com
X-AntiAbuse: Originator/Caller UID/GID - [0 0] / [47 12]
X-AntiAbuse: Sender Address Domain - jwavro.com
X-Source:
X-Source-Args:
X-Source-Dir:
Content-Transfer-Encoding: 8bit
X-archive-position: 41591
X-ecartis-version: Ecartis v1.0.0
Sender: rebol-bounce@rebol.com
Errors-To: rebol-bounce@rebol.com
X-original-sender: charles@jwavro.com
Precedence: bulk
Reply-To: rebolist@rebol.com
X-list: rebol
X-Spam-Checker-Version: SpamAssassin 3.0.6 (2005-12-07) on
        100053-www1.letsrent.com
X-Spam-Level:
X-Spam-Status: No, score=-1.7 required=5.0 tests=AWL,BAYES_00,RCVD_BY_IP
        autolearn=ham version=3.0.6

10 bytes for an integer ?  Why so large ?

Charlie

Anton Rolls wrote:
> Ok, just multiply that number by 10, and you have an estimate
> of the number of bytes consumed by the result. :)
> Each integer, as a rebol value, consumes around 10 bytes, if
> I remember correctly. So it is a fair whack of memory.
>
> Anton.
>
>
>> I'm writing a set of unit tests for the compact-decompact functions for
>> the Rebol Library. I try to include "boundary" conditions in the tests.
>> One of the tests is: decompact [1x2147483646]. When I try this with
>> Romano's decompact Rebol goes into a tight loop that i cannot break out
>> of with escape and have to resort to ctrl-c. This happens both under
>> Core 2.6.2 and Core 2.5.6
>>
>> Is this a bug in Rebol?
>>
>> Peter
>>
>
>



--
To unsubscribe from the list, just send an email to
lists at rebol.com with unsubscribe as the subject.

*/




/** For extracting fields from a pop3 message, example usage:

      POP3Response resp = retr(1);
      char [] to = extractField("To:",resp );
      char [] subject = extractField("Subject:",resp );
      char [] from = extractField("From:",resp );
      char [] returnPath = extractField("Return-Path:",resp );

*/



// some fields are repeated more than once , so we loop through the whole message till we find an empty line,
// which represents the break for the body
char [] [] extractField(char [] headerName, POP3Response resp )
{
  char [] [] result;
  bool wrappedField = false;
  

  foreach ( line; resp.lines)
    {
      
      if ( wrappedField )
	{
	  if ( line.length )
	    {
	      if ( isspace(line[0] ) )
		{
		  result ~= line;
		  continue;
		}
	      else wrappedField = false;
	    }
	}


      if ( line.length > headerName.length )
	{
	  if (line[0 .. headerName.length ] == headerName ) // found the match
	    {

	      result ~= line[headerName.length+1 .. $];
	      wrappedField = true; // we check for wrappedFields

	    }

	}
      

    }

  return result;


}


char [] extractBody(POP3Response resp )
{

  char [] slurp = join(resp.lines,"\r\n");
  uint start = locatePattern(slurp,"\r\n\r\n");
  return slurp[start .. $ ];

}
