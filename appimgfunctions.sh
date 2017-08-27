#!/bin/bash
# Title: spm
# Description: Downloads and installs AppImages and precompiled tar archives.  Can also upgrade and remove installed packages.
# Dependencies: GNU coreutils, tar, wget, python3.x
# Author: simonizor
# Website: http://www.simonizor.gq
# License: GPL v2.0 only

X="0.2.0"
# Set spm version

# Set variables
APPIMG_UPGRADE_CHECK="FALSE"
APPIMG_FORCE_UPGRADE="FALSE"

appimgfunctionsexistsfunc () {
    sleep 0
}

appimgsaveinfofunc () { # Save install info to "$CONFDIR"/appimginstalled/AppImageName
    SAVEDIR="$1"
    echo "BIN_PATH="\"/usr/local/bin/$INSTIMG\""" > "$CONFDIR"/"$SAVEDIR" # Create AppImage installed info file
    echo "APPIMAGE="\"$APPIMAGE_NAME\""" >> "$CONFDIR"/"$SAVEDIR"
    APPIMAGE_VERSION="$NEW_APPIMAGE_VERSION"
    echo "APPIMAGE_VERSION="\"$APPIMAGE_VERSION\""" >> "$CONFDIR"/"$SAVEDIR"
    if [ "$GITHUB_IMG" = "TRUE" ]; then
        echo "WEBSITE="\"$(echo "$GITHUB_APP_URL" | cut -f-5 -d'/')\""" >> "$CONFDIR"/"$SAVEDIR"
    elif [ "$DIRECT_IMG" = "TRUE" ]; then
        echo "WEBSITE="\"$(echo "$DIRECT_APPIMAGE_URL" | cut -f-3 -d'/')\""" >> "$CONFDIR"/"$SAVEDIR"
    fi
    if [ "$GITHUB_IMG" = "TRUE" ]; then
        echo "APPIMG_DESCRIPTION="\"$APPIMG_DESCRIPTION\""" >> "$CONFDIR"/"$SAVEDIR"
    fi
}

appimglistallfunc () {
    echo "$(dir -C -w 1 "$CONFDIR"/appimginstalled | wc -l) AppImages installed:"
    dir -C -w 1 "$CONFDIR"/appimginstalled | pr -tT --column=3 -w 125
    echo
    echo "$(cat "$CONFDIR"/AppImages-github.lst | wc -l) Github AppImages available for install:"
    cat "$CONFDIR"/AppImages-github.lst | cut -f1 -d" " | pr -tT --column=3 -w 125
    echo
    echo "$(cat "$CONFDIR"/AppImages-direct.lst | wc -l) Direct AppImages available for install:"
    cat "$CONFDIR"/AppImages-direct.lst | cut -f1 -d" " | pr -tT --column=3 -w 125
}

appimgcheckfunc () { # check user input against list of known apps here
    if grep -qwi "$1" "$CONFDIR"/AppImages-direct.lst; then # Check AppImages-direct.lst for AppImages from Direct
        APPIMG_NAME="$(grep -woi "$1" "$CONFDIR"/AppImages-direct.lst  | cut -f1 -d" ")"
        DIRECT_IMG="TRUE"
        GITHUB_IMG="FALSE"
    elif grep -qwi "$1" "$CONFDIR"/AppImages-github.lst; then # Check AppImages-github.lst for AppImages from github
        APPIMG_NAME="$(grep -woi "$1" "$CONFDIR"/AppImages-github.lst | cut -f1 -d" ")"
        DIRECT_IMG="FALSE"
        GITHUB_IMG="TRUE"
    else
        DIRECT_IMG="FALSE"
        GITHUB_IMG="FALSE"
    fi
}

