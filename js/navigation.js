/// Author: Aziz Köksal
/// License: zlib/libpng

/// A global object for accessing various properties of the application.
var kandil = {
  /// The original module loaded normally by the browser (not JavaScript.)
  originalModuleFQN: "",
  /// An object that represents the symbol tree.
  symbolTree: null,
  /// An array of all the lines of this module's source code.
  sourceCode: null,
  /// Represents the package tree (located in generated modules.js).
  packageTree: g_packageTree,
  /// Application settings.
  settings: {
    navbar_html: '<div id="navbar">\
  <div id="navtabs">\
    <span id="apitab">{apitab_label}</span>\
    <span id="modtab">{modtab_label}</span>\
  </div>\
  <div id="panels">\
    <div id="apipanel"><div class="scroll"><div class="offsetTop"/></div></div>\
    <div id="modpanel"><div class="scroll"><div class="offsetTop"/></div></div>\
  </div>\
</div>', /// The navbar HTML code prepended to <body>.
    splitbar_html: "<div title='{splitbar_title}' class='splitbar'>\
<div class='handle'/></div>", /// The splitbar's HTML code.
    filter_html : '<div class="filter_elem"><table><tr><td width="1">\
<img src="img/icon_magnifier.png">\
</td><td></td></tr></table></div>',
    navbar_width: 250,    /// Initial navigation bar width.
    navbar_minwidth: 180, /// Minimum resizable width.
    navbar_collapsewidth : 50, /// Hide the navbar at this width.
    default_tab: "#apitab", /// Initial, active tab ("#apitab", "#modtab").
    apitab_label: getPNGIcon("variable")+"Symbols",
    modtab_label: getPNGIcon("module")+"Modules",
    /// Load modules with JavaScript?
    dynamic_mod_loading: true && !!window.history,
    tview_save_delay: 5*1000, /// Delay for saving a treeview's state after
                              /// each collapse and expand event of a node.
    tooltip: {
      delay: 1000, /// Delay in milliseconds before a tooltip is shown.
      delay2: 200, /// Delay before the next tooltip is shown.
      fadein: 200, /// Fade-in speed in ms.
      fadeout: 200, /// Fade-out speed in ms.
      offset: {x:16, y:16}, /// (x, y) offsets from the mouse position.
    },
    cookie_life: 30, /// Life time of cookies in days.
    qs_delay: 500, /// Delay after last key press before quick search starts.
  },
  saved: { /// Functions for saving and getting data.
    splitbar_pos: function(val) { /// The position of the splitbar.
      return parseInt(storage.readwrite("splitbar_pos", val));
    },
    splitbar_collapsed: function(val) { /// The collapse state.
      return storage.readwrite("splitbar_collapsed", val) == "true";
    },
    active_tab: curry(storage.readwrite, "active_tab"), /// Last active tab.
    modules_ul: curry(storage.readwrite, "modules_ul"), /// The module list.
    symbols_ul: function(val) { /// The symbol list as HTML.
      return storage.readwrite("symbols_ul:"+kandil.moduleFQN, val);
    },
    modules_sb: curry(storage.readwrite, "modules_sb"), /// Scrollbar position.
    symbols_sb: function(val) { /// Scrollbar position of the symbol list.
      return storage.readwrite("symbols_sb:"+kandil.moduleFQN, val);
    },
    modules_tv_state: curry(storage.readwrite, "modules_tv_state"),
    symbols_tv_state: function(val) {
      return storage.readwrite("symbols_tv_state:"+kandil.moduleFQN, val);
    },
  },
  save: null, /// An alias for "saved".
  $: { /// Cache of jQuery objects. E.g.: kandil.$.navbar = $("#navbar")
    selectors: { /// VariableName : CSS Selector
      navbar: "#navbar",
      content: "#kandil-content",
      apitab: "#apitab", modtab: "#modtab",
      apipanel: "#apipanel", modpanel: "#modpanel",
    },
    initialize: function() { // This is a lazy load mechanism.
      // Getters are removed and replaced with a jQuery object.
      S = kandil.$;
      for (varname in S.selectors) {
        var getter = function f() {
          delete this[f.varname]; // Remove the getter.
          return this[f.varname] = window.jQuery(f.selector);
        };
        getter.varname = varname;
        getter.selector = S.selectors[varname];
        Object.getter(S, varname, getter);
      }
    }
  },
  msg: {
    failed_module: "Failed loading the module from '{0}'!",
    failed_code: "Failed loading code from '{0}'!",
    loading_module: "Loading module...",
    loading_code: "Loading source code...",
    got_empty_file: "Received an empty file.",
    filter: "Filter...", /// Initial text in the filter boxes.
    splitbar_title: "Drag to resize. Double-click to close or open.",
    no_match: "No match...",
    symboltitle: "Show source code", /// The title attribute of symbols.
    permalink: "Permalink to this symbol",
    srclink: ' <a href="{}" class="srclink" \
title="Go to the HTML source file">#</a>',
    dt_tagtitle: "Click to show the symbol’s source code",
    code_expand: "Double-click to expand.",
    code_shrink: "Double-click to shrink.",
  },
  resize_func: function() {
    // Unfortunately the layout must be scripted. Couldn't find a way
    // to make it work with pure CSS in all targeted browsers.
    // The height is set so that the panel is scrollable.
    // h = viewport_height - y_offset_from_viewport - 2px_margin.
    // offsetTop comes from a dummy div, which has 'position:relative'.
    var docelem = document.documentElement;
    var new_height = docelem.clientHeight - this.firstChild.offsetTop - 2;
    this.style.height = (new_height < 0 ? 0 : new_height)+"px";
  },
  symbolTree_getter: function f() {
    if (f.fqn != kandil.moduleFQN)
    { // Load the JSON file. Cache in an attribute of this function.
      f.fqn = kandil.moduleFQN;
      var xhr = $.ajax({
        url: "symbols/"+f.fqn+".json", dataType: "text", async: false
      });
      f.symbolTree = Symbol.getTree(xhr.responseText, f.fqn);
      f.symbolTree.symbol_tags = kandil.$.symbols;
    }
    return f.symbolTree;
  },
  /// Returns true if vertical scrollbars are present.
  hasVScrollbar: function(tag) {
    return tag.scrollHeight > tag.clientHeight;
  },
  /// Returns true if horizontal scrollbars are present.
  hasHScrollbar: function(tag) {
    return tag.scrollWidth > tag.clientWidth;
  },
  setCreationTime: function(time) {
    var stored_time = storage.creationTime;
    if (!stored_time)
      storage.creationTime = time;
    else if (stored_time != time)
      storage.clear(); // Need to clear storage, if docs are new.
  },
};

