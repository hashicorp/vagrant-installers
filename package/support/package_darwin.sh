#!/usr/bin/env bash
set -ex

# Verify arguments
if [ "$#" -ne "2" ]; then
  echo "Usage: $0 SUBSTRATE-DIR VAGRANT-VERSION" >&2
  exit 1
fi

# Get our directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

SUBSTRATE_DIR=$1
VAGRANT_VERSION=$2
OUTPUT_PATH="`pwd`/vagrant_${VAGRANT_VERSION}"

# Work in a temporary directory
rm -rf package-staging
mkdir -p package-staging
STAGING_DIR=$(cd package-staging; pwd)
pushd $STAGING_DIR
echo "Darwin staging dir: ${STAGING_DIR}"

#-------------------------------------------------------------------------
# Resources
#-------------------------------------------------------------------------
echo "Copying installer resources..."
mkdir -p ${STAGING_DIR}/resources
cp "${DIR}/darwin/background.png" ${STAGING_DIR}/background.png
cp "${DIR}/darwin/welcome.html" ${STAGING_DIR}/welcome.html
cp "${DIR}/darwin/license.html" ${STAGING_DIR}/license.html

#-------------------------------------------------------------------------
# Scripts
#-------------------------------------------------------------------------
echo "Copying installer scripts.."
mkdir -p ${STAGING_DIR}/scripts
cat <<EOF >${STAGING_DIR}/scripts/postinstall
#!/usr/bin/env bash

if [ ! -d /usr/local/bin ]; then
  mkdir -p /usr/local/bin
fi

# Create the symlink so that vagrant is available on the
# PATH.
ln -Fs \$2/bin/vagrant /usr/local/bin/vagrant

# Remove old legacy Vagrant installation
[ -d /Applications/Vagrant ] && rm -rf /Applications/Vagrant

# In some cases the opt folder doesn't exists before Vagrant
# install. This folder must be always hidden.
chflags hidden /opt

# Exit with a success code
exit 0
EOF
chmod 0755 ${STAGING_DIR}/scripts/postinstall

#-------------------------------------------------------------------------
# Pkg
#-------------------------------------------------------------------------
# Create the component package using pkgbuild. The component package
# contains the raw file structure that is installed via the installer package.
echo "Building core.pkg..."
pkgbuild \
    --root ${SUBSTRATE_DIR} \
    --identifier com.vagrant.vagrant \
    --version ${VAGRANT_VERSION} \
    --install-location "/opt/vagrant" \
    --scripts ${STAGING_DIR}/scripts \
    --timestamp=none \
    --sign "Developer ID Installer: Mitchell Hashimoto" \
    ${STAGING_DIR}/core.pkg

# Create the distribution definition, an XML file that describes what
# the installer will look and feel like.
cat <<EOF >${STAGING_DIR}/vagrant.dist
<installer-gui-script minSpecVersion="1">
    <title>Vagrant</title>

    <!-- Configure the visuals and the various pages that exist throughout
         the installation process. -->
    <background file="background.png"
        alignment="bottomleft"
        mime-type="image/png" />
    <welcome file="welcome.html"
        mime-type="text/html" />
    <license file="license.html"
        mime-type="text/html" />

    <!-- Don't let the user customize the install (i.e. choose what
         components to install. -->
    <options customize="never" />

    <!-- The "choices" for things that can be installed, although the
         user has no actually choice, they're still required so that
         the installer knows what to install. -->
    <choice description="Vagrant Application"
        id="choice-vagrant-application"
        title="Vagrant Application">
        <pkg-ref id="com.vagrant.vagrant">core.pkg</pkg-ref>
    </choice>

    <choices-outline>
        <line choice="choice-vagrant-application" />
    </choices-outline>
</installer-gui-script>
EOF

# Build the actual installer.
echo "Building Vagrant.pkg..."
if [ "${DISABLE_DMG_SIGN}" == "1" ]
then
    productbuild \
        --distribution ${STAGING_DIR}/vagrant.dist \
        --resources ${STAGING_DIR}/resources \
        --package-path ${STAGING_DIR} \
        --timestamp=none \
        ${STAGING_DIR}/Vagrant.pkg
else
    productbuild \
        --distribution ${STAGING_DIR}/vagrant.dist \
        --resources ${STAGING_DIR}/resources \
        --package-path ${STAGING_DIR} \
        --timestamp=none \
        --sign "Developer ID Installer: Mitchell Hashimoto" \
        ${STAGING_DIR}/Vagrant.pkg
fi
#-------------------------------------------------------------------------
# DMG
#-------------------------------------------------------------------------
# Stage the files
mkdir -p ${STAGING_DIR}/dmg
cp ${STAGING_DIR}/Vagrant.pkg ${STAGING_DIR}/dmg/Vagrant.pkg
cp "${DIR}/darwin/uninstall.tool" ${STAGING_DIR}/dmg/uninstall.tool
chmod +x ${STAGING_DIR}/dmg/uninstall.tool
mkdir ${STAGING_DIR}/dmg/.support
cp "${DIR}/darwin/background_installer.png" ${STAGING_DIR}/dmg/.support/background.png

# Create the temporary DMG
echo "Creating temporary DMG..."
hdiutil create \
    -srcfolder "${STAGING_DIR}/dmg" \
    -volname "Vagrant" \
    -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" \
    -format UDRW \
    -size 102400k \
    ${STAGING_DIR}/temp.dmg

# Attach the temporary DMG and read the device
echo "Mounting and configuring temp DMG..."
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "${STAGING_DIR}/temp.dmg" | \
         egrep '^/dev/' | sed 1q | awk '{print $1}')

# The magic to setup the DMG for us
echo '
   tell application "Finder"
     tell disk "'Vagrant'"
           open
           set current view of container window to icon view
           set toolbar visible of container window to false
           set statusbar visible of container window to false
           set the bounds of container window to {100, 100, 605, 540}
           set theViewOptions to the icon view options of container window
           set arrangement of theViewOptions to not arranged
           set icon size of theViewOptions to 72
           set background picture of theViewOptions to file ".support:'background.png'"
           delay 5
           set position of item "'Vagrant.pkg'" of container window to {420, 60}
           set position of item "uninstall.tool" of container window to {420, 220}
           update without registering applications
           delay 5
     end tell
   end tell
' | osascript

# Set the permissions and generate the final DMG
echo "Creating final DMG..."
chmod -Rf go-w /Volumes/Vagrant
sync
hdiutil detach ${DEVICE}
hdiutil convert \
    "${STAGING_DIR}/temp.dmg" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "${OUTPUT_PATH}"
rm -f ${STAGING_DIR}/temp.dmg
