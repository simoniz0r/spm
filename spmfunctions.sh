#!/bin/bash
# Title: spm
# Description: Downloads AppImages and moves them to /usr/local/bin/.  Can also upgrade and remove installed AppImages.
# Dependencies: GNU coreutils, wget
# Author: simonizor
# Website: http://www.simonizor.gq
# License: GPL v2.0 only

X="0.0.2"
# Set spm version

helpfunc () { # All unknown arguments come to this function; display help for spm
printf '%s\n' "spm $X
Usage: spm [option] [package]

spm is a simple commandline package manager that installs AppImages and precompiled tar archives.
AppImage information is gotten from https://github.com/AppImage/appimage.github.io and tar archive information
is stored in spm's github repo.  spm keeps track of installed packages and their versions, so spm can also be
used to upgrade and remove packages installed by spm.

AppImages are installed to '/usr/local/bin/AppImageName'. Information for installed AppImages is stored in
'~/.config/spm/appimginstalled/AppImageName'.  Packages on your system should not conflict with AppImages
installed through spm, but spm will not allow AppImages that have the same name as existing commands on
your system to be installed.

Precompiled tar archives are installed to '/opt/PackageName', and symlinks are created for the .desktop and executable
files. Information for installed tar archives is stored in '~/.config/spm/tarinstalled/PackageName'.

spm does not handle installing dependencies for tar packages that are installed through spm. A list of dependencies
will be outputted on install and will also be saved to '~/.config/spm/tarinstalled/PackageName'. If you find that
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

    if [ "$EUID" = "0" ]; then # Prevent spm from being ran as root
        echo "Do not run spm as root!"
        exit 1
    fi

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
            wget --quiet --show-progress "https://github.com/simoniz0r/appimgman/raw/spm/appimgfunctions.sh" -O ~/.config/spm/cache/appimgfunctions.sh
            chmod +x ~/.config/spm/cache/appimgfunctions.sh
            mv ~/.config/spm/cache/appimgfunctions.sh "$RUNNING_DIR"/appimgfunctions.sh || { echo "mv to $RUNNING_DIR failed; trying as sudo..."; sudo mv ~/.config/spm/cache/appimgfunctions.sh "$RUNNING_DIR"/appimgfunctions.sh; }
            echo "appimgfunctions.sh saved to $RUNNING_DIR/appimgfunctions.sh"
        fi
    else
        echo "Missing required file $RUNNING_DIR/appimgfunctions.sh !"
        echo "Downloading appimgfunctions.sh from spm github repo..."
        wget --quiet --show-progress "https://github.com/simoniz0r/appimgman/raw/spm/appimgfunctions.sh" -O ~/.config/spm/cache/appimgfunctions.sh
        chmod +x ~/.config/spm/cache/appimgfunctions.sh
        mv ~/.config/spm/cache/appimgfunctions.sh "$RUNNING_DIR"/appimgfunctions.sh || { echo "mv to $RUNNING_DIR failed; trying as sudo..."; sudo mv ~/.config/spm/cache/appimgfunctions.sh "$RUNNING_DIR"/appimgfunctions.sh; }
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
            wget --quiet --show-progress "https://github.com/simoniz0r/appimgman/raw/spm/tarfunctions.sh" -O ~/.config/spm/cache/tarfunctions.sh
            chmod +x ~/.config/spm/cache/tarfunctions.sh
            mv ~/.config/spm/cache/tarfunctions.sh "$RUNNING_DIR"/tarfunctions.sh || { echo "mv to $RUNNING_DIR failed; trying as sudo..."; sudo mv ~/.config/spm/cache/tarfunctions.sh "$RUNNING_DIR"/tarfunctions.sh; }
            echo "tarfunctions.sh saved to $RUNNING_DIR/tarfunctions.sh"
        fi
    else
        echo "Missing required file $RUNNING_DIR/tarfunctions.sh !"
        echo "Downloading tarfunctions.sh from spm github repo..."
        wget --quiet --show-progress "https://github.com/simoniz0r/appimgman/raw/spm/tarfunctions.sh" -O ~/.config/spm/cache/tarfunctions.sh
        chmod +x ~/.config/spm/cache/tarfunctions.sh
        mv ~/.config/spm/cache/tarfunctions.sh "$RUNNING_DIR"/tarfunctions.sh || { echo "mv to $RUNNING_DIR failed; trying as sudo..."; sudo mv ~/.config/spm/cache/tarfunctions.sh "$RUNNING_DIR"/tarfunctions.sh; }
        echo "tarfunctions.sh saved to $RUNNING_DIR/tarfunctions.sh"
    fi
}

spmlockfunc () {
    if [ ! -f ~/.config/spm/cache/spm.lock ]; then # Create ~/.config/spm/cache/spm.lock file and prevent multiple instances by checking if it exists before running
        touch ~/.config/spm/cache/spm.lock
    else
        echo "spm.lock file is still present.  Are you sure spm isn't running?"
        read -p "Remove spm.lock file and run spm? Y/N " LOCKANSWER
        case $LOCKANSWER in
            n*|N*)
                echo "spm.lock file was not removed; make sure spm is finished before running spm again."
                exit 1
                ;;
        esac
        rm -rf ~/.config/spm/cache/* # Remove any files in cache and lock file
    fi
}

spmfirstrunfunc () {
    if [ ! -d ~/.config/spm ]; then # Create dirs for configs if they don't exist
        echo "spm is being ran for the first time."
        echo "Creating config directories..."
        mkdir ~/.config/spm
        mkdir ~/.config/spm/tarinstalled
        mkdir ~/.config/spm/appimginstalled
        mkdir ~/.config/spm/tarupgrades
        mkdir ~/.config/spm/appimgupgrades
        mkdir ~/.config/spm/cache
        echo "Generating AppImages-bintray.lst from https://dl.bintray.com/probono/AppImages/ ..."
        wget --show-progress --quiet "https://dl.bintray.com/probono/AppImages/" -O - | sed 's/<\/*[^>]*>//g' | grep -o '.*AppImage' | cut -f1 -d"-" | sort -u > ~/.config/spm/AppImages-bintray.lst
        echo "Downloading AppImages-github.lst from spm github..."
        wget --quiet --show-progress "https://raw.githubusercontent.com/simoniz0r/appimgman/spm/AppImages-github.lst" -qO ~/.config/spm/AppImages-github.lst
        echo "Downloading tar-pkgs.lst from tar-pkg github repo..."
        wget "https://raw.githubusercontent.com/simoniz0r/tar-pkg/master/apps/known-pkgs.lst" -qO ~/.config/spm/tar-pkgs.lst
        echo "First run operations complete!"
    fi
}

spmvercheckfunc () {
    # VERTEST="$(wget -q "https://raw.githubusercontent.com/simoniz0r/appimgman/spm/spm" -O - | sed -n '9p' | tr -d 'X="')" # Use wget sed and tr to check current spm version from github
    VERTEST="0.0.1"
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
