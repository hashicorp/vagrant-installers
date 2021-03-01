#!/usr/bin/env bash

function fail() {
    echo "ERROR: ${1}"
    exit 1
}

# Verify arguments
if [ "$#" -ne "2" ]; then
  echo "Usage: $0 SUBSTRATE-DIR VAGRANT-VERSION" >&2
  exit 1
fi

macos_deployment_target="10.9"

sdk_root="/Library/Developer/CommandLineTools/SDKs"
sdk_path="${sdk_root}/MacOSX.sdk"
versioned_sdk_path="${sdk_root}/MacOSX${macos_deployment_target}.sdk"
# Check that deployment target sdk exists
if [ ! -d "${versioned_sdk_path}" ]; then
    echo_stderr " !! Requested macOS SDK version is not available: ${macos_deployment_target}"
    exit 1
else
    rm -f "${sdk_path}"
    ln -s "${versioned_sdk_path}" "${sdk_path}"
fi
export MACOSX_DEPLOYMENT_TARGET="${macos_deployment_target}"
export SDKROOT="${sdk_path}" #"$(xcrun --sdk macosx --show-sdk-path)"
export ISYSROOT="-isysroot ${SDKROOT}"
export SYSLIBROOT="-syslibroot ${SDKROOT}"
export SYS_ROOT="${SDKROOT}"
export CFLAGS="-mmacosx-version-min=${macos_deployment_target} ${ISYSROOT}"
export CXXFLAGS="${CFLAGS}"
export LDFLAGS="-mmacosx-version-min=${macos_deployment_target} ${SYSLIBROOT}"

# Get our directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

VINCE="${DIR}/../vince"
SUBSTRATE_DIR=$1
VAGRANT_VERSION=$2
OUTPUT_PATH="`pwd`/vagrant_${VAGRANT_VERSION}_x86_64.dmg"

function vince() {
    "${VINCE}" -u "${NOTARIZE_USERNAME}" -p "${NOTARIZE_PASSWORD}" "${@}"
}

EMBEDDED_DIR="$1/embedded"
GEM_COMMAND="${EMBEDDED_DIR}/bin/gem"
export GEM_PATH="${EMBEDDED_DIR}/gems/${VERSION}"
export GEM_HOME="${GEM_PATH}"
export GEMRC="${EMBEDDED_DIR}/etc/gemrc"
export CPPFLAGS="${CXXFLAGS} -I${EMBEDDED_DIR}/include -I${EMBEDDED_DIR}/include/libxml2"
export CXXFLAGS="${CPPFLAGS}"
export CFLAGS="${CPPFLAGS}"
export LDFLAGS="${LDFLAGS} -L${EMBEDDED_DIR}/lib -L${EMBEDDED_DIR}/lib64"
export PATH="${EMBEDDED_DIR}/bin:${PATH}"
export PKG_CONFIG_PATH="${EMBEDDED_DIR}/lib/pkgconfig"
export SSL_CERT_FILE="${EMBEDDED_DIR}/cacert.pem"

"${GEM_COMMAND}" install --no-document rake

echo "Rebuild rb-fsevent bin executable..."
pushd "${SUBSTRATE_DIR}/embedded/gems/${VAGRANT_VERSION}/gems/rb-fsevent-"*/ext ||
    fail "Failed to locate rb-fsevent directory"
sed -ibak "s|.*SDK_INFO =.*\$|\$SDK_INFO = \{'Path' => '${SDKROOT}', 'ProductBuildVersion' => '${MACOSX_DEPLOYMENT_TARGET}'\}; next|" rakefile.rb ||
    fail "Failed to update build settings for rb-fsevent rebuild"
cd ..
rake -f ext/rakefile.rb replace_exe ||
    fail "Failed to rebuild rb-fsevent"
popd

# Work in a temporary directory
rm -rf package-staging
mkdir -p package-staging
STAGING_DIR=$(cd package-staging; pwd)
pushd $STAGING_DIR
echo "Darwin staging dir: ${STAGING_DIR}"

# Set information used for package and code signing
PKG_SIGN_IDENTITY=${VAGRANT_PACKAGE_SIGN_IDENTITY:-D38WU7D763}
PKG_SIGN_CERT_PATH=${VAGRANT_PACKAGE_SIGN_CERT_PATH:-"/Users/vagrant/MacOS_PackageSigning.cert"}
PKG_SIGN_KEY_PATH=${VAGRANT_PACKAGE_SIGN_KEY_PATH:-"/Users/vagrant/MacOS_PackageSigning.key"}

