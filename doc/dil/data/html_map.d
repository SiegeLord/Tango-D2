/// A map of document elements and D tokens to format strings.
string[string] map = [
  "DocHead" : `<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">`\n
              `<html>`\n
              `<head>`\n
              `  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">`\n
              `  <title>{0}</title>`\n
              `  <link href="html.css" rel="stylesheet" type="text/css">`\n
              `</head>`\n
              `<body>`\n
              `<table><tr>`\n,
  "CompBegin"   : `<td><div class="compilerinfo">`\n,
  "CompEnd"     : "</div>\n</td></tr><tr>",
  "LexerError"  : `<p class="error L">{0}({1},{2})L: {3}</p>`\n,
  "ParserError" : `<p class="error P">{0}({1},{2})P: {3}</p>`\n,

  "LineNumberBegin" : `<td class="linescolumn">`,
  "LineNumberEnd"   : "</td>\n<td>",
  "LineNumber"      : `<a id="L{0}" href="#L{0}">{0}</a>`,

  "SourceBegin" : `<td><pre class="sourcecode">`\n,
  "SourceEnd"   : "\n</pre></td>",

  "DocEnd"  : "\n</tr></table>"
              "\n</body>"
              "\n</html>",

  // Node categories:
  "Declaration" : "d",
  "Statement"   : "s",
  "Expression"  : "e",
  "Type"        : "t",
  "Other"       : "o",

  // {0} = node category.
  // {1} = node class name: "Call", "If", "Class" etc.
  // E.g.: <span class="d Struct">...</d>
  "NodeBegin" : `<span class="{0} {1}">`,
  "NodeEnd"   : `</span>`,

  "Identifier" : `<span class="i">{0}</span>`,
  "String"     : `<span class="sl">{0}</span>`,
  "Char"       : `<span class="cl">{0}</span>`,
  "Number"     : `<span class="n">{0}</span>`,
  "Keyword"    : `<span class="k">{0}</span>`,

  "LineC"   : `<span class="lc">{0}</span>`,
  "BlockC"  : `<span class="bc">{0}</span>`,
  "NestedC" : `<span class="nc">{0}</span>`,

  "Shebang"  : `<span class="shebang">{0}</span>`,
  "HLine"    : `<span class="hl">{0}</span>`, // #line
  "Filespec" : `<span class="fs">{0}</span>`, // #line N "filespec"
  "Newline"  : "{0}", // \n | \r | \r\n | LS | PS
  "Illegal"  : `<span class="ill">{0}</span>`, // A character not recognized by the lexer.

  "SpecialToken" : `<span class="st">{0}</span>`, // __FILE__, __LINE__ etc.

  "("    : "(",
  ")"    : ")",
  "["    : "[",
  "]"    : "]",
  "{"    : "{",
  "}"    : "}",
  "."    : ".",
  ".."   : "..",
  "..."  : "...",
  "!<>=" : "!&lt;&gt;=", // Unordered
  "!<>"  : "!&lt;&gt;",  // UorE
  "!<="  : "!&lt;=",     // UorG
  "!<"   : "!&lt;",      // UorGorE
  "!>="  : "!&gt;=",     // UorL
  "!>"   : "!&gt;",      // UorLorE
  "<>="  : "&lt;&gt;=",  // LorEorG
  "<>"   : "&lt;&gt;",   // LorG
  "="    : "=",
  "=="   : "==",
  "!"    : "!",
  "!="   : "!=",
  "<="   : "&lt;=",
  "<"    : "&lt;",
  ">="   : "&gt;=",
  ">"    : "&gt;",
  "<<="  : "&lt;&lt;=",
  "<<"   : "&lt;&lt;",
  ">>="  : "&gt;&gt;=",
  ">>"   : "&gt;&gt;",
  ">>>=" : "&gt;&gt;&gt;=",
  ">>>"  : "&gt;&gt;&gt;",
  "|"    : "|",
  "||"   : "||",
  "|="   : "|=",
  "&"    : "&amp;",
  "&&"   : "&amp;&amp;",
  "&="   : "&amp;=",
  "+"    : "+",
  "++"   : "++",
  "+="   : "+=",
  "-"    : "-",
  "--"   : "--",
  "-="   : "-=",
  "/"    : "/",
  "/="   : "/=",
  "*"    : "*",
  "*="   : "*=",
  "%"    : "%",
  "%="   : "%=",
  "^"    : "^",
  "^="   : "^=",
  "~"    : "~",
  "~="   : "~=",
  ":"    : ":",
  ";"    : ";",
  "?"    : "?",
  ","    : ",",
  "$"    : "$",
  "EOF"  : ""
];
