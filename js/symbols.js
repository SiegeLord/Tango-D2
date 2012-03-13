/// Author: Aziz Köksal
/// License: zlib/libpng

/// Builds an enum. Maps strings to IDs and IDs to strings.
function makeEnum(elems, sep)
{
  if (sep !== undefined)
    elems = elems.split(sep);
  var dict = {'toStr': elems};
  for (var i = 0, l = elems.length; i < l; i++)
    (dict[elems[i]] = i)/*, // E.g.: dict["package"] = 0;
    (dict[i] = elems[i])*/; // E.g.: dict[0] = "package"; (use toStr instead)
  return dict;
}

/// An enumeration of symbol kinds.
var SymbolKind = makeEnum(
  "package module template class interface struct union alias \
typedef enum enummem variable function invariant new delete unittest ctor \
dtor sctor sdtor", " ");

/// Returns true if this symbol is a function.
SymbolKind.isFunction = function(key) {
  if (typeof key == typeof "")
    key = this[key]; // Get the ID if the key is a string.
  return 12 <= key && key <= 20; // ID range: 12-20.
};

/// An enumeration of symbol attributes.
var SymbolAttr = makeEnum(
  "private protected package public export abstract auto const \
deprecated extern final override scope static synchronized \
in out ref lazy variadic immutable manifest nothrow pure \
shared gshared thread wild disable property safe system trusted \
C C++ D Windows Pascal System", " ");

/// Returns true for protection attributes.
SymbolAttr.isProtection = function(key) {
  if (typeof key == typeof "")
    key = this[key]; // Get the ID if the key is a string.
  return 0 <= key && key <= 4; // ID range: 0-4.
};

/// Constructs a symbol. Represents a package, a module or a D symbol.
function Symbol(fqn, kind, sub)
{
  var parts = fqn.rpartition(".");
  this.parent_fqn = parts[0]; /// The fully qualified name of the parent.
  this.name = parts[1]; /// The text to be displayed.
  this.kind = kind;     /// The kind of this symbol.
  this.fqn = fqn;       /// The fully qualified name.
  this.parent = null;   /// The parent symbol of this symbol.
  this.sub = sub || []; /// Sub-symbols.
  return this;
}

Symbol.dict = function dict() {
  // Prefix with "." to avoid property collisions.
  return {
    get: function(key) {return this["."+key]},
    set: function(key, val) {return this["."+key] = val},
    del: function(key) {delete this["."+key]},
  }
};

Symbol.getTree = function(json/*=JSON text*/, moduleFQN) {
  json = json || '["",1,[],[1,1],[]]';
  var arrayTree = JSON.parse(json);
  var dict = new Symbol.dict(); // A map of fully qualified names to symbols.
  var list = []; // A flat list of all symbols.
  function visit(s/*=symbol*/, fqn/*=fully qualified name*/)
  { // Assign the elements of this tuple to variables.
    var name = s[0], kind = s[1], attrs = s[2], loc = s[3], members = s[4];
    // E.g.: 'tango.core' + '.' + 'Thread'
    fqn += (fqn ? "." : "") + name;
    // E.g.: 'Thread.this', 'Thread.this:2' etc.
    if (sibling = dict.get(fqn)) // Add ":\d+" suffix if not unique.
      fqn += ":" + (++sibling.count || (sibling.count = 2));
    // Create a new symbol.
    var symbol = new visit.Symbol(fqn, visit.SymbolKind.toStr[kind], members);
    symbol.loc = loc;
    symbol.attrs = attrs;
    // Replace attribute IDs with their string values.
    for (var i = 0, len = attrs.length; i < len; i++)
      attrs[i] = visit.SymbolAttr.toStr[attrs[i]];

    dict.set(fqn, symbol); // Add to the dictionary.
    list.push(symbol); // Add to the list.

    // Visit the members of this symbol.
    for (var i = 0, len = members.length; i < len; i++)
      (members[i] = visit(members[i], fqn)),
      (members[i].parent = symbol);
    return symbol;
  }
  visit.SymbolAttr = SymbolAttr; // Make finding global variables fast.
  visit.SymbolKind = SymbolKind;
  visit.Symbol = Symbol;

  // Avoid including the root's name in the FQNs of the symbols.
  // E.g.: "Culture.this", not "tango.text.locale.Core.Culture.this"
  arrayTree[0] = "";
  var tree = {};
  tree.dict = dict;
  tree.list = list;
  tree.root = visit(arrayTree, "");
  tree.root.name = moduleFQN.rpartition(".", 1);
  tree.root.fqn = moduleFQN;
  return tree;
};


/// Constructs a module.
function M(fqn) {
  return new Symbol(fqn, "module");
}
/// Constructs a package.
function P(fqn, sub) {
  return new Symbol(fqn, "package", sub);
}

function PackageTree(root)
{
  this.root = root;
}
PackageTree.prototype.initList = function() {
  // Create a flat list from the package tree.
  var list = [];
  function visit(syms)
  { // Iterate recursively through the tree.
    for (var i = 0, len = syms.length; i < len; i++) {
      var sym = syms[i];
      list.push(sym);
      if (sym.sub.length) visit(sym.sub);
    }
  }
  visit([this.root]);
  this.list = list;
};
