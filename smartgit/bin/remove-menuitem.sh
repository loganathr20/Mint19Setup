#!/bin/bash
ICON_NAME=syntevo-smartgit-9db9c4c437cb92e73b1092e71611413a

if [ "Ubuntu" = "$WSL_DISTRO_NAME" ]; then
    # On WSL, there are a few issues:
    # 1) 'xdg-desktop-menu' is not available by default
    # 2) 'xdg-desktop-menu' fails unless '/usr/share/desktop-directories' is created manually
    # 3) 'xdg-desktop-menu' is ignored when run without sudo.
    # The workaround is to just use known file locations.
    XDG_DESKTOP_PATH="/usr/share/applications"
    XDG_ICON_PATH="/usr/share/icons/hicolor"
    rm -f "$XDG_ICON_PATH/32x32/apps/$ICON_NAME.png"
    rm -f "$XDG_ICON_PATH/48x48/apps/$ICON_NAME.png"
    rm -f "$XDG_ICON_PATH/64x64/apps/$ICON_NAME.png"
    rm -f "$XDG_ICON_PATH/128x128/apps/$ICON_NAME.png"
    rm -f "$XDG_DESKTOP_PATH/syntevo-smartgit.desktop"
else
    xdg-desktop-menu uninstall syntevo-smartgit.desktop
    xdg-icon-resource uninstall --size  32 $ICON_NAME
    xdg-icon-resource uninstall --size  48 $ICON_NAME
    xdg-icon-resource uninstall --size  64 $ICON_NAME
    xdg-icon-resource uninstall --size 128 $ICON_NAME
fi

