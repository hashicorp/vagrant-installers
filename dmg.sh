#!/usr/bin/env bash

# Variables
SOURCE=/Users/mitchellh/code/personal/ruby/vagrant-installers/dist
TITLE=Vagrant
SIZE=102400
TEMP_PATH=pack.temp.dmg
FINAL_PATH=vagrant.dmg

INSTALLER_NAME=Vagrant.pkg
BG_FILENAME=background.png

# Create the temporary DMG
hdiutil create -srcfolder "${SOURCE}" -volname "${TITLE}" -fs HFS+ \
      -fsargs "-c c=64,a=16,e=16" -format UDRW -size ${SIZE}k ${TEMP_PATH}

# Attach the temporary DMG and read the device number
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "${TEMP_PATH}" | \
         egrep '^/dev/' | sed 1q | awk '{print $1}')

# The magic to setup the DMG for us
echo '
   tell application "Finder"
     tell disk "'${TITLE}'"
           open
           set current view of container window to icon view
           set toolbar visible of container window to false
           set statusbar visible of container window to false
           set the bounds of container window to {400, 100, 885, 430}
           set theViewOptions to the icon view options of container window
           set arrangement of theViewOptions to not arranged
           set icon size of theViewOptions to 72
           set background picture of theViewOptions to file ".background:'${BG_FILENAME}'"
           delay 5
           set position of item "'${INSTALLER_NAME}'" of container window to {375, 50}
           update without registering applications
           delay 5
     end tell
   end tell
' | osascript

# Set the permissions and generate the final DMG
chmod -Rf go-w /Volumes/"${TITLE}"
sync
hdiutil detach ${DEVICE}
hdiutil convert "${TEMP_PATH}" -format UDZO -imagekey zlib-level=9 -o "${FINAL_PATH}"
rm -f ${TEMP_PATH}
