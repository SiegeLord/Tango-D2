#!/usr/bin/python
# -*- coding: utf-8 -*-
# Author: Aziz Köksal
import os, re
from path import Path
from common import *
from html2pdf import PDFGenerator

EXCLUDES = ["std/intrinsic.di", "std/stdarg.di", "std/c/stdarg.di"]

def exclude(file):
    for f in EXCLUDES:
        if file.endswith(f):
            return True
    return False

def copy_runtime_files(path):
  print "Copying Tango runtime files."

  for NAME in ("BitManip", "Exception", "Memory", "Runtime", "Thread"):
    FILE = path/("lib/common/tango/core/%s.d" % NAME)
    print "Copying %s to %s" % (FILE, path/"tango/core/")
    FILE.copy(path/"tango/core/")

def copy_files(DIL, TANGO, DEST):
  """ Copies required files to the destination folder. """
  for FILE, DIR in (
      (TANGO.license, DEST/"License.txt"), # Tango's license.
      (DIL.DATA/"html.css", DEST.HTMLSRC),
      (DIL.KANDIL.style,    DEST.CSS)):
    FILE.copy(DIR)
  if TANGO.favicon.exists:
    TANGO.favicon.copy(DEST.IMG/"favicon.png")
  for FILE in DIL.KANDIL.jsfiles:
    FILE.copy(DEST.JS)
  for img in DIL.KANDIL.images:
    img.copy(DEST.IMG)

def get_tango_version(path):
  for line in open(path):
    m = re.search("Major\s*=\s*(\d+)", line)
    if m: major = int(m.group(1))
    m = re.search("Minor\s*=\s*(\d+)", line)
    if m: minor = int(m.group(1))
  return "%s.%s.%s" % (major, minor/10, minor%10)

def write_tango_ddoc(path, favicon, revision):
  revision = "?rev=" + revision if revision != None else ''
  favicon = "" if not favicon.exists else \
    'FAVICON = <link href="./img/favicon.png" rel="icon" type="image/png"/>'
  open(path, "w").write("""
LICENSE = see $(LINK2 http://www.dsource.org/projects/tango/wiki/LibraryLicense, license.txt)
REPOFILE = http://www.dsource.org/projects/tango/browser/trunk/$(DIL_MODPATH)%(revision)s
CODEURL =
MEMBERTABLE = <table>$0</table>
ANCHOR = <a name="$0"></a>
LB = [
RB = ]
SQRT = √
NAN = NaN
SUP = <sup>$0</sup>
BR = <br/>
%(favicon)s
""" % locals()
  )

def write_PDF(DIL, SRC, VERSION, TMP):
  TMP = TMP/"pdf"
  TMP.exists or TMP.mkdir()

  pdf_gen = PDFGenerator()
  pdf_gen.fetch_files(DIL, TMP)
  html_files = SRC.glob("*.html")
  html_files = filter(lambda path: path.name != "index.html", html_files)
  # Get the logo if present.
  logo_png = Path("logo_tango.png")
  if logo_png.exists:
    logo_png.copy(TMP)
    logo = "<br/>"*2 + "<img src='%s'/>" % logo_png.name
    #logo_svg = open(logo_svg).read()
    #logo_svg = "<br/>"*2 + logo_svg[logo_svg.index("\n"):]
  else:
    logo = ''
  symlink = "http://dil.googlecode.com/svn/doc/Tango_%s" % VERSION
  params = {
    "pdf_title": "Tango %s API" % VERSION,
    "cover_title": "Tango %s<br/><b>API</b>%s" % (VERSION, logo),
    "author": "Tango Team",
    "subject": "Programming API",
    "keywords": "Tango standard library API documentation",
    "x_html": "HTML",
    "nested_toc": True,
    "symlink": symlink
  }
  pdf_gen.run(html_files, SRC/("Tango.%s.API.pdf"%VERSION), TMP, params)

def create_index(dest, prefix_path, files):
  files.sort()
  text = ""
  for filepath in files:
    fqn = get_module_fqn(prefix_path, filepath)
    text += '  <li><a href="%(fqn)s.html">%(fqn)s</a></li>\n' % locals()
  style = "list-style-image: url(img/icon_module.png)"
  text = ("Ddoc\n<ul style='%s'>\n%s\n</ul>"
          "\nMacros:\nTITLE = Index") % (style, text)
  open(dest, 'w').write(text)

