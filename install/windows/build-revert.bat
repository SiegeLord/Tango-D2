del revert.exe
rcc revert.rc
dmd -I../tango revert.d ../tango/tango/stdc/stringz.d revert.res -ofrevert.exe
del revert.map
del revert.obj
del stringz.obj

