#!/bin/bash
# Title: spm
# Description: Downloads and installs AppImages and precompiled tar archives.  Can also upgrade and remove installed packages.
# Dependencies: GNU coreutils, tar, wget
# Author: simonizor
# Website: http://www.simonizor.gq
# License: GPL v2.0 only

X="0.6.1"
# Set spm version

helpfunc () { # All unknown arguments come to this function; display help for spm
printf '%s\n' "spm $X
Usage: spm [option] [package]

spm is a simple commandline package manager that installs AppImages and
precompiled tar archives. Using the lists generated from spm's repo, spm
provides a variety of AppImages and precompiled tars for install. spm keeps
track of installed packages and their versions, so spm can also be used to
upgrade and remove packages installed by spm.

Arguments:
    list (-l) - list all packages known by spm or info about the specified package
    list-installed (-li) - list all installed packages and install info
    search (-s) - search package lists for packages matching input
    install (-i) - install an AppImage or precompiled tar archive
    remove (-r) - remove an installed AppImage or precompiled tar archive
    update (-upd) - update package lists and check for package upgrades
    update-force (-uf) - mark specified AppImage or tar archive for upgrade without checking version
    upgrade (-upg) - upgrade all installed packages that are marked for upgrade or just the specified package
    man (-m) - show spm man page

See https://github.com/simoniz0r/spm for more help or to report issues.

spm is not responsible for bugs within applications that have been
installed using spm.  Please report any bugs that are specific to
installed applications to their maintainers."
}

spmsaveconffunc () {
    echo "CONFDIR="\"$CONFDIR\""" > "$CONFDIR"/spm.conf
    echo "GITHUB_TOKEN="\"$GITHUB_TOKEN\""" >> "$CONFDIR"/spm.conf
    echo "SKIP_DEP_CHECKS="\"FALSE\""" >> "$CONFDIR"/spm.conf
    echo "SPM_REPO_SHA="\"$SPM_REPO_SHA\""" >> "$CONFDIR"/spm.conf
    echo "SPM_REPO_SHA2="\"$SPM_REPO_SHA2\""" >> "$CONFDIR"/spm.conf
    echo "CLR_BLUE="\"${CLR_BLUE}\""" >> "$CONFDIR"/spm.conf
    echo "CLR_LGREEN="\"${CLR_LGREEN}\""" >> "$CONFDIR"/spm.conf
    echo "CLR_GREEN="\"${CLR_GREEN}\""" >> "$CONFDIR"/spm.conf
    echo "CLR_LCYAN="\"${CLR_LCYAN}\""" >> "$CONFDIR"/spm.conf
    echo "CLR_CYAN="\"${CLR_CYAN}\""" >> "$CONFDIR"/spm.conf
    echo "CLR_RED="\"${CLR_RED}\""" >> "$CONFDIR"/spm.conf
}

spmdepchecksfunc () { # Run dep checks, exit if deps not present. If SKIP_DEP_CHECKS has not been set to something other than "FALSE" in spm.conf, skip this function
    if [ "$SKIP_DEP_CHECKS" = "FALSE" ]; then
        if ! type wget >/dev/null 2>&1; then
            MISSING_DEPS="TRUE"
            ssft_display_error "${CLR_RED}Error" "wget is not installed!${CLR_CLEAR}"
        fi
        if [ ! -f "$RUNNING_DIR"/yaml ]; then
            MISSING_DEPS="TRUE"
            ssft_display_error "${CLR_RED}Error" "$RUNNING_DIR/yaml not found! Please download the full release of spm:\nhttps://github.com/simoniz0r/spm/releases${CLR_CLEAR}"
        fi
        if [ ! -f "$RUNNING_DIR"/jq ]; then
            MISSING_DEPS="TRUE"
            ssft_display_error "${CLR_RED}Error" "$RUNNING_DIR/jq not found!  Please download the full release of spm:\nhttps://github.com/simoniz0r/spm/releases${CLR_CLEAR}"
        fi
        if [ "$MISSING_DEPS" = "TRUE" ]; then
            ssft_display_error "${CLR_RED}Error" "Missing one or more packages required to run; exiting...${CLR_CLEAR}"
            exit 1
        fi
    fi
}