(function init_kandil() {
  // Some things that can be done while the document is loading:
  kandil.save = kandil.saved;
  kandil.setCreationTime(g_creationTime);
  kandil.$.initialize();
  cookie.life = kandil.settings.cookie_life;

  Object.getter(kandil, "symbolTree", kandil.symbolTree_getter);


  window.onpopstate = function(event) {
    var fqn = (event.state && event.state.fqn) || kandil.originalModuleFQN;
    app.loadNewModule(fqn, false);
  }
})();

/// Execute when document is ready.
$(function main() {
  if (navigator.vendor == "KDE")
    document.body.addClass("konqueror");
//   else if (window.opera) // Not needed atm.
//     document.body.addClass("opera");

  kandil.originalModuleFQN = kandil.moduleFQN = document.body.id;

  // Create the navigation bar.
  var navbar = kandil.settings.navbar_html.format(kandil.settings);
  $(document.body).prepend(navbar);

  app.createSplitbar(); // Create first, so the width of the navbar is set.
  app.createQuickSearchInputs();
  app.initSymbolTags();
  app.initTabs();

  // Scripted layout. :´(
  var divs = $("#panels>div>div.scroll");
  function resize_divs(){ divs.each(kandil.resize_func); }
  $(window).resize(resize_divs);
  resize_divs();
});