appimggithubinfofunc () {
    GITHUB_APP_URL="$(grep -wi "$INSTIMG" "$CONFDIR"/AppImages-github.lst | cut -f2 -d" ")"
    APPIMG_GITHUB_API_URL="$(grep -wi "$INSTIMG" "$CONFDIR"/AppImages-github.lst | cut -f3- -d" ")"
    if [ -z "$GITHUB_TOKEN" ]; then
        wget --quiet "$APPIMG_GITHUB_API_URL" -O "$CONFDIR"/cache/"$INSTIMG"-release || { echo "wget $APPIMG_GITHUB_API_URL failed; has the repo been renamed or deleted?"; exit 1; }
    else
        wget --quiet --auth-no-challenge --header="Authorization: token "$GITHUB_TOKEN"" "$APPIMG_GITHUB_API_URL" -O "$CONFDIR"/cache/"$INSTIMG"-release || { echo "wget $APPIMG_GITHUB_API_URL failed; is your token valid?"; exit 1; }
    fi
    APPIMAGE_INFO="$HOME/.config/spm/cache/$INSTIMG"-release
    APPIMAGE_NAME="$(grep -iv '.*ia32*.\|.*i686*.\|.*i386*.' "$APPIMAGE_INFO" | grep "$INSTIMG" | grep -im 1 '"name":*..*AppImage"' | cut -f4 -d'"')"
    NEW_APPIMAGE_VERSION="$(grep -iv '.*ia32*.\|.*i686*.\|.*i386*.' "$APPIMAGE_INFO" | grep -B 1 -im 1 '"browser_download_url":*..*AppImage"' | head -n 1 | cut -f4 -d'"')"
    GITHUB_APPIMAGE_URL="$(grep -iv '.*ia32*.\|.*i686*.\|.*i386*.' "$APPIMAGE_INFO" | grep "$INSTIMG" | grep -im 1 '"browser_download_url":*..*AppImage"' | cut -f4 -d'"')"
    if [ -z "$APPIMAGE_NAME" ]; then
        APPIMAGE_NAME="$(grep -iv '.*ia32*.\|.*i686*.\|.*i386*.' "$APPIMAGE_INFO" | grep -im 1 '"name":*..*AppImage"' | cut -f4 -d'"')"
        NEW_APPIMAGE_VERSION="$(grep -iv '.*ia32*.\|.*i686*.\|.*i386*.' "$APPIMAGE_INFO" | grep -B 1 -im 1 '"browser_download_url":*..*AppImage"' | head -n 1 | cut -f4 -d'"')"
        GITHUB_APPIMAGE_URL="$(grep -iv '.*ia32*.\|.*i686*.\|.*i386*.' "$APPIMAGE_INFO" | grep -im 1 '"browser_download_url":*..*AppImage"' | cut -f4 -d'"')"
    fi
    if [ "$APPIMG_UPGRADE_CHECK" = "FALSE" ]; then
        wget --quiet "$GITHUB_APP_URL" -O "$CONFDIR"/cache/"$INSTIMG"-github || { echo "wget $GITHUB_APP_URL failed; has the repo been renamed or deleted?"; rm -rf "$CONFDIR"/cache/*; exit 1; }
        APPIMG_GITHUB_INFO="$HOME/.config/spm/cache/"$INSTIMG"-github"
        APPIMG_DESCRIPTION="$(grep -i '<meta name="description"' "$APPIMG_GITHUB_INFO" | cut -f4 -d'"')"
    fi
}

appimgdirectinfofunc () {
    DIRECT_APPIMAGE_URL="$(grep -wi "$INSTIMG" "$CONFDIR"/AppImages-direct.lst | cut -f2 -d" ")"
    echo "$INSTIMG version cannot be tracked reliably (direct download)."
    if [ -f "$CONFDIR"/appimginstalled/"$INSTIMG" ]; then
        . "$CONFDIR"/appimginstalled/"$INSTIMG"
        APPIMAGE_NAME="$APPIMAGE"
        NEW_APPIMAGE_VERSION="$APPIMAGE_VERSION"
    else
        APPIMAGE_NAME="${DIRECT_APPIMAGE_URL##*/}"
        NEW_APPIMAGE_VERSION="$APPIMAGE_NAME"
    fi
}

appimginfofunc () { # Set variables and temporarily store pages in "$CONFDIR"/cache to get info from them
    if [ "$DIRECT_IMG" = "TRUE" ]; then
        appimgdirectinfofunc
    elif [ "$GITHUB_IMG" = "TRUE" ]; then # If AppImage is from github, use method below to get new AppImage version
        appimggithubinfofunc
    fi
}

appimglistfunc () {
    if [ -f "$CONFDIR"/appimginstalled/"$LISTIMG" ]; then # If installed, list installed info
        echo "Current installed $LISTIMG information:"
        cat "$CONFDIR"/appimginstalled/"$LISTIMG"
        echo "INSTALLED=\"YES\""
    else
        INSTIMG="$LISTIMG"
        appimgcheckfunc "$LISTIMG"
        appimginfofunc
        appimgsaveinfofunc "cache/$LISTIMG.conf"
        if [ -f "$CONFDIR"/cache/"$LISTIMG".conf ]; then
            echo "$LISTIMG information:"
            cat "$CONFDIR"/cache/"$LISTIMG".conf
        else # Exit if not in list or installed
            echo "AppImage not found!"
        fi
    fi
}

