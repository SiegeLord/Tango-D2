/// Author: Aziz Köksal
/// License: zlib/libpng

/// Constructs a Treeview object.
/// Adds treeview functionality to ul. Expects special markup.
function Treeview(ul)
{
  var tv = this;
  ul.addClass("tview");
  this.$ul = ul;
  this.ul = ul[0];

  this.ul.tabIndex = 1; // Make this tag focusable by tabbing and clicking.
  if (window.opera)
    // Unfortunately Opera selects all the text inside ul if it is focused via
    // the tab key. We can still make an element focusable with a value of -1.
    // Hope this gets fixed in Opera 10.
    this.ul.tabIndex = -1; // Make focusable but prevent tabbing.

  this.selected_li = ul[0].firstChild;

  function handleKeypress(e)
  {
    if (33 <= e.keyCode && e.keyCode <= 40 || e.keyCode == 13)
      e.preventDefault(),
      tv.eventHandlerTable[e.keyCode].call(tv, e);
  }

  this.setFocus = function() {
    if (tv.focused) return;
    tv.focused = true;
    tv.ul.addClass("focused");
  }

  this.unsetFocus = function() {
    if (!tv.focused) return;
    tv.focused = false;
    tv.ul.removeClass("focused");
  }

  this.$ul.focus(tv.setFocus);
  this.$ul.blur(tv.unsetFocus); // Losing focus.
  // Note: keyboard navigation is unfinished.
//   this.$ul.keypress(handleKeypress);

  this.$ul.mousedown(function(e) {
    tv.setFocus();
    var tagName = e.target.tagName;
    // The i-tag represents the icon of the tree node.
    if (tagName == "I")
      tv.iconClick(e.target.parentNode);
    else if (tagName == "A" || tagName == "LABEL" || tagName == "SUB")
    {
      var li = e.target;
      for (; li && li.tagName != "LI";)
        li = li.parentNode;
      if (li) tv.selected(li);
    }
  });

  // When the state of a node changes, trigger a delayed save_state event.
  this.$ul.bind("state_toggled", function() {
    tv.savedState = false;
    clearTimeout(tv.saveTID);
    tv.saveTID = setTimeout(function() {
      tv.$ul.trigger("save_state");
    }, kandil.settings.tview_save_delay);
  });
}