var app = {
  kandil : kandil,
  /// Initializes the tabs.
  initTabs : function() {
  // Assign click event handlers for the tabs.
  function makeCurrentTab() {
    var tab = this;
    if (tab.hasClass("current")) return;
    $(".current", tab.parentNode).removeClass('current');
    tab.addClass('current');
    // Don't use .hide(), in order to preserve layout data.
    $("#panels > *").css("height", "0px"); // Hide all panels.
    tab.panel.css("height", "auto"); // Show the panel under this tab.
    kandil.save.active_tab("#"+tab.id); // Save name of the active tab.
    $(window).resize();
  }

  var apitab = kandil.$.apitab, modtab = kandil.$.modtab;

  apitab[0].panel = kandil.$.apipanel;
  apitab.lazyLoad = function _() {
    apitab.unbind("click", _); // Remove the lazyLoad handler.
    app.initAPIList();
  };
  apitab.click(makeCurrentTab).click(apitab.lazyLoad);

  modtab[0].panel = kandil.$.modpanel;
  modtab.lazyLoad = function _() {
    modtab.unbind("click", _); // Remove the lazyLoad handler.
    // Create the list.
    var ul = app.createModulesUL(this.panel.find(">div.scroll"));
    var tv = new Treeview(ul);
    tv.loadState(kandil.saved.modules_tv_state);
    tv.bind("save_state",
      curry2(tv, tv.saveState, kandil.saved.modules_tv_state));
    ul.parent().scroll(function() {
      kandil.save.modules_sb(this.scrollTop);
    });
    setTimeout(function() {
      ul.parent()[0].scrollTop = kandil.save.modules_sb();
    });

    if (kandil.settings.dynamic_mod_loading)
      this.panel.find(".tview a").click(function(event) {
        event.preventDefault();
        var modFQN = this.parentNode.title; // Fqn is in title attribute.
        if (kandil.moduleFQN != modFQN.slice())
          app.loadNewModule(modFQN, true);
      });
    kandil.packageTree.initList(); // Init the list property.
  };
  modtab.click(makeCurrentTab).click(modtab.lazyLoad);
  // Activate the tab that has been saved or activate the default tab.
  var tab = kandil.saved.active_tab() || kandil.settings.default_tab;
  $(tab).click();
},

  /// Creates the quick search text inputs.
  createQuickSearchInputs : function() {
  var options = {text: kandil.msg.filter, delay: kandil.settings.qs_delay};
  var qs = [
    new QuickSearch("apiqs", options), new QuickSearch("modqs", options)
  ];

  // Insert the input tags.
  var table = $(kandil.settings.filter_html);

  var table2 = table.clone();

  table.find("td").slice(1).append(qs[0].input);
  kandil.$.apipanel.prepend(table);
  table2.find("td").slice(1).append(qs[1].input);
  kandil.$.modpanel.prepend(table2);

  qs[0].input.tag_selector = "#apipanel .tview";
  Object.getter(qs[0].input, "symbols", function(){return kandil.symbolTree});
  $.extend(qs[1].input,
    {tag_selector: "#modpanel .tview", symbols: kandil.packageTree});

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
},

  /// Installs event handlers to show tooltips for symbols.
  installTooltipHandlers : function() {
  var ul = kandil.$.apipanel.find(".tview");
  var tooltip = $.extend({
    current: null, // Current tooltip.
    target: null, // The target to show a tooltip for.
    TID: null, // Timeout-ID for delays.
  }, kandil.settings.tooltip); // Add tooltip settings.
  // Shows the tooltip at a calculated position.
  function showTooltip(e)
  { // Get the content of the tooltip.
    var a_tag = tooltip.target,
        a_tag_name = a_tag.href.rpartition('#', 1),
        sym_tag = $(document.getElementsByName(a_tag_name)[0]);
    sym_tag = sym_tag.parent().clone();
    sym_tag.find(".plink, .srclink").remove();
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
  ul.find(">.root>ul").find("a").mouseover(function(e) {
    clearTimeout(tooltip.TID);
    tooltip.target = this;
    // Delay normally if this is the first tooltip being displayed, then
    // delay for a fraction of the normal time in subsequent mouseovers.
    var delay = !tooltip.current ? tooltip.delay : tooltip.delay2;
    tooltip.TID = setTimeout(function(){ showTooltip(e); }, delay);
  }).mouseout(function(e) {
    clearTimeout(tooltip.TID);
    if (tooltip.current)
      app.fadeOutRemove(tooltip.current, 0, tooltip.fadeout);
    tooltip.TID = setTimeout(function() { tooltip.current = null; }, 100);
  });
},

  /// Creates the split bar for resizing the navigation panel and content.
  createSplitbar : function() {
  var settings = kandil.settings, saved = kandil.saved;
  var splitbar = $(settings.splitbar_html.format(kandil.msg))[0];
  var navbar = kandil.$.navbar[0], content = kandil.$.content[0];
  var minwidth = settings.navbar_minwidth,
      collapsewidth = settings.navbar_collapsewidth;

  var body = document.body, html_tag = document.documentElement;
  body.appendChild(splitbar), // Insert the splitbar into the document.

  // Event handlers and other functions:
  splitbar.isMoving = false; // Moving status of the splitbar.
  splitbar.setPos = function(x) {
    this.collapsed = false;
    if (x < collapsewidth)
      (this.collapsed = true),
      x = 0;
    else if (x < minwidth)
      x = minwidth;
    if (x+50 > html_tag.clientWidth)
      x = html_tag.clientWidth - 50;
    if (x)
      this.openPos = x;
    navbar.style.width =
    content.style.marginLeft =
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
  // Register event handlers.
  $(splitbar).mousedown(mouseDownHandler)
             .dblclick(function(e) {
    var pos = this.collapsed ? this.openPos : 0; // Toggle the position.
    this.setPos(pos);
    this.save();
  });
  // Set initial position.
  var pos = saved.splitbar_pos() || settings.navbar_width;
  splitbar.openPos = pos;
  splitbar.collapsed = saved.splitbar_collapsed();
  if (splitbar.collapsed)
    pos = 0;
  splitbar.setPos(pos);
  return splitbar;
},


  initSymbolTags : function() {
  kandil.$.symbols = $(".symbol");

  function addStuffLazily(decl)
  {
    var kandil = window.kandil;
    var symbol = decl.find(">.symbol");
    // Append the '#'-link.
    var src_link = symbol[0].attributes.getNamedItem("href").value;
    src_link = kandil.msg.srclink.format(src_link);
    decl.append(src_link);

    // Add code display functionality to symbol links.
    symbol.click(function(e) {
      e.preventDefault();
      app.showCode($(this));
    }).attr("title", kandil.msg.symboltitle);

    decl.click(function(e) {
      if (e.target == this)
        app.showCode($(">.symbol", this));
    }).attr("title", kandil.msg.dt_tagtitle);

    // Prepare permalinks.
    var plink = decl.find('>.plink');
    // Set the title of the permalinks.
    plink.attr("title", kandil.msg.permalink);
  }

  // Prepare 'dt.decl' tags.
  var decls = $('.decl');
  decls.add("h1.module").mouseover(function f() {
    var decl = $(this).unbind("mouseover", f);
    addStuffLazily(decl);
  });
},

  /// Adds click handlers to symbols and inits the symbol list.
  initAPIList : function() {
  // Create the HTML text and append it to the api panel.
  var ul = app.createSymbolsUL(kandil.$.apipanel.find(">div.scroll"));
  var tv = new Treeview(ul);
  tv.loadState(kandil.saved.symbols_tv_state);
  tv.bind("save_state",
    curry2(tv, tv.saveState, kandil.saved.symbols_tv_state));
  ul.parent().scroll(function() {
    kandil.save.symbols_sb(this.scrollTop);
  });
  setTimeout(function() {
    ul.parent()[0].scrollTop = kandil.save.symbols_sb();
  });
  app.installTooltipHandlers();
},

  /// Loads a new module and updates the content pane.
  loadNewModule : function(moduleFQN, addHistory) {
  var kandil = window.kandil;
  // Load the module's file.
  var doc_url = moduleFQN + ".html";

  function errorHandler(request, error, e)
  {
    app.hideLoadingGif();
    var msg = kandil.msg.failed_module.format(doc_url);
    msg = $(("<p class='ajaxerror'>{0}<br/><br/>\
{1.name}: {1.message}</p>").format(msg, e));
    $(document.body).append(msg);
    app.fadeOutRemove(msg, 5000, 500);
  }

  function extractParts(text)
  { // NB: Profiled code.
    var parts = {};
    var start = text.indexOf('<title>'), end = text.indexOf('</title>');
    parts.title = text.slice(start+7, end) // '<title>'.length = 7
    start = text.indexOf('<div class="module">');
    end = text.lastIndexOf('</div>\n</body>');
    parts.content = text.slice(start, end);
    return parts;
  }

  app.showLoadingGif(kandil.msg.loading_module);
  try {
    $.ajax({url: doc_url, dataType: "text", error: errorHandler,
      async: false,
      success: function(text) {
        if (text == "")
          return errorHandler(0, 0, Error(kandil.msg.got_empty_file));

        var parts = extractParts(new String(text));
        // Reset some global variables.
        kandil.moduleFQN = moduleFQN;
        kandil.sourceCode = null;
        $("html")[0].scrollTop = 0; // Scroll the document to the top.
        kandil.$.content[0].innerHTML = parts.content;
        app.initSymbolTags();
        // Update the API panel.
        kandil.$.apipanel.find(".tview").remove(); // Delete old API list.
        kandil.$.apitab.unbind("click", kandil.$.apitab.lazyLoad)
          .click(kandil.$.apitab.lazyLoad);
        if (kandil.$.apitab.hasClass("current")) // Is the API tab selected?
          kandil.$.apitab.lazyLoad(); // Load the contents then.
        $("#apiqs")[0].qs.resetFirstFocusHandler();
        // Change the title and hide the loading animation.
        document.title = parts.title;
        app.hideLoadingGif();

        if (addHistory)
          window.history.pushState({fqn:moduleFQN}, parts.title, doc_url);
      }
    });
  }
  catch(e){ errorHandler(0, 0, e); }
},

  /// Shows a little message for feedback.
  showLoadingGif : function(msg) {
  if (!msg)
    msg = "";
  var loading = $("#kandil-loading");
  if (!loading.length)
    (loading = $("<div id='kandil-loading'>\
<img src='img/loading.gif'/>&nbsp;<span/></div>")),
    $(document.body).append(loading).addClass("progress");
  $("span", loading).html(msg);
},
  /// Hides the feedback message.
  hideLoadingGif : function() {
  $(document.body).removeClass("progress");
  app.fadeOutRemove($("#kandil-loading"), 1, 500);
},

  createSymbolsUL : function(panel) {
  var root = kandil.symbolTree.root;
  var ul = $('<ul class="tview"><li class="root"><i></i>{0}\
<label><a href="#m-{1}">{1}</a></label></li>\
<li><img src="img/loading.gif"/></li></ul>'
    .format(getPNGIcon("module"), root.fqn));
  panel.append(ul);
  if (root.sub.length) {
    if (!(content = kandil.saved.symbols_ul()))
      kandil.save.symbols_ul(content = app.createSymbolsUL_(root.sub));
    ul[0].firstChild.innerHTML += content;
  }
  $(ul[0].lastChild).remove();
  return ul;
},

  createModulesUL : function(panel) {
  var root = kandil.packageTree.root;
  var ul = $('<ul class="tview"><li class="root"><i></i>{0}\
<label>{1}</label></li>\
<li><img src="img/loading.gif"/></li></ul>'
    .format(getPNGIcon("package"), "Module Tree"));
  panel.append(ul);
  if (root.sub.length) {
    if (!(content = kandil.saved.modules_ul()))
      kandil.save.modules_ul(content = app.createModulesUL_(root.sub));
    ul[0].firstChild.innerHTML += content;
  }
  $(ul[0].lastChild).remove();
  return ul;
},

  /// Constructs a ul (enclosing nested ul's) from the symbols data structure.
  createSymbolsUL_ : function fn(symbols) {
  var list = "<ul>";
  for (var i = 0, len = symbols.length; i < len; i++)
  {
    var sym = symbols[i];
    var hasSubSymbols = sym.sub && sym.sub.length;
    var leafClass = hasSubSymbols ? '' : ' class="leaf"';
    var parts = sym.name.partition(':');
    var label = parts[0], number = parts[1];
    label = number ? label+"<sub>"+number+"</sub>" : label; // An index.
    list += "<li"+leafClass+"><i></i>"+getPNGIcon(sym.kind)+
            "<label><a href='#"+sym.fqn+"'>"+label+"</a></label>";
    if (hasSubSymbols)
      list += fn(sym.sub);
    list += "</li>";
  }
  return list + "</ul>";
},

  /// Constructs a ul (enclosing nested ul's) from the package tree.
  createModulesUL_ : function fn(symbols) {
  var list = "<ul>";
  for (var i = 0, len = symbols.length; i < len; i++)
  {
    var sym = symbols[i];
    var hasSubSymbols = sym.sub && sym.sub.length;
    var leafClass = hasSubSymbols ? '' : ' class="leaf"';
    list += "<li"+leafClass+">"+ //  kind='"+sym.kind+"'
            "<i></i>"+getPNGIcon(sym.kind)+
            '<label title="'+sym.fqn+'">';
    if (hasSubSymbols)
      list += sym.name + "</label>" + fn(sym.sub);
    else
      list += "<a href='"+sym.fqn+".html'>"+sym.name+"</a></label>"
    list += "</li>";
  }
  return list + "</ul>";
},

  /// Extracts the code from the HTML file. Cached in kandil.sourceCode.
  setSourceCode : function(html_code) {
  // NB: Profiled code.
  var start = html_code.indexOf('<pre class="sourcecode">'),
      end = html_code.lastIndexOf('</pre>');
  if (start < 0 || end < 0)
    return;
  // Get the code between the pre tags.
  var code = html_code.slice(start, end);
  // Split on newline.
  kandil.sourceCode = code.split(/\n|\r\n|\r|\u2028|\u2029/);
},

  /// Returns the relative URL to the source code of this module.
  getSourceCodeURL : function() {
  return "htmlsrc/" + kandil.moduleFQN + ".html";
},

  /// Shows the code for a symbol in a div tag beneath it.
  showCode : function(symbol) {
  var dt_tag = symbol.parent()[0];

  if (dt_tag.code_div)
  { // Remove the displayed code div.
    dt_tag.code_div.remove();
    dt_tag.code_div = null;
    return;
  }
  // Assign a dummy tag to block quick, multiple clicks while loading.
  dt_tag.code_div = $("<div/>");

  if (kandil.sourceCode == null)
    app.loadHTMLCode();

  // The function that actually displays the code.
  var loc_tuple = kandil.symbolTree.dict.get(symbol[0].name).loc;
  var line_beg = loc_tuple[0];
  var line_end = loc_tuple[1];
  // Get the code lines.
  var code = kandil.sourceCode.slice(line_beg, line_end+1);
  code = code.join("\n");
  // Create the lines column.
  var lines = "", srcURL = app.getSourceCodeURL();
  // TODO: cache lines?
  for (var num = line_beg; num <= line_end; num++)
    lines += '<a href="' + srcURL + '#L' + num + '">' + num + '</a>\n';
  var table = $('<table class="d_code"/>');
  table[0].innerHTML = '<tr><td class="d_codelines"><pre>'+lines+
    '</pre></td><td class="d_codetext"><pre>'+code+'</pre></td></tr>';
  // Create a container div.
  var div = $('<div class="loaded_code"/>');
  div.append(table);
  $(dt_tag).after(div);
  // Store the created div.
  dt_tag.code_div = div;
  if (kandil.hasVScrollbar(div[0]) && (msg = kandil.msg))
    div.attr("title", msg.code_expand)
       .dblclick(function(e) {
      var val = this.expandedState ?
        ["", msg.code_expand] : ["none", msg.code_shrink];
      this.expandedState = !this.expandedState;
      $(this).css("max-height", val[0]).attr("title", val[1]);
      // e.preventDefault();
      // TODO:
      // show/hide line numbers | expand/minimize
      // A resize bar at the bottom that adjusts max-height when dragged?
    });
},

  /// Loads the HTML source code file and keeps it cached.
  loadHTMLCode : function() {
  var doc_url = app.getSourceCodeURL();

  function errorHandler(request, error, e)
  { // Appends a p-tag to the document. Can be styled with CSS.
    app.hideLoadingGif();
    var msg = kandil.msg.failed_code.format(doc_url);
    msg = $(("<p class='ajaxerror'>{0}<br/><br/>\
{1.name}: {1.message}</p>").format(msg, e));
    $(document.body).append(msg);
    app.fadeOutRemove(msg, 5000, 500);
  }

  app.showLoadingGif(kandil.msg.loading_code);
  try {
    var xhr = $.ajax({url: doc_url, dataType: "text",
      error: errorHandler, async: false});
    var text = xhr.responseText;
    if (text == "")
      return errorHandler(0, 0, Error(kandil.msg.got_empty_file));
    text = new String(text);
    app.setSourceCode(text);
    app.hideLoadingGif();
  }
  catch(e){ errorHandler(0, 0, e); }
},

  /// Delays for 'delay' ms, fades out an element in 'fade' ms and removes it.
  fadeOutRemove : function(tag, delay, fade) {
  tag = $(tag);
  setTimeout(function(){
    tag.fadeOut(fade, function(){ tag.remove() });
  }, delay);
},

}; // End of app variable value.



/// Returns an image tag for the provided kind of symbol.
function getPNGIcon(kind) {
  if (SymbolKind.isFunction(kind))
    kind = "function";
  return "<img src='img/icon_"+kind+".png'/>";
}

function reportBug()
{
  // TODO: implement.
}

