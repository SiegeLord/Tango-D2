/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module tango.net.http.HttpConst;

/*******************************************************************************

        Constants

*******************************************************************************/

struct HttpConst
{
        enum Eol = "\r\n";
}

/*******************************************************************************

        Headers are distinct types in their own right. This is because they
        are somewhat optimized via a trailing ':' character.

*******************************************************************************/

struct HttpHeaderName
{
        const(char)[] value;
}

/*******************************************************************************

        Define the traditional set of HTTP header names
        
*******************************************************************************/

struct HttpHeader
{   
        // size of both the request & response buffer (per thread)
        enum int IOBufferSize                 = 16 * 1024;

        // maximum length for POST parameters (to avoid DOS ...)
        enum int MaxPostParamSize             = 4 * 1024;

        enum HttpHeaderName Version           = {"HTTP/1.1"};
        enum HttpHeaderName TextHtml          = {"text/html"};

        enum HttpHeaderName Accept            = {"Accept:"};
        enum HttpHeaderName AcceptCharset     = {"Accept-Charset:"};
        enum HttpHeaderName AcceptEncoding    = {"Accept-Encoding:"};
        enum HttpHeaderName AcceptLanguage    = {"Accept-Language:"};
        enum HttpHeaderName AcceptRanges      = {"Accept-Ranges:"};
        enum HttpHeaderName Age               = {"Age:"};
        enum HttpHeaderName Allow             = {"Allow:"};
        enum HttpHeaderName Authorization     = {"Authorization:"};
        enum HttpHeaderName CacheControl      = {"Cache-Control:"};
        enum HttpHeaderName Connection        = {"Connection:"};
        enum HttpHeaderName ContentEncoding   = {"Content-Encoding:"};
        enum HttpHeaderName ContentLanguage   = {"Content-Language:"};
        enum HttpHeaderName ContentLength     = {"Content-Length:"};
        enum HttpHeaderName ContentLocation   = {"Content-Location:"};
        enum HttpHeaderName ContentRange      = {"Content-Range:"};
        enum HttpHeaderName ContentType       = {"Content-Type:"};
        enum HttpHeaderName Cookie            = {"Cookie:"};
        enum HttpHeaderName Date              = {"Date:"};
        enum HttpHeaderName ETag              = {"ETag:"};
        enum HttpHeaderName Expect            = {"Expect:"};
        enum HttpHeaderName Expires           = {"Expires:"};
        enum HttpHeaderName From              = {"From:"};
        enum HttpHeaderName Host              = {"Host:"};
        enum HttpHeaderName Identity          = {"Identity:"};
        enum HttpHeaderName IfMatch           = {"If-Match:"};
        enum HttpHeaderName IfModifiedSince   = {"If-Modified-Since:"};
        enum HttpHeaderName IfNoneMatch       = {"If-None-Match:"};
        enum HttpHeaderName IfRange           = {"If-Range:"};
        enum HttpHeaderName IfUnmodifiedSince = {"If-Unmodified-Since:"};
        enum HttpHeaderName KeepAlive         = {"Keep-Alive:"};
        enum HttpHeaderName LastModified      = {"Last-Modified:"};
        enum HttpHeaderName Location          = {"Location:"};
        enum HttpHeaderName MaxForwards       = {"Max-Forwards:"};
        enum HttpHeaderName MimeVersion       = {"MIME-Version:"};
        enum HttpHeaderName Pragma            = {"Pragma:"};
        enum HttpHeaderName ProxyAuthenticate = {"Proxy-Authenticate:"};
        enum HttpHeaderName ProxyConnection   = {"Proxy-Connection:"};
        enum HttpHeaderName Range             = {"Range:"};
        enum HttpHeaderName Referrer          = {"Referer:"};
        enum HttpHeaderName RetryAfter        = {"Retry-After:"};
        enum HttpHeaderName Server            = {"Server:"};
        enum HttpHeaderName ServletEngine     = {"Servlet-Engine:"};
        enum HttpHeaderName SetCookie         = {"Set-Cookie:"};
        enum HttpHeaderName SetCookie2        = {"Set-Cookie2:"};
        enum HttpHeaderName TE                = {"TE:"};
        enum HttpHeaderName Trailer           = {"Trailer:"};
        enum HttpHeaderName TransferEncoding  = {"Transfer-Encoding:"};
        enum HttpHeaderName Upgrade           = {"Upgrade:"};
        enum HttpHeaderName UserAgent         = {"User-Agent:"};
        enum HttpHeaderName Vary              = {"Vary:"};
        enum HttpHeaderName Warning           = {"Warning:"};
        enum HttpHeaderName WwwAuthenticate   = {"WWW-Authenticate:"};
}


/*******************************************************************************

        Declare the traditional set of HTTP response codes

*******************************************************************************/

enum HttpResponseCode
{       
        Continue                     = 100,
        SwitchingProtocols           = 101,
        OK                           = 200,
        Created                      = 201,
        Accepted                     = 202,
        NonAuthoritativeInformation  = 203,
        NoContent                    = 204,
        ResetContent                 = 205,
        PartialContent               = 206,
        MultipleChoices              = 300,
        MovedPermanently             = 301,
        Found                        = 302,
        SeeOther                     = 303,
        NotModified                  = 304,
        UseProxy                     = 305,
        TemporaryRedirect            = 307,
        BadRequest                   = 400,
        Unauthorized                 = 401,
        PaymentRequired              = 402,
        Forbidden                    = 403,
        NotFound                     = 404,
        MethodNotAllowed             = 405,
        NotAcceptable                = 406,
        ProxyAuthenticationRequired  = 407,
        RequestTimeout               = 408,
        Conflict                     = 409,
        Gone                         = 410,
        LengthRequired               = 411,
        PreconditionFailed           = 412,
        RequestEntityTooLarge        = 413,
        RequestURITooLarge           = 414,
        UnsupportedMediaType         = 415,
        RequestedRangeNotSatisfiable = 416,
        ExpectationFailed            = 417,
        InternalServerError          = 500,
        NotImplemented               = 501,
        BadGateway                   = 502,
        ServiceUnavailable           = 503,
        GatewayTimeout               = 504,
        VersionNotSupported          = 505,
}

