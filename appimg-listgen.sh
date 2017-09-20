#!/bin/bash
# Title: spm
# Description: Downloads and installs AppImages and precompiled tar archives.  Can also upgrade and remove installed packages.
# Dependencies: GNU coreutils, tar, wget, python3.x
# Author: simonizor
# Website: http://www.simonizor.gq
# License: GPL v2.0 only
# Generate two separate lists from cloned appimagehub github repo's data folder

# Generate list of github AppImages with versions that can be managed
for image in $(dir -C -w 1 /home/$USER/github/spm-repo/data); do
    URL="$(grep -v '#' /home/$USER/github/spm-repo/data/"$image" | grep '.*github*.' | cut -f-5 -d"/")"
    if [ ! -z "$URL" ]; then
        case $URL in
            *api.github*)
                REPO="$(echo $URL | cut -f5,6 -d"/")"
                URL="https://github.com/$REPO"
                ;;
            *)
                REPO="$(echo $URL | cut -f4,5 -d"/")"
                ;;
        esac
        lower_image="$(echo "$image" | tr '[:upper:]' '[:lower:]')"
        echo "$lower_image:"
        echo "    name: $image"
        echo "    url: $URL/releases"
        echo "    apiurl: https://api.github.com/repos/$REPO/releases"
    fi
done > /home/$USER/github/spm/AppImages-github.yaml


# Generate a list of AppImages from sites other than github with versions that cannot be managed
for image in $(dir -C -w 1 /home/$USER/github/spm-repo/data); do
    URL="$(grep -v '#' /home/$USER/github/spm-repo/data/"$image" | grep -v '.*github*.')"
    if [ ! -z "$URL" ]; then
        lower_image="$(echo "$image" | tr '[:upper:]' '[:lower:]')"
        echo "$lower_image:"
        echo "    name: $image"
        echo "    url: $URL"
    fi
done > /home/$USER/github/spm/AppImages-direct.yaml

