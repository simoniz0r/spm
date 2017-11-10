#!/bin/bash
# Title: spm
# Description: Downloads and installs AppImages and precompiled tar archives.  Can also upgrade and remove installed packages.
# Dependencies: GNU coreutils, tar, wget
# Author: simonizor
# Website: http://www.simonizor.gq
# License: GPL v2.0 only

X="0.6.1"
# Set spm version

# Set variables
APPIMG_FORCE_UPGRADE="FALSE"
APPIMAGE_SIZE="N/A"
APPIMAGE_DOWNLOADS="N/A"
APPIMG_CLR="${CLR_GREEN}"

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
        wget --quiet "$APPIMG_GITHUB_API_URL" -O "$CONFDIR"/cache/"$INSTIMG"full || { ssft_display_error "${CLR_RED}Error" "wget $APPIMG_GITHUB_API_URL failed!${CLR_CLEAR}"; rm -rf "$CONFDIR"/cache/*; exit 1; }
    else
        wget --quiet --auth-no-challenge --header="Authorization: token "$GITHUB_TOKEN"" "$APPIMG_GITHUB_API_URL" -O "$CONFDIR"/cache/"$INSTIMG"full || { ssft_display_error "${CLR_RED}Error" "wget failed!${CLR_CLEAR}"; rm -rf "$CONFDIR"/cache/*; exit 1; }
    fi
    JQARG=".[].assets[] | select(.name | contains(\".AppImage\"), contains(\".appimage\")) | select(.name | contains(\"$INSTIMG_NAME\")) | select(.name | contains(\"ia32\") | not) | select(.name | contains(\"i386\") | not) | select(.name | contains(\"i686\") | not) | { name: .name, updated: .updated_at, url: .browser_download_url, size: .size, numdls: .download_count}"
    cat "$CONFDIR"/cache/"$INSTIMG"full | "$RUNNING_DIR"/jq --raw-output "$JQARG" | sed 's%{%data:%g' | tr -d '",}' > "$CONFDIR"/cache/"$INSTIMG"release
    if [ "$(cat "$CONFDIR"/cache/"$INSTIMG"release | wc -l)" = "0" ]; then
        rm "$CONFDIR"/cache/"$INSTIMG"release
        JQARG=".[].assets[] | select(.name | contains(\".AppImage\"), contains(\".appimage\")) | select(.name | contains(\"ia32\") | not) | select(.name | contains(\"i386\") | not) | select(.name | contains(\"i686\") | not) | { name: .name, updated: .updated_at, url: .browser_download_url, size: .size, numdls: .download_count}"
        cat "$CONFDIR"/cache/"$INSTIMG"full | "$RUNNING_DIR"/jq --raw-output "$JQARG" | sed 's%{%data:%g' | tr -d '",}' > "$CONFDIR"/cache/"$INSTIMG"release
    fi
    if [ "$(cat "$CONFDIR"/cache/"$INSTIMG"release | wc -l)" = "0" ]; then
        rm "$CONFDIR"/cache/"$INSTIMG"release
        JQARG=".[].assets[] | select(.name | contains(\"$INSTIMG_NAME\")) | select(.name | contains(\"ia32\") | not) | select(.name | contains(\"i386\") | not) | select(.name | contains(\"i686\") | not) | { name: .name, updated: .updated_at, url: .browser_download_url, size: .size, numdls: .download_count}"
        cat "$CONFDIR"/cache/"$INSTIMG"full | "$RUNNING_DIR"/jq --raw-output "$JQARG" | sed 's%{%data:%g' | tr -d '",}' > "$CONFDIR"/cache/"$INSTIMG"release
    fi
    if [ "$(cat "$CONFDIR"/cache/"$INSTIMG"release | wc -l)" = "0" ]; then
        rm "$CONFDIR"/cache/"$INSTIMG"release
        JQARG=".[].assets[] | select(.name | contains(\"ia32\") | not) | select(.name | contains(\"i386\") | not) | select(.name | contains(\"i686\") | not) | { name: .name, updated: .updated_at, url: .browser_download_url, size: .size, numdls: .download_count}"
        cat "$CONFDIR"/cache/"$INSTIMG"full | "$RUNNING_DIR"/jq --raw-output "$JQARG" | sed 's%{%data:%g' | tr -d '",}' > "$CONFDIR"/cache/"$INSTIMG"release
    fi
    APPIMAGE_NAME="$(cat "$CONFDIR"/cache/"$INSTIMG"release | "$RUNNING_DIR"/yaml r - data.name)"
    NEW_APPIMAGE_VERSION="$(cat "$CONFDIR"/cache/"$INSTIMG"release | "$RUNNING_DIR"/yaml r - data.updated)"
    GITHUB_APPIMAGE_URL="$(cat "$CONFDIR"/cache/"$INSTIMG"release | "$RUNNING_DIR"/yaml r - data.url)"
    APPIMAGE_SIZE="$(cat "$CONFDIR"/cache/"$INSTIMG"release | "$RUNNING_DIR"/yaml r - data.size)"
    APPIMAGE_SIZE="$(awk "BEGIN {print ("$APPIMAGE_SIZE"/1024)/1024}" | cut -c-5) MBs"
    APPIMAGE_DOWNLOADS="$(cat "$CONFDIR"/cache/"$INSTIMG"release | "$RUNNING_DIR"/yaml r - data.numdls)"
    APPIMAGE_DESCRIPTION="$("$RUNNING_DIR"/yaml r "$CONFDIR"/appimginstalled/."$INSTIMG".yml description)"
    APPIMAGE_GITHUB_TAG="$(echo "$GITHUB_APPIMAGE_URL" | cut -f8 -d"/")"
}

appimgdirectinfofunc () {
    DIRECT_APPIMAGE_URL="$("$RUNNING_DIR"/yaml r "$CONFDIR"/appimginstalled/."$INSTIMG".yml url)"
    # wget -S --read-timeout=30 --spider "$DIRECT_APPIMAGE_URL" -o "$CONFDIR"/cache/"$INSTIMG".latest
    NEW_APPIMAGE_VERSION="$(wget -S --read-timeout=30 --spider "$DIRECT_APPIMAGE_URL" -O - 2>&1 | grep -m 1 'Location:')"
    NEW_APPIMAGE_VERSION="${NEW_APPIMAGE_VERSION##*/}"
    APPIMAGE_DESCRIPTION="$DIRECT_APPIMAGE_URL"
    if [ -z "$NEW_APPIMAGE_VERSION" ]; then
        NEW_APPIMAGE_VERSION="${DIRECT_APPIMAGE_URL##*/}"
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
        APPIMG_CLR="${CLR_GREEN}"
        appimgdirectinfofunc
    elif [ "$GITHUB_IMG" = "TRUE" ]; then # If AppImage is from github, use method below to get new AppImage version
        APPIMG_CLR="${CLR_LGREEN}"
        appimggithubinfofunc
    fi
}

