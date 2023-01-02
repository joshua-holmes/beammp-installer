#!/bin/bash

if [ $(whoami) != root ];
then
    echo "This script must be run as root"
    exit 1
fi

export USER_HOME=$(getent passwd $SUDO_USER | cut -d : -f 6)

searchFS () {
    # $1 is file/folder name to search for
    # $2 is criteria the path must follow to result in true, optional
    # $2 must be a function that sets `returnPath` variable
    returnPath=""
    local results="$(find $2 -name $1)"
    local results=$(echo $results | sed "s/\ \//\&\&\//g") # replace ' /' with '&&/'
    local results=$(echo $results | sed "s/\ /\#\#/g") # replace ' ' with '##'
    local results=$(echo $results | sed "s/\&\&/\ /g") # replace '&&' with ' '
    read -a searchArr <<< $results
    for path in ${searchArr[@]}; do
        path=$(echo $path | sed "s/\#\#/\\\ /g") # replace '##' with '\ '
        if [[ "$3" != "" ]]; then
            "$3" "$path"
        else
            returnPath="$path"
        fi

        if [[ "$returnPath" != "" ]]; then
            return
        fi
    done
}

# Find Steam executable
searchFS steam.sh "$USER_HOME"
steam="$returnPath"
steamDir=$(echo "$steam" | sed "s/\/steam.sh$//g")

if [[ "$steam" == "" ]]; then
    echo "Error! 'steam.sh' could not be found." 
    echo "Is Steam installed on this computer in the user's home directory?"
    echo "'$USER_HOME'"
    exit 1
fi

inQuote="0"
isGoingToBePath="0"
isPath="0"
word=""
steamLibraries="" # Delimited by ' ', with literal ' ' replaced represented as '##'
while read char; do
    if [[ "$char" == '"' ]]; then
        if [[ "$inQuote" == "0" ]]; then
            inQuote="1"
            if [[ "$isGoingToBePath" == "1" ]]; then
                isGoingToBePath="0"
                isPath="1"
            fi
        else
            inQuote="0"
            word=""
            if [[ "$isPath" == "1" ]]; then
                isPath="0"
                steamLibraries="${steamLibraries} "
            fi
        fi
    elif [[ "$isPath" == "1" ]]; then
        if [[ "$char" == "" ]]; then # if char is a space (shown in code as empty string)
            steamLibraries="${steamLibraries}##"
        else
            steamLibraries="${steamLibraries}${char}"
        fi
    elif [[ "path" =~ "$char" ]]; then
        word="${word}${char}"
        if [[ "$word" == "path" ]]; then
            isGoingToBePath="1"
        elif [[ ! "path" =~ "$word" ]]; then
            word=""
        fi
    fi
    ## For debugging, uncomment this
    # echo $char inQuote $inQuote isGoingToBePath $isGoingToBePath isPath $isPath word $word
done <<< "$(grep -oE . $steamDir/config/libraryfolders.vdf)"

read -r -a steamLibrariesArr <<< "$steamLibraries"

echo "Searching Steam libraries for BeamNG, Proton prefix, and Proton Experimental executable..."
for steamLib in "${steamLibrariesArr[@]}"; do
    steamLib=$(echo $steamLib | sed "s/\#\#/\\\ /g") # Replace '##' with '\ '
    echo "Searching library: ${steamLib}"

    # Find BeamNG Proton prefix
    if [[ "$pfx" == "" ]]; then
        
        isPrefix () {
            path="$1"
            if [[ "$path" != *"cache"* ]] && [[ "$path" == *"compatdata"* ]]; then
                returnPath="$path"
            fi
        }
        searchFS 284160 "$steamLib/" isPrefix
        pfx="$returnPath"
    fi

    # Find Proton executable
    if [[ "$proton" == "" ]]; then
        isProtonExp () {
            path="$1"
            if [[ "$path" == *"Proton\ -\ Experimental/proton" ]]; then
                returnPath="$path"
            fi
        }
        searchFS proton "$steamLib/" isProtonExp
        proton="$returnPath"
    fi

    # Find BeamNG executable
    if [[ "$beamng" == "" ]]; then
        searchFS BeamNG.drive.exe "$steamLib/"
        beamng="$returnPath"
    fi
done
pfx="${pfx}/pfx"

if [[ "$pfx" == "/pfx" ]] || [[ "$proton" == "" ]] || [[ "$beamng" == "" ]]; then
    if [[ "$pfx" == "/pfx" ]]; then
        echo "ERROR! Proton prefix for BeamNG could not be found."
    fi
    if [[ "$proton" == "" ]]; then
        echo "ERROR! Proton Experimental could not be found. Is it installed on your system in a Steam library?"
    fi
    if [[ "$beamng" == "" ]]; then
        echo "ERROR! BeamNG is not installed on this device using Steam."
    fi
    echo "Cannot continue with installation...exiting"
    exit 1
fi

configFile="${USER_HOME}/.config/BeamMP.conf"
echo "Found necessary paths. Saving to config file here:"
echo "$configFile"
mkdir --parents "${USER_HOME}/.config"
printf "BMP_STEAM=${steam}
BMP_PROTON_PREFIX=${pfx}
BMP_PROTON=${proton}
BMP_BEAMNG=${beamng}\n" > "$configFile"
echo

export BMP_STEAM="$steam"
export BMP_PROTON_PREFIX="$pfx"
export BMP_PROTON="$proton"
export BMP_BEAMNG="$beamng"
export BMP_CONFIG="$configFile"
export STEAM_COMPAT_DATA_PATH="$pfx"
export STEAM_COMPAT_CLIENT_INSTALL_PATH="$steam"
export -f searchFS

curDir="$(dirname $0)"

echo "Running 'beammp_installer.sh'"
"${curDir}/beammp_installer.sh"

echo "Compiling 'beammp-launcher'"
binFoler="${USER_HOME}/.local/bin"
mkdir --parents "$binFoler"
if [[ !($(echo "$PATH") =~ "$binFolder") ]]; then
    export PATH="${binFolder}:${PATH}"
    printf "export PATH=${binFolder}:${PATH}\n" >> "${USER_HOME}/.bashrc"
fi
g++ -o "${binFoler}/beammp-launcher" "${curDir}/beammp_launcher.cpp"

echo "Starting initialization of BeamNG (required for BeamMP to work). PLEASE WAIT."

proton2=$(echo $proton | sed 's/\\ /\ /g')
echo "${proton2} run ${beamng}"
timeout 15 runuser --user "$SUDO_USER" "$proton2" run "$beamng"
echo

applications="${USER_HOME}/.local/share/applications"
if [[ -d "$applications" ]]; then
    echo "Creating desktop application entry"
    printf "[Desktop Entry]
Name=BeamMP
Comment=A multiplayer mod for BeamNG
Exec=${USER_HOME}/.local/bin/beammp-launcher
Icon=steam_icon_284160
Terminal=false
Type=Application
Categories=Game;\n" > "${applications}/BeamMP.desktop"

else
    echo "Cannot find ${USER_HOME}/.local/share/applications"
    echo "Skipping creation of desktop application entry. Continuing..."
fi

echo
echo "Done! Installation complete."
echo "Search for BeamMP in your applications to run the game!"
echo "If BeamMP does not show up, run 'beammp-launcher' in your terminal to launch BeamMP."