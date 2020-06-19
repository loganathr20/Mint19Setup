#!/bin/bash

# pass n as a command line argument, and it will find all the installed
# kernels and keep only the n most recent ones => uninstall all older ones

# dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d'
# this command gives the list of all packages EXCEPT for the latest kernel.
# source : https://help.ubuntu.com/community/Lubuntu/Documentation/RemoveOldKernels

n=$1

# find the installed kernel versions :
# dpkg-query -W -f='${Version}\n' 'linux-image-*' | grep . | sort -n
# gives version numbers, one in each line
# dpkg-query -W -f='${Version}\n' 'linux-image-*' | grep . | sed 's/\...$//g' | grep -v '\...$'| sort -u
# gives only the ones that appear in linux-image

# suffix, e.g. -generic-pae
# the kind of kernel you boot into
suffix=$(uname -r | sed 's:^[0-9]\.[0-9]\.[0-9]\-[0-9]\{2\}::g')

command="apt-get purge "

for version in $(dpkg-query -W -f='${Version}\n' 'linux-image-*' | grep . | sed 's/\...$//g' | grep -v '\...$'| sort -u | head -n -${n})
do
    command=${command}"^linux-image-${version}${suffix} "
done

$command



