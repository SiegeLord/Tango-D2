import std.stream;
import std.stdio;
import std.path;
import std.regexp;

const char[] DIMPLE_VERSION = "0.13";

/* dimple, D import-list explorer
 *
 * Copyright (c) 2005 by Wang Zhen
 * All Rights Reserved
 * Webpage: http://www.shfls.org/w/d/dimple/
 *
 * See GNU General Public License for terms of use.
 */

class ProducerExhausted : Exception{ this(){ super(""); } }

interface IProducer(T){	T next(); }

alias IProducer!(char) ICharProducer;

class FileCharStream : ICharProducer{
	this(char[] filename){
		_file = new BufferedFile(filename);
	}
	char next(){
		if(_file.eof())
			throw new ProducerExhausted;
		else
			return _file.getc();
	}
private:
	BufferedFile _file;
}

class CommentFilter : ICharProducer{
//todo: /+ nested /+ comment +/ +/
//todo: r"wysiwyg string literal"
	this(ICharProducer parent){
		_parent = parent;
		_state = STATE.echo;
		_cached = false;
	}
	char next(){		
		static char c;
		if(_cached){
			_cached = false;
			return c;
		}
		for(;;){
			c = _parent.next();
			if(c=='\r')
				continue;
			
			switch(_state){
			case STATE.echo:
				switch(c){
				case '/': _state = STATE.slash;	continue;
				case '"': _state = STATE.dquote; break;
				case '\'': _state = STATE.squote; break;
				case '`': _state = STATE.aquote; break;
				default:
				}
				break;
			case STATE.aquote:
				if(c=='`')
					_state = STATE.echo;
				break;
			case STATE.sqescape:
				_state = STATE.squote;
				break;
			case STATE.squote:
				switch(c){
				case '\'': _state = STATE.echo; break;
				case '\\': _state = STATE.sqescape; break;
				default:
				}
				break;
			case STATE.dquote:
				switch(c){
				case '"': _state = STATE.echo; break;
				case '\\': _state = STATE.dqescape; break;
				default:
				}
				break;
			case STATE.dqescape:
				_state = STATE.dquote;
				break;
			case STATE.slash:
				switch(c){
				case '/': _state = STATE.linecomment; continue;
				case '*': _state = STATE.blockcomment; return ' ';
				default: _state = STATE.echo; _cached = true; return '/';
				}
			case STATE.linecomment:
				if(c!='\n')
					continue;
				_state = STATE.echo;
				break;
			case STATE.blockcomment:
				switch(c){
				case '\n': return c;
				case '*': _state = STATE.star;
				default: continue;
				}
			case STATE.star:
				switch(c){
				case '\n': return c;
				case '/': _state = STATE.echo;
				default: continue;
				}
			}			
			return c;			
		}
	}
private:
	ICharProducer _parent;
	
	enum STATE { echo, slash, linecomment, blockcomment, star,
				dquote, dqescape, squote, sqescape, aquote,};
	STATE _state;
	bit _cached;
}

//kludge: simplified lexer
class Token{
	this(char[] text){
		_text = text;
	}
	char[] toString(){
		return _text;
	}
private:
	//int _type;
	char[] _text;
}

alias IProducer!(Token) ITokenProducer;

class TokenStream : ITokenProducer{
//todo: r"wysiwyg string literal"
	this(ICharProducer parent){
		_parent = parent;
	}
	Token next(){
		char[] t;
		static char c = ' ';
		bit isws(char c){
			return c==' '||c=='\n'||c=='\t';
		}
		while(isws(c))
			c = _parent.next();
			
		switch(c){
		case ';': c=' '; return new Token(";");
		case ',': c=' '; return new Token(",");
		case '"':
			t ~= c;
			L1: for(;;){					
					t ~= c = _parent.next();
					switch(c){
					case '"': c = ' '; break L1;
					case '\\': t ~= c = _parent.next();
					default:
					}
				}
			break;
		case '\'':
			t ~= c;
			L2: for(;;){					
					t ~= c = _parent.next();
					switch(c){
					case '\'': c = ' '; break L2;
					case '\\': t ~= c= _parent.next();
					default:
					}
				}
			break;
		case '`':
			t ~= c;
			for(;;){
				t ~= c = _parent.next();
				if(c=='`'){
					c = ' ';
					break;
				}
			}
			break;
		default:
			try{					
			L0: for(;;){
					t ~= c;
					c = _parent.next();
					switch(c){
					case ' ':
					case '\t':
					case '\n':
					case ';':
					case ',':
						break L0;
					default:
					}
				}
			}catch(ProducerExhausted){
				c = ' ';
			}
			break;			
		}		
		return new Token(t);		
	}
private:
	ICharProducer _parent;
}

alias IProducer!(char[]) IStringProducer;

class ImportList : IStringProducer{
	this(ITokenProducer parent){
		_parent = parent;
		_state = STATE.imp;
	}
	char[] next(){
		Token t;
		for(;;){
			switch(_state){
			case STATE.imp:
				while((t=_parent.next()).toString()!="import"){}
				_state = STATE.mod;
				break;
			case STATE.mod:
				if((t=_parent.next()).toString()==";"){
					_state = STATE.imp;
					continue;
				}
			}
			return _parent.next().toString();
		}
	}
private:
	ITokenProducer _parent;
	enum STATE { imp, mod, }
	STATE _state;
}

