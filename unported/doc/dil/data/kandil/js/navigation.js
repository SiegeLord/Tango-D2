/// Author: Aziz Köksal
/// License: zlib/libpng

/// A global object for accessing various properties of the application.
var kandil = {
  /// The original module loaded normally by the browser (not JavaScript.)
  originalModuleFQN: "",
  /// An object that represents the symbol tree.
  symbolTree: {},
  /// The tags with the symbol CSS class.
  symbolTags: null,
  /// An array of all the lines of this module's source code.
  sourceCode: [],
  /// Represents the package tree (located in generated modules.js).
  packageTree: g_packageTree,
  /// Application settings.
  settings: {
    navbar_html: "<div id='navbar'><p id='navtabs'>\
<span id='apitab' class='current'>{apitab_label}</span>\
<span id='modtab'>{modtab_label}</span></p>\
<div id='panels'><div id='apipanel'/><div id='modpanel'/></div>\
</div>", /// The navbar HTML code prepended to the body.
    splitbar_html: "<div title='{splitbar_title}' class='splitbar'>\
<div class='handle'/></div>", /// The splitbar's HTML code.
    navbar_width: 250,    /// Initial navigation bar width.
    navbar_minwidth: 180, /// Minimum resizable width.
    navbar_collapsewidth : 50, /// Hide the navbar at this width.
    default_tab: "#apitab", /// Initial, active tab ("#apitab", "#modtab").
    apitab_label: getPNGIcon("variable")+"Symbols",
    modtab_label: getPNGIcon("module")+"Modules",
    dynamic_mod_loading: true, /// Load modules with JavaScript?
    tview_save_delay: 5*1000, /// Delay for saving a treeview's state after
                              /// each collapse and expand event of a node.
    tooltip: {
      delay: 1000, /// Delay in milliseconds before a tooltip is shown.
      delay2: 200, /// Delay before the next tooltip is shown.
      fadein: 200, /// Fade-in speed in ms.
      fadeout: 200, /// Fade-out speed in ms.
      offset: {x:16, y:16}, /// (x, y) offsets from the mouse position.
    },
    cookie_life: 30, /// Life-time of cookies in days.
    qs_delay: 500, /// Delay after last key press before quick search starts.
  },
  saved: {
    /// The position of the splitbar.
    splitbar_pos: cookie.func("splitbar_pos", parseInt),
    /// The collapse state.
    splitbar_collapsed: cookie.func("splitbar_collapsed",
                                    function(v){return v == "true"}),
    active_tab: cookie.func("active_tab"), /// Last active tab.
  },
  save: null, /// An alias for "saved".
  msg: {
    failed_module: "Failed loading the module from '{0}'!",
    failed_code: "Failed loading code from '{0}'!",
    loading_module: "Loading module...",
    loading_code: "Loading source code...",
    filter: "Filter...", /// Initial text in the filter boxes.
    splitbar_title: "Drag to resize. Double-click to close or open.",
    no_match: "No match...",
  },
};
kandil.save = kandil.saved;

/// Execute when document is ready.
$(function() {
  if (navigator.vendor == "KDE")
    document.body.addClass("konqueror");
//   else if (window.opera) // Not needed atm.
//     document.body.addClass("opera");

  kandil.originalModuleFQN = kandil.moduleFQN = g_moduleFQN;

  $("#kandil-content").addClass("left_margin");

  // Create the navigation bar.
  var navbar = $(kandil.settings.navbar_html.format(kandil.settings));
  $(document.body).prepend(navbar);

  createQuickSearchInputs();

  createSplitbar();

  initSymbolTags();

  // Assign click event handlers for the tabs.
  function makeCurrentTab() {
    $(".current", this.parentNode).removeClass('current');
    this.addClass('current');
    $("#panels > *:visible").hide(); // Hide all panels.
    kandil.save.active_tab("#"+this.id);
  }

  $("#apitab").click(makeCurrentTab)
              .click(function lazyLoad() {
    $(this).unbind("click", lazyLoad); // Remove the lazyLoad handler.
    initAPIList();
  }).click(function() {
    $("#apipanel").show(); // Display the API list.
  });

  $("#modtab").click(makeCurrentTab)
              .click(function lazyLoad() {
    $(this).unbind("click", lazyLoad); // Remove the lazyLoad handler.
    var modpanel = $("#modpanel");
    // Create the list.
    var ul = createModulesUL(modpanel);
    var tv = new Treeview(ul);
    tv.loadState("module_tree");
    tv.bind("save_state", function() {
      tv.saveState("module_tree");
    });
    if (kandil.settings.dynamic_mod_loading)
      $(".tview a", modpanel).click(handleLoadingModule);
    kandil.packageTree.initList(); // Init the list property.
  }).click(function() { // Add the display handler.
    $("#modpanel").show(); // Display the modules list.
  });
  // Activate the tab that has been saved or activate the default tab.
  var tab = kandil.saved.active_tab() || kandil.settings.default_tab;
  $(tab).trigger("click");
});