appimglistinstalledfunc () {
    echo "$(dir -C -w 1 "$CONFDIR"/appimginstalled | wc -l) AppImages installed:"
    dir -C -w 1 "$CONFDIR"/appimginstalled | pr -tT --column=3 -w 125
    echo
    for AppImage in $(dir -C -w 1 "$CONFDIR"/appimginstalled); do
        echo "$AppImage installed information:"
        cat "$CONFDIR"/appimginstalled/"$AppImage"
        echo "INSTALLED=\"YES\""
        echo
    done
}

appimgvercheckfunc () { # Check version by getting the latest version from the bintray website or github releases page using wget, grep, cut, and head
    if [ -f "$CONFDIR"/appimginstalled/"$INSTIMG" ]; then # Load installed information if AppImage is installed
        . "$CONFDIR"/appimginstalled/"$INSTIMG"
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
    for AppImage in $(dir -C -w 1 "$CONFDIR"/appimginstalled); do
        INSTIMG="$AppImage"
        echo "Checking $AppImage version..."
        appimgcheckfunc "$AppImage"
        appimginfofunc # Download web pages containing app info and set variables from them
        appimgvercheckfunc
        if [ "$APPIMG_NEW_UPGRADE" = "TRUE" ]; then # Mark AppImage for upgrade if appimgvercheckfunc outputs APPIMG_NEW_UPGRADE="TRUE"
            echo "$(tput setaf 2)New upgrade available for $AppImage -- $NEW_APPIMAGE_VERSION !$(tput sgr0)"
            appimgsaveinfofunc "appimgupgrades/$AppImage"
            # echo "$AppImage" >> "$CONFDIR"/upgrade-list.lst
        fi
    done
    APPIMG_UPGRADE_CHECK="FALSE"
    echo
    if [ "$(dir "$CONFDIR"/appimgupgrades | wc -l)" = "1" ]; then
        echo "$(tput setaf 2)$(dir -C -w 1 "$CONFDIR"/appimgupgrades | wc -l) new AppImage upgrade available.$(tput sgr0)"
    elif [ "$(dir "$CONFDIR"/appimgupgrades | wc -l)" = "0" ]; then
        echo "No new AppImage upgrades."
    else
        echo "$(tput setaf 2)$(dir -C -w 1 "$CONFDIR"/appimgupgrades | wc -l) new AppImage upgrades available.$(tput sgr0)"
    fi
}

appimgupgradecheckfunc () {
    if [ ! -f "$CONFDIR"/appimginstalled/"$INSTIMG" ]; then
        echo "$INSTIMG is not installed..."
    else
        APPIMG_UPGRADE_CHECK="TRUE"
        echo "Checking $INSTIMG version..."
        appimgcheckfunc "$INSTIMG" # Check whether AppImage is in lists and which list it is in
        appimginfofunc # Download web pages containing app info and set variables from them
        appimgvercheckfunc
        if [ "$APPIMG_NEW_UPGRADE" = "TRUE" ]; then # Mark AppImage for upgrade if appimgvercheckfunc outputs APPIMG_NEW_UPGRADE="TRUE"
            echo "$(tput setaf 2)New upgrade available for $INSTIMG -- $NEW_APPIMAGE_VERSION !$(tput sgr0)"
            appimgsaveinfofunc "appimgupgrades/$INSTIMG"
            # echo "$INSTIMG" >> "$CONFDIR"/upgrade-list.lst
        else
            echo "No new upgrade for $INSTIMG"
        fi
    fi
}

