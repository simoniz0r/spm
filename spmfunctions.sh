#!/bin/bash
# Title: spm
# Description: Downloads and installs AppImages and precompiled tar archives.  Can also upgrade and remove installed packages.
# Dependencies: GNU coreutils, tar, wget
# Author: simonizor
# Website: http://www.simonizor.gq
# License: GPL v2.0 only

X="0.4.7"
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

spmdepchecksfunc () { # Run dep checks, exit if deps not present. If SKIP_DEP_CHECKS has not been set to something other than "FALSE" in spm.conf, skip this function
    if [ "$SKIP_DEP_CHECKS" = "FALSE" ]; then
        if ! type wget >/dev/null 2>&1; then
            MISSING_DEPS="TRUE"
            echo "$(tput setaf 1)wget is not installed!$(tput sgr0)"
        fi
        if [ ! -f "$RUNNING_DIR"/yaml ]; then
            MISSING_DEPS="TRUE"
            echo -e "$(tput setaf 1)$RUNNING_DIR/yaml not found! Please download the full release of spm:\nhttps://github.com/simoniz0r/spm/releases"
        fi
        if [ ! -f "$RUNNING_DIR"/jq ]; then
            MISSING_DEPS="TRUE"
            echo -e "$(tput setaf 1)$RUNNING_DIR/jq not found!  Please download the full release of spm:\nhttps://github.com/simoniz0r/spm/releases"
        fi
        if [ "$MISSING_DEPS" = "TRUE" ]; then
            echo "$(tput setaf 1)Missing one or more packages required to run; exiting...$(tput sgr0)"
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
            echo "$(tput setaf 1)appimgfunctions.sh $FUNCTIONS_VER version does not match $X !"
            echo "appimgfunctions.sh is out of date! Please download the full release of spm from https://github.com/simoniz0r/spm/releases !$(tput sgr0)"
            exit 1
        fi
    else
        echo "$(tput setaf 1)Missing required file $RUNNING_DIR/appimgfunctions.sh !"
        echo "appimgfunctions.sh is missing! Please download the full release of spm from https://github.com/simoniz0r/spm/releases !$(tput sgr0)"
        exit 1
    fi
}

tarfunctioncheckfunc () { # Checks to make sure that tarfunctions.sh exists and is up to date
    if [ -f $RUNNING_DIR/tarfunctions.sh ]; then
        FUNCTIONS_VER="$(cat "$RUNNING_DIR"/tarfunctions.sh | sed -n 9p | cut -f2 -d'"')"
        if [ "$X" != "$FUNCTIONS_VER" ]; then
            echo "$(tput setaf 1)tarfunctions.sh $FUNCTIONS_VER version does not match $X !"
            echo "tarfunctions.sh is out of date! Please download the full release of spm from https://github.com/simoniz0r/spm/releases !$(tput sgr0)"
            exit 1
        fi
    else
        echo "$(tput setaf 1)Missing required file $RUNNING_DIR/tarfunctions.sh !"
        echo "tarfunctions.sh is missing! Please download the full release of spm from https://github.com/simoniz0r/spm/releases !$(tput sgr0)"
        exit 1
    fi
}

spmlockfunc () { # Create "$CONFDIR"/cache/spm.lock file and prevent multiple instances by checking if it exists before running
    if [ ! -f "$CONFDIR"/cache/spm.lock ]; then
        touch "$CONFDIR"/cache/spm.lock
    else
        echo "$(tput setaf 1)spm.lock file is still present.  Did spm exit correctly?  Are you sure spm isn't running?"
        read -p "Remove spm.lock file and run spm? Y/N $(tput sgr0)" LOCKANSWER
        case $LOCKANSWER in
            n*|N*)
                echo "$(tput setaf 1)spm.lock file was not removed; make sure spm is finished before running spm again.$(tput sgr0)"
                exit 1
                ;;
        esac
        rm -rf "$CONFDIR"/cache/* # Remove any files in cache and lock file
    fi
}

spmvercheckfunc () { # Check spm version when running update argument and notify of new version if available
    VERTEST="$(wget -q "https://raw.githubusercontent.com/simoniz0r/spm/master/spm" -O - | sed -n '9p' | tr -d 'X="')" # Use wget sed and tr to check current spm version from github
    if [[ "$VERTEST" != "$X" ]]; then # If current version not equal to installed version, notify of new version
        echo "$(tput setaf 2)A new version of spm is available!"
        echo "Current version: $VERTEST -- Installed version: $X"
        if type >/dev/null 2>&1 spm; then # If spm is installed, suggest upgrading spm through spm
            echo "Use 'spm' to upgrade to the latest version!$(tput sgr0)"
            echo
        else # If not, output link to releases page
            echo "Download the latest version at https://github.com/simoniz0r/appimgman/releases/latest$(tput sgr0)"
            echo
        fi
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
            echo "$(tput setaf 1)Package not found!$(tput sgr0)"
            rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
            exit 1
        fi
    else
        appimgupdatelistfunc # Check all installed AppImages for upgrades
        echo
        tarupdatelistfunc # Check all installed tar packages for upgrades
        echo
        if [ "$(dir "$CONFDIR"/tarupgrades | wc -w)" = "0" ] && [ "$(dir "$CONFDIR"/appimgupgrades | wc -w)" = "0" ]; then
            echo "No new AppImage or tar package upgrades available."
        else
            echo "$(tput setaf 2)$(dir "$CONFDIR"/appimgupgrades | wc -w) new AppImage and $(dir "$CONFDIR"/tarupgrades | wc -w) new tar package upgrade(s) available!$(tput sgr0)"
        fi
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
        if [ "$APPIMGUPGRADES" = "TRUE" ]; then
            INSTIMG="$1"
            appimgupgradestartfunc # Upgrade specified AppImage if available
        fi
        echo
        if [ "$TARUPGRADES" = "TRUE" ]; then
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
    if [ -z "$LISTIMG" ]; then
        appimglistallfunc # List all AppImages available for install
        echo
        tarlistfunc # List all tar packages available for install
    else
        appimglistfunc # List info for specified AppImage if available
        echo
        tarlistfunc # List info for specified tar package if available
        if [ "$APPIMG_NOT_FOUND" = "TRUE" ] && [ "$TARPKG_NOT_FOUND" = "TRUE" ]; then # If both tarfunctions.sh and appimgfunctions.sh output no packages found, tell user package not found
            echo "$(tput setaf 1)$LISTIMG not found in package lists!$(tput sgr0)"
        fi
        rm -rf "$CONFDIR"/cache/* # Remove any files in cache before exiting
        exit 0
    fi
}
