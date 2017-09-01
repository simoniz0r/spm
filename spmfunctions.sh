#!/bin/bash
# Title: spm
# Description: Downloads and installs AppImages and precompiled tar archives.  Can also upgrade and remove installed packages.
# Dependencies: GNU coreutils, tar, wget, python2.x
# Author: simonizor
# Website: http://www.simonizor.gq
# License: GPL v2.0 only

X="0.3.1"
# Set spm version

helpfunc () { # All unknown arguments come to this function; display help for spm
printf '%s\n' "spm $X
Usage: spm [option] [package]

spm is a simple commandline package manager that installs AppImages and precompiled tar archives. spm
integrates with appimagehub to get a list of AppImages for install. Precompiled tar archive information
is stored in spm's github repo.   spm keeps track of installed packages and their versions, so spm can
also be used to upgrade and remove packages installed by spm.

Arguments:
    list (-l) - list all installed packages and all packages known by spm or info about the specified package
    list-installed (-li) - list all installed packages and install info
    appimg-install (-ai) - install an AppImage
    tar-install (-ti) - install a precompiled tar archive
    appimg-remove (-ar) - remove an installed AppImage
    tar-remove (-tr) remove an installed precompiled tar archive
    update (-upd) - update package lists and check for package upgrades
    appimg-update-force (-auf) - mark specified AppImage for upgrade without checking version
    tar-update-force (-tuf) - mark specified precompiled tar archive for upgrade without checking version
    upgrade (-upg) - upgrade all installed packages that are marked for upgrade or just the specified package
    man (-m) - show spm man page

See https://github.com/simoniz0r/spm for more help or to report issues.

spm is not responsible for bugs within applications that have been
installed using spm.  Please report any bugs that are specific to
installed applications to their maintainers."
}