CODE_SIGN_IDENTITY=${VAGRANT_CODE_SIGN_IDENTITY:-D38WU7D763}
CODE_SIGN_CERT_PATH=${VAGRANT_CODE_SIGN_CERT_PATH:-"/Users/vagrant/MacOS_CodeSigning.p12"}
SIGN_KEYCHAIN=${VAGRANT_SIGN_KEYCHAIN:-/Library/Keychains/System.keychain}

SIGN_REQUIRED="${VAGRANT_PACKAGE_SIGNING_REQUIRED}"
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

cat <<EOF >${STAGING_DIR}/scripts/preinstall
#!/usr/bin/env bash

[ -d /opt/vagrant ] && rm -rf /opt/vagrant/

exit 0

EOF
chmod 0755 ${STAGING_DIR}/scripts/preinstall

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

# Install and enable package signing if available
if [ -f "${PKG_SIGN_CERT_PATH}" ] && [ -f "${PKG_SIGN_KEY_PATH}" ]; then
    security find-identity | grep "Installer.*${PKG_SIGN_IDENTITY}"
    if [ $? -ne 0 ]; then
        security import "${PKG_SIGN_CERT_PATH}" -k "${SIGN_KEYCHAIN}" -T /usr/bin/codesign -T /usr/bin/pkgbuild -T /usr/bin/productbuild ||
            fail "Failed to import signing certificate"
        security import "${PKG_SIGN_KEY_PATH}" -k "${SIGN_KEYCHAIN}" -T /usr/bin/codesign -T /usr/bin/pkgbuild -T /usr/bin/productbuild ||
            fail "Failed to import signing key"
    fi
    SIGN_PKG="1"
fi

# Install and enable code signing if available
if [ -f "${CODE_SIGN_CERT_PATH}" ] && [ ! -z "${CODE_SIGN_PASS}" ]; then
    security find-identity | grep "Application.*${CODE_SIGN_IDENTITY}"
    if [ $? -ne 0 ]; then
        echo "==> Installing code signing key..."
        security import "${CODE_SIGN_CERT_PATH}" -k "${SIGN_KEYCHAIN}" -P "${CODE_SIGN_PASS}" -T /usr/bin/codesign ||
            fail "Failed to import code signing key"
    fi
    SIGN_CODE="1"
fi

if [ "${SIGN_REQUIRED}" = "1" ]; then
    if [ "${SIGN_CODE}" != "1" ]; then
        fail "Signing is required but code signing is not enabled"
    fi
    if [ "${SIGN_PKG}" != "1" ]; then
        fail "Signing is required but code signing is not enabled"
    fi
    if [ -z "${NOTARIZE_USERNAME}" ] || [ -z "${NOTARIZE_PASSWORD}" ]; then
        fail "Signing is required but notarization credentials are not valid"
    fi
fi

# Perform library scrubbing to remove files which will fail notarization
rm -rf "${SUBSTRATE_DIR}/embedded/gems/${VAGRANT_VERSION}/cache/"*
rm -rf "${SUBSTRATE_DIR}/embedded/gems/${VAGRANT_VERSION}/gems/rubyzip-"*/test/

#-------------------------------------------------------------------------
# Code sign
#-------------------------------------------------------------------------
# Sign all executables within package
if [ "${SIGN_CODE}" = "1" ]; then
    cat <<EOF >entitlements.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
<key>com.apple.security.cs.disable-library-validation</key>
<true/>
</dict>
</plist>
EOF
    echo "Validating plist format..."
    plutil -lint entitlements.plist ||
        fail "Entitlements plist file format is invalid"
    echo "Signing all substrate executables..."
    find "${SUBSTRATE_DIR}" -type f -perm +0111 -exec codesign --timestamp --options=runtime --entitlements entitlements.plist -s "${CODE_SIGN_IDENTITY}" {} \; ||
        fail "Failure while signing executables"
    echo "Finding all substate bundles..."
    find "${SUBSTRATE_DIR}" -name "*.bundle" -exec codesign -f --timestamp --options=runtime -s "${CODE_SIGN_IDENTITY}" {} \; ||
        fail "Failure while signing bundles"
    echo "Finding all substrate shared library objects..."
    find "${SUBSTRATE_DIR}" -name "*.dylib" -exec codesign -f --timestamp --options=runtime -s "${CODE_SIGN_IDENTITY}" {} \; ||
        fail "Failure while signing share library objects"
    rm entitlements.plist
fi

#-------------------------------------------------------------------------
# Pkg
#-------------------------------------------------------------------------
# Create the component package using pkgbuild. The component package
# contains the raw file structure that is installed via the installer package.
if [ "${SIGN_PKG}" = "1" ]; then
    echo "Building core.pkg..."
    pkgbuild \
        --root ${SUBSTRATE_DIR} \
        --identifier com.vagrant.vagrant \
        --version ${VAGRANT_VERSION} \
        --install-location "/opt/vagrant" \
        --scripts ${STAGING_DIR}/scripts \
        --timestamp=none \
        --sign "${PKG_SIGN_IDENTITY}" \
        ${STAGING_DIR}/core.pkg ||
        fail "Failed to build core package"
