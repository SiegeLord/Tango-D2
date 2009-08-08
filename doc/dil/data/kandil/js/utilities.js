/// Author: Aziz Köksal
/// License: zlib/libpng

/// Escapes the regular expression meta characters in str.
RegExp.escape = function(str) {
  return str.replace(/([\\.*+?^${}()|[\]/])/g, '\\$1');
};

/// Splits a string by 'sep' returning a tuple (head, tail).
/// Returns (this, "") if sep is not found.
String.prototype.partition = function(sep) {
  var sep_pos = this.indexOf(sep), head = this, tail = "";
  if (sep_pos != -1)
    (head = this.slice(0, sep_pos)), (tail = this.slice(sep_pos+1));
  return [head, tail];
};

/// Splits a string by 'sep' returning a tuple (head, tail).
/// Returns ("", this) if sep is not found.
String.prototype.rpartition = function(sep) {
  var sep_pos = this.lastIndexOf(sep);
  var head = (sep_pos == -1) ? "" : this.slice(0, sep_pos);
  var tail = this.slice(sep_pos+1);
  return [head, tail];
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
  var str = this.replace(rx, ""), i = str.length;
  if (i) while(rx.test(str[--i])){}
  return str.substring(0, i+1);*/
};

/// Returns a formatted string filled in with the provided arguments.
String.prototype.format = function(args) {
  if (!(typeof args == typeof [] || typeof args == typeof {}))
    args = Array.prototype.slice.call(arguments); // Convert to propery array.
  return this.replace(/\{\{|\{[^{}]+\}/g, function(m) {
    return m.length == 2 ? m : args[m.slice(1, -1)];
  });
}

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
          if(className.indexOf(" "+classes[i]+" ") != -1) // hasClass
            this.removeClass(classes[i]);
          else
            this.addClass(classes[i]);
      }
    }
    else // Turn classes on or off according to provided state parameter.
      state ? this.addClass(classes) : this.removeClass(classes);
    return this;
  }
});

// Replace the methods in jQuery.
jQuery.extend(jQuery.fn, function(p/*rototype*/){ return {
  removeClass: function(){ return this.each(p.removeClass, arguments) },
  addClass:    function(){ return this.each(p.addClass, arguments) },
  toggleClass: function(){ return this.each(p.toggleClass, arguments) },
  hasClass:    function(classes){
    for (var i = 0, len = this.length; i < len; i++)
      if (p.hasClass.call(this[i], classes))
        return true;
    return false;
  }
}}(Element.prototype));

/// Gets a cookie or sets it to a value.
function cookie(name, value, expires, path, domain, secure)
{ // Get the cookie.
  if (value == undefined) {
    var m = document.cookie.match(RegExp("\\b"+name+"=([^;]*)"));
    return m ? cookie.unescape(m[1]) : null;
  }
  // Set the cookie.
  value = cookie.escape(String(value)); // Escape semicolons.
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
  return function(val) { return val == undefined ? convert(cookie(name)) :
    (cookie(name, val, kandil.settings.cookie_life), val)
  };
}

/*// Create "console" variable for browsers that don't support it.
var emptyFunc = function(){};
if (window.opera)
  console = {log: function(){ opera.postError(arguments.join(" ")) },
             profile: emptyFunc, profileEnd: emptyFunc};
else if (!window.console)
  console = {log: emptyFunc, profile:emptyFunc, profileEnd: emptyFunc};

profile = function profile(msg, func) {
  console.profile(msg);
  func();
  console.profileEnd(msg);
};*/
