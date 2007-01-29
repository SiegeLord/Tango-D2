/*******************************************************************************

        copyright:      Copyright (c) 2004 Kris Bell. All rights reserved

        license:        BSD style: $(LICENSE)
        
        version:        Initial release: April 2004      
        
        author:         Kris

*******************************************************************************/

module tango.net.http.model.HttpConst;

/*******************************************************************************

        Constants

*******************************************************************************/

struct HttpConst
{
        const char[] Eol = "\r\n";
}

/*******************************************************************************

        Headers are distinct types in their own right. This is because they
        are somewhat optimized via a trailing ':' character.

*******************************************************************************/

struct HttpHeaderName
{
        char[]     value;  
}

/*******************************************************************************

        Define the traditional set of HTTP header names
        
*******************************************************************************/

struct HttpHeader
{   
        // size of both the request & response buffer (per thread)
        static const int IOBufferSize                 = 16 * 1024;

        // maximum length for POST parameters (to avoid DOS ...)
        static const int MaxPostParamSize             = 4 * 1024;

        static const HttpHeaderName Version           = {"HTTP/1.0"};
        static const HttpHeaderName TextHtml          = {"text/html"};

        static const HttpHeaderName Accept            = {"Accept:"};
        static const HttpHeaderName AcceptCharset     = {"Accept-Charset:"};
        static const HttpHeaderName AcceptEncoding    = {"Accept-Encoding:"};
        static const HttpHeaderName AcceptLanguage    = {"Accept-Language:"};
        static const HttpHeaderName AcceptRanges      = {"Accept-Ranges:"};
        static const HttpHeaderName Age               = {"Age:"};
        static const HttpHeaderName Allow             = {"Allow:"};
        static const HttpHeaderName Authorization     = {"Authorization:"};
        static const HttpHeaderName CacheControl      = {"Cache-Control:"};
        static const HttpHeaderName Connection        = {"Connection:"};
        static const HttpHeaderName ContentEncoding   = {"Content-Encoding:"};
        static const HttpHeaderName ContentLanguage   = {"Content-Language:"};
        static const HttpHeaderName ContentLength     = {"Content-Length:"};
        static const HttpHeaderName ContentLocation   = {"Content-Location:"};
        static const HttpHeaderName ContentRange      = {"Content-Range:"};
        static const HttpHeaderName ContentType       = {"Content-Type:"};
        static const HttpHeaderName Cookie            = {"Cookie:"};
        static const HttpHeaderName Date              = {"Date:"};
        static const HttpHeaderName ETag              = {"ETag:"};
        static const HttpHeaderName Expect            = {"Expect:"};
        static const HttpHeaderName Expires           = {"Expires:"};
        static const HttpHeaderName From              = {"From:"};
        static const HttpHeaderName Host              = {"Host:"};
        static const HttpHeaderName Identity          = {"Identity:"};
        static const HttpHeaderName IfMatch           = {"If-Match:"};
        static const HttpHeaderName IfModifiedSince   = {"If-Modified-Since:"};
        static const HttpHeaderName IfNoneMatch       = {"If-None-Match:"};
        static const HttpHeaderName IfRange           = {"If-Range:"};
        static const HttpHeaderName IfUnmodifiedSince = {"If-Unmodified-Since:"};
        static const HttpHeaderName LastModified      = {"Last-Modified:"};
        static const HttpHeaderName Location          = {"Location:"};
        static const HttpHeaderName MaxForwards       = {"Max-Forwards:"};
        static const HttpHeaderName MimeVersion       = {"MIME-Version:"};
        static const HttpHeaderName Pragma            = {"Pragma:"};
        static const HttpHeaderName ProxyAuthenticate = {"Proxy-Authenticate:"};
        static const HttpHeaderName ProxyConnection   = {"Proxy-Connection:"};
        static const HttpHeaderName Range             = {"Range:"};
        static const HttpHeaderName Referrer          = {"Referer:"};
        static const HttpHeaderName RetryAfter        = {"Retry-After:"};
        static const HttpHeaderName Server            = {"Server:"};
        static const HttpHeaderName ServletEngine     = {"Servlet-Engine:"};
        static const HttpHeaderName SetCookie         = {"Set-Cookie:"};
        static const HttpHeaderName SetCookie2        = {"Set-Cookie2:"};
        static const HttpHeaderName TE                = {"TE:"};
        static const HttpHeaderName Trailer           = {"Trailer:"};
        static const HttpHeaderName TransferEncoding  = {"Transfer-Encoding:"};
        static const HttpHeaderName Upgrade           = {"Upgrade:"};
        static const HttpHeaderName UserAgent         = {"User-Agent:"};
        static const HttpHeaderName Vary              = {"Vary:"};
        static const HttpHeaderName Warning           = {"Warning:"};
        static const HttpHeaderName WwwAuthenticate   = {"WWW-Authenticate:"};
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
        MovedTemporarily             = 302,
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
};