/// Creates the quick search text inputs.
function createQuickSearchInputs()
{
  var options = {text: kandil.msg.filter, delay: kandil.settings.qs_delay};
  var qs = [
    new QuickSearch("apiqs", options), new QuickSearch("modqs", options)
  ];
  $("#apipanel").prepend(qs[0].input);
  $("#modpanel").prepend(qs[1].input);
  $.extend(qs[0].input,
    {tag_selector: "#apipanel>ul", symbols: kandil.symbolTree});
  $.extend(qs[1].input,
    {tag_selector: "#modpanel>ul", symbols: kandil.packageTree});
  function handleFirstFocus(e, qs) {
    extendSymbols($(this.tag_selector)[0], this.symbols);
  }
  function handleSearch(e, qs)
  {
    var ul = $(this.tag_selector)[0]; // Get 'ul' tag.
    var symbols = [this.symbols.root];
    // Remove the message if present.
    $(ul.lastChild).filter(".no_match_msg").remove();
    if (!qs.parse()) // Nothing to do if query is empty.
      return ul.removeClass("filtered"), undefined;
    ul.addClass("filtered");
    // Start the search.
    if (!(quick_search(qs, symbols) & 1))
      $(ul).append("<li class='no_match_msg'>{0}</li>"
                   .format(kandil.msg.no_match));
  }
  qs[0].$input.add(qs[1].$input)
    .bind("first_focus", handleFirstFocus).bind("start_search", handleSearch);
  qs[0].input.tabIndex = qs[1].input.tabIndex = 0;
}

/// Installs event handlers to show tooltips for symbols.
function installTooltipHandlers()
{
  var ul = $("#apipanel > ul.tview");
  var tooltip = $.extend({
    current: null, // Current tooltip.
    target: null, // The target to show a tooltip for.
    TID: null, // Timeout-ID for delays.
  }, kandil.settings.tooltip); // Add tooltip settings.
  // Shows the tooltip at a calculated position.
  function showTooltip(e)
  { // Get the content of the tooltip.
    var a_tag = tooltip.target,
        a_tag_name = a_tag.href.slice(a_tag.href.lastIndexOf("#")+1),
        sym_tag = $(document.getElementsByName(a_tag_name)[0]);
    sym_tag = sym_tag.parent().clone();
    $(".symlink, .srclink", sym_tag).remove();
    // Create the tooltip.
    var tt = tooltip.current = $("<div class='tooltip'/>");
    tt.append(sym_tag[0].childNodes); // Contents of the tooltip.
    // Substract scrollTop because we need viewport coordinates.
    var top = e.pageY + tooltip.offset.y - $(window).scrollTop(),
        left = e.pageX + tooltip.offset.x;
    // First insert hidden to get a height.
    tt.css({visibility: "hidden", position: "fixed"})
      .appendTo(document.body);
    // Correct the position if the tooltip is not inside the viewport.
    var overflow = (top + tt[0].offsetHeight) - window.innerHeight;
    if (overflow > 0)
      top -= overflow;
    tt.css({display: "none", visibility: "", top: top, left: left})
      .fadeIn(tooltip.fadein);
  };
  // TODO: try implementing this with a single mousemove event handler on ul.
  // For some reason $(">.root>ul a", ul) doesn't produce correct results.
  $("a", $(">.root>ul", ul)).mouseover(function(e) {
    clearTimeout(tooltip.TID);
    tooltip.target = this;
    // Delay normally if this is the first tooltip being displayed, then
    // delay for a fraction of the normal time in subsequent mouseovers.
    var delay = !tooltip.current ? tooltip.delay : tooltip.delay2;
    tooltip.TID = setTimeout(function(){ showTooltip(e); }, delay);
  }).mouseout(function(e) {
    clearTimeout(tooltip.TID);
    if (tooltip.current) fadeOutRemove(tooltip.current, 0, tooltip.fadeout);
    tooltip.TID = setTimeout(function() { tooltip.current = null; }, 100);
  });
}

