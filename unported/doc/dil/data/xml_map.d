/// A map of document elements and D tokens to format strings.
string[string] map = [
  "DocHead" : `<?xml version="1.0"?>`\n
              `<?xml-stylesheet href="xml.css" type="text/css"?>`\n
              "<root>\n",
  "DocEnd"  : "\n</root>",
  "SourceBegin" : "<sourcecode>",
  "SourceEnd"   : "\n</sourcecode>",
  "CompBegin"   : "<compiler>\n",
  "CompEnd"     : "</compiler>\n",
  "LexerError"  : `<error t="L">{0}({1},{2})L: {3}</error>`\n,
  "ParserError" : `<error t="P">{0}({1},{2})P: {3}</error>`\n,
  "LineNumberBegin" : `<linescolumn>`,
  "LineNumberEnd"   : `</linescolumn>`,
  "LineNumber"      : `<a xml:id="L{0}">{0}</a>`,

  // Node categories:
  "Declaration" : "d",
  "Statement"   : "s",
  "Expression"  : "e",
  "Type"        : "t",
  "Other"       : "o",

  // {0} = node category.
  // {1} = node class name: "Call", "If", "Class" etc.
  // E.g.: <d t="Struct">...</d>
  "NodeBegin" : `<{0} t="{1}">`,
  "NodeEnd"   : `</{0}>`,

  "Identifier" : "<i>{0}</i>",
  "String"     : "<sl>{0}</sl>",
  "Char"       : "<cl>{0}</cl>",
  "Number"     : "<n>{0}</n>",
  "Keyword"    : "<k>{0}</k>",

  "LineC"   : "<lc>{0}</lc>",
  "BlockC"  : "<bc>{0}</bc>",
  "NestedC" : "<nc>{0}</nc>",

  "Shebang"  : "<shebang>{0}</shebang>",
  "HLine"    : "<hl>{0}</hl>", // #line
  "Filespec" : "<fs>{0}</fs>", // #line N "filespec"
  "Newline"  : "{0}", // \n | \r | \r\n | LS | PS
  "Illegal"  : "<ill>{0}</ill>", // A character not recognized by the lexer.

  "SpecialToken" : "<st>{0}</st>", // __FILE__, __LINE__ etc.

  "("    : "<br>(</br>",
  ")"    : "<br>)</br>",
  "["    : "<br>[</br>",
  "]"    : "<br>]</br>",
  "{"    : "<br>{</br>",
  "}"    : "<br>}</br>",
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
