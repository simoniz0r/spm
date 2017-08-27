#!/bin/bash
# Title: spm
# Description: Downloads AppImages and moves them to /usr/local/bin/.  Can also upgrade and remove installed AppImages.
# Dependencies: GNU coreutils, tar, wget, python3.x
# Author: simonizor
# Website: http://www.simonizor.gq
# License: GPL v2.0 only

X="0.0.7"
# Set spm version

helpfunc () { # All unknown arguments come to this function; display help for spm
printf '%s\n' "spm $X
Usage: spm [option] [package]

spm is a simple commandline package manager that installs AppImages and precompiled tar archives.
AppImage information is downloaded from https://github.com/AppImage/appimage.github.io and tar archive information
is downloaded from spm's github repo.  spm keeps track of installed packages and their versions, so spm can also be
used to upgrade and remove packages installed by spm.

AppImages are installed to '/usr/local/bin/AppImageName'. Information for installed AppImages is stored in
'"$CONFDIR"/appimginstalled/AppImageName'.  Packages on your system should not conflict with AppImages
installed through spm, but spm will not allow AppImages that have the same name as existing commands on
your system to be installed.

Precompiled tar archives are installed to '/opt/PackageName', and symlinks are created for the .desktop and executable
files. Information for installed tar archives is stored in '"$CONFDIR"/tarinstalled/PackageName'.

spm does not handle installing dependencies for tar packages that are installed through spm. A list of dependencies
will be outputted on install and will also be saved to '"$CONFDIR"/tarinstalled/PackageName'. If you find that
you are missing dependencies needed for a package installed through spm, you can look there for some help.

AppImages, on the other hand, contain all dependencies that are necessary for the app to run as long as
those dependencies would not be on a normal Linux system.  This means that AppImages should \"just work\"
without having to install any additional packages!

Arguments:
    list (-l) - list all installed AppImages and all AppImages known by spm or info about the specified AppImage
    list-installed (-li) - list all installed AppImages and install info
    appimg-install (-ai) - install an AppImage
    tar-install (-ti - install a precompiled tar archive
    appimg-remove (-ar) - remove an installed AppImage
    tar-remove (-tr) remove an installed precompiled tar archive
    update (-upd) - update package lists and check for new AppImage and precompiled tar archive versions
    appimg-update-force (-auf) - add specified AppImage to upgrade-list without checking versions
    tar-update-force (-tuf) - add specified precompiled tar archive to list of upgrades without checking versions
    upgrade (-upg) - upgrade all installed packages that are marked for upgrade or just the specified package

See https://github.com/simoniz0r/appimgman for more help or to report issues.

spm is not responsible for bugs within applications that have been
installed using spm.  Please report any bugs that are specific to
installed applications to their maintainers."
}

spmdepchecksfunc () {
    USE_GIT="TRUE"

    if ! type wget >/dev/null 2>&1; then
        MISSING_DEPS="TRUE"
        echo "wget is not installed!"
    fi
    # if ! type jq >/dev/null 2>&1; then # Not used yet
    #    MISSING_DEPS="TRUE"
    #     echo "jq is not installed!"
    # fi
    if [ "$MISSING_DEPS" = "TRUE" ]; then
        echo "Missing one or more packages required to run; exiting..."
        exit 1
    fi
    # if ! type git >/dev/null 2>&1; then # Not used yet
    #     USE_GIT="FALSE"
    #     echo "git is not installed; wget will be used instead."
    # fi
}

appimgfunctioncheckfunc () {
    REALPATH="$(readlink -f $0)"
    RUNNING_DIR="$(dirname "$REALPATH")" # Find directory script is running from
    if [ -f $RUNNING_DIR/appimgfunctions.sh ]; then
        FUNCTIONS_VER="$(cat "$RUNNING_DIR"/appimgfunctions.sh | sed -n 9p | cut -f2 -d'"')"
        if [ "$X" != "$FUNCTIONS_VER" ]; then
            echo "appimgfunctions.sh $FUNCTIONS_VER version does not match $X; removing and updating..."
            rm "$RUNNING_DIR"/appimgfunctions.sh || { echo "rm $RUNNING_DIR/appimgfunctions.sh failed; trying with sudo..."; sudo rm "$RUNNING_DIR"/appimgfunctions.sh; }
            echo "$RUNNING_DIR/appimgfunctions.sh has been removed."
            echo "Downloading appimgfunctions.sh from spm github repo..."
            wget --quiet --show-progress "https://github.com/simoniz0r/appimgman/raw/spm/appimgfunctions.sh" -O "$CONFDIR"/cache/appimgfunctions.sh
            chmod +x "$CONFDIR"/cache/appimgfunctions.sh
            mv "$CONFDIR"/cache/appimgfunctions.sh "$RUNNING_DIR"/appimgfunctions.sh || { echo "mv to $RUNNING_DIR failed; trying as sudo..."; sudo mv "$CONFDIR"/cache/appimgfunctions.sh "$RUNNING_DIR"/appimgfunctions.sh; }
            echo "appimgfunctions.sh saved to $RUNNING_DIR/appimgfunctions.sh"
        fi
    else
        echo "Missing required file $RUNNING_DIR/appimgfunctions.sh !"
        echo "Downloading appimgfunctions.sh from spm github repo..."
        wget --quiet --show-progress "https://github.com/simoniz0r/appimgman/raw/spm/appimgfunctions.sh" -O "$CONFDIR"/cache/appimgfunctions.sh
        chmod +x "$CONFDIR"/cache/appimgfunctions.sh
        mv "$CONFDIR"/cache/appimgfunctions.sh "$RUNNING_DIR"/appimgfunctions.sh || { echo "mv to $RUNNING_DIR failed; trying as sudo..."; sudo mv "$CONFDIR"/cache/appimgfunctions.sh "$RUNNING_DIR"/appimgfunctions.sh; }
        echo "appimgfunctions.sh saved to $RUNNING_DIR/appimgfunctions.sh"
    fi
}

tarfunctioncheckfunc () {
    if [ -f $RUNNING_DIR/tarfunctions.sh ]; then
        FUNCTIONS_VER="$(cat "$RUNNING_DIR"/tarfunctions.sh | sed -n 9p | cut -f2 -d'"')"
        if [ "$X" != "$FUNCTIONS_VER" ]; then
            echo "tarfunctions.sh $FUNCTIONS_VER version does not match $X; removing and updating..."
            rm "$RUNNING_DIR"/tarfunctions.sh || { echo "rm $RUNNING_DIR/tarfunctions.sh failed; trying with sudo..."; sudo rm "$RUNNING_DIR"/tarfunctions.sh; }
            echo "$RUNNING_DIR/tarfunctions.sh has been removed."
            echo "Downloading tarfunctions.sh from spm github repo..."
            wget --quiet --show-progress "https://github.com/simoniz0r/appimgman/raw/spm/tarfunctions.sh" -O "$CONFDIR"/cache/tarfunctions.sh
            chmod +x "$CONFDIR"/cache/tarfunctions.sh
            mv "$CONFDIR"/cache/tarfunctions.sh "$RUNNING_DIR"/tarfunctions.sh || { echo "mv to $RUNNING_DIR failed; trying as sudo..."; sudo mv "$CONFDIR"/cache/tarfunctions.sh "$RUNNING_DIR"/tarfunctions.sh; }
            echo "tarfunctions.sh saved to $RUNNING_DIR/tarfunctions.sh"
        fi
    else
        echo "Missing required file $RUNNING_DIR/tarfunctions.sh !"
        echo "Downloading tarfunctions.sh from spm github repo..."
        wget --quiet --show-progress "https://github.com/simoniz0r/appimgman/raw/spm/tarfunctions.sh" -O "$CONFDIR"/cache/tarfunctions.sh
        chmod +x "$CONFDIR"/cache/tarfunctions.sh
        mv "$CONFDIR"/cache/tarfunctions.sh "$RUNNING_DIR"/tarfunctions.sh || { echo "mv to $RUNNING_DIR failed; trying as sudo..."; sudo mv "$CONFDIR"/cache/tarfunctions.sh "$RUNNING_DIR"/tarfunctions.sh; }
        echo "tarfunctions.sh saved to $RUNNING_DIR/tarfunctions.sh"
    fi
}

jsonparsecheck () {
    if [ ! -f $RUNNING_DIR/jsonparse.py ]; then
        echo "Missing required file $RUNNING_DIR/jsonparse.py !"
        echo "Downloading jsonparse.py from spm github repo..."
        wget --quiet --show-progress "https://github.com/simoniz0r/appimgman/raw/spm/jsonparse.py" -O "$CONFDIR"/cache/jsonparse.py
        chmod +x "$CONFDIR"/cache/jsonparse.py
        mv "$CONFDIR"/cache/jsonparse.py "$RUNNING_DIR"/jsonparse.py || { echo "mv to $RUNNING_DIR failed; trying as sudo..."; sudo mv "$CONFDIR"/cache/jsonparse.py "$RUNNING_DIR"/jsonparse.py; }
        echo "jsonparse.py saved to $RUNNING_DIR/jsonparse.py"
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
