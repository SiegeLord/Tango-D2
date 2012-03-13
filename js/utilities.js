/// Author: Aziz Köksal
/// License: zlib/libpng

/// Escapes the regular expression meta characters in str.
RegExp.escape = function(str) {
  return str.replace(/([\\.*+?^${}()|[\]/])/g, '\\$1');
};

/// Splits a string by 'sep' returning a tuple (head, tail).
/// Returns (this, "") if sep is not found.
String.prototype.partition = function(sep, part) {
  var sep_pos = this.indexOf(sep);
  if (sep_pos < 0) sep_pos = this.length;
  if (part != undefined)
    return new String(part == 0 ? this.slice(0, sep_pos) :
                      this.slice(sep_pos+sep.length));
  return [new String(this.slice(0, sep_pos)),
          new String(this.slice(sep_pos+sep.length))];
};

/// Splits a string by 'sep' returning a tuple (head, tail).
/// Returns ("", this) if sep is not found.
String.prototype.rpartition = function(sep, part) {
  var sep_pos = this.lastIndexOf(sep);
  if (sep_pos < 0) sep_pos = -this.length-sep.length;
  if (part != undefined)
    return new String(part == 0 ? this.slice(0, sep_pos) :
                      this.slice(sep_pos+sep.length));
  return [new String(this.slice(0, sep_pos)),
          new String(this.slice(sep_pos+sep.length))];
};

/// Strips chars (defaults to whitespace) from the start and end of a string.
String.prototype.strip = function(chars) {
  var rx = /^\s+|\s+$/g; // Fast for short strings.
  if (arguments.length == 1)
    (chars = RegExp.escape(chars)),
    (rx = RegExp("^["+chars+"]+|["+chars+"]+$", "g"));
  return this.replace(rx, "");
  // Alternative method (fast for long strings):
  /*var rx = /^\s+/;
  if (arguments.length == 1)
    (chars = RegExp.escape(chars)),
    (rx = RegExp("^["+chars+"]+"));
  var str = new String(this.replace(rx, "")), i = str.length;
  if (i) while (rx.test(str[--i])){}
  return str.substring(0, i+1);*/
};

