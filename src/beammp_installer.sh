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
    echo "BMP_PROTON_PREFIX environment variable must be set to continue installation."
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
echo "Downloading BeamMP"
cache="${home}/.cache/beammp"
zipFile="${cache}/BeamMP_Installer.zip"
exeFile="${cache}/BeamMP_Installer.exe"
mkdir --parents "$cache"
wget --quiet --output-document="$zipFile" https://beammp.com/installer/BeamMP_Installer.zip
unzip -od "$cache" "$zipFile"

# Run BeamMP installer using Proton
proton=$(echo $BMP_PROTON | sed 's/\\ /\ /g')
echo "Running BeamMP installer in Proton:"
echo -e "runuser --user ${user} ${proton} run ${exeFile}\n"
runuser --user "$user" "$proton" run "$exeFile"
echo

# Add BeamMP exe location to config file
mkdir --parents "${home}/.config"
export BMP_BEAMMP="${BMP_PROTON_PREFIX}/drive_c/users/${user}/AppData/Roaming/BeamMP-Launcher/BeamMP-Launcher.exe"
if [[ "$BMP_CONFIG" == "" ]]; then
    config="${home}/.config/BeamMP.conf"
else
    config="$BMP_CONFIG"
fi

printf "BMP_BEAMMP=${BMP_BEAMMP}\n" >> "$config"

# Cleanup
rm -fr "$cache"
