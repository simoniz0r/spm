#!/bin/bash
# Title: spm
# Description: Downloads and installs AppImages and precompiled tar archives.  Can also upgrade and remove installed packages.
# Dependencies: GNU coreutils, tar, wget
# Author: simonizor
# Website: http://www.simonizor.gq
# License: GPL v2.0 only

X="0.5.6"
# Set spm version

# Set variables
APPIMG_FORCE_UPGRADE="FALSE"
APPIMAGE_SIZE="N/A"
APPIMAGE_DOWNLOADS="N/A"

appimgfunctionsexistsfunc () {
    sleep 0
}

appimgsaveinfofunc () { # Save install info to "$CONFDIR"/appimginstalled/AppImageName
    SAVEDIR="$1"
    echo "APPIMAGE="\"$APPIMAGE_NAME\""" > "$CONFDIR"/"$SAVEDIR"
    if [ ! -z "$NEW_APPIMAGE_VERSION" ]; then
        APPIMAGE_VERSION="$NEW_APPIMAGE_VERSION"
    fi
    echo "APPIMAGE_VERSION="\"$APPIMAGE_VERSION\""" >> "$CONFDIR"/"$SAVEDIR"
    echo "APPIMAGE_SIZE="\"$APPIMAGE_SIZE\""" >> "$CONFDIR"/"$SAVEDIR"
    echo "APPIMAGE_DOWNLOADS="\"$APPIMAGE_DOWNLOADS\""" >> "$CONFDIR"/"$SAVEDIR"
    if [ "$GITHUB_IMG" = "TRUE" ]; then
        echo "APPIMAGE_GITHUB_VERSION="\"$APPIMAGE_GITHUB_NEW_VERSION\""" >> "$CONFDIR"/"$SAVEDIR"
        echo "APPIMAGE_GITHUB_TAG="\"$APPIMAGE_GITHUB_TAG\""" >> "$CONFDIR"/"$SAVEDIR"
        echo "WEBSITE="\"$(echo "$GITHUB_APP_URL" | cut -f-5 -d'/')\""" >> "$CONFDIR"/"$SAVEDIR"
    elif [ "$DIRECT_IMG" = "TRUE" ]; then
        echo "WEBSITE="\"$(echo "$DIRECT_APPIMAGE_URL" | cut -f-3 -d'/')\""" >> "$CONFDIR"/"$SAVEDIR"
    fi
    echo "BIN_PATH="\"/usr/local/bin/$INSTIMG\""" >> "$CONFDIR"/"$SAVEDIR"
    echo "APPIMAGE_DESCRIPTION="\"$APPIMAGE_DESCRIPTION\""" >> "$CONFDIR"/"$SAVEDIR"
}

appimgcheckfunc () { # check user input against list of known apps here
    case $("$RUNNING_DIR"/yaml r "$CONFDIR"/AppImages.yml $INSTIMG) in
        null)
            GITHUB_IMG="FALSE"
            DIRECT_IMG="FALSE"
            ;;
        *)
            SPM_APPIMG_REPO_BRANCH="$("$RUNNING_DIR"/yaml r "$CONFDIR"/AppImages.yml $INSTIMG)"
            ;;
    esac
    case $SPM_APPIMG_REPO_BRANCH in
        AppImages-github)
            GITHUB_IMG="TRUE"
            DIRECT_IMG="FALSE"
            if [ ! -f "$CONFDIR/appimginstalled/.$INSTIMG.yml" ]; then
                wget --quiet "https://github.com/simoniz0r/spm-repo/raw/AppImages-github/$INSTIMG.yml" -O "$CONFDIR"/appimginstalled/."$INSTIMG".yml
            fi
            APPIMG_NAME="$("$RUNNING_DIR"/yaml r "$CONFDIR"/appimginstalled/."$INSTIMG".yml name)"
            ;;
        AppImages-other)
            GITHUB_IMG="FALSE"
            DIRECT_IMG="TRUE"
            if [ ! -f "$CONFDIR/appimginstalled/.$INSTIMG.yml" ]; then
                wget --quiet "https://github.com/simoniz0r/spm-repo/raw/AppImages-other/$INSTIMG.yml" -O "$CONFDIR"/appimginstalled/."$INSTIMG".yml
            fi
            APPIMG_NAME="$("$RUNNING_DIR"/yaml r "$CONFDIR"/appimginstalled/."$INSTIMG".yml name)"
            ;;
    esac
}