appimglistfunc () {
    if [ -f "$CONFDIR"/appimginstalled/"$INSTIMG" ]; then # If installed, list installed info
        . "$CONFDIR"/appimginstalled/"$INSTIMG"
        if [ ! -z "$APPIMAGE_GITHUB_TAG" ]; then
            APPIMG_CLR="${CLR_LGREEN}"
            echo "${APPIMG_CLR}$INSTIMG installed information${CLR_CLEAR}:"
        else
            APPIMG_CLR="${CLR_GREEN}"
            echo "${APPIMG_CLR}$INSTIMG installed information${CLR_CLEAR}:"
        fi
        echo "${APPIMG_CLR}Info${CLR_CLEAR}:  $APPIMAGE_DESCRIPTION"
        echo "${APPIMG_CLR}Version${CLR_CLEAR}:  $APPIMAGE_VERSION"
        if [ ! -z "$APPIMAGE_GITHUB_TAG" ]; then
            echo "${APPIMG_CLR}Tag${CLR_CLEAR}:  $APPIMAGE_GITHUB_TAG"
            echo "${APPIMG_CLR}Size${CLR_CLEAR}:  $APPIMAGE_SIZE"
            echo "${APPIMG_CLR}Total DLs${CLR_CLEAR}:  $APPIMAGE_DOWNLOADS"
        fi
        echo "${APPIMG_CLR}URL${CLR_CLEAR}:  $WEBSITE"
        echo "${APPIMG_CLR}Install dir${CLR_CLEAR}: $BIN_PATH"
        echo
    else
        INSTIMG="$INSTIMG"
        appimgcheckfunc "$INSTIMG"
        appimginfofunc
        if [ "$GITHUB_IMG" = "TRUE" ] || [ "$DIRECT_IMG" = "TRUE" ]; then
            appimgsaveinfofunc "cache/$INSTIMG.conf"
            echo "${APPIMG_CLR}$INSTIMG AppImage information${CLR_CLEAR}:"
            . "$CONFDIR"/cache/"$INSTIMG".conf
            echo "${APPIMG_CLR}Info${CLR_CLEAR}:  $APPIMAGE_DESCRIPTION"
            echo "${APPIMG_CLR}Version${CLR_CLEAR}:  $APPIMAGE_VERSION"
            if [ ! -z "$APPIMAGE_GITHUB_TAG" ]; then
                echo "${APPIMG_CLR}Tag${CLR_CLEAR}:  $APPIMAGE_GITHUB_TAG"
                echo "${APPIMG_CLR}Size${CLR_CLEAR}:  $APPIMAGE_SIZE"
                echo "${APPIMG_CLR}Total DLs${CLR_CLEAR}:  $APPIMAGE_DOWNLOADS"
            fi
            echo "${APPIMG_CLR}URL${CLR_CLEAR}:  $WEBSITE"
            echo "${APPIMG_CLR}Install dir${CLR_CLEAR}: $BIN_PATH"
            echo
            rm -f "$CONFDIR"/appimginstalled/."$INSTIMG".yml
        else
            APPIMG_NOT_FOUND="TRUE"
        fi
    fi
}

