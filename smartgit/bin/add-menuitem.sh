#!/bin/bash
#
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

SMARTGIT_BIN=`dirname "$PRG"`

# absolutize dir
oldpwd=`pwd`
cd "${SMARTGIT_BIN}"
SMARTGIT_BIN=`pwd`
cd "${oldpwd}"

ICON_NAME=syntevo-smartgit-9db9c4c437cb92e73b1092e71611413a
TMP_DIR=`mktemp --directory`
DESKTOP_FILE=$TMP_DIR/syntevo-smartgit.desktop
cat << EOF > $DESKTOP_FILE
[Desktop Entry]
Version=1.0
Name=SmartGit
Keywords=git
Comment=Git-Client
Type=Application
Categories=Development;RevisionControl
Terminal=false
StartupWMClass=SmartGit
Exec="$SMARTGIT_BIN/smartgit.sh" %u
MimeType=x-scheme-handler/git;x-scheme-handler/smartgit;
Icon=$ICON_NAME
EOF

# seems necessary to refresh immediately:
chmod 644 $DESKTOP_FILE

wslCopyFileTo() {
    SRC_PATH=$1
    DST_PATH=$2
    DST_FOLDER=$(dirname $DST_PATH)
    if [ ! -d "$DST_FOLDER" ]; then
        mkdir -p "$DST_FOLDER"
    fi

    if ! cp -f "$SRC_PATH" "$DST_PATH"; then
        echo "WSL only creates Windows shortcuts for system desktop entries."
        echo "Please re-run this script with sudo."
        exit 1
    fi
}

if [ "Ubuntu" = "$WSL_DISTRO_NAME" ]; then
    # On WSL, there are a few issues:
    # 1) 'xdg-desktop-menu' is not available by default
    # 2) 'xdg-desktop-menu' fails unless '/usr/share/desktop-directories' is created manually
    # 3) 'xdg-desktop-menu' is ignored when run without sudo.
    # The workaround is to just use known file locations.
    XDG_DESKTOP_PATH="/usr/share/applications"
    XDG_ICON_PATH="/usr/share/icons/hicolor"

    wslCopyFileTo "$SMARTGIT_BIN/smartgit-32.png"  "$XDG_ICON_PATH/32x32/apps/$ICON_NAME.png"
    wslCopyFileTo "$SMARTGIT_BIN/smartgit-48.png"  "$XDG_ICON_PATH/48x48/apps/$ICON_NAME.png"
    wslCopyFileTo "$SMARTGIT_BIN/smartgit-64.png"  "$XDG_ICON_PATH/64x64/apps/$ICON_NAME.png"
    wslCopyFileTo "$SMARTGIT_BIN/smartgit-128.png" "$XDG_ICON_PATH/128x128/apps/$ICON_NAME.png"
    wslCopyFileTo "$DESKTOP_FILE" "$XDG_DESKTOP_PATH/syntevo-smartgit.desktop"
else
    xdg-icon-resource install --size  32 "$SMARTGIT_BIN/smartgit-32.png"  $ICON_NAME
    xdg-icon-resource install --size  48 "$SMARTGIT_BIN/smartgit-48.png"  $ICON_NAME
    xdg-icon-resource install --size  64 "$SMARTGIT_BIN/smartgit-64.png"  $ICON_NAME
    xdg-icon-resource install --size 128 "$SMARTGIT_BIN/smartgit-128.png" $ICON_NAME
    xdg-desktop-menu install $DESKTOP_FILE
fi

rm $DESKTOP_FILE
rm -R $TMP_DIR
