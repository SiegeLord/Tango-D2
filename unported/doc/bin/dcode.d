private import std.file, std.path, std.stdio;
private import std.regexp;
private import std.string;
private import std.stream;
private import std.conv;

int tabSpacing = 4;
char[] lineSep = "\n";


bool getArg(char[] prefix, char[] input, ref char[] output) {
	if (input.length >= prefix.length && input[0 .. prefix.length] == prefix) {
		output = input[prefix.length .. length];
		return true;
	}

	return false;
}


void main(char[][] args) {
	if (args.length <= 1) {
		char[] options = `
Disclaimer: All your base are belong to us !

Options:

-file=filename.d      // the input file name...
-r                    // recursive; ignores -file
-ts=integer           // number of spaces per tab; default=4
-no-line-numbers      // guess what :P
-add-template         // add the template.pre and template.post files' contents
                      // to the result
-output-dir=dir       // output directory prefix
-crlf                 // use CRLF's to separate lines


Special strings to use in template.pre and template.post:

    %file%   - file's name with extension
    %path%   - file's path
    %root%   - '../' * path.depth


Segmentation fault`;
		writefln(options.replace("%", "%%"));
		return;
	}

	char[] data;
	char[] filename;
	char[] outputDir = "";
	bool wantLineNumbers = true;
	bool addTemplate = false;
	bool recursive = false;

	foreach (arg; args) {
		char[] val;

		if (getArg("-file=", arg, val)) {
			filename = val;
    		data = cast(char[])std.file.read(filename);
		}
		else if (getArg("-r", arg, val)) {
			recursive = true;
		}
		else if (getArg("-ts=", arg, val)) {
			tabSpacing = toInt(val);
		}
		else if (getArg("-no-line-numbers", arg, val)) {
			wantLineNumbers = false;
		}
		else if (getArg("-add-template", arg, val)) {
			addTemplate = true;
		}
		else if (getArg("-output-dir=", arg, outputDir)) {
			// nothing
		}
		else if (getArg("-crlf", arg, val)) {
			lineSep = "\r\n";
		}
	}


	try {
		dKeywords1 = std.string.splitlines(cast(char[])std.file.read("keywords1.txt"));
		dKeywords2 = std.string.splitlines(cast(char[])std.file.read("keywords2.txt"));
		dKeywords3 = std.string.splitlines(cast(char[])std.file.read("keywords3.txt"));
		dKeywords4 = std.string.splitlines(cast(char[])std.file.read("keywords4.txt"));
	} catch (Exception e) {
		throw new Exception("could not read one of keywords[1-4].txt files");
	}


	char[] preTempl, postTempl;
	if (addTemplate) {
		preTempl	= cast(char[])std.file.read("template.pre").dup;
		postTempl	= cast(char[])std.file.read("template.post").dup;
	}

	if (!recursive) {
		processFile(filename, preTempl, postTempl, outputDir, wantLineNumbers);
	} else {
		foreach (char[] f; listdir("", "*")) {
			if (isfile(f) && fnmatch(f, "*.d")) {
				writefln(f);
				processFile(f, preTempl, postTempl, outputDir, wantLineNumbers);
			}
		}
	}
}


void recMkDir(char[] dir) {
	if ("" == dir) return;

	if (!std.file.exists(dir)) {
		char[] parent = getDirName(dir);
		if (parent != dir) {
			recMkDir(parent);
		} else {
			throw new Exception("Couldn't create dir '" ~ dir ~ "'");
		}

		mkdir(dir);
	}
}