appimglistinstalledfunc () {
    for AppImage in $(dir -C -w 1 "$CONFDIR"/appimginstalled); do
        . "$CONFDIR"/appimginstalled/"$AppImage"
        if [ ! -z "$APPIMAGE_GITHUB_TAG" ]; then
            APPIMG_CLR="${CLR_LGREEN}"
            echo "${APPIMG_CLR}$AppImage installed information${CLR_CLEAR}:"
            APPIMAGE_GITHUB_TAG=""
        else
            APPIMG_CLR="${CLR_GREEN}"
            echo "${APPIMG_CLR}$AppImage installed information${CLR_CLEAR}:"
        fi
        . "$CONFDIR"/appimginstalled/"$AppImage"
        echo "${APPIMG_CLR}Info${CLR_CLEAR}:  $APPIMAGE_DESCRIPTION"
        echo "${APPIMG_CLR}Version${CLR_CLEAR}:  $APPIMAGE_VERSION"
        if [ ! -z "$APPIMAGE_GITHUB_TAG" ]; then
            echo "${APPIMG_CLR}Tag${CLR_CLEAR}:  $APPIMAGE_GITHUB_TAG"
            echo "${APPIMG_CLR}Size${CLR_CLEAR}:  $APPIMAGE_SIZE"
            echo "${APPIMG_CLR}Total DLs${CLR_CLEAR}:  $APPIMAGE_DOWNLOADS"
            APPIMAGE_GITHUB_TAG=""
        fi
        echo "${APPIMG_CLR}URL${CLR_CLEAR}:  $WEBSITE"
        echo "${APPIMG_CLR}Install dir${CLR_CLEAR}: $BIN_PATH"
        echo
    done
}

appimgvercheckfunc () { # Check version
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
        ssft_display_error "${CLR_RED}Error" "Error checking $INSTIMG version!${CLR_CLEAR}" "If this error continues to happen for $INSTIMG, the maintainer may have not built a new AppImage for the latest release. Check $GITHUB_APP_URL to see if a new AppImage is available for $INSTIMG.${CLR_CLEAR}"
        APPIMG_NEW_UPGRADE="FALSE"
        APPIMAGE_ERROR="TRUE"
    fi
}

