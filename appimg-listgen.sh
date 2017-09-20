#!/bin/bash
# Title: spm
# Description: Downloads and installs AppImages and precompiled tar archives.  Can also upgrade and remove installed packages.
# Dependencies: GNU coreutils, tar, wget, python3.x
# Author: simonizor
# Website: http://www.simonizor.gq
# License: GPL v2.0 only
# Generate two separate lists from cloned appimagehub github repo's data folder
# MODIFY THIS TO OUTPUT TO INDIVIDUAL YAML FILES FOR SPM-REPO
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
        lower_image="$(echo "$image" | tr '[:upper:]' '[:lower:]' | tr -d '.')"
        # echo "$lower_image:"
        if [ ! -f "/home/$USER/github/spm-repo/AppImages-github/$lower_image.yml" ]; then
            echo "name: $image" > /home/$USER/github/spm-repo/AppImages-github/"$lower_image".yml
            echo "url: $URL/releases" >> /home/$USER/github/spm-repo/AppImages-github/"$lower_image".yml
            echo "apiurl: https://api.github.com/repos/$REPO/releases" >> /home/$USER/github/spm-repo/AppImages-github/"$lower_image".yml
            echo "description: $(wget --quiet "$URL" -O - | grep -i '<meta name="description"' | cut -f4 -d'"' | sed "s/[^a-zA-Z']/ /g")" >> /home/$USER/github/spm-repo/AppImages-github/"$lower_image".yml
            echo "$(tput setaf 6)yaml file for $image has been generated!$(tput sgr0)"
        else
            echo "$(tput setaf 5)yaml file for $image already exists; skipping...$(tput sgr0)"
        fi
    fi
done # > /home/$USER/github/spm/AppImages-github.yaml


# Generate a list of AppImages from sites other than github with versions that cannot be managed
for image in $(dir -C -w 1 /home/$USER/github/spm-repo/data); do
    URL="$(grep -v '#' /home/$USER/github/spm-repo/data/"$image" | grep -v '.*github*.')"
    if [ ! -z "$URL" ]; then
        lower_image="$(echo "$image" | tr '[:upper:]' '[:lower:]')"
        # echo "$lower_image:"
        echo "name: $image" > /home/$USER/github/spm-repo/AppImages-other/"$lower_image".yml
        echo "url: $URL" >> /home/$USER/github/spm-repo/AppImages-other/"$lower_image".yml
        if [ ! -f "/home/$USER/github/spm-repo/AppImages-other/$lower_image.yml" ]; then
            echo "$(tput setaf 6)yaml file for $image has been generated!$(tput sgr0)"
        else
            echo "$(tput setaf 5)yaml file for $image already exists.$(tput sgr0)"
        fi
    fi

done # > /home/$USER/github/spm/AppImages-direct.yaml