class Source{
	this(char[] modulename){
		_modulename = modulename;
		_visible = false;
	}
	char[] modulename(){ return _modulename; }
	char[] pathname(){
		char[] result;
		foreach(char c; _modulename)
			result ~= (c=='.'?'/':c);				
		return result ~ ".d";
	}
	char[] toString(){ return _modulename; }
	bit visible(){ return _visible; }
	void visible(bit v){ _visible = v; }
	void linked(Source by){ _linked ~= by; }
	Source[] linked(){ return _linked; }
	void link(Source to){ _link ~= to; }
	Source[] link(){ return _link; }
	int din, dout;
private:
	char[] _modulename;
	bit _visible;
	Source[] _linked, _link;
}

int usage(){
	writef("dimple ", DIMPLE_VERSION,`
D import-list explorer
Copyright(c) 2005 by Wang Zhen
Webpage: http://www.shfls.org/w/d/dimple/

Usage:
  dimple entry.module { -switch }
  
  entry.module     module identifier
  -x=regexp        excluded module(s)
  
Example:
  dimple dmdscript.program "-x=\.(script|dobject)" | dot -Tps -ofdep.ps
`);
	return 1;
}

int main(char[][]args){
	if(args.length==1)
		return usage();
	
	RegExp excluded;	
	Source[] src;
	
	foreach(char[] a; args[1..args.length])
		if(a.length>3 && a[0..3]=="-x=")
			excluded = new RegExp(a[3..a.length], "");
		else
			src ~= new Source(a);

	for(int i=0; i<src.length; ++i){		
		Source curr = src[i];
		if(excluded && excluded.test(curr.modulename))
			continue;		
		try{
			ImportList imported;
			try{
				imported =	new ImportList(
							new TokenStream(
							new CommentFilter(
							new FileCharStream(curr.pathname))));
			}catch(OpenException){
				//writefln("  //ignoring ", curr.pathname);
				continue;
			}
			
			curr.visible(true);			
			for(;;){
				char[] mod = imported.next();
//                                writefln (mod);                                 
				
				Source dep;
				foreach(Source s; src) {
					if(s.modulename == mod){
						dep = s;
						break;
					}
                                }

				if(!dep)					
					src ~= dep = new Source(mod);				
				dep.linked(curr);				
			}
		}catch(ProducerExhausted){
		}catch(Exception e){
			return writefln("error : ", e), 1;
		}
	}
	
	int l = 0;
	foreach(Source s; src)
		if(s.visible)
			src[l++] = s;
	src.length = l;
	
	foreach(Source s; src)
		foreach(Source r; s.linked)
			r.link(s);		
	
	//memo: output in "graphviz dot" format
	writefln("digraph d{
                edge [color=gray64];
                node [fontname=Helvetica, style=filled, color=gray, fillcolor=darkseagreen1, fontsize=12, height=0, width=0];
                graph [fontname=Helvetica, dpi=72, fontcolor=black];");
		
	foreach(Source s; src)		
		foreach(Source r; s.link)
			writefln (`"`, s, `" -> "`,  r, `"`,
//			`[weight=`, cast(int)(100.0/r.linked.length),`]`,
			`;`);
	
        // emit colors and urls
        auto BaseUrl = "http://svn.dsource.org/projects/tango/trunk/doc/html/";
	foreach(Source s; src)		
                if (std.string.find(s.toString, "model.") > 0)
                    writefln(`"`, s, "\" [fillcolor=khaki1, URL=\"%s\"];", BaseUrl~s.toString~".html");
                else
                   writefln(`"`, s, "\" [fillcolor=darkseagreen1, URL=\"%s\"];", BaseUrl~s.toString~".html");



	//memo: mark modules in a cycle of dependency
	
	//memo: step 1: reduce the set of candidate nodes
	int dsum = 0;
	foreach(Source s; src){
		s.din = s.linked.length;
		s.dout = s.link.length;
		dsum += s.din - s.dout;
//		writefln(`//`, s, ` fan-in=`, s.din, ` fan-out=`, s.dout);
	}
	assert(dsum==0);	

	bit rescan;
	do{
		rescan = false;
		foreach(Source s; src)
			if(s.din==0 && s.dout==0)
				continue;
			else if(s.din==0){
				foreach(Source r; s.link)
					if(r.din)
						r.din--;
				s.dout = 0;
				rescan = true;
			}else if(s.dout==0){
				foreach(Source r; s.linked)
					if(r.dout)
						r.dout--;
				s.din = 0;
				rescan = true;
			}		
	}while(rescan);
	
	//memo: step 2: calculate the transitive closure
	Source[] candidates;
	foreach(Source s; src)
		if(s.din)
			candidates ~= s;
	int n = candidates.length;
	bit[] mtx = new bit[n*n];
	foreach(int i, Source a; candidates)
		foreach(int j, Source b; candidates)
			foreach(Source c; a.link)
				if(b==c){
					mtx[i*n+j] = true;
					break;
				}	
	
	for(int k=0; k<n; ++k)
		for(int i=0; i<n; ++i)
			for(int j=0; j<n; ++j)					
				if(!mtx[i*n+j] && mtx[i*n+k] && mtx[k*n+j])
					mtx[i*n+j] = true;	

	for(int i=0; i<n; ++i)
		if(mtx[i*n+i])
			writefln(`"`, candidates[i], `" [fillcolor=salmon];`);
		
	writefln(`}`);

	return 0;
}