appimgfunctioncheckfunc () { # Checks to make sure that appimgfunctions.sh exists and is up to date
    REALPATH="$(readlink -f $0)"
    RUNNING_DIR="$(dirname "$REALPATH")" # Find directory script is running from
    if [ -f $RUNNING_DIR/appimgfunctions.sh ]; then
        FUNCTIONS_VER="$(cat "$RUNNING_DIR"/appimgfunctions.sh | sed -n 9p | cut -f2 -d'"')"
        if [ "$X" != "$FUNCTIONS_VER" ]; then
            ssft_display_error "${CLR_RED}Error" "appimgfunctions.sh $FUNCTIONS_VER version does not match $X !" "appimgfunctions.sh is out of date! Please download the full release of spm from https://github.com/simoniz0r/spm/releases !${CLR_CLEAR}"
            exit 1
        fi
    else
        ssft_display_error "${CLR_RED}Error" "Missing required file $RUNNING_DIR/appimgfunctions.sh !" "appimgfunctions.sh is missing! Please download the full release of spm from https://github.com/simoniz0r/spm/releases !${CLR_CLEAR}"
        exit 1
    fi
}

tarfunctioncheckfunc () { # Checks to make sure that tarfunctions.sh exists and is up to date
    if [ -f $RUNNING_DIR/tarfunctions.sh ]; then
        FUNCTIONS_VER="$(cat "$RUNNING_DIR"/tarfunctions.sh | sed -n 9p | cut -f2 -d'"')"
        if [ "$X" != "$FUNCTIONS_VER" ]; then
            ssft_display_error "${CLR_RED}Error" "tarfunctions.sh $FUNCTIONS_VER version does not match $X !" "tarfunctions.sh is out of date! Please download the full release of spm from https://github.com/simoniz0r/spm/releases !${CLR_CLEAR}"
            exit 1
        fi
    else
        ssft_display_error "${CLR_RED}Error" "Missing required file $RUNNING_DIR/tarfunctions.sh !" "tarfunctions.sh is missing! Please download the full release of spm from https://github.com/simoniz0r/spm/releases !${CLR_CLEAR}"
        exit 1
    fi
}

