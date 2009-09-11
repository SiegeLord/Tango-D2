#!/usr/bin/env bash
# returns os-platform
# tango & apache 2.0 license, © 2009 Fawzi Mohamed

osName=`uname -s`
platformName=`uname -m`
versionName=`uname -r`

case $osName in
    Linux) echo linux-$platformName ;;
    Darwin)
      if [ "$platformName" == "Power Macintosh" ]; then
        echo osx-PPC
      else
        echo osx-$platformName
      fi
      ;;
    FreeBSD) echo freebsd-$platformName ;;
    *) echo $osName-$platformName
esac
