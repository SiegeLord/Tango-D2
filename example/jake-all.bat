@rem ###########################################################################
@rem # CONCURRENCY EXAMPLES
@rem ###########################################################################

@jake concurrency\fiber_test.d -I.. -op -unittest

@rem ###########################################################################
@rem # CONDUIT EXAMPLES
@rem ###########################################################################

@jake conduits\composite.d -I.. -op
@jake conduits\filebubbler.d -I.. -op
@jake -c conduits\filebucket.d -I.. -op
@jake conduits\filecat.d -I.. -op
@jake conduits\filecopy.d -I.. -op
@jake conduits\filepathname.d -I -op
@jake conduits\filescan.d -I.. -op
@jake conduits\filescanregex.d -I.. -op
@jake conduits\lineio.d -I.. -op
@jake conduits\mmap.d -I.. -op
@jake conduits\randomio.d -I.. -op
@jake conduits\unifile.d -I.. -op

@rem ###########################################################################
@rem # CONSOLE EXAMPLES
@rem ###########################################################################

@jake console\hello.d -I.. -op
@jake console\stdout.d -I.. -op

@rem ###########################################################################
@rem # LOGGING EXAMPLES
@rem ###########################################################################

@jake logging\chainsaw.d -I.. -op
@jake logging\logging.d -I.. -op

@rem ###########################################################################
@rem # REFERENCE MANUAL EXAMPLES
@rem ###########################################################################

@rem  example\manual\chapter4.d  (FIX ME)
@jake manual\chapterStorage.d -I.. -op 

@rem ###########################################################################
@rem # NETWORKING EXAMPLES
@rem ###########################################################################

@jake networking\homepage.d -I.. -op
@jake networking\httpget.d -I.. -op
@jake networking\sockethello.d -I.. -op
@jake networking\socketserver.d -I.. -op

IF EXIST ..\mango. (@jake networking\httpserver.d -I.. -op)
IF EXIST ..\mango. (@jake networking\servlets.d -I.. -op)
IF EXIST ..\mango. (@jake networking\servletserver.d -I.. -op)

rem  *** jake networking\selector.d *** (FIX ME)

@rem ###########################################################################
@rem # SYSTEM EXAMPLES
@rem ###########################################################################

@jake system\argparser.d -I.. -op
@jake system\localtime.d -I.. -op
@jake system\normpath.d -I.. -op

rem @jake system\process.d 

@rem ###########################################################################
@rem # TEXT EXAMPLES
@rem ###########################################################################

@jake text\formatalign.d -I.. -op
@jake text\formatindex.d -I.. -op
@jake text\formatspec.d -I.. -op
@jake text\localetime.d -I.. -op
@jake text\token.d -I.. -op

@del *.map
@dir *.exe