appimggithubinfofunc () {
    GITHUB_APP_URL="$("$RUNNING_DIR"/yaml r "$CONFDIR"/appimginstalled/."$INSTIMG".yml url)"
    GITHUB_APP_URL="$(echo "$GITHUB_APP_URL" | cut -f-5 -d'/')"
    APPIMG_GITHUB_API_URL="$("$RUNNING_DIR"/yaml r "$CONFDIR"/appimginstalled/."$INSTIMG".yml apiurl)"
    INSTIMG_NAME="$("$RUNNING_DIR"/yaml r "$CONFDIR"/appimginstalled/."$INSTIMG".yml name)"
    if [ -z "$GITHUB_TOKEN" ]; then
        wget --quiet "$APPIMG_GITHUB_API_URL" -O "$CONFDIR"/cache/"$INSTIMG"full || { echo "$(tput setaf 1)wget $APPIMG_GITHUB_API_URL failed!$(tput sgr0)"; rm -rf "$CONFDIR"/cache/*; exit 1; }
    else
        wget --quiet --auth-no-challenge --header="Authorization: token "$GITHUB_TOKEN"" "$APPIMG_GITHUB_API_URL" -O "$CONFDIR"/cache/"$INSTIMG"full || { echo "$(tput setaf 1)wget failed!$(tput sgr0)"; rm -rf "$CONFDIR"/cache/*; exit 1; }
    fi
    JQARG=".[].assets[] | select(.name | contains(\".AppImage\"), contains(\".appimage\")) | select(.name | contains(\"$INSTIMG_NAME\")) | select(.name | contains(\"ia32\") | not) | select(.name | contains(\"i386\") | not) | select(.name | contains(\"i686\") | not) | { name: .name, updated: .updated_at, url: .browser_download_url, size: .size, numdls: .download_count}"
    cat "$CONFDIR"/cache/"$INSTIMG"full | "$RUNNING_DIR"/jq --raw-output "$JQARG" | sed 's%{%data:%g' | tr -d '",}' > "$CONFDIR"/cache/"$INSTIMG"release
    if [ "$(cat "$CONFDIR"/cache/"$INSTIMG"release | wc -l)" = "0" ]; then
        rm "$CONFDIR"/cache/"$INSTIMG"release
        JQARG=".[].assets[] | select(.name | contains(\".AppImage\"), contains(\".appimage\")) | select(.name | contains(\"ia32\") | not) | select(.name | contains(\"i386\") | not) | select(.name | contains(\"i686\") | not) | { name: .name, updated: .updated_at, url: .browser_download_url, size: .size, numdls: .download_count}"
        cat "$CONFDIR"/cache/"$INSTIMG"full | "$RUNNING_DIR"/jq --raw-output "$JQARG" | sed 's%{%data:%g' | tr -d '",}' > "$CONFDIR"/cache/"$INSTIMG"release
    fi
    APPIMAGE_NAME="$(cat "$CONFDIR"/cache/"$INSTIMG"release | "$RUNNING_DIR"/yaml r - data.name)"
    NEW_APPIMAGE_VERSION="$(cat "$CONFDIR"/cache/"$INSTIMG"release | "$RUNNING_DIR"/yaml r - data.updated)"
    GITHUB_APPIMAGE_URL="$(cat "$CONFDIR"/cache/"$INSTIMG"release | "$RUNNING_DIR"/yaml r - data.url)"
    APPIMAGE_SIZE="$(cat "$CONFDIR"/cache/"$INSTIMG"release | "$RUNNING_DIR"/yaml r - data.size)"
    APPIMAGE_SIZE="$(echo "scale = 3; $APPIMAGE_SIZE / 1024 / 1024" | bc) MBs"
    APPIMAGE_DOWNLOADS="$(cat "$CONFDIR"/cache/"$INSTIMG"release | "$RUNNING_DIR"/yaml r - data.numdls)"
    APPIMAGE_DESCRIPTION="$("$RUNNING_DIR"/yaml r "$CONFDIR"/appimginstalled/."$INSTIMG".yml description)"
    APPIMAGE_GITHUB_NEW_VERSION="$(echo "$GITHUB_APPIMAGE_URL" | cut -f8 -d"/")"
    APPIMAGE_GITHUB_TAG="$(wget --quiet "$GITHUB_APP_URL.git/info/refs?service=git-upload-pack" -O - | cut -f3 -d'/' | tac | head -n 2 | tail -n 1 | cut -f1 -d'^')"
}

appimgdirectinfofunc () {
    DIRECT_APPIMAGE_URL="$("$RUNNING_DIR"/yaml r "$CONFDIR"/appimginstalled/."$INSTIMG".yml url)"
    wget -S --read-timeout=30 --spider "$DIRECT_APPIMAGE_URL" -o "$CONFDIR"/cache/"$INSTIMG".latest
    NEW_APPIMAGE_VERSION="$(grep -o "Location:.*" "$CONFDIR"/cache/"$INSTIMG".latest | cut -f2 -d" ")"
    NEW_APPIMAGE_VERSION="${NEW_APPIMAGE_VERSION##*/}"
    APPIMAGE_DESCRIPTION="$DIRECT_APPIMAGE_URL"
    if [ -z "$NEW_APPIMAGE_VERSION" ]; then
        NEW_APPIMAGE_VERSION="$(tput setaf 1)Cannot check version; upgrades will have to be forced$(tput sgr0)"
    fi
    APPIMAGE_NAME="$NEW_APPIMAGE_VERSION"
    if [ -f "$CONFDIR"/appimginstalled/"$INSTIMG" ]; then
        . "$CONFDIR"/appimginstalled/"$INSTIMG"
    fi
    APPIMAGE_SIZE="N/A"
    APPIMAGE_DOWNLOADS="N/A"
}

