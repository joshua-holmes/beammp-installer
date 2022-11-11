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
    local results="$(find $USER_HOME/ -name $1)"
    local results=$(echo $results | sed "s/\ \//\&\&\//g") # replace ' /' with '&&/'
    local results=$(echo $results | sed "s/\ /\#\#/g") # replace ' ' with '##'
    local results=$(echo $results | sed "s/\&\&/\ /g") # replace '&&' with ' '
    read -a searchArr <<< $results
    for path in ${searchArr[@]}; do
        path=$(echo $path | sed "s/\#\#/\\\ /g") # replace '##' with '\ '
        if [[ "$2" != "" ]]; then
            "$2" "$path"
        else
            returnPath=$path
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
# searchFS 284160 isPrefix
# pfx="${returnPath}/pfx"

# # Find Steam executable
# steam=$(which steam)
# if [ "$steam" == "" ]; then
#     searchFS steam.sh
#     steam="$returnPath"
# fi
# if [ "$steam" == "" ]; then
#     searchFS Steam.exe
#     steam="$returnPath"
# fi

# Find Proton executable
isProtonExp () {
    path="$1"
    if [[ "$path" == *"Proton\ -\ Experimental/proton"* ]]; then
        returnPath="$path"
    fi
}
isProtonGE () {
    path="$1"
    if [[ "$path" == *"Proton\ -\ Experimental/proton"* ]]; then
        returnPath="$path"
    fi
}
searchFS proton isProtonExp
proton="$returnPath"
if [ "$proton" == "" ]; then
    searchFS proton isProton
    steam="$returnPath"
fi
echo "proton is: $proton"

# Find BeamNG executable
