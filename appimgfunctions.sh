#!/bin/bash
# Title: spm
# Description: Downloads AppImages and moves them to /usr/local/bin/.  Can also upgrade and remove installed AppImages.
# Dependencies: GNU coreutils, wget
# Author: simonizor
# Website: http://www.simonizor.gq
# License: GPL v2.0 only

X="0.0.2"
# Set spm version

# Set variables
APPIMG_UPGRADE_CHECK="FALSE"
APPIMG_FORCE_UPGRADE="FALSE"
GITHUB_CONTINUOUS="FALSE"

appimgfunctionsexistsfunc () {
    sleep 0
}

appimglistallfunc () {
    echo "$(dir -C -w 1 ~/.config/spm/appimginstalled | wc -l) AppImages installed:"
    dir -C -w 1 ~/.config/spm/appimginstalled | pr -tT --column=3 -w 125
    echo
    echo "$(cat ~/.config/spm/AppImages-bintray.lst | wc -l) Bintray AppImages available for install:"
    cat ~/.config/spm/AppImages-bintray.lst | pr -tT --column=3 -w 125
    echo
    echo "$(cat ~/.config/spm/AppImages-github.lst | wc -l) Github AppImages available for install:"
    cat ~/.config/spm/AppImages-github.lst | cut -f1 -d" " | pr -tT --column=3 -w 125
}