appimginfofunc () { # Set variables and temporarily store pages in "$CONFDIR"/cache to get info from them
    if [ "$DIRECT_IMG" = "TRUE" ]; then
        appimgdirectinfofunc
    elif [ "$GITHUB_IMG" = "TRUE" ]; then # If AppImage is from github, use method below to get new AppImage version
        appimggithubinfofunc
    fi
}

appimglistfunc () {
    if [ -f "$CONFDIR"/appimginstalled/"$INSTIMG" ]; then # If installed, list installed info
        echo "$(tput bold)$(tput setaf 2)$INSTIMG AppImage installed information$(tput sgr0):"
        . "$CONFDIR"/appimginstalled/"$INSTIMG"
        echo "$(tput bold)$(tput setaf 2)Info$(tput sgr0):  $APPIMAGE_DESCRIPTION"
        echo "$(tput bold)$(tput setaf 2)Version$(tput sgr0):  $APPIMAGE_VERSION"
        if [ ! -z "$APPIMAGE_GITHUB_TAG" ]; then
            echo "$(tput bold)$(tput setaf 2)Tag$(tput sgr0):  $APPIMAGE_GITHUB_TAG"
        fi
        echo "$(tput bold)$(tput setaf 2)Total DLs$(tput sgr0):  $APPIMAGE_DOWNLOADS"
        echo "$(tput bold)$(tput setaf 2)URL$(tput sgr0):  $WEBSITE"
        echo "$(tput bold)$(tput setaf 2)Size$(tput sgr0):  $APPIMAGE_SIZE"
        echo "$(tput bold)$(tput setaf 2)Install dir$(tput sgr0): $BIN_PATH"
        echo
    else
        INSTIMG="$INSTIMG"
        appimgcheckfunc "$INSTIMG"
        appimginfofunc
        if [ "$GITHUB_IMG" = "TRUE" ] || [ "$DIRECT_IMG" = "TRUE" ]; then
            appimgsaveinfofunc "cache/$INSTIMG.conf"
            echo "$(tput bold)$(tput setaf 2)$INSTIMG AppImage information$(tput sgr0):"
            . "$CONFDIR"/cache/"$INSTIMG".conf
            echo "$(tput bold)$(tput setaf 2)Info$(tput sgr0):  $APPIMAGE_DESCRIPTION"
            echo "$(tput bold)$(tput setaf 2)Version$(tput sgr0):  $APPIMAGE_VERSION"
            if [ ! -z "$APPIMAGE_GITHUB_TAG" ]; then
                echo "$(tput bold)$(tput setaf 2)Tag$(tput sgr0):  $APPIMAGE_GITHUB_TAG"
            fi
            echo "$(tput bold)$(tput setaf 2)Total DLs$(tput sgr0):  $APPIMAGE_DOWNLOADS"
            echo "$(tput bold)$(tput setaf 2)URL$(tput sgr0):  $WEBSITE"
            echo "$(tput bold)$(tput setaf 2)Size$(tput sgr0):  $APPIMAGE_SIZE"
            echo "$(tput bold)$(tput setaf 2)Install dir$(tput sgr0): $BIN_PATH"
            echo
            rm -f "$CONFDIR"/appimginstalled/."$INSTIMG".yml
        else
            APPIMG_NOT_FOUND="TRUE"
        fi
    fi
}