void processFile(char[] filename, char[] preTempl, char[] postTempl, char[] outputDir_, bool lineNums) {
	char[] data = cast(char[])std.file.read(filename);
	if (0 == data.length) {
		throw new Exception("could not read file '" ~ filename ~ "'");
	}

	char[] outputFileName = std.path.getName(filename) ~ ".html";
	if (outputDir_.length) {
		outputFileName = std.path.join(outputDir_, outputFileName);
	}

	char[] outputDir = getDirName(outputFileName);
	recMkDir(outputDir);

	auto output = new BufferedFile(outputFileName, FileMode.OutNew);

	output.writeString(formatTemplate(preTempl, filename));

	output.writeString("<table id='dcode'>");
	output.writeString("<tr>");

	char[][] formatted = std.string.splitlines(formatTokens(tokenizeData(data)));
	if (lineNums) {
		output.writeString("<td id='lnum'><pre>");

		for (int i = 1; i <= formatted.length; ++i) {
    		output.writeString(/+"<span>" ~ +/toString(i)/+ ~ "</span>"+/ ~ lineSep);
		}

		output.writeString("</pre></td>");
	}

	output.writeString("<td id='code'><pre>");

	foreach (line; formatted) {
    	output.writeString(line ~ lineSep);
	}
    
    output.writeString("</pre></td></tr></table>");
	
	output.writeString(formatTemplate(postTempl, filename));

	output.close();
	delete output;
	
	return false;
}


char[] getRoot(char[] filename) {
	int numDirs = std.string.countchars(filename, "\\") + std.string.countchars(filename, "/");
	char[] res;
	for (int i = 0; i < numDirs; ++i) res ~= "../";
	return res;
}


char[] formatTemplate(char[] templ, char[] filename) {
	return templ	.replace("%file%", getBaseName(filename))
					.replace("%path%", getDirName(filename).replace("\\", "/"))
					//.replace("%module%", filename.replace("\\", ".").replace("/", ".")[0 .. length-2])
					.replace("%root%", getRoot(filename));
}


char[] str(...)
{
    char[] result;
    
    void putc(dchar c)
    {
        result ~= cast(char)c;
    }

    std.format.doFormat(&putc, _arguments, _argptr);
    return result;
}


private class TokenizerRule
{
    char[]      name;
    RegExp  regexp;
    
    this(char[] name, char[] regexp, char[] flags)
    {
        this.name = name;
        //writefln("tokenizer regexp: '", regexp, "'");
        char[] rule = std.regexp.sub(regexp, "&quot;", "\"");
        //writefln("tokenizer rule: '", rule, "'");
        this.regexp = new RegExp(rule, flags);
    }
}


private TokenizerRule[] readRules(char[] rulesFile=null)
{
    if (rulesFile is null) {
        rulesFile = `D.rules`;
    }


    char[]      data = cast(char[]) std.file.read(rulesFile);
    data = data.replace("\r", "");
    char[][]    lines = std.string.splitlines(data);
    
    TokenizerRule[] rules;
    
    RegExp lineSplit = new RegExp("\t+", "");
    
    foreach (char[] line; lines)
    {
        char foo[][] = lineSplit.split(line);
        
        if (foo.length < 2)     continue;
        if ("#" == foo[0])  continue;
        
        char[] flags = "";
        if (foo.length > 2)
        {
            foo[2] = std.string.strip(foo[2]);
            if ("insensitive" == foo[2]) flags = "i";
            else throw new Exception("Invalid option: `" ~ foo[2] ~ "`");
        }
        
        rules ~= new TokenizerRule(foo[0], "^" ~ std.string.strip(foo[1]), flags);
    }
    
    return rules;
}


struct SearchResult
{
    uint start;
    uint end;
    
    char[] ruleName;
};


SearchResult findBestMatch(char[] data, TokenizerRule[] rules)
{
    for (uint i = 0; i < data.length; ++i)
    {
        uint longestMatch           = 0;
        uint longestMatchIndex  = 0;
        
        int start, end;
        int startL, endL;
        
        for (uint j = 0; j < rules.length; ++j)
        {
            TokenizerRule rule = rules[j];
            
            if (0 == rule.regexp.test(data[i .. length])) continue;

            start   = rule.regexp.pmatch[0].rm_so + i;
            end     = rule.regexp.pmatch[0].rm_eo + i;
            
            if (end - start > longestMatch)
            {
                longestMatch = end - start;
                longestMatchIndex = j;
                startL = start;
                endL = end;
            }
        }
        
        if (0 != longestMatch)
        {
            SearchResult res;
            res.ruleName    = rules[longestMatchIndex].name;
            
            res.start       = startL;
            res.end         = endL; 
            
            return res;
        }
    }

    SearchResult res;
    res.start = res.end = 0;
    return res;
}


