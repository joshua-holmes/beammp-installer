#!/bin/bash

USER_HOME=$(getent passwd $SUDO_USER | cut -d: -f6)

if [ $(whoami) != root ];
then
    echo "This script must be run as root"
    exit 1
fi

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

# Find BeamNG Proton prefix
# isPrefix () {
#     path="$1"
#     if [[ "$path" != *"cache"* ]]; then
#         returnPath="$path"
#     fi
# }
# searchFS 284160 "$USER_HOME/" isPrefix
# pfx="${returnPath}/pfx"

# Find Steam executable
searchFS steam.sh "$USER_HOME/"
steam="$returnPath"
steamDir=$(echo "$steam" | sed "s/\/steam.sh$//g")

# # Find Proton executable
# isProtonExp () {
#     path="$1"
#     if [[ "$path" == *"Proton\ -\ Experimental/proton" ]]; then
#         returnPath="$path"
#     fi
# }
# searchFS proton "$USER_HOME/" isProtonExp
# proton="$returnPath"


# Find BeamNG executable

# echo "$steamDir/config/libraryfolders.vdf"
# libraryfolders=$(cat "$steamDir/config/libraryfolders.vdf")
# libraryfolders=$(echo $libraryfolders | sed "s/\ /\#\#/g") # replace ' ' with '##'
# for line in $(grep -oE '"path"\s*"/.+"'); do
#     echo before $line
#     path=$(echo "$line" | grep -oE '/\S+[^"]')
#     echo after $path
#     if [[ "$line" =~ "/" ]]; then
#         echo $path
#     fi

# done
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
done
# searchFS BeamNG.drive.exe "$USER_HOME/"
# beamng="$returnPath"

# echo "beamng is: $beamng"