else
    echo "Building core.pkg..."
    pkgbuild \
        --root ${SUBSTRATE_DIR} \
        --identifier com.vagrant.vagrant \
        --version ${VAGRANT_VERSION} \
        --install-location "/opt/vagrant" \
        --scripts ${STAGING_DIR}/scripts \
        --timestamp=none \
        ${STAGING_DIR}/core.pkg ||
        fail "Failed to build core package"
fi

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

# Check is signing certificate is available. Install
# and sign if found.
if [ "${SIGN_PKG}" = "1" ]; then
    productbuild \
        --distribution ${STAGING_DIR}/vagrant.dist \
        --resources ${STAGING_DIR}/resources \
        --package-path ${STAGING_DIR} \
        --timestamp=none \
        --sign "${PKG_SIGN_IDENTITY}" \
        ${STAGING_DIR}/Vagrant.pkg ||
        fail "Failed to build Vagrant package"
else
    productbuild \
        --distribution ${STAGING_DIR}/vagrant.dist \
        --resources ${STAGING_DIR}/resources \
        --package-path ${STAGING_DIR} \
        --timestamp=none \
        ${STAGING_DIR}/Vagrant.pkg ||
        fail "Failed to build Vagrant package"
fi
#-------------------------------------------------------------------------
# DMG
#-------------------------------------------------------------------------
# Stage the files
mkdir -p ${STAGING_DIR}/dmg
cp ${STAGING_DIR}/Vagrant.pkg ${STAGING_DIR}/dmg/vagrant.pkg
cp "${DIR}/darwin/uninstall.tool" ${STAGING_DIR}/dmg/uninstall.tool
chmod +x ${STAGING_DIR}/dmg/uninstall.tool

echo "Creating DMG"
dmgbuild -s "${DIR}/darwin/dmgbuild.py" -D srcfolder="${STAGING_DIR}/dmg" -D backgroundimg="${DIR}/darwin/background_installer.png" Vagrant "${OUTPUT_PATH}" ||
    fail "Failed to create Vagrant DMG"

if [ "${SIGN_PKG}" != "1" ]; then
    echo
    echo "!!!!!!!!!!!! WARNING !!!!!!!!!!!!"
    echo "! Vagrant installer package is  !"
    echo "! NOT signed. Rebuild using the !"
    echo "! signing key for release build !"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo
else
    echo "==> Signing DMG..."
    codesign -s "${PKG_SIGN_IDENTITY}" --timestamp "${OUTPUT_PATH}" ||
        fail "Failed to sign the Vagrant DMG"
fi

if [ "${SIGN_PKG}" = "1" ] && [ "${SIGN_CODE}" = "1" ] && [ "${NOTARIZE_USERNAME}" != "" ]; then
    if [ -z "${DISABLE_NOTARIZATION}" ]; then
        echo "==> Submitting DMG for notarization..."
        uuid="$(vince notarize com.hashicorp.vagrant "${OUTPUT_PATH}")"
        if [ $? -ne 0 ]; then
            echo "!!!! Failed to submit notarization. Waiting and trying again..."
            sleep 30
            uuid="$(vince notarize com.hashicorp.vagrant "${OUTPUT_PATH}")" ||
                fail "Failed to submit Vagrant package for notarization"
        fi

        wait_result=1
        retries=5
        while [ "${retries}" -gt 0 ]; do
            vince wait "${uuid}"
            wait_result=$?
            if [ $wait_result -ne 0 ]; then
                retries=$((retries-1))
            else
                retries=0
            fi
            if [ $retries -gt 0 ]; then
                echo ".... Pausing and retrying notarization wait..."
                sleep 30
            fi
        done

        vince validate "${uuid}"

        if [ $? -ne 0 ]; then
            vince logs "${uuid}"
            fail "Vagrant package notarization failed"
        fi

        vince staple "${OUTPUT_PATH}" ||
            fail "Vagrant package notarization stapling failed"
    else
        echo
        echo "!!!!!!!!!!!!WARNING!!!!!!!!!!!!!!!!!!!"
        echo "! Vagrant installer package is NOT   !"
        echo "! notarized. Notarization has been   !"
        echo "! expliticly disabled. Please enable !"
        echo "! package notarization and rebuild.  !"
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    fi
else
    echo
    echo "!!!!!!!!!!!!WARNING!!!!!!!!!!!!!!!!!!"
    echo "! Vagrant installer package is NOT  !"
    echo "! notarized. Rebuild with proper    !"
    echo "! signing and credentials to enable !"
    echo "! package notarization.             !"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
fi
