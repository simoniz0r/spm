#!/bin/bash
# Generate two separate lists from cloned appimagehub github repo's data folder

# Generate list of github AppImages with versions that can be managed
for image in $(dir -C -w 1 /home/simonizor/TestScripts/appimage.github.io/data); do
    URL="$(grep -v '#' /home/simonizor/TestScripts/appimage.github.io/data/"$image" | grep '.*github*.' | cut -f-5 -d"/")"
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
done > /home/simonizor/github/spm/AppImages-github.lst
# Add any AppImages that appimagehub misses
sed -i 's%sharexin ShareXin https://github.com/ShareXin/ShareXin/releases https://api.github.com/repos/ShareXin/ShareXin/releases%%g' /home/simonizor/github/spm/AppImages-github.lst # Remove duplicate
sed -i 's%nteract nteract https://github.com/nteract/releases https://api.github.com/repos/nteract/releases%nteract nteract https://github.com/nteract/nteract/releases https://api.github.com/repos/nteract/nteract/releases%g' /home/simonizor/github/spm/AppImages-github.lst # Fix broken link
sed -i 's%vlc VLC https://github.com/darealshinji/releases https://api.github.com/repos/darealshinji/releases%%g' /home/simonizor/github/spm/AppImages-github.lst # Remove broken link
sed -i '/^$/d' /home/simonizor/github/spm/AppImages-github.lst # Remove blank lines
echo "discord https://github.com/simoniz0r/AppImages/releases/tag/discord https://api.github.com/repos/simoniz0r/AppImages/releases" >> /home/simonizor/github/spm/AppImages-github.lst
echo "tc-linux https://github.com/mccxiv/tc https://api.github.com/repos/mccxiv/tc/releases" >> /home/simonizor/github/spm/AppImages-github.lst
echo "$(sort -u /home/simonizor/github/spm/AppImages-github.lst)" > /home/simonizor/github/spm/AppImages-github.lst
# Generate a list of AppImages from sites other than github with versions that cannot be managed
for image in $(dir -C -w 1 /home/simonizor/TestScripts/appimage.github.io/data); do
    URL="$(grep -v '#' /home/simonizor/TestScripts/appimage.github.io/data/"$image" | grep -v '.*github*.')"
    if [ ! -z "$URL" ]; then
        lower_image="$(echo "$image" | tr '[:upper:]' '[:lower:]')"
        echo "$lower_image $image $URL"
    fi
done > /home/simonizor/github/spm/AppImages-direct.lst
