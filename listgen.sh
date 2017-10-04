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
for image in $(dir -C -w 1 $HOME/github/spm_repo/data); do
    URL="$(grep -v '#' $HOME/github/spm_repo/data/"$image" | grep '.*github*.' | cut -f-5 -d"/")"
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
        if [ ! -f "$HOME/github/spm_repo/AppImages-github/$lower_image.yml" ]; then
            echo "name: $image" > $HOME/github/spm_repo/AppImages-github/"$lower_image".yml
            echo "url: $URL/releases" >> $HOME/github/spm_repo/AppImages-github/"$lower_image".yml
            echo "apiurl: https://api.github.com/repos/$REPO/releases" >> $HOME/github/spm_repo/AppImages-github/"$lower_image".yml
            echo "description: $(wget --quiet "$URL" -O - | grep -i '<meta name="description"' | cut -f4 -d'"' | tr -cd '[:alnum:] -')" >> $HOME/github/spm_repo/AppImages-github/"$lower_image".yml
            echo "$(tput setaf 1)yaml file for $image has been generated!$(tput sgr0)"
            echo "$lower_image: AppImages-github" >> $HOME/github/spm_repo/AppImages.yml
        else
            echo "$(tput setaf 2)yaml file for $image already exists; skipping...$(tput sgr0)"
        fi
    fi
done


# Generate a list of AppImages from sites other than github with versions that cannot be managed
for image in $(dir -C -w 1 $HOME/github/spm_repo/data); do
    URL="$(grep -v '#' $HOME/github/spm_repo/data/"$image" | grep -v '.*github*.')"
    if [ ! -z "$URL" ]; then
        lower_image="$(echo "$image" | tr '[:upper:]' '[:lower:]')"
        # echo "$lower_image:"
        if [ ! -f "$HOME/github/spm_repo/AppImages-other/$lower_image.yml" ]; then
            echo "name: $image" > $HOME/github/spm_repo/AppImages-other/"$lower_image".yml
            echo "url: $URL" >> $HOME/github/spm_repo/AppImages-other/"$lower_image".yml
            echo "$(tput setaf 1)yaml file for $image has been generated!$(tput sgr0)"
            echo "$lower_image: AppImages-other" >> $HOME/github/spm_repo/AppImages.yml
        else
            STORED_URL="$(yaml r $HOME/github/spm_repo/AppImages-other/$lower_image.yml url)"
            if [ "$STORED_URL" != "$URL" ]; then
                echo "$(tput setaf 1)New url for $image!$(tput sgr0)"
                echo "name: $image" > $HOME/github/spm_repo/AppImages-other/"$lower_image".yml
                echo "url: $URL" >> $HOME/github/spm_repo/AppImages-other/"$lower_image".yml
            else
                echo "$(tput setaf 2)No changes for $image.$(tput sgr0)"
            fi
        fi
    fi

done
rm $HOME/github/spm_repo/tar-pkgs.yml
for tar in $(dir -C -w 1 $HOME/github/spm_repo/tar-github); do
    tar_name="$(echo "$tar" | cut -f1 -d'.')"
    echo "$tar_name: tar-github" >> $HOME/github/spm_repo/tar-pkgs.yml
done

for tar in $(dir -C -w 1 $HOME/github/spm_repo/tar-other); do
    tar_name="$(echo "$tar" | cut -f1 -d'.')"
    echo "$tar_name: tar-other" >> $HOME/github/spm_repo/tar-pkgs.yml
done

echo "$(sort $HOME/github/spm_repo/AppImages.yml)" > $HOME/github/spm_repo/AppImages.yml
echo "$(sort $HOME/github/spm_repo/tar-pkgs.yml)" > $HOME/github/spm_repo/tar-pkgs.yml

