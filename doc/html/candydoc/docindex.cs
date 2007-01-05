<html>
 <head>
  <meta http-equiv="content-type" content="text/html; charset=utf-8">
  <link rel="stylesheet" href="css/style.css" type="text/css" />
  <title>Tango API Index</title>
 </head>
 <body>
  <a href="../../">Project Pages</a>
  <h2>Tango API Index</h2>
  <p>Use the Browser incremental search facility to quickly locate a particular
    module name.</p>
  <p>Source code for each module is available by clicking the <a href="#">big
    blue title</a> at the top of each page, and all other links therein lead to
    Wiki annotations. Packages are sorted by name:</p>
  <ul>
<?cs each:module = modules ?>   <li><a href="<?cs var:module ?>.html"><?cs 
  var:module ?></a></li>
<?cs /each ?>
  </ul>
 </body>
</html>
