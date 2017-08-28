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
        echo "$image $URL/releases https://api.github.com/repos/$REPO/releases"
    fi
done > /home/simonizor/TestScripts/AppImages-github.lst
# Add any AppImages that appimagehub misses
echo "tc-linux https://github.com/mccxiv/tc https://api.github.com/repos/mccxiv/tc/releases" >> /home/simonizor/TestScripts/AppImages-github.lst
# Generate a list of AppImages from sites other than github with versions that cannot be managed
for image in $(dir -C -w 1 /home/simonizor/TestScripts/appimage.github.io/data); do
    URL="$(grep -v '#' /home/simonizor/TestScripts/appimage.github.io/data/"$image" | grep -v '.*github*.')"
    if [ ! -z "$URL" ]; then
        echo "$image $URL"
    fi
done > /home/simonizor/TestScripts/AppImages-direct.lst