/*******************************************************************************

        Status is a compound type, with a name and a code.

*******************************************************************************/

struct HttpStatus
{
        int     code; 
        char[]  name;  
}

/*******************************************************************************

        Declare the traditional set of HTTP responses

*******************************************************************************/

struct HttpResponses
{       
        static final HttpStatus Continue                     = {HttpResponseCode.Continue, "Continue"};
        static final HttpStatus SwitchingProtocols           = {HttpResponseCode.SwitchingProtocols, "SwitchingProtocols"};
        static final HttpStatus OK                           = {HttpResponseCode.OK, "OK"};
        static final HttpStatus Created                      = {HttpResponseCode.Created, "Created"};
        static final HttpStatus Accepted                     = {HttpResponseCode.Accepted, "Accepted"};
        static final HttpStatus NonAuthoritativeInformation  = {HttpResponseCode.NonAuthoritativeInformation, "NonAuthoritativeInformation"};
        static final HttpStatus NoContent                    = {HttpResponseCode.NoContent, "NoContent"};
        static final HttpStatus ResetContent                 = {HttpResponseCode.ResetContent, "ResetContent"};
        static final HttpStatus PartialContent               = {HttpResponseCode.PartialContent, "PartialContent"};
        static final HttpStatus MultipleChoices              = {HttpResponseCode.MultipleChoices, "MultipleChoices"};
        static final HttpStatus MovedPermanently             = {HttpResponseCode.MovedPermanently, "MovedPermanently"};
        static final HttpStatus MovedTemporarily             = {HttpResponseCode.MovedTemporarily, "MovedTemporarily"};
        static final HttpStatus SeeOther                     = {HttpResponseCode.SeeOther, "SeeOther"};
        static final HttpStatus NotModified                  = {HttpResponseCode.NotModified, "NotModified"};
        static final HttpStatus UseProxy                     = {HttpResponseCode.UseProxy, "UseProxy"};
        static final HttpStatus BadRequest                   = {HttpResponseCode.BadRequest, "BadRequest"};
        static final HttpStatus Unauthorized                 = {HttpResponseCode.Unauthorized, "Unauthorized"};
        static final HttpStatus PaymentRequired              = {HttpResponseCode.PaymentRequired, "PaymentRequired"};
        static final HttpStatus Forbidden                    = {HttpResponseCode.Forbidden, "Forbidden"};
        static final HttpStatus NotFound                     = {HttpResponseCode.NotFound, "NotFound"};
        static final HttpStatus MethodNotAllowed             = {HttpResponseCode.MethodNotAllowed, "MethodNotAllowed"};
        static final HttpStatus NotAcceptable                = {HttpResponseCode.NotAcceptable, "NotAcceptable"};
        static final HttpStatus ProxyAuthenticationRequired  = {HttpResponseCode.ProxyAuthenticationRequired, "ProxyAuthenticationRequired"};
        static final HttpStatus RequestTimeout               = {HttpResponseCode.RequestTimeout, "RequestTimeout"};
        static final HttpStatus Conflict                     = {HttpResponseCode.Conflict, "Conflict"};
        static final HttpStatus Gone                         = {HttpResponseCode.Gone, "Gone"};
        static final HttpStatus LengthRequired               = {HttpResponseCode.LengthRequired, "LengthRequired"};
        static final HttpStatus PreconditionFailed           = {HttpResponseCode.PreconditionFailed, "PreconditionFailed"};
        static final HttpStatus RequestEntityTooLarge        = {HttpResponseCode.RequestEntityTooLarge, "RequestEntityTooLarge"};
        static final HttpStatus RequestURITooLarge           = {HttpResponseCode.RequestURITooLarge, "RequestURITooLarge"};
        static final HttpStatus UnsupportedMediaType         = {HttpResponseCode.UnsupportedMediaType, "UnsupportedMediaType"};
        static final HttpStatus RequestedRangeNotSatisfiable = {HttpResponseCode.RequestedRangeNotSatisfiable, "RequestedRangeNotSatisfiable"};
        static final HttpStatus ExpectationFailed            = {HttpResponseCode.ExpectationFailed, "ExpectationFailed"};
        static final HttpStatus InternalServerError          = {HttpResponseCode.InternalServerError, "InternalServerError"};
        static final HttpStatus NotImplemented               = {HttpResponseCode.NotImplemented, "NotImplemented"};
        static final HttpStatus BadGateway                   = {HttpResponseCode.BadGateway, "BadGateway"};
        static final HttpStatus ServiceUnavailable           = {HttpResponseCode.ServiceUnavailable, "ServiceUnavailable"};
        static final HttpStatus GatewayTimeout               = {HttpResponseCode.GatewayTimeout, "GatewayTimeout"};
        static final HttpStatus VersionNotSupported          = {HttpResponseCode.VersionNotSupported, "VersionNotSupported"};
}


