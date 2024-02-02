#!/bin/bash --login
#
# Editing this script should not be required.
#
# To specify additional VM options, add them to smartgit.vmoptions files.

APP_NAME=SmartGit
APP_LOWER=smartgit
SWT_VERSION=

parseVmOptions() {
	if [ -f $1 ]; then
		while read LINE || [[ -n "$LINE" ]]; do
			LINE="${LINE#"${LINE%%[![:space:]]*}"}"
			if [ ${#LINE} -gt 0 ] && [ ! ${LINE:0:1} == '#' ]; then
				if [ ${LINE:0:4} == 'jre=' ]; then
					echo "Ignoring following line in file $1"
					echo "$LINE"
				elif [ ${LINE:0:5} == 'path=' ]; then
					APP_PATH="$APP_PATH:${LINE:5}"
				elif [ ${LINE:0:7} == 'swtver=' ]; then
					SWT_VERSION="${LINE:7}"
				else
					_VM_PROPERTIES="$_VM_PROPERTIES $LINE"
				fi
			fi
		done < $1
	fi
}

echoJreConfigurationAndExit() {
	mkdir --parents $APP_CONFIG_DIR
	touch $APP_CONFIG_DIR/$APP_LOWER.vmoptions
	exit 1
}

case "$BASH" in
	*/bash) :
		;;
	*)
		exec /bin/bash "$0" "$@"
		;;
esac


# check system architecture
ARCHITECTURE=`uname -m`
if [ "$ARCHITECTURE" != "x86_64" ] ; then
	if [ "$ARCHITECTURE" != "aarch64" ] ; then
		echo "You are running $ARCHITECTURE."
		echo "$APP_NAME is only supported on x86_64 and aarch64 systems."
		exit 1
	fi
fi

# Resolve the location of the SmartGit installation.
# This includes resolving any symlinks.
PRG=$0
while [ -h "$PRG" ]; do
	ls=`ls -ld "$PRG"`
	link=`expr "$ls" : '^.*-> \(.*\)$' 2>/dev/null`
	if expr "$link" : '^/' 2> /dev/null >/dev/null; then
		PRG="$link"
	else
		PRG="`dirname "$PRG"`/$link"
	fi
done

APP_BIN=`dirname "$PRG"`

# Absolutize dir
oldpwd=`pwd`
cd "${APP_BIN}";
APP_BIN=`pwd`
cd "${oldpwd}";
unset oldpwd

APP_CONFIG_DIR=${XDG_CONFIG_HOME:-$HOME/.config}/$APP_LOWER

APP_HOME=`dirname "$APP_BIN"`
APP_JAVA_HOME=$SMARTGIT_JAVA_HOME
parseVmOptions $APP_BIN/$APP_LOWER.vmoptions
parseVmOptions $HOME/.$APP_LOWER/$APP_LOWER.vmoptions
parseVmOptions $APP_CONFIG_DIR/$APP_LOWER.vmoptions

# Determine Java Runtime
_JAVA_EXEC="java"
if [ "$APP_JAVA_HOME" != "" ] ; then
	_TMP="$APP_JAVA_HOME/bin/java"
	if [ -f "$_TMP" ] ; then
		if [ -x "$_TMP" ] ; then
			_JAVA_EXEC="$_TMP"
		else
			echo "Warning: $_TMP is not executable"
		fi
	else
		echo "Warning: $_TMP does not exist"
	fi
elif [ -e "$APP_HOME/jre/bin/java" ] ; then
	_JAVA_EXEC="$APP_HOME/jre/bin/java"
fi

if which which >/dev/null 2>&1 ; then
	if ! which "$_JAVA_EXEC" >/dev/null 2>&1 ; then
		echo "Error: No Java Runtime Environment (JRE) 17 or higher found"
		echoJreConfigurationAndExit
	fi
fi

if type "lsb_release" > /dev/null 2> /dev/null ; then
	if [ "$XDG_CURRENT_DESKTOP" == "Unity" ] ; then
		# Without the following line sliders are not visible in Ubuntu 12.04
		# (see <https://bugs.eclipse.org/bugs/show_bug.cgi?id=368929>)
		export LIBOVERLAY_SCROLLBAR=0
	fi
fi

if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
	# comment the next line if you have problems with incorrectly zoomed drawing (see https://bugs.eclipse.org/bugs/show_bug.cgi?id=574182)
	export GDK_BACKEND=x11
fi

# work-around for https://bugs.eclipse.org/bugs/show_bug.cgi?id=542675
if [ "$GTK_IM_MODULE" == "xim" ] ; then
	export GTK_IM_MODULE=ibus
fi

#export GTK_THEME=Adwaita
if [ "$GTK_THEME" != "Adwaita" ] ; then
	echo "If you experience strange GUI bugs or crashes, try setting GTK_THEME=Adwaita."
fi

# If you experience problems with garbled non-US-ASCII characters, try uncommenting the next line.
#export LC_ALL=en_US.UTF-8

_VM_OPTS=(
	-XX:+UseG1GC                           # use G1 garbage collector because it can release claimed memory back to the operating system
	-XX:MaxGCPauseMillis=100               # limit GC pauses (soft goal)
	-XX:InitiatingHeapOccupancyPercent=25  # start whole heap GC (instead just generations) at 25%
	-Xmx1024m                              # allow up to 1GB memory
	-Xss2m                                 # use up to 2MB stack size
	-XX:-UsePerfData                       # disable the perfdata feature
	-XX:MaxJavaStackTraceDepth=1000000     # to prevent truncated stack traces
	-Dsun.io.useCanonCaches=false          # disable caching of canonical file paths to increase performance
	-XX:ErrorFile=$APP_CONFIG_DIR/23.1/hs_err_pid%p.log  # write VM crash files to this location
)

_MISC_OPTS=""

if [ "$SWT_VERSION" != "" ] ; then
	echo "Configured custom SWT_VERSION=$SWT_VERSION."
	_JAR_FILE=$APP_HOME/opt/org.eclipse.swt.gtk.linux.x86_64.$SWT_VERSION.jar
	if [ ! -f $_JAR_FILE ] ; then
		echo "Custom SWT JAR '$_JAR_FILE' does not exist!"
	else
		_MISC_OPTS="$_MISC_OPTS -Dsmartboot.additionalJars="
		_MISC_OPTS="$_MISC_OPTS -Dsmartboot.prefixClassPath=file://$_JAR_FILE"
	fi
fi

APP_PATH="$PATH$SMARTGIT_PATH"

(export PATH="$APP_PATH"; "$_JAVA_EXEC" ${_VM_OPTS[@]} $_MISC_OPTS $_VM_PROPERTIES -jar "$APP_HOME/lib/bootloader.jar" "$@")
