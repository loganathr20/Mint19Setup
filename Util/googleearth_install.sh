# Then this script as install-google-earth in /root :

#! /bin/bash
set -x
dpkg --add-architecture i386 && sudo apt-get update
apt-get install ia32-libs
apt-get install googleearth-package
apt-get install google-earth-stable:i386