/// Creates the split bar for resizing the navigation panel and content.
function createSplitbar()
{
  var settings = kandil.settings, saved = kandil.saved;
  var splitbar = $(settings.splitbar_html.format(kandil.msg))[0];
  splitbar.isMoving = false; // Moving status of the splitbar.
  var navbar = $("#navbar"), content = $("#kandil-content"),
      body = document.body;
  body.appendChild(splitbar); // Insert the splitbar into the document.
  // The margin between the navbar and the content.
  var margin = parseInt(content.css("margin-left")) - navbar.width(),
      minwidth = settings.navbar_minwidth,
      collapsewidth = settings.navbar_collapsewidth;
  splitbar.setPos = function(x) {
    this.collapsed = false;
    if (x < collapsewidth)
      (this.collapsed = true),
      x = 0;
    else if (x < minwidth)
      x = minwidth;
    if (x+50 > window.innerWidth)
      x = window.innerWidth - 50;
    if (x)
      this.openPos = x;
    navbar.css("width", x);
    content.css("margin-left", x + margin);
    splitbar.style.left = x+"px";
  };
  splitbar.save = function() {
    saved.splitbar_pos(this.openPos); // Save the position.
    saved.splitbar_collapsed(this.collapsed); // Save the state.
  };
  function mouseMoveHandler(e) { splitbar.setPos(e.pageX); }
  function mouseUpHandler(e) {
    if (splitbar.isMoving)
      (splitbar.isMoving = false),
      splitbar.removeClass("moving"), body.removeClass("moving_splitbar"),
      splitbar.save(),
      $(document).unbind("mousemove", mouseMoveHandler)
                 .unbind("mouseup", mouseUpHandler);
  }
  function mouseDownHandler(e) {
    if (!splitbar.isMoving)
      (splitbar.isMoving = true),
      splitbar.addClass("moving"), body.addClass("moving_splitbar"),
      $(document).mousemove(mouseMoveHandler).mouseup(mouseUpHandler);
    e.preventDefault();
  }
  $(splitbar).mousedown(mouseDownHandler)
             .dblclick(function(e) {
    var pos = this.collapsed ? this.openPos : 0; // Toggle the position.
    this.setPos(pos);
    this.save();
  });
  // Set initial position.
  var pos = saved.splitbar_pos() || kandil.navbar_width;
  splitbar.openPos = pos;
  splitbar.collapsed = !!saved.splitbar_collapsed();
  if (splitbar.collapsed)
    pos = 0;
  splitbar.setPos(pos);
  return splitbar;
}

/// Handles a mouse click on a module list item.
function handleLoadingModule(event)
{
  event.preventDefault();
  var modFQN = this.href.slice(this.href.lastIndexOf("/")+1,
                               this.href.lastIndexOf(".html"));
  loadNewModule(modFQN);
}

function initSymbolTags()
{
  kandil.symbolTags = $(".symbol");
  // Add code display functionality to symbol links.
  kandil.symbolTags.click(function(event) {
    event.preventDefault();
    showCode($(this));
  });
  // Prevent permalinks from loading a new page,
  // in case a different module is loaded.
  if (kandil.originalModuleFQN != kandil.moduleFQN)
    $(".symlink").click(function(event) {
      event.preventDefault();
      this.scrollIntoView();
    });
}

/// Adds click handlers to symbols and inits the symbol list.
function initAPIList()
{
  initializeSymbolTree(kandil.symbolTags);

  // Create the HTML text and append it to the api panel.
  var ul = createSymbolsUL($("#apipanel"));
  var tv = new Treeview(ul);
  tv.loadState(kandil.moduleFQN);
  tv.bind("save_state", function() {
    tv.saveState(kandil.moduleFQN);
  });
  installTooltipHandlers();
}

/// Delays for 'delay' ms, fades out an element in 'fade' ms and removes it.
function fadeOutRemove(tag, delay, fade)
{
  tag = $(tag);
  setTimeout(function(){
    tag.fadeOut(fade, function(){ tag.remove() });
  }, delay);
}

