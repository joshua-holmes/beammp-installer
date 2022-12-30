#!/bin/bash

files=("beammp_installer.sh" "beammp_launcher.cpp" "setup.sh")

echo "Downloading installation files..."
for f in "${files[@]}"; do
    echo "$f"
    curl --location --output "$f" "https://raw.githubusercontent.com/joshua-holmes/beammp-installer/main/src/${f}"
done

sudo ./setup.sh

echo "Cleanup..."
for f in "${files[@]}"; do
    rm "$f"
done

echo "Done"