appimglistinstalledfunc () {
    for AppImage in $(dir -C -w 1 "$CONFDIR"/appimginstalled); do
        echo "$(tput bold)$(tput setaf 2)$AppImage installed information$(tput sgr0):"
        . "$CONFDIR"/appimginstalled/"$AppImage"
        echo "$(tput bold)$(tput setaf 2)Info$(tput sgr0):  $APPIMAGE_DESCRIPTION"
        echo "$(tput bold)$(tput setaf 2)Version$(tput sgr0):  $APPIMAGE_VERSION"
        if [ ! -z "$APPIMAGE_GITHUB_TAG" ]; then
            echo "$(tput bold)$(tput setaf 2)Tag$(tput sgr0):  $APPIMAGE_GITHUB_TAG"
            APPIMAGE_GITHUB_TAG=""
        fi
        echo "$(tput bold)$(tput setaf 2)Total DLs$(tput sgr0):  $APPIMAGE_DOWNLOADS"
        echo "$(tput bold)$(tput setaf 2)URL$(tput sgr0):  $WEBSITE"
        echo "$(tput bold)$(tput setaf 2)Size$(tput sgr0):  $APPIMAGE_SIZE"
        echo "$(tput bold)$(tput setaf 2)Install dir$(tput sgr0): $BIN_PATH"
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
        case $NEW_APPIMAGE_VERSION in
            *Cannot*)
                APPIMG_NEW_UPGRADE="FALSE"
                APPIMAGE_ERROR="FALSE"
                ;;
            *)
                APPIMG_NEW_UPGRADE="TRUE"
                APPIMAGE_ERROR="FALSE"
                ;;
        esac
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
    for AppImage in $(dir -C -w 1 "$CONFDIR"/appimginstalled); do
        INSTIMG="$AppImage"
        echo "Checking $(tput setaf 2)$AppImage$(tput sgr0) version..."
        appimgcheckfunc "$AppImage"
        appimginfofunc # Download web pages containing app info and set variables from them
        appimgvercheckfunc
        if [ "$APPIMG_NEW_UPGRADE" = "TRUE" ]; then # Mark AppImage for upgrade if appimgvercheckfunc outputs APPIMG_NEW_UPGRADE="TRUE"
            echo "$(tput setaf 2)$(tput bold)New upgrade available for $AppImage -- $NEW_APPIMAGE_VERSION !$(tput sgr0)"
            appimgsaveinfofunc "appimgupgrades/$AppImage"
        fi
    done
}