Treeview.prototype = {
//   default_li: {
//     nextSibling: ,
//     lastChild: {
//     }
//   },
  selected: function(new_li) {
    if (new_li != undefined) {
      new_li.addClass("selected");
      if (new_li == this.selected_li)
        return;
      this.selected_li.removeClass("selected");
      this.selected_li = new_li;
      // TODO: Adjust the scrollbar position.
      // This is very difficult.
//       if (new_li.scrollTop < this.ul.scrollTop)
//         this.ul.scrollTop = new_li.scrollTop;
//       else if (new_li.scrollTop > this.ul.scrollTop + this.ul.clientHeight)
//         this.ul.scrollTop = new_li.scrollTop;
    }
    return this.selected_li;
  },

  // Functions for keyboard navigation:
  // TODO: The code must be reviewed, debugged and tested for correctness.

  getLastLI: function(ul) {
    var li = $(">li:visible:last", ul)[0];
    if (li && li.lastChild.tagName == "UL" && li.lastChild.clientHeight != 0)
      return this.getLastLI(li.lastChild);
    return li;
  },
  movePageUp: function(e) { /*TODO:*/ },
  movePageDown: function(e) { /*TODO:*/ },
  moveHome: function(e) {
    if (first_li = this.ul.firstChild)
      this.selected(first_li);
  },
  moveEnd: function(e) {
    if (last_li = this.getLastLI(this.ul))
      this.selected(last_li);
  },
  moveLeft: function(e) {
    var li = this.selected();
    if (li.lastChild.tagName == "UL" &&
        !li.hasClass("closed|has_hidden|show_hidden"))
      this.iconClick(li);
    else if (li.parentNode != this.ul)
      (li = li.parentNode.parentNode),
      this.selected(li),
      this.iconClick(li);
    else
      this.moveUp(e);
  },
  moveUp: function(e) {
    var tview = this;
    function prev_visible(li)
    {
      var prev_li = li.previousSibling; // Default.
      if (prev_li && prev_li.tagName != "LI")
        return prev_visible(prev_li);
      if (!prev_li && li.parentNode != tview.ul)
        prev_li = li.parentNode.parentNode; // Go up one level.
      else if (prev_li && prev_li.lastChild.tagName == "UL" &&
              !prev_li.hasClass("closed"))
        // Get the last li-tag of the previous branch.
        prev_li = tview.getLastLI(prev_li.lastChild);
      if (prev_li && prev_li.clientHeight == 0)
        return prev_visible(prev_li);
      return prev_li;
    }
    if (li = prev_visible(this.selected()))
      this.selected(li);
  },
  moveRight: function(e) {
    var li = this.selected();
    if (li.hasClass("closed|has_hidden"))
      this.iconClick(li);
    else
      this.moveDown(e);
  },
  moveDown: function(e) {
    var tview = this;
    function next_visible(li)
    {
      var next_li = li.nextSibling; // Default.
      if (li.lastChild &&
          li.lastChild.tagName == "UL" &&
          !li.hasClass("closed"))
        next_li = li.lastChild.firstChild; // Go down one level.
      if (!next_li)
        // Backtrack to the next sibling branch.
        for (var p_ul = li.parentNode; !next_li && p_ul != tview.ul;
             p_ul = p_ul.parentNode.parentNode)
          if (p_ul.parentNode.nextSibling)
            next_li = p_ul.parentNode.nextSibling;
//       if (next_li && next_li.tagName != "LI")
//         return next_visible(next_li);
      if (next_li && next_li.clientHeight == 0)
        return next_visible(next_li);
      return next_li;
    }
    if (li = next_visible(this.selected()))
      this.selected(li);
  },
  itemEnter: function(e) {
    if (link = $(">label>a", this.selected())[0])
      if (link.click) link.click(); // For Opera.
      else { // Browsers like Firefox, Safari etc.
        var ev = document.createEvent('MouseEvents');
        ev.initEvent('click', true, true);
        link.dispatchEvent(ev);
      }
  },
  iconClick: function(li) {
    if (this.ul.hasClass("filtered")) {
      // Go from [.] -> [-] -> [+] -> [.]
      if (li.hasClass("has_hidden")) {
        if (li.hasClass("closed")) // [+] -> [.]
          li.removeClass("closed");
        else // [.] -> [-]
          li.addClass("show_hidden").removeClass("has_hidden");
      }
      else if (li.hasClass("show_hidden")) // [-] -> [+]
        li.addClass("has_hidden|closed").removeClass("show_hidden");
      else // [-] <-> [+]
        li.toggleClass("closed");
    }
    else // Normal node. [-] <-> [+]
      li.toggleClass("closed");
    this.$ul.trigger("state_toggled");
  },
  // Binds a function to an event from the ul tag.
  bind: function(which_event, func) {
    this.$ul.bind(which_event, func);
  },
};

Treeview.prototype.eventHandlerTable = (function() {
  var p = Treeview.prototype;
  return {
    33:p.movePageUp, 34:p.movePageDown, 35:p.moveEnd, 36:p.moveHome,
    37:p.moveLeft, 38:p.moveUp, 39:p.moveRight, 40:p.moveDown,
    13:p.itemEnter
  };
})();

/// Saves the state of a treeview in a cookie.
Treeview.prototype.saveState = function(save_fn) {
  // TODO: save the whole ul tree in 'storage'.
  if (this.savedState)
    return;
  var ul_tags = this.ul.getElementsByTagName("ul"), list = "";
  for (var i = 0, len = ul_tags.length; i < len; i++)
    if (ul_tags[i].parentNode.hasClass("closed"))
      list += i + ",";
  save_fn(list.slice(0, -1)); // Strip last comma.
  this.savedState = true;
};
/// Loads the state of a treeview from a cookie.
Treeview.prototype.loadState = function(load_fn) {
  var list = load_fn();
  if (!list)
    return;
  var ul_tags = this.ul.getElementsByTagName("ul");
  list = list.split(",");
  for (var i = 0, len = list.length; i < len; i++)
    ul_tags[list[i]].parentNode.addClass("closed");
};
