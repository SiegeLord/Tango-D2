/// Author: Aziz Köksal
/// License: zlib/libpng

/// An enumeration of symbol kinds.
var SymbolKind = (function(){
  var kinds = "package module template class interface struct union alias \
typedef enum enummem variable function invariant new delete unittest ctor \
dtor sctor sdtor".split(" ");
  var dict = {str: kinds};
  for (var i = 0, len = kinds.length; i < len; i++)
    dict[kinds[i]] = i; // E.g.: dict.package = 0
  dict.isFunction = function(key) {
    if (typeof key == typeof "")
      key = this[key]; // Get the index.
    return 12 <= key && key <= 20; // 12-20 index range.
  };
  return dict;
}());

/// Constructs a symbol. Represents a package, a module or a D symbol.
function Symbol(fqn, kind, sub)
{
  var parts = fqn.rpartition(".");
  this.parent_fqn = parts[0]; /// The fully qualified name of the parent.
  this.name = parts[1]; /// The text to be displayed.
  this.kind = kind;     /// The kind of this symbol.
  this.fqn = fqn;       /// The fully qualified name.
  this.sub = sub || []; /// Sub-symbols.
  return this;
}

/// Constructs a module.
function M(fqn) {
  return Symbol.call({}, fqn, "module");
}
/// Constructs a package.
function P(fqn, sub) {
  return Symbol.call({}, fqn, "package", sub);
}

function PackageTree(root)
{
  this.root = root;
  this.initList = function() {
    // Create a flat list from the package tree.
    var list = [];
    function visit(syms)
    { // Iterate recursively over the tree.
      for (var i = 0, len = syms.length; i < len; i++) {
        var sym = syms[i];
        list = list.concat(sym);
        if (sym.sub.length) visit(sym.sub);
      }
    }
    visit([this.root]);
    this.list = list;
  }
}
