#!/bin/bash
# returns os-platform
# tango & apache 2.0 license, © 2009 Fawzi Mohamed

osName=`uname -s`
platformName=`uname -m`
versionName=`uname -r`

case $osName in
    Linux) echo linux-$platformName ;;
    Darwin) echo osx-$platformName ;;
    *) echo $osName-$platformName
esac
