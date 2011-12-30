#!/bin/sh

set -e

base_dir="docs"

mod_list=`make source -f posix.mak | sed 's/ /\n/g' | sort -u`

dir_list=`echo $mod_list | xargs -n 1 dirname | sort -u`

echo "MODULES =" > $base_dir/candydoc/modules.ddoc

temp_list=$mod_list

for i in $dir_list
do
	mod_in_dir=""
	for j in $temp_list
	do
		if test "$i" = `dirname $j` ; then
			mod_in_dir="$mod_in_dir $j"
			temp_list=`echo $temp_list | sed 's;'$j';;'`
		fi
	done
	grep -h -e "^module" $mod_in_dir | sort -u | sed 's/;//' | sed 's/\r//' |  sed 's/module \(.*\)$/\t$(MODULE \1)/' >> $base_dir/candydoc/modules.ddoc
done

dmd -o- -D -Dd$base_dir $base_dir/candydoc/modules.ddoc $base_dir/candydoc/candy.ddoc $mod_list
