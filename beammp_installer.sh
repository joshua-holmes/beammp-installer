#!/bin/bash
set -e

if [ $(whoami) == root ]; then
    home="$(getent passwd $SUDO_USER | cut -d : -f 6)"
    user="$SUDO_USER"
else
    home="$HOME"
    user="$USER"
fi

if [[ "$BMP_PROTON_PREFIX" == "" ]]; then
    echo "BMP_PROTON_PREFIX environment variables must be set to continue installation."
    echo "Currently this is what it is set to:"
    echo
    echo "BMP_PROTON_PREFIX=$BMP_PROTON_PREFIX"
    echo
    echo "It is recommended to run setup.sh file instead of running this script (beammp_installer.sh) directly."
    echo "If you insist on running this script, please:"
    echo -e "\tSet BMP_PROTON_PREFIX to path of BeamNG's proton prefix (ending in .../pfx)"
    echo "Installation failed. Exiting..."
    exit 1
fi

# Download BeamMP installer
cache="${home}/.cache/beammp"
zipFile="${cache}/BeamMP_Installer.zip"
exeFile="${cache}/BeamMP_Installer.exe"
mkdir --parents "$cache"
wget --quiet --output-document="$zipFile" https://beammp.com/installer/BeamMP_Installer.zip
unzip -o "$zipFile"

# Run BeamMP installer using Proton Experimental
export WINE_PREFIX="$BMP_PROTON_PREFIX"
echo "Running installer in Wine:"
echo runuser --user "$user" wine "$exeFile"
echo
runuser --user "$user" wine "$exeFile"

# Cleanup
rm -fr "$cache"