appimglistfunc () {
    if [ -f ~/.config/spm/appimginstalled/"$LISTIMG" ]; then # If installed, list installed info
        echo "Current installed $LISTIMG information:"
        cat ~/.config/spm/appimginstalled/"$LISTIMG"
        echo "INSTALLED=\"YES\""
    elif grep -qw "$LISTIMG" ~/.config/spm/AppImages-bintray.lst; then # If not installed and in Bintray list, list Bintray info
        echo "$LISTIMG AppImage information:"
        APPIMAGE="$(wget -q "https://bintray.com/package/files/probono/AppImages/$LISTIMG?order=desc&sort=fileLastModified&basePath=&tab=files" -O - | grep -e '64.AppImage">' | cut -d '"' -f 6 | head -n 1 | cut -f2 -d"=")"
        echo "APPIMAGE=\"${APPIMAGE##*/}\""
        # echo "APPIMAGE_VERSION=\"$(echo "$APPIMAGE" | cut -f2 -d'-')\""
        echo "WEBSITE="\"https://bintray.com/probono/AppImages/$LISTIMG\"""
        echo "APPIMG_DESCRIPTION="\"$(wget --quiet "https://bintray.com/probono/AppImages/$LISTIMG/" -O - | grep '<div class="description-text">' | cut -f2 -d'>' | cut -f1 -d'<')\"""
        echo "INSTALLED=\"NO\""
    elif grep -qw "$LISTIMG" ~/.config/spm/AppImages-github.lst; then # If not installed and in Github list, list Github info
        GITHUB_APP_URL="$(grep -w "$LISTIMG" ~/.config/spm/AppImages-github.lst | cut -f2 -d" ")"
        APPIMAGE="$(wget --quiet "$GITHUB_APP_URL/releases" -O - | grep -i '.*/download/.*64.AppImage' | head -n 1 | cut -f2 -d'"')"
        MAIN_GITHUB_URL="$(echo "$GITHUB_APP_URL" | cut -f-5 -d'/')"
        # APPIMAGE_VERSION="$(wget --quiet "$GITHUB_APP_URL" -O - | grep '<a href="/*..*/commit/*.' | cut -f5 -d"/" | cut -f1 -d'"' | head -n 1)"
        if [ -z "$APPIMAGE" ]; then
            APPIMAGE="$(wget --quiet "$GITHUB_APP_URL/releases" -O - | grep -i '.*/download/.*.AppImage' | head -n 1 | cut -f2 -d'"')"
        fi
        echo "$LISTIMG AppImage information:"
        echo "APPIMAGE=\"${APPIMAGE##*/}\""
        # echo "APPIMAGE_VERSION="\"$APPIMAGE_VERSION\"""
        echo "WEBSITE=\"$MAIN_GITHUB_URL\""
        echo "APPIMG_DESCRIPTION=\"$(wget --quiet "$MAIN_GITHUB_URL" -O - | grep -i '<meta name="description"' | cut -f4 -d'"')\""
        echo "INSTALLED=\"NO\""
    else # Exit if not in list or installed
        echo "AppImage not found!"
        rm -rf ~/.config/spm/cache/* # Remove any files in cache before exiting
        exit 1
    fi
}

appimglistinstalledfunc () {
    echo "$(dir -C -w 1 ~/.config/spm/appimginstalled | wc -l) AppImages installed:"
    dir -C -w 1 ~/.config/spm/appimginstalled | pr -tT --column=3 -w 125
    echo
    for AppImage in $(dir -C -w 1 ~/.config/spm/appimginstalled); do
        echo "$AppImage installed information:"
        cat ~/.config/spm/appimginstalled/"$AppImage"
        echo "INSTALLED=\"YES\""
        echo
    done
}

appimgcheckfunc () { # check user input against list of known apps here
    if grep -qwi "$1" ~/.config/spm/AppImages-bintray.lst; then # Check AppImages-bintray.lst for AppImages from Bintray
        APPIMG_NAME="$(grep -wi "$1" ~/.config/spm/AppImages-bintray.lst)"
        BINTRAY_IMG="TRUE"
        GITHUB_IMG="FALSE"
    elif grep -qwi "$1" ~/.config/spm/AppImages-github.lst; then # Check AppImages-github.lst for AppImages from github
        APPIMG_NAME="$(grep -wi "$1" ~/.config/spm/AppImages-github.lst | cut -f1 -d" ")"
        BINTRAY_IMG="FALSE"
        GITHUB_IMG="TRUE"
    else
        BINTRAY_IMG="FALSE"
        GITHUB_IMG="FALSE"
    fi
}

appimggithubinfofunc () {
    GITHUB_APP_URL="$(grep -wi "$INSTIMG" ~/.config/spm/AppImages-github.lst | cut -f2 -d" ")"
    APPIMG_GITHUB_API_URL="$(grep -wi "$INSTIMG" ~/.config/spm/AppImages-github.lst | cut -f3- -d" ")"
    wget --quiet "$APPIMG_GITHUB_API_URL" -O ~/.config/spm/cache/"$INSTIMG"-release || { echo "wget $APPIMG_GITHUB_API_URL failed; has the repo been renamed or deleted?"; exit 1; }
    APPIMAGE_INFO="$HOME/.config/spm/cache/$INSTIMG"-release
    if grep -q '"tag_name":*..*continuous"' "$APPIMAGE_INFO"; then # First try to find continuous builds
        GITHUB_CONTINUOUS="TRUE"
        APPIMAGE_NAME="$(grep -im 1 '"name":*..*64.AppImage"' "$APPIMAGE_INFO" | cut -f4 -d'"')"
        if [ -z "$APPIMAGE_NAME" ]; then # Try to find AppImages that do not specify architecture
            APPIMAGE_NAME="$(grep -im 1 '"name":*..*.AppImage"' "$APPIMAGE_INFO" | cut -f4 -d'"')"
        fi
    fi
    if [ "$GITHUB_CONTINUOUS" = "FALSE" ] || [ -z "$APPIMAGE_NAME" ]; then # If no continuous build found, find regular release
        APPIMAGE_NAME="$(grep -im 1 '"name":*..*64.AppImage"' "$APPIMAGE_INFO"  | cut -f4 -d'"')"
        if [ -z "$APPIMAGE_NAME" ]; then # Try to find AppImages that don't specify architecture
            APPIMAGE_NAME="$(grep -im 1 '"name":*..*.AppImage"' "$APPIMAGE_INFO" | cut -f4 -d'"')"
        fi
    fi
    NEW_APPIMAGE_VERSION="$(grep -B 1 -im 1 '"browser_download_url":*..*64.AppImage"' "$APPIMAGE_INFO" | head -n 1 | cut -f4 -d'"')"
    GITHUB_APPIMAGE_URL="$(grep -im 1 '"browser_download_url":*..*64.AppImage"' "$APPIMAGE_INFO" | cut -f4 -d'"')"
    if [ -z "$GITHUB_APPIMAGE_URL" ]; then
        NEW_APPIMAGE_VERSION="$(grep -B 1 -im 1 '"browser_download_url":*..*.AppImage"' "$APPIMAGE_INFO" | head -n 1 | cut -f4 -d'"')"
        GITHUB_APPIMAGE_URL="$(grep -im 1 '"browser_download_url":*..*.AppImage"' "$APPIMAGE_INFO" | cut -f4 -d'"')"
    fi
    if [ "$APPIMG_UPGRADE_CHECK" = "FALSE" ]; then
        wget --quiet "$GITHUB_APP_URL" -O ~/.config/spm/cache/"$INSTIMG"-github || { echo "wget $GITHUB_APP_URL failed; has the repo been renamed or deleted?"; rm -rf ~/.config/spm/cache/*; exit 1; }
        APPIMG_GITHUB_INFO="$HOME/.config/spm/cache/"$INSTIMG"-github"
        APPIMG_DESCRIPTION="$(grep -i '<meta name="description"' "$APPIMG_GITHUB_INFO" | cut -f4 -d'"')"
    fi
    GITHUB_CONTINUOUS="FALSE"
}

bintrayinfofunc () {
    BINTRAY_APPIMAGE_URL="$(wget -q "https://bintray.com/package/files/probono/AppImages/$APPIMG_NAME?order=desc&sort=fileLastModified&basePath=&tab=files" -O - | grep -e '64.AppImage">' | cut -d '"' -f 6 | head -n 1)"
    APPIMAGE_NAME="$(wget -q "https://bintray.com/package/files/probono/AppImages/$APPIMG_NAME?order=desc&sort=fileLastModified&basePath=&tab=files" -O - | grep -e '64.AppImage">' | cut -d '"' -f 6 | head -n 1 | cut -f2 -d"=")"
    NEW_APPIMAGE_VERSION="$(echo "$APPIMAGE_NAME" | cut -f2 -d'-')"
    if [ "$APPIMG_UPGRADE_CHECK" = "FALSE" ]; then
        APPIMG_DESCRIPTION="$(wget --quiet "https://bintray.com/probono/AppImages/$APPIMG_NAME/" -O - | grep '<div class="description-text">' | cut -f2 -d'>' | cut -f1 -d'<')"
    fi
}

appimginfofunc () { # Set variables and temporarily store pages in ~/.config/spm/cache to get info from them
    if [ "$BINTRAY_IMG" = "TRUE" ]; then
        bintrayinfofunc
    elif [ "$GITHUB_IMG" = "TRUE" ]; then # If AppImage is from github, use method below to get new AppImage version
        appimggithubinfofunc
    fi
}

appimgvercheckfunc () { # Check version by getting the latest version from the bintray website or github releases page using wget, grep, cut, and head
    if [ -f ~/.config/spm/appimginstalled/"$INSTIMG" ]; then # Load installed information if AppImage is installed
        . ~/.config/spm/appimginstalled/"$INSTIMG"
    fi
    if [ -z "$APPIMAGE" ]; then # If no existing AppImage version was found, do not mark for upgrade
        APPIMG_NEW_UPGRADE="FALSE"
        APPIMAGE_ERROR="FALSE"
    elif [[ "$NEW_APPIMAGE_VERSION" != "$APPIMAGE_VERSION" ]]; then # If current AppImage version does not equal new AppImage version, mark for upgrade
        APPIMG_NEW_UPGRADE="TRUE"
        APPIMAGE_ERROR="FALSE"
    elif [ "$APPIMG_FORCE_UPGRADE" = "TRUE" ]; then # This is used for the upgrade-force argument
        APPIMG_NEW_UPGRADE="TRUE"
        APPIMG_FORCE_UPGRADE=""
        APPIMAGE_ERROR="FALSE"
    else # If current AppImage version equals new AppImage version, do not mark for ugprade
        APPIMG_NEW_UPGRADE="FALSE"
        APPIMAGE_ERROR="FALSE"
    fi
    if [ -z "$APPIMAGE_NAME" ] && [ "$APPIMG_FORCE_UPGRADE" = "FALSE" ] ; then # If no new AppImage version was found, output an error
        echo "$(tput setaf 1)Error checking $INSTIMG version!$(tput sgr0)"
        echo "$(tput setaf 1)If this error continues to happen for $INSTIMG, the maintainer may have not built a new AppImage for the latest release.$(tput sgr0)"
        echo "$(tput setaf 1)Check $GITHUB_APP_URL to see if a new AppImage is available for $INSTIMG.$(tput sgr0)"
        APPIMG_NEW_UPGRADE="FALSE"
        APPIMAGE_ERROR="TRUE"
    fi
}

appimgupgradecheckallfunc () {
    APPIMG_UPGRADE_CHECK="TRUE" # Set this variable to avoid downloading unnecessary webpages in appimginfofunc
    for AppImage in $(dir -C -w 1 ~/.config/spm/appimginstalled); do
        INSTIMG="$AppImage"
        echo "Checking $AppImage version..."
        appimgcheckfunc "$AppImage"
        appimginfofunc # Download web pages containing app info and set variables from them
        appimgvercheckfunc
        if grep -qw "$AppImage" ~/.config/spm/upgrade-list.lst; then # If AppImage is already on upgrade-list.lst, do not add it again
            echo "$(tput setaf 2)New upgrade available for $AppImage -- $NEW_APPIMAGE_VERSION !"
            echo "$AppImage is already marked for upgrade!"
            echo "Run 'spm upgrade' to upgrade $AppImage$(tput sgr0)"
        elif [ "$APPIMG_NEW_UPGRADE" = "TRUE" ]; then # Add AppImage to upgrade-list.lst if appimgvercheckfunc outputs APPIMG_NEW_UPGRADE="TRUE"
            echo "$(tput setaf 2)New upgrade available for $AppImage -- $NEW_APPIMAGE_VERSION !$(tput sgr0)"
            echo "$AppImage" >> ~/.config/spm/upgrade-list.lst
        fi
    done
    APPIMG_UPGRADE_CHECK="FALSE"
    echo
    if [ "$(cat ~/.config/spm/upgrade-list.lst | wc -l)" = "0" ]; then # If no AppImages were added to upgrade-list.lst, remove file
        rm ~/.config/spm/upgrade-list.lst
    fi
    if [ -f ~/.config/spm/upgrade-list.lst ]; then # If AppImages were added, list number of upgrades available
        if [ "$(cat ~/.config/spm/upgrade-list.lst | wc -l)" = "1" ]; then
            echo "$(tput setaf 2)$(cat ~/.config/spm/upgrade-list.lst | wc -l) upgrade available.$(tput sgr0)"
        else
            echo "$(tput setaf 2)$(cat ~/.config/spm/upgrade-list.lst | wc -l) upgrades available.$(tput sgr0)"
        fi
    else
        echo "No new AppImage upgrades."
    fi
}

appimgupgradecheckfunc () {
    if [ ! -f ~/.config/spm/appimginstalled/"$INSTIMG" ]; then
        echo "$INSTIMG is not installed; exiting..."
        rm -rf ~/.config/spm/cache/* # Remove any files in cache before exiting
        exit 1
    fi
    if grep -qw "$INSTIMG" ~/.config/spm/upgrade-list.lst; then # If AppImage is already on upgrade-list.lst, do not add it again 
        echo "$(tput setaf 2)$INSTIMG is already marked for upgrade!"
        echo "Run 'spm upgrade $INSTIMG' to upgrade $INSTIMG$(tput sgr0)"
        rm -rf ~/.config/spm/cache/* # Remove any files in cache before exiting
        exit 0
    fi
    APPIMG_UPGRADE_CHECK="TRUE"
    echo "Checking $INSTIMG version..."
    appimgcheckfunc "$INSTIMG" # Check whether AppImage is in lists and which list it is in
    appimginfofunc # Download web pages containing app info and set variables from them
    appimgvercheckfunc
    if [ "$APPIMG_NEW_UPGRADE" = "TRUE" ]; then # Add AppImage to upgrade-list.lst if appimgvercheckfunc outputs APPIMG_NEW_UPGRADE="TRUE"
        echo "$(tput setaf 2)New upgrade available for $INSTIMG -- $NEW_APPIMAGE_VERSION !$(tput sgr0)"
        echo "$INSTIMG" >> ~/.config/spm/upgrade-list.lst
    else
        echo "No new upgrade for $INSTIMG"
    fi
    if [ "$(cat ~/.config/spm/upgrade-list.lst | wc -l)" = "0" ]; then # If no AppImages were added to upgrade-list.lst, remove file
        rm ~/.config/spm/upgrade-list.lst
    fi
}

appimgupdatelistfunc () { # Regenerate AppImages-bintray.lst from bintray, download AppImages-github.lst from github, and check versions
    echo "Regenerating AppImages-bintray.lst from https://dl.bintray.com/probono/AppImages/ ..." # Generate list of AppImages from Bintray site using wget sed grep cut and sort
    cd ~/.config/spm
    wget --show-progress --quiet "https://dl.bintray.com/probono/AppImages/" -O - | sed 's/<\/*[^>]*>//g' | grep -o '.*AppImage' | cut -f1 -d"-" | sort -u > ~/.config/spm/AppImages-bintray.lst || { echo "wget failed; exiting..."; exit 1; }
    echo "AppImages-bintray.lst updated!"
    echo "Downloading AppImages-github.lst from spm github repo..." # Download existing list of github AppImages from spm github repo
    rm ~/.config/spm/AppImages-github.lst
    wget --quiet --show-progress "https://raw.githubusercontent.com/simoniz0r/appimgman/spm/AppImages-github.lst" || { echo "wget failed; exiting..."; rm -rf ~/.config/spm/cache/*; exit 1; }
    echo "AppImages-github.lst updated!"
    if [ ! -f ~/.config/spm/upgrade-list.lst ]; then # Create upgrade-list.lst file to avoid error outputs during update checks
        touch ~/.config/spm/upgrade-list.lst
    fi
    if [ -z "$2" ]; then # If no AppImage specified by user, check all installed AppImage versions
        appimgupgradecheckallfunc
    else # If user inputs AppImage, check that AppImage version
        INSTIMG="$2"
        appimgupgradecheckfunc
    fi
    APPIMG_UPGRADE_CHECK="FALSE"
    rm -rf ~/.config/spm/cache/* # Remove any files in cache before exiting
}

appimgupdateforcefunc () {
    if [ -f ~/.config/spm/appimginstalled/"$INSTIMG" ]; then # Show AppImage info if installed, exit if not
        cat ~/.config/spm/appimginstalled/"$INSTIMG"
    else
        echo "AppImage not found!"
        rm -rf ~/.config/spm/cache/* # Remove any files in cache before exiting
        exit 1
    fi
    if [ -f ~/.config/spm/upgrade-list.lst ]; then # Exit if already on upgrade-list.lst
        if grep -qw "$INSTIMG" ~/.config/spm/upgrade-list.lst; then
            echo "$(tput setaf 2)$INSTIMG is already marked for upgrade!"
            echo "Run 'spm upgrade $INSTIMG' to upgrade $INSTIMG$(tput sgr0)"
            rm -rf ~/.config/spm/cache/* # Remove any files in cache before exiting
            exit 0
        fi
    fi
    echo "Marking $INSTIMG for upgrade by force..."
    APPIMG_FORCE_UPGRADE="TRUE" # Mark for upgrade by force without checking versions
    appimgcheckfunc "$INSTIMG" # Check whether AppImage is in lists and which list it is in
    appimgvercheckfunc # Run vercheckfunc anyway to add AppImage to upgrade-list.lst
    if [ "$APPIMG_NEW_UPGRADE" = "TRUE" ]; then
        echo "$(tput setaf 2)New upgrade available for $INSTIMG!$(tput sgr0)"
        echo "$INSTIMG" >> ~/.config/spm/upgrade-list.lst
    else
        echo "No new upgrade for $INSTIMG"
    fi
}

appimgdlfunc () { # wget latest url from bintray website or github repo and wget it
    if [ "$BINTRAY_IMG" = "TRUE" ]; then # If AppImage is from Bintray, use method below to download it
        wget --show-progress --quiet "https://bintray.com/$BINTRAY_APPIMAGE_URL" -O ~/.config/spm/cache/"$INSTIMG" || { echo "wget $BINTRAY_APPIMAGE_URL failed; exiting..."; rm -rf ~/.config/spm/cache/*; exit 1; }
        # APPIMAGE="$(echo "$BINTRAY_APPIMAGE_URL" | cut -f2 -d"=")"
    elif [ "$GITHUB_IMG" = "TRUE" ]; then # If AppImage is from github, use method below to download it
        # APPIMAGE="${GITHUB_APPIMAGE_URL##*/}"
        wget --show-progress --quiet "$GITHUB_APPIMAGE_URL" -O ~/.config/spm/cache/"$INSTIMG" || { echo "wget $GITHUB_APPIMAGE_URL failed; exiting..."; rm -rf ~/.config/spm/cache/*; exit 1; }
    fi
}

appimgsaveinfofunc () { # Save install info to ~/.config/spm/appimginstalled/AppImageName
    INSTIMG="$1"
    echo "BIN_PATH="\"/usr/local/bin/$INSTIMG\""" > ~/.config/spm/appimginstalled/"$INSTIMG" # Create AppImage installed info file
    echo "APPIMAGE="\"$APPIMAGE_NAME\""" >> ~/.config/spm/appimginstalled/"$INSTIMG"
    if [ "$GITHUB_IMG" = "TRUE" ]; then
        APPIMAGE_VERSION="$NEW_APPIMAGE_VERSION"
    elif [ "$BINTRAY_IMG" = "TRUE" ]; then
        APPIMAGE_VERSION="$NEW_APPIMAGE_VERSION"
        APPIMAGE_VERSION="$(echo "$APPIMAGE_VERSION" | cut -f2 -d'-')"
    fi
    echo "APPIMAGE_VERSION="\"$APPIMAGE_VERSION\""" >> ~/.config/spm/appimginstalled/"$INSTIMG"
    if [ "$GITHUB_IMG" = "TRUE" ]; then
        echo "WEBSITE="\"$(echo "$GITHUB_APP_URL" | cut -f-5 -d'/')\""" >> ~/.config/spm/appimginstalled/"$INSTIMG"
    elif [ "$BINTRAY_IMG" = "TRUE" ]; then
        echo "WEBSITE="\"https://bintray.com/probono/AppImages/$APPIMG_NAME\""" >> ~/.config/spm/appimginstalled/"$INSTIMG"
    fi
    echo "APPIMG_DESCRIPTION="\"$APPIMG_DESCRIPTION\""" >> ~/.config/spm/appimginstalled/"$INSTIMG"
}

appimginstallfunc () { # chmod and mv AppImages to /usr/local/bin and create file containing install info in ~/.config/spm/appimginstalled
    chmod a+x ~/.config/spm/cache/"$INSTIMG" # Make AppImage executable
    echo "Moving $INSTIMG to /usr/local/bin/$INSTIMG ..."
    sudo mv ~/.config/spm/cache/"$INSTIMG" /usr/local/bin/"$INSTIMG" # Move AppImage to /usr/local/bin
    appimgsaveinfofunc "$INSTIMG"
    echo "$APPIMAGE_NAME has been installed to /usr/local/bin/$INSTIMG !"
}

appimginstallstartfunc () {
    if [ -f ~/.config/spm/appimginstalled/"$INSTIMG" ]; then # Exit if AppImage already installed by spm
        echo "$INSTIMG is already installed."
        echo "Use 'spm update' to check for a new version of $INSTIMG."
        rm -rf ~/.config/spm/cache/* # Remove any files in cache before exiting
        exit 1
    fi
    if type >/dev/null 2>&1 "$INSTIMG"; then # If a command by the same name as AppImage already exists on user's system, exit
        echo "$INSTIMG is already installed and not managed by spm; exiting..."
        rm -rf ~/.config/spm/cache/* # Remove any files in cache before exiting
        exit 1
    fi
    if [ -f "/usr/local/bin/$INSTIMG" ]; then # If for some reason type does't pick up same file existing as AppImage name in /usr/local/bin, exit
        echo "/usr/local/bin/$INSTIMG exists; exiting..."
        rm -rf ~/.config/spm/cache/* # Remove any files in cache before exiting
        exit 1
    fi
    appimgcheckfunc "$INSTIMG" # Check whether AppImage is in lists and which list it is in
    appimginfofunc # Download web pages containing app info and set variables from them
    appimgvercheckfunc # Use vercheckfunc to get AppImage name for output before install
    if [ "$BINTRAY_IMG" = "FALSE" ] && [ "$GITHUB_IMG" = "FALSE" ];then # If AppImage not in either list, exit
        echo "$INSTIMG is not in AppImages-bintray.lst or AppImages-github.lst; try running 'spm update'."
        rm -rf ~/.config/spm/cache/* # Remove any files in cache before exiting
        exit 1
    else
        if [ "$APPIMAGE_ERROR" = "TRUE" ]; then # If error getting AppImage, exit
            rm -rf ~/.config/spm/cache/* # Remove any files in cache before exiting
            exit 1
        fi
        echo "$APPIMAGE_NAME will be installed to /usr/local/bin/$INSTIMG" # Ask user if sure they want to install AppImage
        read -p "Continue? Y/N " INSTANSWER
        case $INSTANSWER in
            N*|n*) # If answer is no, exit
                echo "$APPIMAGE_NAME was not installed."
                rm -rf ~/.config/spm/cache/* # Remove any files in cache before exiting
                exit 0
                ;;
        esac
    fi
}

appimgupgradefunc () { # rm old AppImage, chmod, and mv new AppImage to /usr/local/bin
    echo "Removing previous $INSTIMG version..."
    sudo rm /usr/local/bin/"$INSTIMG" # Remove old AppImage before upgrading
    chmod a+x ~/.config/spm/cache/"$INSTIMG" # Make new AppImage executable
    echo "Moving $INSTIMG to /usr/local/bin/$INSTIMG ..."
    sudo mv ~/.config/spm/cache/"$INSTIMG" /usr/local/bin/"$INSTIMG" # Move new AppImage to /usr/local/bin
    appimgsaveinfofunc "$INSTIMG"
    echo "$INSTIMG has been upgraded to $INSTIMG version $APPIMAGE_VERSION !"
}

appimgupgradestartallfunc () {
    if [ "$APPIMGUPGRADES" = "FALSE" ]; then
        sleep 0
    else
        if [ "$(cat ~/.config/spm/upgrade-list.lst | wc -l)" = "1" ]; then # Output number of upgrades available
            echo "$(tput setaf 2)1 AppImage upgrade available.$(tput sgr0)"
        else
            echo "$(tput setaf 2)$(cat ~/.config/spm/upgrade-list.lst | wc -l) AppImage upgrades available.$(tput sgr0)"
        fi
        cat ~/.config/spm/upgrade-list.lst | tr '\n' ' ' | tr -d '"' # Ouput AppImages available for upgrades
        echo
        if [ "$(cat ~/.config/spm/upgrade-list.lst | wc -l)" = "1" ]; then
            echo "1 AppImage will be upgraded."
        else
            echo "$(cat ~/.config/spm/upgrade-list.lst | wc -l) AppImages will be upgraded."
        fi
        read -p "Continue? Y/N " UPGRADEALLANSWER # Ask user if they want to upgrade
        case $UPGRADEALLANSWER in
            Y*|y*) # Do upgrade functions if yes
                for UPGRADE_IMG in $(cat ~/.config/spm/upgrade-list.lst); do
                    INSTIMG="$UPGRADE_IMG"
                    echo "Downloading $INSTIMG..."
                    appimgcheckfunc "$INSTIMG" # Check whether AppImage is in lists and which list it is in
                    appimginfofunc
                    appimgdlfunc "$INSTIMG" # Download AppImage from Bintray or Github
                    appimgupgradefunc # Run upgrade function for AppImage
                    echo
                done
                ;;
            N*|n*) # Exit if no
                echo "No AppImages were upgraded; exiting..."
                rm -rf ~/.config/spm/cache/* # Remove any files in cache before exiting
                exit 0
                ;;
        esac
    fi
}

appimgupgradestartfunc () {
    echo "$INSTIMG will be upgraded to the latest version." # Ask user if sure about upgrade
    read -p "Continue? Y/N " UPGRADEANSWER
    case $UPGRADEANSWER in
        Y*|y*) # Do upgrade functions if yes
            appimgcheckfunc "$INSTIMG" # Check whether AppImage is in lists and which list it is in
            appimginfofunc
            appimgdlfunc "$INSTIMG" # Download AppImage from Bintray or Github
            appimgupgradefunc # Run upgrade function for AppImage
            if [ "$(cat ~/.config/spm/upgrade-list.lst | wc -l)" = "1" ]; then # Remove upgrade-list.lst if AppImage was only one in list
                rm ~/.config/spm/upgrade-list.lst
            else # Remove AppImage from upgrade-list.lst if more than one AppImage in list
                sed -i "s:"$INSTIMG"::g" ~/.config/spm/upgrade-list.lst # Use sed to remove AppImage name
                sed -i '/^$/d' ~/.config/spm/upgrade-list.lst # Use sed to remove blank space left from previous sed
            fi
            rm -rf ~/.config/spm/cache/* # Remove any files in cache before exiting
            exit 0
            ;;
        N*|n*) # Exit if no
            echo "$INSTIMG was not upgraded."
            rm -rf ~/.config/spm/cache/* # Remove any files in cache before exiting
            exit 0
            ;;
    esac
}

appimgremovefunc () { # rm AppImage in /usr/local/bin and remove install info file
    . ~/.config/spm/appimginstalled/"$REMIMG"
    echo "Removing $REMIMG..." # Ask user if sure they want to remove AppImage
    read -p "Continue? Y/N " IMGREMANSWER
    case $IMGREMANSWER in
        N*|n*) # If user answers no, exit
            echo "$REMIMG was not removed."
            rm -rf ~/.config/spm/cache/* # Remove any files in cache before exiting
            exit 0
            ;;
    esac
    if [ -f ~/.config/spm/upgrade-list.lst ]; then # If AppImage is on upgrade-list.lst, remove it from list to prevent future problems
        if grep -qw "$REMIMG" ~/.config/spm/upgrade-list.lst; then
            if [ "$(cat ~/.config/spm/upgrade-list.lst | wc -l)" = "1" ]; then
                rm ~/.config/spm/upgrade-list.lst
            else
                sed -i "s:"$REMIMG"::g" ~/.config/spm/upgrade-list.lst
                sed -i '/^$/d' ~/.config/spm/upgrade-list.lst
            fi
        fi
    fi
    echo "Removing /usr/local/bin/$REMIMG ..."
    sudo rm /usr/local/bin/"$REMIMG" # Remove AppImage from /usr/local/bin
    rm ~/.config/spm/appimginstalled/"$REMIMG" # Remove installed info file for AppImage
    echo "$REMIMG has been removed!"
}