appimgupgradecheckfunc () {
    if [ ! -f "$CONFDIR"/appimginstalled/"$INSTIMG" ]; then
        echo "$(tput setaf 1)$INSTIMG is not installed...$(tput sgr0)"
    else
        echo "Downloading AppImages.yml from spm github repo..." # Download existing list of AppImages from spm github repo
        rm -f "$CONFDIR"/AppImages.yml
        rm -f "$CONFDIR"/AppImages-*
        wget --no-verbose "https://raw.githubusercontent.com/simoniz0r/spm-repo/master/AppImages.yml" -O "$CONFDIR"/AppImages.yml || { echo "$(tput setaf 1)wget failed; exiting...$(tput sgr0)"; rm -rf "$CONFDIR"/cache/*; exit 1; }
        echo "AppImages.yml updated!"
        echo "Checking $(tput setaf 2)$INSTIMG$(tput sgr0) version..."
        appimgcheckfunc "$INSTIMG" # Check whether AppImage is in lists and which list it is in
        appimginfofunc # Download web pages containing app info and set variables from them
        appimgvercheckfunc
        if [ "$APPIMG_NEW_UPGRADE" = "TRUE" ]; then # Mark AppImage for upgrade if appimgvercheckfunc outputs APPIMG_NEW_UPGRADE="TRUE"
            echo "$(tput setaf 2)$(tput bold)New upgrade available for $INSTIMG -- $NEW_APPIMAGE_VERSION !$(tput sgr0)"
            appimgsaveinfofunc "appimgupgrades/$INSTIMG"
            # echo "$INSTIMG" >> "$CONFDIR"/upgrade-list.lst
        else
            echo "No new upgrade for $(tput setaf 2)$INSTIMG$(tput sgr0)"
        fi
    fi
}

appimgupdatelistfunc () { # Download AppImages.yml from github, and check versions
    if [ -z "$1" ]; then # If no AppImage specified by user, check all installed AppImage versions
        if [ "$(dir -C -w 1 "$CONFDIR"/appimginstalled)" = "0" ]; then
            sleep 0
        else
            echo "Checking for changes from spm-repo..."
            if [ "$SPM_REPO_SHA" = "$NEW_SPM_REPO_SHA" ]; then
                echo "No new changes from spm-repo; skipping package list updates..."
            else
                SPM_REPO_SHA="$NEW_SPM_REPO_SHA"
                spmsaveconffunc
                echo "Downloading AppImages.yml from spm github repo..." # Download existing list of AppImages from spm github repo
                rm -f "$CONFDIR"/AppImages.yml
                rm -f "$CONFDIR"/AppImages-*
                wget --no-verbose "https://raw.githubusercontent.com/simoniz0r/spm-repo/master/AppImages.yml" -O "$CONFDIR"/AppImages.yml || { echo "$(tput setaf 1)wget failed; exiting...$(tput sgr0)"; rm -rf "$CONFDIR"/cache/*; exit 1; }
                echo "AppImages.yml updated!"
                echo "Downloading new information from spm-repo..."
                for appimg in $(dir -C -w 1 "$CONFDIR"/appimginstalled); do
                    SPM_APPIMG_REPO_BRANCH="$("$RUNNING_DIR"/yaml r "$CONFDIR"/AppImages.yml $appimg)"
                    echo "https://github.com/simoniz0r/spm-repo/raw/$SPM_APPIMG_REPO_BRANCH/$appimg.yml" >> "$CONFDIR"/cache/appimg-yml-wget.list
                done
                cd "$CONFDIR"/cache
                wget --no-verbose -i "$CONFDIR"/cache/appimg-yml-wget.list || { echo "$(tput setaf 1)wget failed!$(tput sgr0)"; rm -rf "$CONFDIR"/cache/*; exit 1; }
                for ymlfile in $(dir -C -w 1 "$CONFDIR"/cache/*.yml); do
                    ymlfile="${ymlfile##*/}"
                    mv "$CONFDIR"/cache/"$ymlfile" "$CONFDIR"/appimginstalled/."$ymlfile"
                done
            fi
            appimgupgradecheckallfunc
        fi
    else # If user inputs AppImage, check that AppImage version
        INSTIMG="$1"
        appimgupgradecheckfunc
    fi
}