/// Returns a formatted string filled in with the provided arguments.
String.prototype.format = function format(args) {
  if (!(arguments.length == 1 && format.rx_type.test(typeof args)))
    args = format.toArray.call(arguments); // Convert to proper array.
  var implicit_idx = 0;
  return this.replace(format.rx, function(m) {
    if (m[1] == '{') return '{'; // Replace '{{' with '{'.
    if (m[1] == '}')
      return (implicit_idx in args) ? args[implicit_idx++] : // Replace '{}'.
        format.error.format("no args["+implicit_idx+"]"); // Else: error.
    // Split e.g.: "0.member1.m2"
    var indices = m.slice(1, -1).split('.'), obj = args;
    for (var i=0, len=indices.length; i < len; i++)
      if ((index = indices[i]) in obj)
        obj = obj[index];
      else // Intelligent and helpful error message:
        return format.error.format(indices.slice(0, i+1).join('.'));
    return obj;
  });
};
(function(format_func) {
  format_func.rx_type = /^array|object$/;
  format_func.rx = /\{\{|\{[^{}]*\}/g;
  format_func.toArray = Array.prototype.slice;
  format_func.error = "{{FormatIndexError:{0}}";
})(String.prototype.format);

/// Calculates the Levenshtein distance between str1 and str2.
function levenshtein_distance(str1, str2)
{
  var a0, a1;
  var i = 0, j = 0, cost = 0;
  var len1 = str1.length, len2 = str2.length;
  var tmp;
  if (len1 < len2) { // Swap shorter with longer string.
    tmp = str1; str1 = str2; str2 = tmp;
    tmp = len1; len1 = len2; len2 = tmp;
  }

  if (len2 < 64)
  {
    a0 = levenshtein_distance.a0_static.slice(); // Copy pre-initialized.
    a1 = a0.slice();
  }
  else
  { // String is longer.
    a0 = []; a1 = [];
    var len = len1 < len2 ? len1 : len2;
    for (; i <= len; i++)
      a0[i] = a1[i] = i;
  }

  for (i = 0; i < len1; i++)
  {
    var char1 = str1[i];
    a1[0] = i+1;
    for (j = 0; j < len2; j++)
    {
      cost = (char1 != str2[j]); // char2 = str2[j]
      // a1[j+1] = min(x1,x2,x2)
      var x1 = a0[j+1] + 1,  // Deletion.
          x2 = a1[j] + 1,    // Insertion.
          x3 = a0[j] + cost; // Substitution.
      x1 = x1 < x2 ? x1 : x2;
      a1[j+1] = x1 < x3 ? x1 : x3;
    }
    tmp = a0; a0 = a1; a1 = tmp; // Swap arrays.
  }
  return a0[j];
}

levenshtein_distance.a0_static = (function() {
  var a = []; // Initialize an array of 64+1 elements.
  for (var i = 0; i < 65; i++)
    a[i] = i;
  return a;
})();

if (!window.JSON)
  JSON = {
    parse: function(text) { // Warning: Don't use untrusted data.
      return eval('(' + text + ')');
    },
    stringify: function(obj){ return "N/A";}
  };

/// Prepends and appends chars to each element and returns a joined string.
// Array.prototype.surround = function(chars) {
//   return chars+this.join(chars+chars)+chars;
// };

// Extend the DOM Element class with custom methods.
// They're faster than the jQuery methods.
jQuery.extend(Element.prototype, {
  /// Removes one or more CSS classes (separated by '|') from a node.
  removeClass: function(classes) {
    if (/*this.nodeType != 1 || */this.className == undefined) return;
    // Can't work with:
    // 1. '\b(?:classes)\b' would match class names with hyphens: "name-abc".
    // 2. '(?:\s|^)(?:classes)(?:\s|$)' produces wrong matches.
    // Adding a space to both sides elegantly solves this problem.
    // The look-ahead is necessary to avoid eating the space
    // between 'a' and 'b' e.g.: " a b "
    var rx = RegExp(" (?:"+classes+")(?= )", "g");
    this.className = (" "+this.className+" ").replace(rx, "").slice(1, -1);
    return this;
  },
  /// Adds one or more CSS classes (separated by '|') to a node.
  addClass: function(classes) {
    this.removeClass(classes);
    var className = this.className;
    className = className ? className + " " : "";
    this.className = className + classes.replace(/\|/g, " ");
    return this;
  },
  /// Returns true if the node has one of the classes (separated by '|').
  hasClass: function(classes) {
    if (/*this.nodeType != 1 || */this.className == undefined) return;
    return RegExp(" (?:"+classes+") ").test(" "+this.className+" ");
  },
  /// Toggles one or more CSS classes (separated by '|') of a node.
  /// Note: $('<x class="a b"/>').toggleClass("b|c|d") -> "a c d"
  toggleClass: function(classes, state) {
    if (typeof state != typeof true) {
      var className = this.className;
      if (!className) // Just add all classes when className is empty.
        this.addClass(classes);
      else { // Iterate over each class separately and toggle its state.
        className = " "+className+" ";
        classes = classes.split("|");
        for (var i = 0, len = classes.length; i < len; i++)
          if (className.indexOf(" "+classes[i]+" ") != -1) // hasClass
            this.removeClass(classes[i]);
          else
            this.addClass(classes[i]);
      }
    }
    else // Turn classes on or off according to provided state parameter.
      state ? this.addClass(classes) : this.removeClass(classes);
    return this;
  },
  /// Returns the computed value of a CSS property. If property is undefined,
  /// the ComputedCSSStyleDeclaration object is returned instead.
  cCSS: function(property) {
    var cs = window.getComputedStyle(this, null);
    return (property === undefined) ? cs : cs.getPropertyValue(property);
  },
  xpath: function(path, opt) {
    opt = opt || {};
    opt.type = window.XPathResult[opt.type];
    return document.evaluate(path, this, opt.ns, opt.type, opt.res);
  },
});

// Replace the methods in jQuery.
jQuery.extend(jQuery.fn, {
  removeClass: function(){ return this.each(Element.prototype.removeClass, arguments) },
  addClass:    function(){ return this.each(Element.prototype.addClass, arguments) },
  toggleClass: function(){ return this.each(Element.prototype.toggleClass, arguments) },
  hasClass:    function(classes) {
    for (var i = 0, len = this.length; i < len; i++)
      if (!this[i].hasClass(classes))
        return false;
    return true;
  },
  cCSS: function(property) {
    return this.map(function(){return this.cCSS(property)});
  },
  xpath: function(path, options) {
    return this.map(function(){return this.xpath(path, options)});
  },
});


/// Returns a curried version of f().
/// Calling the returned function g() is like calling f()
/// with the provided arguments.
/// Uses f.this_ as the 'this' object if defined.
function curry(f/*, arg1, arg2...*/) {
  // if (arguments.length <= 1) return f;
  var g = curry.new_g();
  g.args = Array.prototype.slice.call(arguments, 1);
  g.f = f;
  g.this_ = f.this_;
  return g;
}
curry.new_g = function() { return function g() {
  return g.f.apply(g.this_ || this, arguments.length ?
    Array.prototype.concat.apply(g.args, arguments) : g.args);
}};

/// Returns a curried version of f(). Takes a 'this' object.
function curry2(this_, f/*, arg1, arg2...*/) {
  // if (arguments.length <= 2) return f;
  var g = curry.new_g();
  g.args = Array.prototype.slice.call(arguments, 2);
  g.f = f;
  g.this_ = this_;
  return g;
}

// Use standardized function.
if (!Object.defineProperty)
  Object.defineProperty = function(o, p, f) {
    f.set && o.__defineSetter__(p, f.set);
    f.get && o.__defineGetter__(p, f.get);
    return o;
  };

Object.getter = function(o, p, f) {
  return this.defineProperty(o, p, {'get':f, 'configurable':true})
};
Object.setter = function(o, p, f) {
  return this.defineProperty(o, p, {'set':f, 'configurable':true})
};


// Use an alias for the localStorage object.
var storage = window.localStorage;

if (storage) {
  /// Reads or writes a value, depending on whether val is defined or not.
  Storage.prototype.readwrite = function(key, val) {
    return val === undefined ? this[key] : this[key] = val;
  };
}
else
  storage = {"readwrite":function(){}};

storage.readwrite.this_ = storage; // Make this a delegate for curry().


/// Gets a cookie or sets it to a value.
function cookie(name, value, expires, path, domain, secure)
{ // Get the cookie.
  if (value == undefined) {
    var m = document.cookie.match(RegExp("\\b"+name+"=([^;]*)"));
    return m ? cookie.unescape(m[1]) : null;
  }
  // Set the cookie.
  value = cookie.escape(new String(value)); // Escape semicolons.
  if (expires != undefined) {
    var date = expires;
    if (!date.toUTCString) // 86400000 = 24h*60m*60s*1000ms
      (date = new Date()),
      date.setTime(date.getTime() + expires*86400000);
    value += "; expires=" + date.toUTCString();
  }
  value += (path ? "; path="+path : "")+(domain ? "; domain="+domain : "")+
           (secure ? "; secure" : "");
  document.cookie = name + "=" + value;
}
cookie.life = 30; /// Life time in days.
/// Escapes semicolons with the hex value 0x01.
cookie.escape = function(value) { return value.replace(/;/g, "\x01") }
/// Replaces hex values 0x01 with a semicolon.
cookie.unescape = function(value) { return value.replace(/\x01/g, ";") }
/// Deletes a cookie.
cookie.del = function(name) { cookie(name, "", -1) }
cookie.default_converter = function(val) { return val }
/// Returns a convenience function that can read a cookie and
/// apply a converter function to its value, it can also write to the cookie.
cookie.func = function (name, convert) {
  convert = convert || cookie.default_converter;
  return function(val) {
    return val === undefined ?
       convert(cookie(name)) : (cookie(name, val, cookie.life), val);
  };
}

/*// Create "console" variable for browsers that don't support it.
var emptyFunc = function(){};
if (window.opera)
  console = {
    log: function() {
      opera.postError(Array.prototype.join.call(arguments, " "));
    },
    profile: emptyFunc, profileEnd: emptyFunc
  };
else if (!window.console)
  console = {log: emptyFunc, profile:emptyFunc, profileEnd: emptyFunc};

function profile(msg, func) {
  console.profile(msg);
  func();
  console.profileEnd(msg);
};*/