def get_tango_path(path):
  path = firstof(Path, path, Path(path))
  path.SRC = path/"import"
  is_svn = not path.SRC.exists
  if is_svn:
    path.SRC.mkdir()
    print "Copying tango/, std/ and object.di to import/."
    (path/"tango").copytree(path.SRC/"tango")
    (path/"std").copytree(path.SRC/"std")
    (path/"object.di").copy(path.SRC)
  path.license = path/"LICENSE"
  path.favicon = Path("tango_favicon.png") # Look in CWD atm.
  return path

def main():
  from optparse import OptionParser

  usage = "Usage: scripts/tango_doc.py TANGO_DIR [DESTINATION_DIR]"
  parser = OptionParser(usage=usage)
  parser.add_option("--rev", dest="revision", metavar="REVISION", default=None,
    type="int", help="set the repository REVISION to use in symbol links"
                     " (unused atm)")
  parser.add_option("--posix", dest="posix", default=False, action="store_true",
    help="define version Posix instead of Win32 and Windows")
  parser.add_option("--zip", dest="zip", default=False, action="store_true",
    help="create a 7z archive")
  parser.add_option("--pdf", dest="pdf", default=False, action="store_true",
    help="create a PDF document")

  parser.add_option("--data", dest="data", help="path to data and kandil")

  (options, args) = parser.parse_args()

  if len(args) < 1:
    return parser.print_help()

  # Path to dil's root folder.
  dil_dir    = '/usr/' #script_parent_folder(__file__) # Assumed dil path.
  DIL       = dil_path(dil_dir)
  #DIL.KANDIL = kandil_path('/var/dsource/scripts/kandil'
  if options.data:
  	DIL.DATA = Path(options.data).normpath
	DIL.KANDIL = DIL.DATA/"kandil"
	DIL.KANDIL = kandil_path(DIL.KANDIL)
  # The version of Tango we're dealing with.
  VERSION   = ""
  # Root of the Tango source code (either svn or zip.)
  copy_runtime_files(Path(args[0]))
  TANGO     = get_tango_path(args[0])
  # Destination of doc files.
  DEST      = doc_path(firstof(str, getitem(args, 1), 'tangodoc'))
  # Temporary directory, deleted in the end.
  TMP       = (DEST/"tmp").abspath
  # Some DDoc macros for Tango.
  TANGO_DDOC= TMP/"tango.ddoc"
  # The list of module files (with info) that have been processed.
  MODLIST   = TMP/"modules.txt"
  # The files to generate documentation for.
  FILES     = []

  build_dil_if_inexistant(DIL.EXE)

  if not TANGO.exists:
    print "The path '%s' doesn't exist." % TANGO
    return

  VERSION = get_tango_version(TANGO.SRC/"tango"/"core"/"Version.d")

  # Create directories.
  DEST.makedirs()
  map(Path.mkdir, (DEST.HTMLSRC, DEST.JS, DEST.CSS, DEST.IMG, TMP))

  find_source_files(TANGO.SRC, FILES)

  FILES = [f for f in FILES if not exclude(f)]

  create_index(TMP/"index.d", TANGO.SRC, FILES)
  write_tango_ddoc(TANGO_DDOC, TANGO.favicon, options.revision)
  DOC_FILES = [DIL.KANDIL.ddoc, TANGO_DDOC, TMP/"index.d"] + FILES
  versions = ["Tango", "DDoc", "D_Ddoc"]
  versions += ["Posix"] if options.posix else ["Windows", "Win32"]
  generate_docs(DIL.EXE, DEST.abspath, MODLIST, DOC_FILES,
                versions, options=['-v', '-hl', '--kandil'], cwd=DIL)

  copy_files(DIL, TANGO, DEST)
  if options.pdf:
      write_PDF(DIL, DEST, VERSION, TMP)

  TMP.rmtree()

  if options.zip:
    name, src = "tango.%s-docs" % VERSION, DEST
    zipcmd = "zip -r9 %(name)s.zip %(src)s" % locals()
    print zipcmd
    os.system(zipcmd)

  print "Exiting normally."

if __name__ == "__main__":
  main()
