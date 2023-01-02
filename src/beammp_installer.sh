#!/bin/bash
set -e

home="$(getent passwd $SUDO_USER | cut -d : -f 6)"
user="$SUDO_USER"

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
searchFS "BeamMP-Launcher.exe" "$BMP_PROTON_PREFIX"
beammp="$returnPath"
export BMP_BEAMMP="$beammp"
if [[ "$BMP_CONFIG" == "" ]]; then
    config="${home}/.config/BeamMP.conf"
else
    config="$BMP_CONFIG"
fi

printf "BMP_BEAMMP=${beammp}\n" >> "$config"

# Cleanup
rm -fr "$cache"