enum TokenType
{
    IDENT = 1,
    LINE,                   // #line
    NBR,                        // any number
    ESCSTR,             // e.g. \n or \x0f
    CHAR,                   // 'x'
    STRING,             // "foobar"
    WYSIWYG,            // `foobaz`
    ENDL,                   // end of line
    SPACE,                  // space or tab
    SEMICOLON,      // ;
    COMMA,              // ,
    DOT,                    // .
    COMMENT,            // any comment
    NCO,                    // INTERNAL. nested comment open
    NCC,                    // INTERNAL. nested comment close
    CURLYOPEN,      // {
    CURLYCLOSE,     // }
    ROUNDOPEN,      // (
    ROUNDCLOSE,     // )
    SQUAREOPEN,     // [
    SQUARECLOSE,    // ]
    LOR,                        // ||
    LAND,                   // &&
    OTHER,                  // other token... like +=, ^, *
    OP,
    UEOF                    // unexpected end of file
}


static TokenType[char[]] tokenMap;
static char[][TokenType] tokenMapInv;


static this()
{
    tokenMap["ident"] = TokenType.IDENT;
    tokenMap["pragma"] = TokenType.LINE;
    tokenMap["nbr"] = TokenType.NBR;
    tokenMap["escstr"] = TokenType.ESCSTR;
    tokenMap["char"] = TokenType.CHAR;
    tokenMap["string"] = TokenType.STRING;
    tokenMap["wysiwyg"] = TokenType.WYSIWYG;
    tokenMap["endl"] = TokenType.ENDL;
    tokenMap["space"] = TokenType.SPACE;
    tokenMap["semicolon"] = TokenType.SEMICOLON;
    tokenMap["comma"] = TokenType.COMMA;
    tokenMap["dot"] = TokenType.DOT;
    tokenMap["comment"] = TokenType.COMMENT;
    tokenMap["nestedCommentO"] = TokenType.NCO;
    tokenMap["nestedCommentC"] = TokenType.NCC;
    tokenMap["curlyOpen"] = TokenType.CURLYOPEN;
    tokenMap["curlyClose"] = TokenType.CURLYCLOSE;
    tokenMap["roundOpen"] = TokenType.ROUNDOPEN;
    tokenMap["roundClose"] = TokenType.ROUNDCLOSE;
    tokenMap["squareOpen"] = TokenType.SQUAREOPEN;
    tokenMap["squareClose"] = TokenType.SQUARECLOSE;
    tokenMap["lor"] = TokenType.LOR;
    tokenMap["land"] = TokenType.LAND;
    tokenMap["other"] = TokenType.OTHER;
    tokenMap["unknown"] = TokenType.OTHER;
    tokenMap["ueof"] = TokenType.UEOF;
    tokenMap["op"] = TokenType.OP;
    
    foreach(char[] key, TokenType val; tokenMap)
        tokenMapInv[val] = key;
}


struct Token
{
    TokenType   type;
    char[]          data;
    uint                line;
    char[]          file;

    // Struct 'constructor'
    static Token opCall(char[] type, char[] data, uint line, char[] file)
    {
        Token t;
        t.type = tokenMap[type];
        
        t.data = data;
        t.line = line;
        t.file = file;
        
        return t;
    }
    
    char[] asctype()
    {
        foreach (char[] k, TokenType v; tokenMap)
            if (v == type) return k;
            
         return "#err";
    }