appimgupdatelistfunc () { # Regenerate AppImages-direct.lst from github, download AppImages-github.lst from github, and check versions
    APPIMG_UPGRADE_CHECK="TRUE"
    echo "Downloading AppImages-direct.lst from spm github repo..." # Download existing list of direct AppImages from spm github repo
    cd "$CONFDIR"
    rm "$CONFDIR"/AppImages-direct.lst
    wget --quiet "https://raw.githubusercontent.com/simoniz0r/spm/master/AppImages-direct.lst" || { echo "wget failed; exiting..."; rm -rf "$CONFDIR"/cache/*; exit 1; }
    echo "AppImages-direct.lst updated!"
    echo "Downloading AppImages-github.lst from spm github repo..." # Download existing list of github AppImages from spm github repo
    rm "$CONFDIR"/AppImages-github.lst
    wget --quiet "https://raw.githubusercontent.com/simoniz0r/spm/master/AppImages-github.lst" || { echo "wget failed; exiting..."; rm -rf "$CONFDIR"/cache/*; exit 1; }
    echo "AppImages-github.lst updated!"
    if [ -z "$1" ]; then # If no AppImage specified by user, check all installed AppImage versions
        appimgupgradecheckallfunc
    else # If user inputs AppImage, check that AppImage version
        INSTIMG="$1"
        appimgupgradecheckfunc
    fi
    APPIMG_UPGRADE_CHECK="FALSE"
}

appimgupdateforcefunc () {
    if [ -f "$CONFDIR"/appimginstalled/"$INSTIMG" ]; then # Show AppImage info if installed, exit if not
        cat "$CONFDIR"/appimginstalled/"$INSTIMG"
    else
        echo "AppImage not found!"
        rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
        exit 1
    fi
    echo "Marking $INSTIMG for upgrade by force..."
    . "$CONFDIR"/appimginstalled/"$INSTIMG"
    APPIMAGE_NAME="$APPIMAGE"
    NEW_APPIMAGE_VERSION="$APPIMAGE_VERSION"
    GITHUB_APP_URL="$WEBSITE"
    echo "$(tput setaf 2)New upgrade available for $INSTIMG!$(tput sgr0)"
    appimgsaveinfofunc "appimgupgrades/$INSTIMG"
}

appimgdlfunc () { # wget latest url from direct website or github repo and wget it
    if [ "$DIRECT_IMG" = "TRUE" ]; then # If AppImage is DIRECT, use method below to download it
        cd "$CONFDIR"/cache
        wget --quiet --read-timeout=30 --show-progress --trust-server-names "$DIRECT_APPIMAGE_URL" || { echo "wget $DIRECT_APPIMAGE_URL failed; exiting..."; rm -rf "$CONFDIR"/cache/*; exit 1; }
        APPIMAGE_NAME="$(dir -C -w 1 "$CONFDIR"/cache/ | grep -iw '.*AppImage')"
        NEW_APPIMAGE_VERSION="$APPIMAGE_NAME"
        mv "$CONFDIR"/cache/"$APPIMAGE_NAME" "$CONFDIR"/cache/"$INSTIMG"
    elif [ "$GITHUB_IMG" = "TRUE" ]; then # If AppImage is from github, use method below to download it
        # APPIMAGE="${GITHUB_APPIMAGE_URL##*/}"
        wget --show-progress --quiet "$GITHUB_APPIMAGE_URL" -O "$CONFDIR"/cache/"$INSTIMG" || { echo "wget $GITHUB_APPIMAGE_URL failed; exiting..."; rm -rf "$CONFDIR"/cache/*; exit 1; }
    fi
}

appimginstallfunc () { # chmod and mv AppImages to /usr/local/bin and create file containing install info in "$CONFDIR"/appimginstalled
    chmod a+x "$CONFDIR"/cache/"$INSTIMG" # Make AppImage executable
    echo "Moving $INSTIMG to /usr/local/bin/$INSTIMG ..."
    sudo mv "$CONFDIR"/cache/"$INSTIMG" /usr/local/bin/"$INSTIMG" # Move AppImage to /usr/local/bin
    appimgsaveinfofunc "appimginstalled/$INSTIMG"
    echo "$APPIMAGE_NAME has been installed to /usr/local/bin/$INSTIMG !"
}

appimginstallstartfunc () {
    if [ -f "$CONFDIR"/appimginstalled/"$INSTIMG" ]; then # Exit if AppImage already installed by spm
        echo "$INSTIMG is already installed."
        echo "Use 'spm update' to check for a new version of $INSTIMG."
        rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
        exit 1
    fi
    if type >/dev/null 2>&1 "$INSTIMG"; then # If a command by the same name as AppImage already exists on user's system, exit
        echo "$INSTIMG is already installed and not managed by spm; exiting..."
        rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
        exit 1
    fi
    if [ -f "/usr/local/bin/$INSTIMG" ]; then # If for some reason type does't pick up same file existing as AppImage name in /usr/local/bin, exit
        echo "/usr/local/bin/$INSTIMG exists; exiting..."
        rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
        exit 1
    fi
    appimgcheckfunc "$INSTIMG" # Check whether AppImage is in lists and which list it is in
    appimginfofunc # Download web pages containing app info and set variables from them
    appimgvercheckfunc # Use vercheckfunc to get AppImage name for output before install
    if [ "$DIRECT_IMG" = "FALSE" ] && [ "$GITHUB_IMG" = "FALSE" ];then # If AppImage not in either list, exit
        echo "$INSTIMG is not in AppImages-direct.lst or AppImages-github.lst; try running 'spm update'."
        rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
        exit 1
    else
        if [ "$APPIMAGE_ERROR" = "TRUE" ]; then # If error getting AppImage, exit
            rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
            exit 1
        fi
        echo "$APPIMAGE_NAME will be installed to /usr/local/bin/$INSTIMG" # Ask user if sure they want to install AppImage
        read -p "Continue? Y/N " INSTANSWER
        case $INSTANSWER in
            N*|n*) # If answer is no, exit
                echo "$APPIMAGE_NAME was not installed."
                rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
                exit 0
                ;;
        esac
    fi
}

appimgupgradefunc () { # rm old AppImage, chmod, and mv new AppImage to /usr/local/bin
    echo "Removing previous $INSTIMG version..."
    sudo rm /usr/local/bin/"$INSTIMG" # Remove old AppImage before upgrading
    chmod a+x "$CONFDIR"/cache/"$INSTIMG" # Make new AppImage executable
    echo "Moving $INSTIMG to /usr/local/bin/$INSTIMG ..."
    sudo mv "$CONFDIR"/cache/"$INSTIMG" /usr/local/bin/"$INSTIMG" # Move new AppImage to /usr/local/bin
    appimgsaveinfofunc "appimginstalled/$INSTIMG"
    echo "$INSTIMG has been upgraded to $INSTIMG version $APPIMAGE_VERSION !"
}

appimgupgradestartallfunc () {
    if [ "$APPIMGUPGRADES" = "FALSE" ]; then
        sleep 0
    else
        if [ "$(dir "$CONFDIR"/appimgupgrades | wc -l)" = "1" ]; then
            echo "$(tput setaf 2)$(dir -C -w 1 "$CONFDIR"/appimgupgrades | wc -l) new AppImage upgrade available.$(tput sgr0)"
        elif [ "$(dir "$CONFDIR"/appimgupgrades | wc -l)" = "0" ]; then
            echo "No new AppImage upgrades."
        else
            echo "$(tput setaf 2)$(dir -C -w 1 "$CONFDIR"/appimgupgrades | wc -l) new AppImage upgrades available.$(tput sgr0)"
        fi
        dir -C -w 1 "$CONFDIR"/appimgupgrades | pr -tTw 125 -3 # Ouput AppImages available for upgrades
        echo
        read -p "Continue? Y/N " UPGRADEALLANSWER # Ask user if they want to upgrade
        case $UPGRADEALLANSWER in
            Y*|y*) # Do upgrade functions if yes
                for UPGRADE_IMG in $(dir -C -w 1 "$CONFDIR"/appimgupgrades); do
                    INSTIMG="$UPGRADE_IMG"
                    echo "Downloading $INSTIMG..."
                    appimgcheckfunc "$INSTIMG" # Check whether AppImage is in lists and which list it is in
                    appimginfofunc
                    appimgdlfunc "$INSTIMG" # Download AppImage from Direct or Github
                    appimgupgradefunc # Run upgrade function for AppImage
                    rm "$CONFDIR"/appimgupgrades/"$INSTIMG"
                    echo
                done
                ;;
            N*|n*) # Exit if no
                echo "No AppImages were upgraded; exiting..."
                rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
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
            appimgdlfunc "$INSTIMG" # Download AppImage from Direct or Github
            appimgupgradefunc # Run upgrade function for AppImage
            rm "$CONFDIR"/appimgupgrades/"$INSTIMG"
            rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
            exit 0
            ;;
        N*|n*) # Exit if no
            echo "$INSTIMG was not upgraded."
            rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
            exit 0
            ;;
    esac
}

appimgremovefunc () { # rm AppImage in /usr/local/bin and remove install info file
    . "$CONFDIR"/appimginstalled/"$REMIMG"
    echo "Removing $REMIMG..." # Ask user if sure they want to remove AppImage
    read -p "Continue? Y/N " IMGREMANSWER
    case $IMGREMANSWER in
        N*|n*) # If user answers no, exit
            echo "$REMIMG was not removed."
            rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
            exit 0
            ;;
    esac
    if [ -f "$CONFDIR"/appimgupgrades/"$REMIMG" ]; then # If AppImage is marked for upgrade, remove it from list to prevent future problems
        rm "$CONFDIR"/appimgupgrades/"$REMIMG"
    fi
    echo "Removing /usr/local/bin/$REMIMG ..."
    sudo rm /usr/local/bin/"$REMIMG" # Remove AppImage from /usr/local/bin
    rm "$CONFDIR"/appimginstalled/"$REMIMG" # Remove installed info file for AppImage
    echo "$REMIMG has been removed!"
}