appimgupdateforcefunc () {
    if [ -f "$CONFDIR"/appimginstalled/"$INSTIMG" ]; then # Show AppImage info if installed, exit if not
        . "$CONFDIR"/appimginstalled/"$INSTIMG"
        echo "$(tput bold)$(tput setaf 2)Info$(tput sgr0):  $APPIMAGE_DESCRIPTION"
        echo "$(tput bold)$(tput setaf 2)Version$(tput sgr0):  $APPIMAGE_VERSION"
        if [ ! -z "$APPIMAGE_GITHUB_TAG" ]; then
            echo "$(tput bold)$(tput setaf 2)Tag$(tput sgr0):  $APPIMAGE_GITHUB_TAG"
        fi
        echo "$(tput bold)$(tput setaf 2)Total DLs$(tput sgr0):  $APPIMAGE_DOWNLOADS"
        echo "$(tput bold)$(tput setaf 2)URL$(tput sgr0):  $WEBSITE"
        echo "$(tput bold)$(tput setaf 2)Size$(tput sgr0):  $APPIMAGE_SIZE"
        echo "$(tput bold)$(tput setaf 2)Install dir$(tput sgr0): $BIN_PATH"
        echo
    else
        echo "$(tput setaf 1)AppImage not found!$(tput sgr0)"
        rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
        exit 1
    fi
    echo "Marking $(tput setaf 2)$INSTIMG$(tput sgr0) for upgrade by force..."
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
        wget --read-timeout=30 "$DIRECT_APPIMAGE_URL" -O "$CONFDIR"/cache/"$APPIMAGE_NAME" || { echo "$(tput setaf 1)wget $DIRECT_APPIMAGE_URL failed; exiting...$(tput sgr0)"; rm -rf "$CONFDIR"/cache/*; exit 1; }
        if [ -z "$APPIMAGE_NAME" ]; then
            APPIMAGE_NAME="$(dir -C -w 1 "$CONFDIR"/cache/ | grep -iw '.*AppImage')"
        fi
        if [ -z "$APPIMAGE_NAME" ]; then
            APPIMAGE_NAME="$(dir -C -w 1 "$CONFDIR"/cache/ | grep -iw '.*App')"
        fi
        NEW_APPIMAGE_VERSION="$APPIMAGE_NAME"
        mv "$CONFDIR"/cache/"$APPIMAGE_NAME" "$CONFDIR"/cache/"$INSTIMG"
    elif [ "$GITHUB_IMG" = "TRUE" ]; then # If AppImage is from github, use method below to download it
        wget --read-timeout=30 "$GITHUB_APPIMAGE_URL" -O "$CONFDIR"/cache/"$INSTIMG" || { echo "$(tput setaf 1)wget $GITHUB_APPIMAGE_URL failed; exiting...$(tput sgr0)"; rm -rf "$CONFDIR"/cache/*; exit 1; }
    fi
}

appimginstallfunc () { # chmod and mv AppImages to /usr/local/bin and create file containing install info in "$CONFDIR"/appimginstalled
    chmod a+x "$CONFDIR"/cache/"$INSTIMG" # Make AppImage executable
    echo "Moving $(tput setaf 2)$INSTIMG$(tput sgr0) to /usr/local/bin/$INSTIMG ..."
    sudo mv "$CONFDIR"/cache/"$INSTIMG" /usr/local/bin/"$INSTIMG" || { echo "Failed!"; rm -rf "$CONFDIR"/cache/*; exit 1; } # Move AppImage to /usr/local/bin
    appimgsaveinfofunc "appimginstalled/$INSTIMG"
    echo "$(tput setaf 2)$APPIMAGE_NAME$(tput sgr0) has been installed to /usr/local/bin/$INSTIMG !"
}

appimginstallstartfunc () {
    if [ -f "$CONFDIR"/tarinstalled/"$INSTIMG" ] || [ -f "$CONFDIR"/appimginstalled/"$INSTIMG" ]; then # Exit if already installed by spm
        echo "$(tput setaf 1)$INSTIMG is already installed."
        echo "Use 'spm update' to check for a new version of $INSTIMG.$(tput sgr0)"
        rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
        exit 1
    fi
    if type >/dev/null 2>&1 "$INSTIMG" && [ "$INSTIMG" != "spm" ]; then # If a command by the same name as AppImage already exists on user's system, exit
        echo "$(tput setaf 1)$INSTIMG is already installed and not managed by spm; exiting...$(tput sgr0)"
        rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
        exit 1
    fi
    if [ -f "/usr/local/bin/$INSTIMG" ]; then # If for some reason type does't pick up same file existing as AppImage name in /usr/local/bin, exit
        echo "$(tput setaf 1)/usr/local/bin/$INSTIMG exists; exiting...$(tput sgr0)"
        rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
        exit 1
    fi
    appimgcheckfunc "$INSTIMG" # Check whether AppImage is in lists and which list it is in
    if [ "$DIRECT_IMG" = "FALSE" ] && [ "$GITHUB_IMG" = "FALSE" ];then # If AppImage not in either list, exit
        echo "$(tput setaf 1)$INSTIMG is not in AppImages.yml; try running 'spm update'.$(tput sgr0)"
        rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
        exit 1
    fi
    appimginfofunc # Download web pages containing app info and set variables from them
    appimgvercheckfunc # Use vercheckfunc to get AppImage name for output before install
    if [ "$APPIMAGE_ERROR" = "TRUE" ]; then # If error getting AppImage, exit
        rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
        exit 1
    fi
    echo "AppImage: $APPIMAGE_NAME"
    echo "AppImage for $(tput setaf 2)$INSTIMG$(tput sgr0) will be installed." # Ask user if sure they want to install AppImage
    read -p "Continue? Y/N " INSTANSWER
    case $INSTANSWER in
        N*|n*) # If answer is no, exit
            echo "$(tput setaf 1)$INSTIMG was not installed.$(tput sgr0)"
            rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
            exit 0
            ;;
    esac
}

appimgupgradefunc () { # rm old AppImage, chmod, and mv new AppImage to /usr/local/bin
    echo "Removing previous $(tput setaf 2)$INSTIMG$(tput sgr0) version..."
    sudo rm /usr/local/bin/"$INSTIMG" # Remove old AppImage before upgrading
    chmod a+x "$CONFDIR"/cache/"$INSTIMG" # Make new AppImage executable
    echo "Moving $(tput setaf 2)$INSTIMG$(tput sgr0) to /usr/local/bin/$INSTIMG ..." || { echo "$(tput setaf 1)Failed!$(tput sgr0)"; rm -rf "$CONFDIR"/cache/*; exit 1; }
    sudo mv "$CONFDIR"/cache/"$INSTIMG" /usr/local/bin/"$INSTIMG" # Move new AppImage to /usr/local/bin
    appimgsaveinfofunc "appimginstalled/$INSTIMG"
    echo "$(tput setaf 2)$INSTIMG$(tput sgr0) has been upgraded to version $APPIMAGE_VERSION !"
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
                    echo "Downloading $(tput setaf 2)$INSTIMG$(tput sgr0)..."
                    appimgcheckfunc "$INSTIMG" # Check whether AppImage is in lists and which list it is in
                    appimginfofunc
                    appimgdlfunc "$INSTIMG" # Download AppImage from Direct or Github
                    appimgupgradefunc # Run upgrade function for AppImage
                    rm "$CONFDIR"/appimgupgrades/"$INSTIMG"
                    echo
                done
                ;;
            N*|n*) # Exit if no
                echo "$(tput setaf 1)No AppImages were upgraded; exiting...$(tput sgr0)"
                rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
                exit 0
                ;;
        esac
    fi
}

appimgupgradestartfunc () {
    echo "$(tput setaf 2)$INSTIMG$(tput sgr0) will be upgraded to the latest version." # Ask user if sure about upgrade
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
            echo "$(tput setaf 1)$INSTIMG was not upgraded.$(tput sgr0)"
            rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
            exit 0
            ;;
    esac
}

appimgremovefunc () { # rm AppImage in /usr/local/bin and remove install info file
    . "$CONFDIR"/appimginstalled/"$REMIMG"
    echo "Removing $(tput setaf 2)$REMIMG$(tput sgr0)..." # Ask user if sure they want to remove AppImage
    read -p "Continue? Y/N " IMGREMANSWER
    case $IMGREMANSWER in
        N*|n*) # If user answers no, exit
            echo "$(tput setaf 1)$REMIMG was not removed.$(tput sgr0)"
            rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
            exit 0
            ;;
    esac
    if [ -f "$CONFDIR"/appimgupgrades/"$REMIMG" ]; then # If AppImage is marked for upgrade, remove it from list to prevent future problems
        rm "$CONFDIR"/appimgupgrades/"$REMIMG"
    fi
    echo "Removing /usr/local/bin/$REMIMG ..."
    sudo rm /usr/local/bin/"$REMIMG" || { echo "Failed!"; rm -rf "$CONFDIR"/cache/*; exit 1; } # Remove AppImage from /usr/local/bin
    rm "$CONFDIR"/appimginstalled/"$REMIMG" # Remove installed info file for AppImage
    rm "$CONFDIR"/appimginstalled/."$REMIMG".yml # Remove installed info file for AppImage
    echo "$(tput setaf 2)$REMIMG$(tput sgr0) has been removed!"
}
