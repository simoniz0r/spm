#!/bin/bash
# Title: spm
# Description: Downloads and installs AppImages and precompiled tar archives.  Can also upgrade and remove installed packages.
# Dependencies: GNU coreutils, tar, wget, python3.x
# Author: simonizor
# Website: http://www.simonizor.gq
# License: GPL v2.0 only
# Generate two separate lists from cloned appimagehub github repo's data folder

# Generate list of github AppImages with versions that can be managed
for image in $(dir -C -w 1 /home/$USER/github/appimage.github.io/data); do
    URL="$(grep -v '#' /home/$USER/github/appimage.github.io/data/"$image" | grep '.*github*.' | cut -f-5 -d"/")"
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
        echo "$lower_image $image $URL/releases https://api.github.com/repos/$REPO/releases"
    fi
done > /home/$USER/github/spm/AppImages-github.lst
# Fix/remove broken links and add any AppImages that appimagehub misses
sed -i 's%sharexin ShareXin https://github.com/ShareXin/ShareXin/releases https://api.github.com/repos/ShareXin/ShareXin/releases%%g' /home/$USER/github/spm/AppImages-github.lst # Remove duplicate
sed -i 's%nteract nteract https://github.com/nteract/releases https://api.github.com/repos/nteract/releases%nteract nteract https://github.com/nteract/nteract/releases https://api.github.com/repos/nteract/nteract/releases%g' /home/$USER/github/spm/AppImages-github.lst # Fix broken link
sed -i 's%vlc VLC https://github.com/darealshinji/releases https://api.github.com/repos/darealshinji/releases%%g' /home/$USER/github/spm/AppImages-github.lst # Remove broken link
sed -i '/^$/d' /home/$USER/github/spm/AppImages-github.lst # Remove blank lines
echo "discord discord https://github.com/simoniz0r/AppImages/releases https://api.github.com/repos/simoniz0r/AppImages/releases" >> /home/$USER/github/spm/AppImages-github.lst
echo "inxi inxi https://github.com/simoniz0r/AppImages/releases https://api.github.com/repos/simoniz0r/AppImages/releases" >> /home/$USER/github/spm/AppImages-github.lst
echo "neofetch neofetch https://github.com/simoniz0r/AppImages/releases https://api.github.com/repos/simoniz0r/AppImages/releases" >> /home/$USER/github/spm/AppImages-github.lst
echo "tc-linux tc-linux https://github.com/mccxiv/tc https://api.github.com/repos/mccxiv/tc/releases" >> /home/$USER/github/spm/AppImages-github.lst
echo "vterm vterm https://github.com/vterm/vterm/releases https://api.github.com/repos/vterm/vterm/releases" >> /home/$USER/github/spm/AppImages-github.lst
echo "$(sort /home/$USER/github/spm/AppImages-github.lst)" > /home/$USER/github/spm/AppImages-github.lst
# Generate a list of AppImages from sites other than github with versions that cannot be managed
for image in $(dir -C -w 1 /home/$USER/github/appimage.github.io/data); do
    URL="$(grep -v '#' /home/$USER/github/appimage.github.io/data/"$image" | grep -v '.*github*.')"
    if [ ! -z "$URL" ]; then
        lower_image="$(echo "$image" | tr '[:upper:]' '[:lower:]')"
        echo "$lower_image $image $URL"
    fi
done > /home/$USER/github/spm/AppImages-direct.lst
sed -i 's%wastesedge wastesedge http://download.savannah.gnu.org/releases/adonthell/wastesedge-0.3.6-x86_64-linux.tar.gz%%g' /home/$USER/github/spm/AppImages-direct.lst # Remove this; not going to support AppImages in tar archives
sed -i '/^$/d' /home/$USER/github/spm/AppImages-direct.lst # Remove blank lines