    char[] xformType(char[] type) {
        switch (type) {
            case "char": case "string": case "wysiwyg":
                return "str";
            case "nbr":
                return "nbr";
            case "comment":
                return "com";
            case "curlyOpen": case "curlyClose": case "roundOpen": case "roundClose": case "squareOpen": case "squareClose": case "op":
                return "opr";
            
            default:
                foreach (x; dKeywords1) if (x == data) return "kw1";
                foreach (x; dKeywords2) if (x == data) return "kw2";
                foreach (x; dKeywords3) if (x == data) return "kw3";
                foreach (x; dKeywords4) if (x == data) return "kw4";
                return "";
        }
    }

    char[] xform(char[] x) {
        return x.replace("&", "&amp;")
                .replace("\\'", "&#039;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;")
				.expandtabs(tabSpacing);//.replace("  ", " &nbsp;");
    }
    
    char[] toString()
    {
		if (TokenType.SPACE == type) return xform(data);

        if (TokenType.ENDL == type) {
            return "\n";
        }

        char[] type = xformType(asctype);
        if ("" == type) {
            return xform(data);
        } else {
            return str("<span class='%s'>%s</span>", type, xform(data));
        }
    }
}


//! 'file' is given only to be passed to tokens' field 'file'
Token[] tokenize(char[] data, TokenizerRule[] rules, char[] file)
{
    Token[] result;
    uint line = 1;
    
    while (data.length)
    {
        SearchResult s = findBestMatch(data, rules);
        if (0 == s.start && 0 == s.end)
        {
            result ~= Token("unknown", data, line, file);
            break;
        }
        
        if (s.start != 0)
        {
            char[] tdata = data[0 .. s.start];
            result ~= Token("unknown", tdata, line, file);
            foreach (char c; tdata) if ('\n' == c) ++line;
        }
        
        char[] tdata = data[s.start .. s.end];
        result ~= Token(s.ruleName, tdata, line, file);
        foreach (char c; tdata) if ('\n' == c) ++line;
        
        data = data[s.end .. length];
    }
    
    return result;
}


void flattenComments(ref Token[] tokens)
{
    for (uint i = 0; i < tokens.length; ++i)
    {
        if (TokenType.NCO == tokens[i].type)
        {
            uint endOfComment = 0xffffffff;
            int depth = 1;
            inner: for (uint j = i+1; j < tokens.length; ++j)
            {
                switch (tokens[j].type)
                {
                    case TokenType.NCO: ++depth; break;
                    case TokenType.NCC:
                    {
                        if (1 == depth)
                        {
                            endOfComment = j;
                            break inner;
                        }
                        else --depth;
                        break;
                    }
                    default: break;
                }
            }

            if (0xffffffff == endOfComment)
            {
				writefln(tokens[$-5].asctype);
				writefln(tokens[$-4].asctype);
				writefln(tokens[$-3].asctype);
				writefln(tokens[$-2].asctype);
				writefln(tokens[$-1].asctype);
                throw new Exception("Parse error: End of file while searching for the end of a D-style comment");
            }
            
            for (uint j = i+1; j <= endOfComment; ++j)
                tokens[i].data ~=  tokens[j].data;
                
            tokens[i].type = TokenType.COMMENT;
                
            uint diff = endOfComment - i;
            for (uint j = i+1; j+diff < tokens.length; ++j)
            {
                tokens[j] = tokens[j+diff];
            }
            
            tokens.length = tokens.length - diff;
        }
    }
}


//! 'file' is given only to be passed to tokens' field 'file'
Token[] tokenizeData(char[] data)
{
    TokenizerRule[] rules = readRules();
    Token[] tokens = tokenize(data, rules, "memory");
    
    flattenComments(tokens);
    //removeComments(tokens);
    return tokens;
}


char[] formatTokens(Token[] tokens)
{
    char[] result;
    foreach(Token t; tokens)
    {
        result ~= t.toString();
    }
    return result;
}


char[][] dKeywords1;
char[][] dKeywords2;
char[][] dKeywords3;
char[][] dKeywords4;