/*******************************************************************************

        Status is a compound type, with a name and a code.

*******************************************************************************/

struct HttpStatus
{
        int     code; 
        const(char)[]  name;  
}

/*******************************************************************************

        Declare the traditional set of HTTP responses

*******************************************************************************/

struct HttpResponses
{       
    enum 
    {
        HttpStatus Continue          = HttpStatus(HttpResponseCode.Continue, "Continue"),
        SwitchingProtocols           = HttpStatus(HttpResponseCode.SwitchingProtocols, "SwitchingProtocols"),
        OK                           = HttpStatus(HttpResponseCode.OK, "OK"),
        Created                      = HttpStatus(HttpResponseCode.Created, "Created"),
        Accepted                     = HttpStatus(HttpResponseCode.Accepted, "Accepted"),
        NonAuthoritativeInformation  = HttpStatus(HttpResponseCode.NonAuthoritativeInformation, "NonAuthoritativeInformation"),
        NoContent                    = HttpStatus(HttpResponseCode.NoContent, "NoContent"),
        ResetContent                 = HttpStatus(HttpResponseCode.ResetContent, "ResetContent"),
        PartialContent               = HttpStatus(HttpResponseCode.PartialContent, "PartialContent"),
        MultipleChoices              = HttpStatus(HttpResponseCode.MultipleChoices, "MultipleChoices"),
        MovedPermanently             = HttpStatus(HttpResponseCode.MovedPermanently, "MovedPermanently"),
        Found                        = HttpStatus(HttpResponseCode.Found, "Found"),
        TemporaryRedirect            = HttpStatus(HttpResponseCode.TemporaryRedirect, "TemporaryRedirect"),
        SeeOther                     = HttpStatus(HttpResponseCode.SeeOther, "SeeOther"),
        NotModified                  = HttpStatus(HttpResponseCode.NotModified, "NotModified"),
        UseProxy                     = HttpStatus(HttpResponseCode.UseProxy, "UseProxy"),
        BadRequest                   = HttpStatus(HttpResponseCode.BadRequest, "BadRequest"),
        Unauthorized                 = HttpStatus(HttpResponseCode.Unauthorized, "Unauthorized"),
        PaymentRequired              = HttpStatus(HttpResponseCode.PaymentRequired, "PaymentRequired"),
        Forbidden                    = HttpStatus(HttpResponseCode.Forbidden, "Forbidden"),
        NotFound                     = HttpStatus(HttpResponseCode.NotFound, "NotFound"),
        MethodNotAllowed             = HttpStatus(HttpResponseCode.MethodNotAllowed, "MethodNotAllowed"),
        NotAcceptable                = HttpStatus(HttpResponseCode.NotAcceptable, "NotAcceptable"),
        ProxyAuthenticationRequired  = HttpStatus(HttpResponseCode.ProxyAuthenticationRequired, "ProxyAuthenticationRequired"),
        RequestTimeout               = HttpStatus(HttpResponseCode.RequestTimeout, "RequestTimeout"),
        Conflict                     = HttpStatus(HttpResponseCode.Conflict, "Conflict"),
        Gone                         = HttpStatus(HttpResponseCode.Gone, "Gone"),
        LengthRequired               = HttpStatus(HttpResponseCode.LengthRequired, "LengthRequired"),
        PreconditionFailed           = HttpStatus(HttpResponseCode.PreconditionFailed, "PreconditionFailed"),
        RequestEntityTooLarge        = HttpStatus(HttpResponseCode.RequestEntityTooLarge, "RequestEntityTooLarge"),
        RequestURITooLarge           = HttpStatus(HttpResponseCode.RequestURITooLarge, "RequestURITooLarge"),
        UnsupportedMediaType         = HttpStatus(HttpResponseCode.UnsupportedMediaType, "UnsupportedMediaType"),
        RequestedRangeNotSatisfiable = HttpStatus(HttpResponseCode.RequestedRangeNotSatisfiable, "RequestedRangeNotSatisfiable"),
        ExpectationFailed            = HttpStatus(HttpResponseCode.ExpectationFailed, "ExpectationFailed"),
        InternalServerError          = HttpStatus(HttpResponseCode.InternalServerError, "InternalServerError"),
        NotImplemented               = HttpStatus(HttpResponseCode.NotImplemented, "NotImplemented"),
        BadGateway                   = HttpStatus(HttpResponseCode.BadGateway, "BadGateway"),
        ServiceUnavailable           = HttpStatus(HttpResponseCode.ServiceUnavailable, "ServiceUnavailable"),
        GatewayTimeout               = HttpStatus(HttpResponseCode.GatewayTimeout, "GatewayTimeout"),
        VersionNotSupported          = HttpStatus(HttpResponseCode.VersionNotSupported, "VersionNotSupported"),
    }
}
