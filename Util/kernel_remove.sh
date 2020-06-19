#  Copyright (C) 2015       Jarno Suni (8@iki.fi)
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#

set -o nounset
set -o errexit

# Usage info
show_help() {
cat << EOF
Usage: ${0##*/} [OPTION]...
Purge some kernel related packages that have older version than the 
current kernel. This is especially useful in order to prevent /boot 
partition from getting full. First warn, if some linux-* packages are
only partially or unsuccessfully installed.

Options:
    -h, -?, --help  Display this help and exit.
    -k NUM,
    --keep NUM,
    --keep=NUM      Keep NUM kernels that are older than the currently 
                    used one. Default is 1.
    -s, --simulate  Dry-run; don't actually remove packages. You do not
                    have to be superuser with this option.
    -y, --yes       Purge without user confirmation.

Exit Status:
    Exit with 1, if some command line argument is invalid.
    Inherit the exit status of the apt-get purge command issued.
EOF
}

error()
{
   echo 'ERROR: '"$1" >&2
   exit ${2:-1}
}

n=1
yes=""
simulate=""

while :; do
    case ${1-} in       
        -h|-\?|--help)   
            show_help
            exit
            ;;
        -k|--keep)
            if ! ${2:+false}; then
              n=$2
              shift 2
              continue
            else
               error 'Must specify a non-empty "--keep NUM" argument.'
            fi
            ;;
        --keep=?*)
            n=${1#*=} # Delete everything up to "=" and assign the remainder.
            ;;
        --keep=)
             error 'Must specify a non-empty "--keep NUM" argument.'
            ;;            
        -s|--simulate)
            simulate="-s"
            ;;
        -y|--yes)
            yes="-y"
            ;;          
        --)              # End of all options.
            shift
            break
            ;;
        -?*)
            echo 'WARNING: Unknown option (ignored): '"$1" >&2
            ;;
        # Default case: If no more options then break out of the loop.
        *)
            break
    esac

    shift
done

if [ $# -ne 0 ] ; then
 show_help
 exit
fi

if ! [[ "$n" =~ ^[0-9]+$ ]] ; then
 error "$n is invalid number of older kernels to keep."
fi
# $n is valid number

Pkgs="$(dpkg-query --show --showformat='${Status} ${Package}\n' "linux-*" |
 awk '$2!="ok" || ($3!="installed" && $3!="not-installed") {print $4}')"
if [ "${Pkgs}" ]; then 
 echo -e "WARNING: The following linux packages are not properly\
 installed. You may want to purge or reinstall them:\n"${Pkgs} >&2
 if ! [[ "$simulate" || "$yes" ]]; then
  read -r -p "Continue anyway (y/n)? " response
  response=${response,,}    # tolower
  ! [[ $response =~ ^(yes|y)$ ]] && exit
 fi
 echo
fi

# Versions of installed kernel packages
Versions="$(dpkg-query --show --showformat='${Status} ${Package}\n' "linux-image-*" |
sed -nr "s/^[^ ]+ ok installed .+image-([[:digit:].]+-[^-]+)-.+/\1/p" |
sort --version-sort --unique)"

#Alternative way, but maybe not as reliable, if kernel is only partially installed
#Versions="$(ls -1U /boot/vmlinuz-* | cut -d- -f2,3 | sort -Vu)"

# current kernel version number (present in the respective kernel 
# package name, too)
current="$(uname -r | cut -f1,2 -d-)"

# keep n versions that are older than the current one (if they exist).
num=$(awk '($0==c){a=NR-1-n; if(a>0){print a}else{print 0} exit}' c=${current} n=$n <<<"${Versions}")
VersionsToPurge="$(head -n ${num} <<<"${Versions}")"

if [ "${VersionsToPurge}" ]; then
    # purge linux packages matching the versions
    apt-get -q ${simulate} ${yes} purge --auto-remove $(
    sed -r -e 's/\./\\./g' -e 's/.*/^linux-.+-&($|-)/' <<<"$VersionsToPurge")   
else
    echo "0 kernels purged."
fi