appimgupgradecheckallfunc () {
    touch "$CONFDIR"/cache/appimgupdate.lock
    for AppImage in $(dir -C -w 1 "$CONFDIR"/appimginstalled); do
        INSTIMG="$AppImage"
        appimgcheckfunc "$AppImage"
        appimginfofunc # Download web pages containing app info and set variables from them
        echo "Checking ${APPIMG_CLR}$AppImage${CLR_CLEAR} version..."
        appimgvercheckfunc
        if [ "$APPIMG_NEW_UPGRADE" = "TRUE" ]; then # Mark AppImage for upgrade if appimgvercheckfunc outputs APPIMG_NEW_UPGRADE="TRUE"
            echo "${APPIMG_CLR}$(tput bold)New upgrade available for $AppImage -- $NEW_APPIMAGE_VERSION !${CLR_CLEAR}"
            appimgsaveinfofunc "appimgupgrades/$AppImage"
        fi
    done
    rm -f "$CONFDIR"/cache/appimgupdate.lock
}

appimgupgradecheckfunc () {
    if [ ! -f "$CONFDIR"/appimginstalled/"$INSTIMG" ]; then
        ssft_display_error "${CLR_RED}Error" "$INSTIMG is not installed...${CLR_CLEAR}"
    else
        echo "Downloading AppImages.yml from spm github repo..." # Download existing list of AppImages from spm github repo
        rm -f "$CONFDIR"/AppImages.yml
        rm -f "$CONFDIR"/AppImages-*
        wget --no-verbose "https://raw.githubusercontent.com/simoniz0r/spm-repo/master/AppImages.yml" -O "$CONFDIR"/AppImages.yml || { ssft_display_error "${CLR_RED}Error" "wget failed; exiting...${CLR_CLEAR}"; rm -rf "$CONFDIR"/cache/*; exit 1; }
        echo "AppImages.yml updated!"
        appimgcheckfunc "$INSTIMG" # Check whether AppImage is in lists and which list it is in
        appimginfofunc # Download web pages containing app info and set variables from them
        echo "Checking ${APPIMG_CLR}$INSTIMG${CLR_CLEAR} version..."
        appimgvercheckfunc
        if [ "$APPIMG_NEW_UPGRADE" = "TRUE" ]; then # Mark AppImage for upgrade if appimgvercheckfunc outputs APPIMG_NEW_UPGRADE="TRUE"
            echo "${APPIMG_CLR}$(tput bold)New upgrade available for $INSTIMG -- $NEW_APPIMAGE_VERSION !${CLR_CLEAR}"
            appimgsaveinfofunc "appimgupgrades/$INSTIMG"
            # echo "$INSTIMG" >> "$CONFDIR"/upgrade-list.lst
        else
            echo "No new upgrade for ${APPIMG_CLR}$INSTIMG${CLR_CLEAR}"
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
                touch "$CONFDIR"/cache/appimgupdate.lock
                echo "Downloading AppImages.yml from spm github repo..." # Download existing list of AppImages from spm github repo
                rm -f "$CONFDIR"/AppImages.yml
                rm -f "$CONFDIR"/AppImages-*
                wget --no-verbose "https://raw.githubusercontent.com/simoniz0r/spm-repo/master/AppImages.yml" -O "$CONFDIR"/AppImages.yml || { ssft_display_error "${CLR_RED}Error" "wget failed; exiting...${CLR_CLEAR}"; rm -rf "$CONFDIR"/cache/*; exit 1; }
                echo "AppImages.yml updated!"
                echo "Downloading new information from spm-repo..."
                for appimg in $(dir -C -w 1 "$CONFDIR"/appimginstalled); do
                    SPM_APPIMG_REPO_BRANCH="$("$RUNNING_DIR"/yaml r "$CONFDIR"/AppImages.yml $appimg)"
                    echo "https://github.com/simoniz0r/spm-repo/raw/$SPM_APPIMG_REPO_BRANCH/$appimg.yml" >> "$CONFDIR"/cache/appimg-yml-wget.list
                done
                cd "$CONFDIR"/cache
                wget --no-verbose -i "$CONFDIR"/cache/appimg-yml-wget.list || { ssft_display_error "${CLR_RED}Error" "wget failed!${CLR_CLEAR}"; rm -rf "$CONFDIR"/cache/*; exit 1; }
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
        if [ ! -z "$APPIMAGE_GITHUB_TAG" ]; then
            APPIMG_CLR="${CLR_LGREEN}"
        else
            APPIMG_CLR="${CLR_GREEN}"
        fi
        echo "${APPIMG_CLR}Info${CLR_CLEAR}:  $APPIMAGE_DESCRIPTION"
        echo "${APPIMG_CLR}Version${CLR_CLEAR}:  $APPIMAGE_VERSION"
        if [ ! -z "$APPIMAGE_GITHUB_TAG" ]; then
            echo "${APPIMG_CLR}Tag${CLR_CLEAR}:  $APPIMAGE_GITHUB_TAG"
            echo "${APPIMG_CLR}Size${CLR_CLEAR}:  $APPIMAGE_SIZE"
            echo "${APPIMG_CLR}Total DLs${CLR_CLEAR}:  $APPIMAGE_DOWNLOADS"
        fi
        echo "${APPIMG_CLR}URL${CLR_CLEAR}:  $WEBSITE"
        echo "${APPIMG_CLR}Install dir${CLR_CLEAR}: $BIN_PATH"
        echo
    else
        ssft_display_error "${CLR_RED}Error" "AppImage not found!${CLR_CLEAR}"
        rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
        exit 1
    fi
    echo "Marking ${APPIMG_CLR}$INSTIMG${CLR_CLEAR} for upgrade by force..."
    . "$CONFDIR"/appimginstalled/"$INSTIMG"
    APPIMAGE_NAME="$APPIMAGE"
    NEW_APPIMAGE_VERSION="$APPIMAGE_VERSION"
    GITHUB_APP_URL="$WEBSITE"
    echo "${APPIMG_CLR}New upgrade available for $INSTIMG!${CLR_CLEAR}"
    appimgsaveinfofunc "appimgupgrades/$INSTIMG"
}

appimgdlfunc () { # wget latest url from direct website or github repo and wget it
    if [ "$DIRECT_IMG" = "TRUE" ]; then # If AppImage is DIRECT, use method below to download it
        cd "$CONFDIR"/cache
        wget --read-timeout=30 "$DIRECT_APPIMAGE_URL" -O "$CONFDIR"/cache/"$APPIMAGE_NAME" || { ssft_display_error "${CLR_RED}Error" "wget $DIRECT_APPIMAGE_URL failed; exiting...${CLR_CLEAR}"; rm -rf "$CONFDIR"/cache/*; exit 1; }
        if [ -z "$APPIMAGE_NAME" ]; then
            APPIMAGE_NAME="$(dir -C -w 1 "$CONFDIR"/cache/ | grep -iw '.*AppImage')"
        fi
        if [ -z "$APPIMAGE_NAME" ]; then
            APPIMAGE_NAME="$(dir -C -w 1 "$CONFDIR"/cache/ | grep -iw '.*App')"
        fi
        NEW_APPIMAGE_VERSION="$APPIMAGE_NAME"
        mv "$CONFDIR"/cache/"$APPIMAGE_NAME" "$CONFDIR"/cache/"$INSTIMG"
    elif [ "$GITHUB_IMG" = "TRUE" ]; then # If AppImage is from github, use method below to download it
        wget --read-timeout=30 "$GITHUB_APPIMAGE_URL" -O "$CONFDIR"/cache/"$INSTIMG" || { ssft_display_error "${CLR_RED}Error" "wget $GITHUB_APPIMAGE_URL failed; exiting...${CLR_CLEAR}"; rm -rf "$CONFDIR"/cache/*; exit 1; }
    fi
}

appimginstallfunc () { # chmod and mv AppImages to /usr/local/bin and create file containing install info in "$CONFDIR"/appimginstalled
    chmod a+x "$CONFDIR"/cache/"$INSTIMG" # Make AppImage executable
    echo "Moving ${APPIMG_CLR}$INSTIMG${CLR_CLEAR} to /usr/local/bin/$INSTIMG ..."
    sudo mv "$CONFDIR"/cache/"$INSTIMG" /usr/local/bin/"$INSTIMG" || { ssft_display_error "${CLR_RED}Error" "Failed!"; rm -rf "$CONFDIR"/cache/*; exit 1; } # Move AppImage to /usr/local/bin
    appimgsaveinfofunc "appimginstalled/$INSTIMG"
    echo "${APPIMG_CLR}$APPIMAGE_NAME${CLR_CLEAR} has been installed to /usr/local/bin/$INSTIMG !"
}

appimginstallstartfunc () {
    if [ -f "$CONFDIR"/tarinstalled/"$INSTIMG" ] || [ -f "$CONFDIR"/appimginstalled/"$INSTIMG" ]; then # Exit if already installed by spm
        ssft_display_error "${CLR_RED}Error" "$INSTIMG is already installed. Use 'spm update' to check for a new version of $INSTIMG.${CLR_CLEAR}"
        rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
        exit 1
    fi
    if type >/dev/null 2>&1 "$INSTIMG" && [ "$INSTIMG" != "spm" ]; then # If a command by the same name as AppImage already exists on user's system, exit
        ssft_display_error "${CLR_RED}Error" "$INSTIMG is already installed and not managed by spm; exiting...${CLR_CLEAR}"
        rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
        exit 1
    fi
    if [ -f "/usr/local/bin/$INSTIMG" ]; then # If for some reason type does't pick up same file existing as AppImage name in /usr/local/bin, exit
        ssft_display_error "${CLR_RED}Error" "/usr/local/bin/$INSTIMG exists; exiting...${CLR_CLEAR}"
        rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
        exit 1
    fi
    appimgcheckfunc "$INSTIMG" # Check whether AppImage is in lists and which list it is in
    if [ "$DIRECT_IMG" = "FALSE" ] && [ "$GITHUB_IMG" = "FALSE" ];then # If AppImage not in either list, exit
        ssft_display_error "${CLR_RED}Error" "$INSTIMG is not in AppImages.yml; try running 'spm update'.${CLR_CLEAR}"
        rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
        exit 1
    fi
    appimginfofunc # Download web pages containing app info and set variables from them
    appimgvercheckfunc # Use vercheckfunc to get AppImage name for output before install
    if [ "$APPIMAGE_ERROR" = "TRUE" ]; then # If error getting AppImage, exit
        rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
        exit 1
    fi
    ssft_select_single "${APPIMG_CLR}$INSTIMG${CLR_CLEAR} AppImage: $APPIMAGE_NAME" "AppImage for $INSTIMG will be installed." "Install $INSTIMG" "Exit"
    case $SSFT_RESULT in
        Exit|N*|n*) # If answer is no, exit
            ssft_display_error "${CLR_RED}Error" "$INSTIMG was not installed.${CLR_CLEAR}"
            rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
            exit 0
            ;;
    esac
}

appimgupgradefunc () { # rm old AppImage, chmod, and mv new AppImage to /usr/local/bin
    echo "Removing previous ${APPIMG_CLR}$INSTIMG${CLR_CLEAR} version..."
    sudo rm /usr/local/bin/"$INSTIMG" # Remove old AppImage before upgrading
    chmod a+x "$CONFDIR"/cache/"$INSTIMG" # Make new AppImage executable
    echo "Moving ${APPIMG_CLR}$INSTIMG${CLR_CLEAR} to /usr/local/bin/$INSTIMG ..." || { ssft_display_error "${CLR_RED}Error" "Failed!${CLR_CLEAR}"; rm -rf "$CONFDIR"/cache/*; exit 1; }
    sudo mv "$CONFDIR"/cache/"$INSTIMG" /usr/local/bin/"$INSTIMG" # Move new AppImage to /usr/local/bin
    appimgsaveinfofunc "appimginstalled/$INSTIMG"
    echo "${APPIMG_CLR}$INSTIMG${CLR_CLEAR} has been upgraded to version $APPIMAGE_VERSION !"
}

appimgupgradestartallfunc () {
    if [ "$APPIMGUPGRADES" = "FALSE" ]; then
        sleep 0
    else
        if [ "$(dir "$CONFDIR"/appimgupgrades | wc -l)" = "1" ]; then
            echo "${APPIMG_CLR}$(dir -C -w 1 "$CONFDIR"/appimgupgrades | wc -l) new AppImage upgrade available.${CLR_CLEAR}"
        elif [ "$(dir "$CONFDIR"/appimgupgrades | wc -l)" = "0" ]; then
            echo "No new AppImage upgrades."
        else
            echo "${APPIMG_CLR}$(dir -C -w 1 "$CONFDIR"/appimgupgrades | wc -l) new AppImage upgrades available.${CLR_CLEAR}"
        fi
        dir -C -w 1 "$CONFDIR"/appimgupgrades | pr -tTw 125 -3 # Ouput AppImages available for upgrades
        echo
        ssft_select_single "               " "Start upgrade?" "Start upgrade" "Exit"
        case $SSFT_RESULT in
            Start*|Y*|y*) # Do upgrade functions if yes
                for UPGRADE_IMG in $(dir -C -w 1 "$CONFDIR"/appimgupgrades); do
                    INSTIMG="$UPGRADE_IMG"
                    appimgcheckfunc "$INSTIMG" # Check whether AppImage is in lists and which list it is in
                    appimginfofunc
                    echo "Downloading ${APPIMG_CLR}$INSTIMG${CLR_CLEAR}..."
                    appimgdlfunc "$INSTIMG" # Download AppImage from Direct or Github
                    appimgupgradefunc # Run upgrade function for AppImage
                    rm "$CONFDIR"/appimgupgrades/"$INSTIMG"
                    echo
                done
                ;;
            Exit|N*|n*) # Exit if no
                ssft_display_error "${CLR_RED}Error" "No AppImages were upgraded; exiting...${CLR_CLEAR}"
                rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
                exit 0
                ;;
        esac
    fi
}

appimgupgradestartfunc () {
    ssft_select_single "${APPIMG_CLR}$INSTIMG${CLR_CLEAR} upgrade" "$INSTIMG will be upgraded to the latest version. Continue?" "Upgrade $INSTIMG" "Exit"
    case $SSFT_RESULT in
        Upgrade*|Y*|y*) # Do upgrade functions if yes
            appimgcheckfunc "$INSTIMG" # Check whether AppImage is in lists and which list it is in
            appimginfofunc
            appimgdlfunc "$INSTIMG" # Download AppImage from Direct or Github
            appimgupgradefunc # Run upgrade function for AppImage
            rm "$CONFDIR"/appimgupgrades/"$INSTIMG"
            rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
            exit 0
            ;;
        Exit|N*|n*) # Exit if no
            ssft_display_error "${CLR_RED}Error" "$INSTIMG was not upgraded.${CLR_CLEAR}"
            rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
            exit 0
            ;;
    esac
}

appimgremovefunc () { # rm AppImage in /usr/local/bin and remove install info file
    . "$CONFDIR"/appimginstalled/"$REMIMG"
    if [ ! -z "$APPIMAGE_GITHUB_TAG" ]; then
        APPIMG_CLR="${CLR_LGREEN}"
    else
        APPIMG_CLR="${CLR_GREEN}"
    fi
    ssft_select_single "Removing ${APPIMG_CLR}$REMIMG${CLR_CLEAR}..." "$REMIMG will be removed! Continue?" "Remove $REMIMG" "Exit"
    case $SSFT_RESULT in
        Exit|N*|n*) # If user answers no, exit
            ssft_display_error "${CLR_RED}Error" "$REMIMG was not removed.${CLR_CLEAR}"
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
    echo "${APPIMG_CLR}$REMIMG${CLR_CLEAR} has been removed!"
}
