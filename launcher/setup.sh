#!/bin/bash

if [ $(whoami) != root ];
then
    echo "This script must be run as root"
    exit 1
fi

USER_HOME=$(getent passwd $SUDO_USER | cut -d: -f6)

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

for steamLib in "${steamLibrariesArr[@]}"; do
    steamLib=$(echo $steamLib | sed "s/\#\#/\\\ /g") # Replace '##' with '\ '
    echo $steamLib

    # Find BeamNG Proton prefix
    if [[ "$pfx" == "" ]]; then
        
        isPrefix () {
            path="$1"
            if [[ "$path" != *"cache"* ]]; then
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

mkdir --parents "${USER_HOME}/.config"
echo -e '' > "${USER_HOME}/.config/BeamMP.conf"

export bob=hi
