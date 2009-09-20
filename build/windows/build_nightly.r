Rebol [ Title: "Nightly build for SVN tango" ]

do %rcopy.r

location: %/c/projects/tango_install/nightly_build

recreateDir: func [ dir [ file! ]  ]
[

	if exists? dir [ delete-dir dir ] make-dir dir

]

;check out tango 
;http://svn.dsource.org/projects/tango/trunk/

;delete old installation file

change-dir location

if exists? %tango-svn-installer.zip [ delete %tango-svn-installer.zip ]

svn-tango: join [ svn --force export http://svn.dsource.org/projects/tango/trunk] rejoin [ to-local-file location "/tango" ]
;svn-tango: join [ svn --force export http://svn.dsource.org/projects/tango/branches/D1_0/0_96_beta2/ ] rejoin [ to-local-file location "/tango" ]
 
probe svn-tango

delete-dir %tango
call/console reduce [svn-tango]

change-dir rejoin [ location "/tango/lib" ]
call/console [ build-dmd.bat ]
change-dir location


recreateDir %tango_temp
recreateDir %tango_temp/tango/

rcopy/verbose %tango/tango/ %tango_temp/tango/

recreateDir %tango_temp/std/ 
rcopy/verbose %tango/std/ %tango_temp/std/

recreateDir %tango_temp/example/ 
rcopy/verbose %tango/example/ %tango_temp/example/

write %tango_temp/object.di read %tango/object.di

recreateDir %lib/ 

write/binary %lib/tango_phobos.lib read/binary %tango/lib/phobos.lib 
rcopy/verbose %../nightly_svn_lib/ %lib/


recreateDir %tango/ 
rcopy/verbose %tango_temp/ %tango/

delete-dir %tango_temp/
delete-dir %tango/lib/

recreateDir %bin/ 
rcopy/verbose %../nightly_svn_bin/ %bin/

call/console [ "7z a -r -tzip tango-svn-installer.zip * "]

write/binary %../downloads_checkout/tango-svn-installer.zip read/binary %tango-svn-installer.zip 

change-dir %..


call/console ["svn ci -m svn_build downloads_checkout/" ]