spmlockfunc () { # Create "$CONFDIR"/cache/spm.lock file and prevent multiple instances by checking if it exists before running
    if [ ! -f "$CONFDIR"/cache/spm.lock ]; then
        touch "$CONFDIR"/cache/spm.lock
    else
        ssft_select_single "spm lock file error" "spm.lock file is still present.  Did spm exit correctly?  Are you sure spm isn't running? Remove spm.lock file and run spm?" "Remove lock file and run spm" "Exit"
        case $SSFT_RESULT in
            Exit|n*|N*)
                ssft_display_error "${CLR_RED}Error" "spm.lock file was not removed; make sure spm is finished before running spm again.${CLR_CLEAR}"
                exit 1
                ;;
        esac
        echo "Removing cache dir and starting spm..."
        rm -rf "$CONFDIR"/cache/* # Remove any files in cache and lock file
    fi
}

spmvercheckfunc () { # Check spm version when running update argument and notify of new version if available
    VERTEST="$(wget -q "https://raw.githubusercontent.com/simoniz0r/spm/master/spm" -O - | sed -n '9p' | tr -d 'X="')" # Use wget sed and tr to check current spm version from github
    if [[ "$VERTEST" != "$X" ]]; then # If current version not equal to installed version, notify of new version
        echo "${CLR_GREEN}A new version of spm is available!"
        echo "Current version: $VERTEST -- Installed version: $X"
        if type >/dev/null 2>&1 spm; then # If spm is installed, suggest upgrading spm through spm
            echo "Use 'spm' to upgrade to the latest version!${CLR_CLEAR}"
            echo
        else # If not, output link to releases page
            echo "Download the latest version at https://github.com/simoniz0r/appimgman/releases/latest${CLR_CLEAR}"
            echo
        fi
    fi
}

installstartfunc () {
    if [ -f "$CONFDIR"/tarinstalled/"$TESTPKG" ] || [ -f "$CONFDIR"/appimginstalled/"$TESTPKG" ]; then # Exit if already installed by spm
        ssft_display_error "${CLR_RED}Error" "$TESTPKG is already installed. Use 'spm update' to check for a new version of $TESTPKG.${CLR_CLEAR}"
        rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
        exit 1
    fi
    if type >/dev/null 2>&1 "$TESTPKG" && [ "$TESTPKG" != "spm" ]; then # If a command by the same name as AppImage already exists on user's system, exit
        ssft_display_error "${CLR_RED}Error" "$TESTPKG is already installed and not managed by spm; exiting...${CLR_CLEAR}"
        rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
        exit 1
    fi
    if [ -f "/usr/local/bin/$TESTPKG" ]; then # If for some reason type does't pick up same file existing as AppImage name in /usr/local/bin, exit
        ssft_display_error "${CLR_RED}Error" "/usr/local/bin/$TESTPKG exists; exiting...${CLR_CLEAR}"
        rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
        exit 1
    fi
    case $("$RUNNING_DIR"/yaml r "$CONFDIR"/AppImages.yml $TESTPKG) in
        *null*)
            KNOWN_IMG="FALSE"
            ;;
        *)
            KNOWN_IMG="TRUE"
            ;;
    esac
    case $("$RUNNING_DIR"/yaml r "$CONFDIR"/tar-pkgs.yml $TESTPKG) in
        *null*)
            KNOWN_TAR="FALSE"
            ;;
        *)
            KNOWN_TAR="TRUE"
            ;;
    esac
    if [ "$KNOWN_IMG" = "TRUE" ] && [ "$KNOWN_TAR" = "TRUE" ]; then
        ssft_select_single "Install $TESTPKG" "Both an AppImage and tar package are available for $TESTPKG; which would you like to install?" "AppImage" "tar package"
        case $SSFT_RESULT in
            AppImage|1*)
                INSTIMG="$TESTPKG"
                appimginstallstartfunc # Check if specified AppImage is in list, get info for it
                appimgdlfunc "$INSTIMG" # Download AppImage using info from above
                appimginstallfunc # Move downloaded AppImage from $CONFDIR/cache to /usr/local/bin and save config file for spm to keep track of it
                ;;
            tar*|2*)
                TARPKG="$TESTPKG"
                tarinstallstartfunc # Check if specified tar package is in list, get info for it
                tardlfunc "$TARPKG" # Download tar package using info from above
                tarcheckfunc # Check to make sure file downloaded is a tar and run relevant tar arguments for file type
                tarinstallfunc # Move extracted tar from $CONFDIR/cache to /opt/PackageName, create symlinks for .desktop and bin file, and save config file for spm to keep track of it
                ;;
            *)
                ssft_display_error "${CLR_RED}Error" "$SSFT_RESULT 0 was chosen; exiting...${CLR_CLEAR}"
                rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
                exit 1
                ;;
        esac
    elif [ "$KNOWN_IMG" = "TRUE" ]; then
        INSTIMG="$TESTPKG"
        appimginstallstartfunc # Check if specified AppImage is in list, get info for it
        appimgdlfunc "$INSTIMG" # Download AppImage using info from above
        appimginstallfunc # Move downloaded AppImage from $CONFDIR/cache to /usr/local/bin and save config file for spm to keep track of it
    elif [ "$KNOWN_TAR" = "TRUE" ]; then
        TARPKG="$TESTPKG"
        tarinstallstartfunc # Check if specified tar package is in list, get info for it
        tardlfunc "$TARPKG" # Download tar package using info from above
        tarcheckfunc # Check to make sure file downloaded is a tar and run relevant tar arguments for file type
        tarinstallfunc # Move extracted tar from $CONFDIR/cache to /opt/PackageName, create symlinks for .desktop and bin file, and save config file for spm to keep track of it
    else
        ssft_display_error "${CLR_RED}Error" "$TESTPKG not found in package lists; try running the 'update' argument.${CLR_CLEAR}"
    fi
}

removestartfunc () {
    if [ -f "$CONFDIR"/appimginstalled/"$TESTREM" ]; then # Output info about AppImage before removing, exit if not installed
        REMIMG="$TESTREM"
        echo "${CLR_GREEN}Current installed $REMIMG information${CLR_CLEAR}:"
        . "$CONFDIR"/appimginstalled/"$REMIMG"
        echo "${CLR_GREEN}Info${CLR_CLEAR}:  $APPIMAGE_DESCRIPTION"
        if [ -z "$APPIMAGE_NAME" ]; then
            echo "${CLR_GREEN}Name${CLR_CLEAR}:  $APPIMAGE"
        else
            echo "${CLR_GREEN}Name${CLR_CLEAR}:  $APPIMAGE_NAME"
        fi
        echo "${CLR_GREEN}Version${CLR_CLEAR}:  $APPIMAGE_VERSION"
        echo "${CLR_GREEN}URL${CLR_CLEAR}:  $WEBSITE"
        echo "${CLR_GREEN}Install dir${CLR_CLEAR}: $BIN_PATH"
        echo
        appimgremovefunc # Remove AppImage from /usr/local/bin and remove conf file in $CONFDIR/appimginstalled/PackageName
    elif [ -f "$CONFDIR"/tarinstalled/"$TESTREM" ]; then # Output info about tar package before removing, exit if not installed
        REMPKG="$TESTREM"
        echo "${CLR_CYAN}Current installed $REMPKG information${CLR_CLEAR}:"
        . "$CONFDIR"/tarinstalled/"$REMPKG"
        echo "${CLR_CYAN}Info${CLR_CLEAR}:  $TAR_DESCRIPTION"
        echo "${CLR_CYAN}Deps${CLR_CLEAR}:  $DEPENDENCIES"
        if [ -z "$TAR_GITHUB_COMMIT" ]; then
            echo "${CLR_CYAN}Version${CLR_CLEAR}:  $TARFILE"
        else
            echo "${CLR_CYAN}Version${CLR_CLEAR}:  $TAR_GITHUB_COMMIT"
        fi
        echo "${CLR_CYAN}Source${CLR_CLEAR}:  $TAR_DOWNLOAD_SOURCE"
        echo "${CLR_CYAN}URL${CLR_CLEAR}:  $TARURI"
        echo "${CLR_CYAN}Install dir${CLR_CLEAR}:  $INSTDIR"
        echo "${CLR_CYAN}Bin path${CLR_CLEAR}:  $BIN_PATH"
        echo
        TARPKG="$REMPKG"
        tarappcheckfunc # Load info about tar package using this function so tarremovefunc knows where it is
        tarremovefunc # Use info from above to remove /opt/PackageName and symlinks for .desktop and bin file
    else
        ssft_display_error "${CLR_RED}Error" "Package not found!${CLR_CLEAR}"
        rm -rf "$CONFDIR"/cache/*
        exit 1
    fi
}

updatestartfunc () { # Run relevant update argument based on user input
    if [ ! -z "$1" ]; then
        if [ -f "$CONFDIR"/appimginstalled/"$1" ]; then
            INSTIMG="$1"
            appimgupdatelistfunc "$INSTIMG" # Check specified AppImage for upgrade
        elif [ -f "$CONFDIR"/tarinstalled/"$1" ]; then
            TARPKG="$1"
            tarupdatelistfunc "$TARPKG" # Check specified tar package for upgrade
        else
            ssft_display_error "${CLR_RED}Error" "Package not found!${CLR_CLEAR}"
            rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
            exit 1
        fi
    else
        NEW_SPM_REPO_SHA="$(wget --quiet "https://api.github.com/repos/simoniz0r/spm-repo/git/trees/master" -O - | "$RUNNING_DIR"/yaml r - sha)"
        UPD_START_TIME="$(date +%s)"
        appimgupdatelistfunc & # Check all installed AppImages for upgrades
        tarupdatelistfunc # Check all installed tar packages for upgrades
        while [ -f "$CONFDIR/cache/appimgupdate.lock" ]; do
            sleep 0.5
        done
        echo "Checked $(($(dir -C -w 1 "$CONFDIR"/tarinstalled | wc -l)+$(dir -C -w 1 "$CONFDIR"/appimginstalled | wc -l))) packages in $(($(date +%s)-$UPD_START_TIME)) seconds."
        if [ "$(dir "$CONFDIR"/tarupgrades | wc -w)" = "0" ] && [ "$(dir "$CONFDIR"/appimgupgrades | wc -w)" = "0" ]; then
            echo "No new AppImage or tar package upgrades available."
        else
            echo "${CLR_GREEN}$(dir "$CONFDIR"/appimgupgrades | wc -w) new AppImage and $(dir "$CONFDIR"/tarupgrades | wc -w) new tar package upgrade(s) available!${CLR_CLEAR}"
        fi
    fi
}

updateforcestartfunc () {
    if [ -f "$CONFDIR"/appimginstalled/"$TESTUF" ]; then
        INSTIMG="$TESTUF"
        appimgupdateforcefunc # Place a file containing AppImage info in $CONFDIR/appimgupgrades/PackageName for upgrade function to get info from without checking version
    elif [ -f "$CONFDIR"/tarinstalled/"$TESTUF" ]; then
        TARPKG="$TESTUF"
        tarupdateforcefunc # Place a file containing tar package info in $CONFDIR/tarupgrades/PackageName for upgrade function to get info from without checking version
    else
        ssft_display_error "${CLR_RED}Error" "Package not found!${CLR_CLEAR}"
        rm -rf "$CONFDIR"/cache/*
        exit 1
    fi
}

upgradestartfunc () { # Run relevant upgrade argument based on packages marked for upgrades or user input
    if [ "$(dir "$CONFDIR"/appimgupgrades | wc -l)" = "0" ]; then # Check if AppImage upgrades are available. If not, set APPIMGUPGRADES to FALSE so AppImage upgrade function does not run
        APPIMGUPGRADES="FALSE"
    else
        APPIMGUPGRADES="TRUE"
    fi
    if [ "$(dir "$CONFDIR"/tarupgrades | wc -l)" = "0" ]; then # Check if tar package upgrades are available. If not, set TARUPGRADES to FALSE so tar upgrade function does not run
        TARUPGRADES="FALSE"
        if [ "$APPIMGUPGRADES" = "FALSE" ]; then
            echo "No new upgrades available; try running 'spm update'."
            rm -rf "$CONFDIR"/cache/*
            exit 0
        fi
    else
        TARUPGRADES="TRUE"
    fi
    if [ -z "$1" ]; then
        if [ "$APPIMGUPGRADES" = "TRUE" ]; then
            appimgupgradestartallfunc # Run a for loop that upgrades each installed AppImage for upgrade
        fi
        echo
        if [ "$TARUPGRADES" = "TRUE" ]; then
            tarupgradestartallfunc # Run a for loop that upgrades each tar package marked for upgrade
        fi
        rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
        exit 0
    elif [ "$TARUPGRADES" = "TRUE" ] || [ "$APPIMGUPGRADES" = "TRUE" ]; then # If user specifies package, upgrade that package
        if [ "$APPIMGUPGRADES" = "TRUE" ] && [ -f "$CONFDIR/appimginstalled/$1" ]; then
            INSTIMG="$1"
            appimgupgradestartfunc # Upgrade specified AppImage if available
        elif [ "$TARUPGRADES" = "TRUE" ] && [ -f "$CONFDIR/tarinstalled/$1" ]; then
            TARPKG="$1"
            tarupgradestartfunc # Upgrade specified tar package if available
        fi
    else
        echo "No new upgrade for $1; try running 'spm update'."
        rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
        exit 0
    fi
}

liststartfunc () { # Run relevant list function based on user input
    if [ -z "$INSTIMG" ]; then
        for file in $(sort "$CONFDIR"/*s.yml | cut -f1 -d':'); do
            SOURCE="$("$RUNNING_DIR"/yaml r "$CONFDIR"/AppImages.yml "$file")"
            if [ "$SOURCE" = "null" ] || [ "$last_file" = "$file" ]; then
                SOURCE="$("$RUNNING_DIR"/yaml r "$CONFDIR"/tar-pkgs.yml "$file")"
            fi
            last_file="$file"
            case $SOURCE in
                *AppImages-github)
                    if [ -f "$CONFDIR/appimginstalled/$file" ]; then
                        echo "${CLR_LGREEN}$file${CLR_CLEAR} (installed)"
                    else
                        echo "${CLR_LGREEN}$file${CLR_CLEAR}"
                    fi
                    ;;
                *AppImages-other)
                    if [ -f "$CONFDIR/appimginstalled/$file" ]; then
                        echo "${CLR_GREEN}$file${CLR_CLEAR} (installed)"
                    else
                        echo "${CLR_GREEN}$file${CLR_CLEAR}"
                    fi
                    ;;
                *tar-github)
                    if [ -f "$CONFDIR/tarinstalled/$file" ]; then
                        echo "${CLR_LCYAN}$file${CLR_CLEAR} (installed)"
                    else
                        echo "${CLR_LCYAN}$file${CLR_CLEAR}"
                    fi
                    ;;
                *tar-other)
                    if [ -f "$CONFDIR/tarinstalled/$file" ]; then
                        echo "${CLR_CYAN}$file${CLR_CLEAR} (installed)"
                    else
                        echo "${CLR_CYAN}$file${CLR_CLEAR}"
                    fi
                    ;;
            esac
        done | pr -tTaw $(tput cols) -$(($(tput cols)/45))
        echo
        echo "${CLR_BLUE}$(cat "$CONFDIR"/*s.yml | wc -l) packages available for install.${CLR_CLEAR}"
        echo "${CLR_LGREEN}Light green = AppImages from Github"
        echo "${CLR_GREEN}Dark green = AppImages from other sources"
        echo "${CLR_LCYAN}Light cyan = tar packages from Github"
        echo "${CLR_CYAN}Dark cyan = tar packages from other sources${CLR_CLEAR}"
    else
        appimglistfunc # List info for specified AppImage if available
        echo
        tarlistfunc # List info for specified tar package if available
        if [ "$APPIMG_NOT_FOUND" = "TRUE" ] && [ "$TARPKG_NOT_FOUND" = "TRUE" ]; then # If both tarfunctions.sh and appimgfunctions.sh output no packages found, tell user package not found
            ssft_display_error "${CLR_RED}Error" "$INSTIMG not found in package lists!${CLR_CLEAR}"
        fi
        rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
        exit 0
    fi
}

listinstalledfunc () {
    echo "${CLR_GREEN}AppImages${CLR_CLEAR}:"
    echo
    appimglistinstalledfunc || { ssft_display_error "${CLR_RED}Error" "List failed; exiting...${CLR_CLEAR}"; rm -rf "$CONFDIR"/cache/*; exit 1; } # List info about all installed AppImages
    echo
    echo "${CLR_CYAN}tar packages${CLR_CLEAR}:"
    echo
    tarlistinstalledfunc || { ssft_display_error "${CLR_RED}Error" "List failed; exiting...${CLR_CLEAR}"; rm -rf "$CONFDIR"/cache/*; exit 1; } # List info about all installed tar packages
    echo "${CLR_GREEN}$(dir -C -w 1 "$CONFDIR"/appimginstalled | wc -l) AppImages installed${CLR_CLEAR}:" # Output number of and names of installed AppImages
    dir -C -w 1 "$CONFDIR"/appimginstalled | pr -tT --column=3 -w 125
    echo
    echo "${CLR_CYAN}$(dir -C -w 1 "$CONFDIR"/tarinstalled | wc -l) tar packages installed${CLR_CLEAR}:" # Output number of and names of installed tar packages
    dir -C -w 1 "$CONFDIR"/tarinstalled | pr -tT --column=3 -w 125
    echo
}
