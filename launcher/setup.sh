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
    # $2 may look like '[[ "$path" == *"cache"* ]]' if it is required for the path to contain the word "cache" somewhere in the directory
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
isSteam() {
    path="$1"
    if [[ "$path" != *"cache"* ]]; then
        returnPath=$path
    fi
}
searchFS 284160 isSteam
steam="$returnPath"

# Find Steam executable
# steam=$(which steams)
# echo $steam
# if [ "$steam" == "" ]; then
#     searchFS steam.sh
#     for path in ${searchArr[@]}; do
#         path=$(echo $path | sed "s/\#\#/\\\ /g") # replace '##' with '\ '
#         steam=$path
#     done
# fi

# Find Proton executable

# Find BeamNG executable