/// Loads a new module and updates the API panel and the content pane.
function loadNewModule(modFQN)
{
  // Load the module's file.
  var doc_url = modFQN + ".html";

  function errorHandler(request, error, exception)
  {
    hideLoadingGif();
    var msg = kandil.msg.failed_module.format(doc_url);
    msg = $("<p class='ajaxerror'>'"+msg+"</p>");
    $(document.body).append(msg);
    fadeOutRemove(msg, 5000, 500);
  }

  function extractContent(text)
  {
    var start = text.indexOf('<div class="module">'),
        end = text.lastIndexOf('</div>\n</body>');
    return text.slice(start, end);
  }

  function extractTitle(text)
  {
    var start = text.indexOf('<title>'), end = text.indexOf('</title>');
    return text.slice(start+7, end); // '<title>'.length = 7
  }

  showLoadingGif(kandil.msg.loading_module);
  try {
    $.ajax({url: doc_url, dataType: "text", error: errorHandler,
      success: function(data) {
        // Reset some global variables.
        kandil.moduleFQN = modFQN;
        kandil.sourceCode = [];
        document.title = extractTitle(data);
        $("#kandil-content")[0].innerHTML = extractContent(data);
        $("#apipanel > ul").remove(); // Delete old API list.
        if ($("#apitab").hasClass("current"))
          initAPIList();
        else
          $("#apitab").click(function lazyLoad() {
            $(this).unbind("click", lazyLoad); // Remove the lazyLoad handler.
            initAPIList();
          });
        initSymbolTags();
        $("#apiqs")[0].qs.resetFirstFocusHandler();
        hideLoadingGif();
      }
    });
  }
  catch(e){ errorHandler(); }
}

function showLoadingGif(msg)
{
  if (!msg)
    msg = "";
  var loading = $("#kandil-loading");
  if (!loading.length)
    (loading = $("<div id='kandil-loading'><img src='img/loading.gif'/>&nbsp;<span/></div>")),
    $(document.body).append(loading);
  $("span", loading).html(msg);
}

function hideLoadingGif()
{
  fadeOutRemove($("#kandil-loading"), 1, 500);
}

/// Initializes the symbol list under the API tab.
function initializeSymbolTree()
{
  var sym_tags = kandil.symbolTags;
  if (!sym_tags.length)
    return;
  // Prepare the symbol list.
  var header = sym_tags[0]; // Header of the page.
  sym_tags = sym_tags.slice(1); // Every other symbol.

  var symDict = {};
  var root = new M(kandil.moduleFQN);
  var list = [root];
  symDict[''] = root; // The empty string has to point to the root.
  for (var i = 0, len = sym_tags.length; i < len; i++)
  {
    var sym_tag = sym_tags[i];
    var sym = new Symbol(sym_tag.name, sym_tag.getAttribute("kind"));
    list.push(sym); // Append to flat list.
    symDict[sym.parent_fqn].sub.push(sym); // Append to parent.
    symDict[sym.fqn] = sym; // Insert the symbol itself.
  }
  kandil.symbolTree.root = root;
  kandil.symbolTree.list = list;
  kandil.symbolTree.symbol_tags = sym_tags;
}

/// Returns an image tag for the provided kind of symbol.
function getPNGIcon(kind)
{
  if (SymbolKind.isFunction(kind))
    kind = "function";
  return "<img src='img/icon_"+kind+".png'/>";
}

function createSymbolsUL(panel)
{ // TODO: put loading.gif in the center of ul and animate showing/hiding?
  var root = kandil.symbolTree.root;
  var ul = $("<ul class='tview'><li class='root'><i/>"+getPNGIcon("module")+
    "<label><a href='#m-"+root.fqn+"'>"+root.fqn+"</a></label></li>"+
    "<li><img src='img/loading.gif'/></li></ul>");
  panel.append(ul);
  if (root.sub.length)
    $(ul[0].firstChild).append(createSymbolsUL_(root.sub));
  $(ul[0].lastChild).remove();
  return ul;
}

function createModulesUL(panel)
{
  var root = kandil.packageTree.root;
  var ul = $("<ul class='tview'><li class='root'><i/>"+getPNGIcon("package")+
    "<label>/</label></li><li><img src='img/loading.gif'/></li></ul>");
  panel.append(ul);
  if (root.sub.length)
    $(ul[0].firstChild).append(createModulesUL_(root.sub));
  $(ul[0].lastChild).remove();
  return ul;
}

/// Constructs a ul (enclosing nested ul's) from the symbols data structure.
function createSymbolsUL_(symbols)
{
  var list = "<ul>";
  for (var i = 0, len = symbols.length; i < len; i++)
  {
    var sym = symbols[i];
    var hasSubSymbols = sym.sub && sym.sub.length;
    var leafClass = hasSubSymbols ? '' : ' class="leaf"';
    var parts = sym.name.partition(':');
    var label = parts[0], number = parts[1];
    label = number ? label+"<sub>"+number+"</sub>" : label; // An index.
    list += "<li"+leafClass+"><i/>"+getPNGIcon(sym.kind)+
            "<label><a href='#"+sym.fqn+"'>"+label+"</a></label>";
    if (hasSubSymbols)
      list += createSymbolsUL_(sym.sub);
    list += "</li>";
  }
  return list + "</ul>";
}