spmdepchecksfunc () { # Check for packages needed by spm, exit if they aren't installed
    if [ -f ././/bin/jq ]; then # This more than likely will not get set to TRUE unless using the AppImage version of spm which includes 'jq'.
        USE_JQ="TRUE"
        SKIP_DEP_CHECKS="TRUE"
    fi
    if [ "$SKIP_DEP_CHECKS" = "FALSE" ]; then # Run dependency checks if SKIP_DEP_CHECKS has not been set to something other than "FALSE" in spm.conf
        if ! type wget >/dev/null 2>&1; then
            MISSING_DEPS="TRUE"
            echo "wget is not installed!"
        fi
        if ! type python3 >/dev/null 2>&1; then
            MISSING_DEPS="TRUE"
            echo "python3 is not installed!"
        fi
        if [ "$MISSING_DEPS" = "TRUE" ]; then
            echo "Missing one or more packages required to run; exiting..."
            echo "If you are sure you have the required dependencies, but spm does not detect them"
            echo "change `SKIP_DEP_CHECKS` to `TRUE` in `$CONFDIR/spm.conf`"
            exit 1
        fi
    fi
}

appimgfunctioncheckfunc () {
    REALPATH="$(readlink -f $0)"
    RUNNING_DIR="$(dirname "$REALPATH")" # Find directory script is running from
    if [ -f $RUNNING_DIR/appimgfunctions.sh ]; then
        FUNCTIONS_VER="$(cat "$RUNNING_DIR"/appimgfunctions.sh | sed -n 9p | cut -f2 -d'"')"
        if [ "$X" != "$FUNCTIONS_VER" ]; then
            echo "appimgfunctions.sh $FUNCTIONS_VER version does not match $X !"
            echo "appimgfunctions.sh is out of date! Please download the full release of spm from https://github.com/simoniz0r/spm/releases !"
            exit 1
        fi
    else
        echo "Missing required file $RUNNING_DIR/appimgfunctions.sh !"
        echo "appimgfunctions.sh is missing! Please download the full release of spm from https://github.com/simoniz0r/spm/releases !"
        exit 1
    fi
}

tarfunctioncheckfunc () {
    if [ -f $RUNNING_DIR/tarfunctions.sh ]; then
        FUNCTIONS_VER="$(cat "$RUNNING_DIR"/tarfunctions.sh | sed -n 9p | cut -f2 -d'"')"
        if [ "$X" != "$FUNCTIONS_VER" ]; then
            echo "tarfunctions.sh $FUNCTIONS_VER version does not match $X !"
            echo "tarfunctions.sh is out of date! Please download the full release of spm from https://github.com/simoniz0r/spm/releases !"
            exit 1
        fi
    else
        echo "Missing required file $RUNNING_DIR/tarfunctions.sh !"
        echo "tarfunctions.sh is missing! Please download the full release of spm from https://github.com/simoniz0r/spm/releases !"
        exit 1
    fi
}

jsonparsecheck () {
    if [ ! -f $RUNNING_DIR/jsonparse.py ] && [ ! -f ././/bin/jq ]; then
        echo "Missing required file $RUNNING_DIR/jsonparse.py !"
        echo "jsonparse.py is missing! Please download the full release of spm from https://github.com/simoniz0r/spm/releases !"
        exit 1
    fi
}

spmlockfunc () {
    if [ ! -f "$CONFDIR"/cache/spm.lock ]; then # Create "$CONFDIR"/cache/spm.lock file and prevent multiple instances by checking if it exists before running
        touch "$CONFDIR"/cache/spm.lock
    else
        echo "spm.lock file is still present.  Are you sure spm isn't running?"
        read -p "Remove spm.lock file and run spm? Y/N " LOCKANSWER
        case $LOCKANSWER in
            n*|N*)
                echo "spm.lock file was not removed; make sure spm is finished before running spm again."
                exit 1
                ;;
        esac
        rm -rf "$CONFDIR"/cache/* # Remove any files in cache and lock file
    fi
}

spmvercheckfunc () {
    VERTEST="$(wget -q "https://raw.githubusercontent.com/simoniz0r/spm/master/spm" -O - | sed -n '9p' | tr -d 'X="')" # Use wget sed and tr to check current spm version from github
    if [[ "$VERTEST" != "$X" ]]; then # If current version not equal to installed version, notify of new version
        echo "A new version of spm is available!"
        echo "Current version: $VERTEST -- Installed version: $X"
        if type >/dev/null 2>&1 spm; then # If spm is installed, suggest upgrading spm through spm
            echo "Use 'spm' to upgrade to the latest version!"
            echo
        else # If not, output link to releases page
            echo "Download the latest version at https://github.com/simoniz0r/appimgman/releases/latest"
            echo
        fi
    fi
}

updatestartfunc () {
    if [ ! -z "$1" ]; then
        if [ -f "$CONFDIR"/appimginstalled/"$1" ]; then
            INSTIMG="$1"
            appimgupdatelistfunc "$INSTIMG"
        elif [ -f "$CONFDIR"/tarinstalled/"$1" ]; then
            TARPKG="$1"
            tarupdatelistfunc "$TARPKG"
        else
            echo "Package not found!"
            rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
            exit 1
        fi
    else
        appimgupdatelistfunc
        echo
        tarupdatelistfunc
    fi
}

upgradestartfunc () {
    if [ "$(dir "$CONFDIR"/appimgupgrades | wc -l)" = "0" ]; then
        echo "No new AppImage upgrades; skipping AppImage upgrade function..."
        echo
        APPIMGUPGRADES="FALSE"
    else
        APPIMGUPGRADES="TRUE"
    fi
    if [ "$(dir "$CONFDIR"/tarupgrades | wc -l)" = "0" ]; then
        echo "No tar package upgrades; skipping tar upgrade function..."
        echo
        TARUPGRADES="FALSE"
        if [ "$APPIMGUPGRADES" = "FALSE" ]; then
            echo "No new upgrades available; try running 'spm update'."
            rm -rf "$CONFDIR"/cache/*
            exit 0
        fi
    else
        TARUPGRADES="TRUE"
    fi
    if [ -z "$1" ]; then # If no AppImage specified, upgrade all AppImages in upgrade-list.lst
        if [ "$APPIMGUPGRADES" = "TRUE" ]; then
            appimgupgradestartallfunc # Run a for loop that checks each installed AppImage for upgrades
        fi
        echo
        if [ "$TARUPGRADES" = "TRUE" ]; then
            tarupgradestartallfunc
        fi
        rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
        exit 0
    elif [ "$TARUPGRADES" = "TRUE" ] || [ "$APPIMGUPGRADES" = "TRUE" ]; then # If user specifies package, upgrade that package
        if [ "$APPIMGUPGRADES" = "TRUE" ]; then
            INSTIMG="$1"
            appimgupgradestartfunc # Check specified AppImage for upgrade
        fi
        echo
        if [ "$TARUPGRADES" = "TRUE" ]; then
            TARPKG="$1"
            tarupgradestartfunc
        fi
    else # If upgrade-list.lst doesn't exist, suggest to run update function
        echo "No new upgrade for $1; try running 'spm update'."
        rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
        exit 0
    fi
}

liststartfunc () {
    if [ -z "$LISTIMG" ]; then # If no AppImage input, list all AppImages
        echo "AppImages:"
        appimglistallfunc # List all installed and all available AppImages
        echo
        echo "tar packages:"
        tarlistfunc
    else # If AppImage input, list info for that AppImage
        if grep -qow "$LISTIMG" "$CONFDIR"/AppImages-github.lst || grep -qow "$LISTIMG" "$CONFDIR"/AppImages-direct.lst; then
            appimglistfunc # List information about specified AppImage
            echo
            ISAPPIMG="TRUE"
        fi
        if echo "$TAR_LIST" | grep -qow "$TARPKG"; then
            tarlistfunc
            echo
            ISTAR="TRUE"
        fi
        if [ -z "$ISAPPIMG" ] && [ -z "$ISTAR" ]; then
            echo "$LISTIMG not found!"
            rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
            exit 1
        fi
    fi
}