/// Constructs a ul (enclosing nested ul's) from the package tree.
function createModulesUL_(symbols)
{
  var list = "<ul>";
  for (var i = 0, len = symbols.length; i < len; i++)
  {
    var sym = symbols[i];
    var hasSubSymbols = sym.sub && sym.sub.length;
    var leafClass = hasSubSymbols ? '' : ' class="leaf"';
    list += "<li"+leafClass+">"+ //  kind='"+sym.kind+"'
            "<i/>"+getPNGIcon(sym.kind)+"<label>";
    if (hasSubSymbols)
      list += sym.name + "</label>" + createModulesUL_(sym.sub);
    else
      list += "<a href='"+sym.fqn+".html'>"+sym.name+"</a></label>"
    list += "</li>";
  }
  return list + "</ul>";
}

/// Extracts the code from the HTML file and sets kandil.sourceCode.
function setSourceCode(html_code)
{
  html_code = html_code.split(/<pre class="sourcecode">|<\/pre>/);
  if (html_code.length == 3)
  { // Get the code between the pre tags.
    var code = html_code[1];
    // Split on newline.
    kandil.sourceCode = code.split(/\n|\r\n?|\u2028|\u2029/);
  }
}

/// Returns the relative URL to the source code of this module.
function getSourceCodeURL()
{
  return "./htmlsrc/" + kandil.moduleFQN + ".html";
}

/// Shows the code for a symbol in a div tag beneath it.
function showCode(symbol)
{
  var dt_tag = symbol.parent()[0];
  var line_beg = parseInt(symbol.attr("beg"));
  var line_end = parseInt(symbol.attr("end"));

  if (dt_tag.code_div)
  { // Remove the displayed code div.
    dt_tag.code_div.remove();
    dt_tag.code_div = null;
    return;
  }
  // Assign a dummy tag to block quick, multiple clicks while loading.
  dt_tag.code_div = $("<div/>");

  function show()
  { // The function that actually displays the code.
    if ($(dt_tag).is("h1")) { // Special case.
      line_beg = 1;
      line_end = kandil.sourceCode.length -2;
    }
    // Get the code lines.
    var code = kandil.sourceCode.slice(line_beg, line_end+1);
    code = code.join("\n");
    // Create the lines column.
    var lines = "", srcURL = getSourceCodeURL();
    for (var num = line_beg; num <= line_end; num++)
      lines += '<a href="' + srcURL + '#L' + num + '">' + num + '</a>\n';
    var table = $('<table class="d_code"/>');
    table.append('<tr><td class="d_codelines"><pre>'+lines+'</pre></td>'+
                 '<td class="d_codetext"><pre>'+code+'</pre></td></tr>');
    // Create a container div.
    var div = $('<div class="loaded_code"/>');
    div.append(table);
    $(dt_tag).after(div);
    // Store the created div.
    dt_tag.code_div = div;
  }

  if (kandil.sourceCode.length == 0)
  { // Load the HTML source code file.
    var doc_url = getSourceCodeURL();

    function errorHandler(request, error, exception)
    {
      hideLoadingGif();
      var msg = kandil.msg.failed_code.format(doc_url);
      msg = $("<p class='ajaxerror'>"+msg+"</p>");
      $(document.body).append(msg);
      fadeOutRemove(msg, 5000, 500);
    }

    showLoadingGif(kandil.msg.loading_code);
    try {
      $.ajax({url: doc_url, dataType: "text", error: errorHandler,
        success: function(data) {
          setSourceCode(data);
          show();
          hideLoadingGif();
        }
      });
    }
    catch(e){ errorHandler(); }
  }
  else // Already loaded. Show the code.
    show();
}

function reportBug()
{
  // TODO: implement.
}

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
Treeview.prototype.saveState = function(cookie_name) {
  if (this.savedState)
    return;
  var ul_tags = this.ul.getElementsByTagName("ul"), list = "";
  for (var i = 0, len = ul_tags.length; i < len; i++)
    if (ul_tags[i].parentNode.hasClass("closed"))
      list += i + ",";
  if (list)
    cookie(cookie_name, list.slice(0, -1), 30);
  else
    cookie.del(cookie_name);
  this.savedState = true;
};
/// Loads the state of a treeview from a cookie.
Treeview.prototype.loadState = function(cookie_name) {
  var list = cookie(cookie_name);
  if (!list)
    return;
  var ul_tags = this.ul.getElementsByTagName("ul");
  list = list.split(",");
  for (var i = 0, len = list.length; i < len; i++)
    ul_tags[list[i]].parentNode.addClass("closed");
};
