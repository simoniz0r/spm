#!/bin/bash
# Title: spm
# Description: Downloads and installs AppImages and precompiled tar archives.  Can also upgrade and remove installed packages.
# Dependencies: GNU coreutils, tar, wget
# Author: simonizor
# Website: http://www.simonizor.gq
# License: GPL v2.0 only

X="0.4.7"
# Set spm version
TAR_LIST="$(echo -e $(grep '"available"' "$CONFDIR"/tar-pkgs.json | cut -f7 -d" " | tr -d ',"'))"
TAR_SIZE="N/A"
TAR_DOWNLOADS="N/A"

tarfunctionsexistfunc () {
    sleep 0
}

tarsaveconffunc () { # Saves file containing tar package info in specified directory for use later
    if [ -z "$NEW_TARFILE" ]; then
        NEW_TARFILE="$TARFILE"
    fi
    SAVEDIR="$1"
    echo "INSTDIR="\"$INSTDIR\""" > "$CONFDIR"/"$SAVEDIR"
    echo "TAR_DOWNLOAD_SOURCE="\"$TAR_DOWNLOAD_SOURCE\""" >> "$CONFDIR"/"$SAVEDIR"
    echo "TARURI="\"$TARURI\""" >> "$CONFDIR"/"$SAVEDIR"
    echo "TARFILE="\"$NEW_TARFILE\""" >> "$CONFDIR"/"$SAVEDIR"
    echo "TAR_DOWNLOADS="\"$TAR_DOWNLOADS\""" >> "$CONFDIR"/"$SAVEDIR"
    echo "TAR_SIZE="\"$TAR_SIZE\""" >> "$CONFDIR"/"$SAVEDIR"
    if [ "$TAR_DOWNLOAD_SOURCE" = "GITHUB" ]; then
        echo "TAR_GITHUB_COMMIT="\"$TAR_GITHUB_NEW_COMMIT\""" >> "$CONFDIR"/"$SAVEDIR"
        echo "TAR_GITHUB_VERSION="\"$TAR_GITHUB_NEW_VERSION\""" >> "$CONFDIR"/"$SAVEDIR"
    fi
    echo "DESKTOP_FILE_PATH="\"$DESKTOP_FILE_PATH\""" >> "$CONFDIR"/"$SAVEDIR"
    echo "ICON_FILE_PATH="\"$ICON_FILE_PATH\""" >> "$CONFDIR"/"$SAVEDIR"
    echo "EXECUTABLE_FILE_PATH="\"$EXECUTABLE_FILE_PATH\""" >> "$CONFDIR"/"$SAVEDIR"
    echo "BIN_PATH="\"$BIN_PATH\""" >> "$CONFDIR"/"$SAVEDIR"
    echo "CONFIG_PATH="\"$CONFIG_PATH\""" >> "$CONFDIR"/"$SAVEDIR"
    echo "TAR_DESCRIPTION="\"$TAR_DESCRIPTION\""" >> "$CONFDIR"/"$SAVEDIR"
    echo "DEPENDENCIES="\"$DEPENDENCIES\""" >> "$CONFDIR"/"$SAVEDIR"
}

targithubinfofunc () { # Gets updated_at, tar url, and description for specified package for use with listing, installing, and upgrading
    if [ -z "$GITHUB_TOKEN" ]; then
        wget --quiet "$TAR_API_URI" -O "$CONFDIR"/cache/"$TARPKG"-release || { echo "$(tput setaf 1)wget $TAR_API_URI failed; has the repo been renamed or deleted?$(tput sgr0)"; rm -rf "$CONFDIR"/cache/*; exit 1; }
    else
        wget --quiet --auth-no-challenge --header="Authorization: token "$GITHUB_TOKEN"" "$TAR_API_URI" -O "$CONFDIR"/cache/"$TARPKG"-release || { echo "$(tput setaf 1)wget $TAR_API_URI failed; is your token valid?$(tput sgr0)"; rm -rf "$CONFDIR"/cache/*; exit 1; }
    fi
    JQARG=".[].assets[] | select(.name | contains(\".tar\")) | select(.name | contains(\"$TARPKG\")) | select(.name | contains(\"macos\") | not) | select(.name | contains(\"ia32\") | not) | select(.name | contains(\"i386\") | not) | select(.name | contains(\"i686\") | not) | { name: .name, updated: .updated_at, url: .browser_download_url, size: .size, numdls: .download_count}"
    cat "$CONFDIR"/cache/"$TARPKG"-release | "$RUNNING_DIR"/jq --raw-output "$JQARG" | sed 's%{%data:%g' | tr -d '",}' > "$CONFDIR"/cache/"$TARPKG"release
    if [ "$(cat "$CONFDIR"/cache/"$TARPKG"release | wc -l)" = "0" ]; then
        rm "$CONFDIR"/cache/"$TARPKG"release
        JQARG=".[].assets[] | select(.name | contains(\".tar\")) | select(.name | contains(\"macos\") | not) | select(.name | contains(\"ia32\") | not) | select(.name | contains(\"i386\") | not) | select(.name | contains(\"i686\") | not) | { name: .name, updated: .updated_at, url: .browser_download_url, size: .size, numdls: .download_count}"
        cat "$CONFDIR"/cache/"$TARPKG"-release | "$RUNNING_DIR"/jq --raw-output "$JQARG" | sed 's%{%data:%g' | tr -d '",}' > "$CONFDIR"/cache/"$TARPKG"release
    fi
    NEW_TARFILE="$(cat "$CONFDIR"/cache/"$TARPKG"release | "$RUNNING_DIR"/yaml r - data.name)"
    TAR_GITHUB_NEW_COMMIT="$(cat "$CONFDIR"/cache/"$TARPKG"release | "$RUNNING_DIR"/yaml r - data.updated)"
    TAR_GITHUB_NEW_DOWNLOAD="$(cat "$CONFDIR"/cache/"$TARPKG"release | "$RUNNING_DIR"/yaml r - data.url)"
    TAR_SIZE="$(cat "$CONFDIR"/cache/"$TARPKG"release | "$RUNNING_DIR"/yaml r - data.size)"
    TAR_SIZE="$(echo "scale = 3; $TAR_SIZE / 1024 / 1024" | bc) MBs"
    TAR_DOWNLOADS="$(cat "$CONFDIR"/cache/"$TARPKG"release | "$RUNNING_DIR"/yaml r - data.numdls)"
    TAR_DOWNLOAD_SOURCE="GITHUB"
    TAR_GITHUB_NEW_VERSION="$(echo "$TAR_GITHUB_NEW_DOWNLOAD" | cut -f8 -d"/")"
    tarsaveconffunc "cache/$TARPKG.conf"
    . "$CONFDIR"/cache/"$TARPKG".conf
    if [ -z "$NEW_TARFILE" ]; then
        echo "$(tput setaf 1)Error finding latest tar for $TARPKG!$(tput sgr0)"
        GITHUB_DOWNLOAD_ERROR="TRUE"
    fi
}

tarappcheckfunc () { # check user input against list of known apps here
    case $(cat "$CONFDIR"/tar-pkgs.json | "$RUNNING_DIR"/yaml r - "$TARPKG") in
        null)
            KNOWN_TAR="FALSE"
            ;;
        *)
            KNOWN_TAR="TRUE"
            ;;
    esac
    case $KNOWN_TAR in
        TRUE)
            # TARPKG_NAME="$(cat $CONFDIR/tar-pkgs.json | tr '\\' '\n' | grep -iowm 1 "$1" | cut -f2 -d'"')"
            if [ ! -z "$DOWNLOAD_SOURCE" ]; then
                TAR_DOWNLOAD_SOURCE="$DOWNLOAD_SOURCE"
            fi
            INSTDIR="$("$RUNNING_DIR"/yaml r "$CONFDIR"/tar-pkgs.json "$TARPKG.instdir")"
            TAR_DOWNLOAD_SOURCE="$("$RUNNING_DIR"/yaml r "$CONFDIR"/tar-pkgs.json "$TARPKG.download_source")"
            TARURI="$("$RUNNING_DIR"/yaml r "$CONFDIR"/tar-pkgs.json "$TARPKG.taruri")"
            TAR_API_URI="$("$RUNNING_DIR"/yaml r "$CONFDIR"/tar-pkgs.json "$TARPKG.apiuri")"
            DESKTOP_FILE_PATH="$("$RUNNING_DIR"/yaml r "$CONFDIR"/tar-pkgs.json "$TARPKG.desktop_file_path")"
            ICON_FILE_PATH="$("$RUNNING_DIR"/yaml r "$CONFDIR"/tar-pkgs.json "$TARPKG.icon_file_path")"
            EXECUTABLE_FILE_PATH="$("$RUNNING_DIR"/yaml r "$CONFDIR"/tar-pkgs.json "$TARPKG.executable_file_path")"
            BIN_PATH="$("$RUNNING_DIR"/yaml r "$CONFDIR"/tar-pkgs.json "$TARPKG.bin_path")"
            CONFIG_PATH="$("$RUNNING_DIR"/yaml r "$CONFDIR"/tar-pkgs.json "$TARPKG.config_path")"
            TAR_DESCRIPTION="$("$RUNNING_DIR"/yaml r "$CONFDIR"/tar-pkgs.json "$TARPKG.description")"
            DEPENDENCIES="$("$RUNNING_DIR"/yaml r "$CONFDIR"/tar-pkgs.json "$TARPKG.dependencies")"
            if [ "$TAR_DOWNLOAD_SOURCE" = "GITHUB" ]; then
                targithubinfofunc
            else
                TAR_SIZE="N/A"
                TAR_DOWNLOADS="N/A"
                tarsaveconffunc "cache/$TARPKG.conf"
            fi
            ;;
    esac
}

tarlistfunc () { # List info about specified package or list all packages
    if [ -z "$TARPKG" ]; then
        echo "$(tput bold)$(tput setaf 6)$(echo "$TAR_LIST" | wc -l) tar packages for install$(tput sgr0):"
        echo
        echo "$TAR_LIST" | pr -tTw 125 -3
    else
        if [ -f "$CONFDIR"/tarinstalled/"$TARPKG" ]; then
            echo "$(tput bold)$(tput setaf 6)$TARPKG tar installed information$(tput sgr0):"
            . "$CONFDIR"/tarinstalled/"$TARPKG"
            echo "$(tput bold)$(tput setaf 6)Info$(tput sgr0):  $TAR_DESCRIPTION"
            echo "$(tput bold)$(tput setaf 6)Deps$(tput sgr0):  $DEPENDENCIES"
            if [ -z "$TAR_GITHUB_COMMIT" ]; then
                echo "$(tput bold)$(tput setaf 6)Version$(tput sgr0):  $TARFILE"
            else
                echo "$(tput bold)$(tput setaf 6)Version$(tput sgr0):  $TAR_GITHUB_COMMIT"
            fi
            echo "$(tput bold)$(tput setaf 6)Total DLs$(tput sgr0):  $TAR_DOWNLOADS"
            echo "$(tput bold)$(tput setaf 6)URL$(tput sgr0):  $TARURI"
            echo "$(tput bold)$(tput setaf 6)Size$(tput sgr0):  $TAR_SIZE"
            echo "$(tput bold)$(tput setaf 6)Install dir$(tput sgr0):  $INSTDIR"
            echo "$(tput bold)$(tput setaf 6)Bin path$(tput sgr0):  $BIN_PATH"
            echo
        else
            tarappcheckfunc "$TARPKG"
            if [ "$KNOWN_TAR" = "TRUE" ]; then
                echo "$(tput bold)$(tput setaf 6)$TARPKG tar package information$(tput sgr0):"
                tarsaveconffunc "cache/$TARPKG.conf"
                . "$CONFDIR"/cache/"$TARPKG".conf
                echo "$(tput bold)$(tput setaf 6)Info$(tput sgr0):  $TAR_DESCRIPTION"
                echo "$(tput bold)$(tput setaf 6)Deps$(tput sgr0):  $DEPENDENCIES"
                if [ -z "$TAR_GITHUB_COMMIT" ]; then
                    echo "$(tput bold)$(tput setaf 6)Version$(tput sgr0):  $TARFILE"
                else
                    echo "$(tput bold)$(tput setaf 6)Version$(tput sgr0):  $TAR_GITHUB_COMMIT"
                fi
                echo "$(tput bold)$(tput setaf 6)Total DLs$(tput sgr0):  $TAR_DOWNLOADS"
                echo "$(tput bold)$(tput setaf 6)URL$(tput sgr0):  $TARURI"
                echo "$(tput bold)$(tput setaf 6)Size$(tput sgr0):  $TAR_SIZE"
                echo "$(tput bold)$(tput setaf 6)Install dir$(tput sgr0):  $INSTDIR"
                echo "$(tput bold)$(tput setaf 6)Bin path$(tput sgr0):  $BIN_PATH"
                echo
            else
                TARPKG_NOT_FOUND="TRUE"
            fi
        fi
    fi
}

tarlistinstalledfunc () { # List info about installed tar packages
    for tarpkg in $(dir -C -w 1 "$CONFDIR"/tarinstalled); do
        echo "$(tput bold)$(tput setaf 6)$tarpkg installed information$(tput sgr0):"
        . "$CONFDIR"/tarinstalled/"$tarpkg"
        echo "$(tput bold)$(tput setaf 6)Info$(tput sgr0):  $TAR_DESCRIPTION"
        echo "$(tput bold)$(tput setaf 6)Deps$(tput sgr0):  $DEPENDENCIES"
        if [ "$TAR_DOWNLOAD_SOURCE" = "DIRECT" ]; then
            TAR_SIZE="N/A"
            TAR_DOWNLOADS="N/A"
            echo "$(tput bold)$(tput setaf 6)Version$(tput sgr0):  $TARFILE"
        else
            echo "$(tput bold)$(tput setaf 6)Version$(tput sgr0):  $TAR_GITHUB_COMMIT"
        fi
        echo "$(tput bold)$(tput setaf 6)Total DLs$(tput sgr0):  $TAR_DOWNLOADS"
        echo "$(tput bold)$(tput setaf 6)URL$(tput sgr0):  $TARURI"
        echo "$(tput bold)$(tput setaf 6)Size$(tput sgr0):  $TAR_SIZE"
        echo "$(tput bold)$(tput setaf 6)Install dir$(tput sgr0):  $INSTDIR"
        echo "$(tput bold)$(tput setaf 6)Bin path$(tput sgr0):  $BIN_PATH"
        echo
    done
}

tardlfunc () { # Download tar from specified source.  If not from github, use --trust-server-names to make sure the tar file is saved with the proper file name
    case $TAR_DOWNLOAD_SOURCE in
        GITHUB)
            cd "$CONFDIR"/cache
            wget --read-timeout=30 "$TAR_GITHUB_NEW_DOWNLOAD" || { echo "$(tput setaf 1)wget $TARURI_DL failed; exiting...$(tput sgr0)"; rm -rf "$CONFDIR"/cache/*; exit 1; }
            ;;
        DIRECT)
            cd "$CONFDIR"/cache
            wget --read-timeout=30 --trust-server-names "$TARURI" || { echo "$(tput setaf 1)wget $TARURI failed; exiting...$(tput sgr0)"; rm -rf "$CONFDIR"/cache/*; exit 1; }
            ;;
    esac
    TARFILE="$(dir "$CONFDIR"/cache/*.tar*)"
    TARFILE="${TARFILE##*/}"
    NEW_TARFILE="$TARFILE"
}

tarcheckfunc () { # Check to make sure downloaded file is a tar and run relevant tar arguments for type of tar
    case $TARFILE in
        *tar.gz)
            tar -xvzf "$CONFDIR"/cache/"$TARFILE" || { echo "$(tput setaf 1)tar $TARFILE failed; exiting...$(tput sgr0)"; rm -rf "$CONFDIR"/cache/*; exit 1; }
            ;;
        *tar.bz2|*tar.tbz|*tar.tb2|*tar|*tar.xz)
            tar -xvf "$CONFDIR"/cache/"$TARFILE" || { echo "$(tput setaf 1)tar $TARFILE failed; exiting...$(tput sgr0)"; rm -rf "$CONFDIR"/cache/*; exit 1; }
            ;;
        *)
            echo "$(tput setaf 1)Unknown file type!$(tput sgr0)"
            rm -rf "$CONFDIR"/cache/*
            exit 1
            ;;
    esac
}

checktarversionfunc () { # Use info from githubinfo function or using wget -S --spider for redirecting links
    . "$CONFDIR"/tarinstalled/"$TARPKG"
    if [ "$TAR_DOWNLOAD_SOURCE" = "GITHUB" ]; then
        if [ "$GITHUB_DOWNLOAD_ERROR" = "TRUE" ]; then
            TAR_NEW_UPGRADE="FALSE"
            GITHUB_DOWNLOAD_ERROR="FALSE"
        elif [ "$TAR_FORCE_UPGRADE" = "TRUE" ]; then
            TAR_NEW_UPGRADE="TRUE"
            TAR_FORCE_UPGRADE="FALSE"
        elif [ $TAR_GITHUB_COMMIT != $TAR_GITHUB_NEW_COMMIT ]; then
            TAR_NEW_UPGRADE="TRUE"
        else
            TAR_NEW_UPGRADE="FALSE"
        fi
    else
        wget -S --read-timeout=30 --spider "$TARURI" -o "$CONFDIR"/cache/"$TARPKG".latest
        NEW_TARURI="$(grep -o "Location:.*" "$CONFDIR"/cache/"$TARPKG".latest | cut -f2 -d" ")"
        NEW_TARFILE="${NEW_TARURI##*/}"
        if [ "$TAR_FORCE_UPGRADE" = "TRUE" ]; then
            TAR_NEW_UPGRADE="TRUE"
            TAR_FORCE_UPGRADE="FALSE"
        elif [[ "$NEW_TARFILE" != "$TARFILE" ]]; then
            TAR_NEW_UPGRADE="TRUE"
        elif [ "$RENAMED" = "TRUE" ] && [ -d /opt/"$OLD_NAME" ]; then
            TAR_NEW_UPGRADE="TRUE"
            RENAMED=""
        else
            TAR_NEW_UPGRADE="FALSE"
        fi
    fi
    if [ -z "$NEW_TARFILE" ] && [ -z "$NEW_COMMIT" ] && [ "$TAR_FORCE_UPGRADE" = "FALSE" ]; then
        echo "$(tput setaf 1)Error checking new version for $TARPKG!$(tput sgr0)"
        TAR_NEW_UPGRADE="FALSE"
    fi
}

tarupdateforcefunc () { # Mark specified tar package for upgrade without checking version
    if [ -f "$CONFDIR"/tarinstalled/"$TARPKG" ]; then
        . "$CONFDIR"/tarinstalled/"$TARPKG"
        echo "$(tput bold)$(tput setaf 6)Info$(tput sgr0):  $TAR_DESCRIPTION"
        echo "$(tput bold)$(tput setaf 6)Deps$(tput sgr0):  $DEPENDENCIES"
        if [ -z "$TAR_GITHUB_COMMIT" ]; then
            echo "$(tput bold)$(tput setaf 6)Version$(tput sgr0):  $TARFILE"
        else
            echo "$(tput bold)$(tput setaf 6)Version$(tput sgr0):  $TAR_GITHUB_COMMIT"
        fi
        echo "$(tput bold)$(tput setaf 6)Total DLs$(tput sgr0):  $TAR_DOWNLOADS"
        echo "$(tput bold)$(tput setaf 6)URL$(tput sgr0):  $TARURI"
        echo "$(tput bold)$(tput setaf 6)Size$(tput sgr0):  $TAR_SIZE"
        echo "$(tput bold)$(tput setaf 6)Install dir$(tput sgr0):  $INSTDIR"
        echo "$(tput bold)$(tput setaf 6)Bin path$(tput sgr0):  $BIN_PATH"
        echo
    else
        echo "$(tput setaf 1)Package not found!$(tput sgr0)"
        rm -rf "$CONFDIR"/cache/*
        exit 1
    fi
    . "$CONFDIR"/tarinstalled/"$TARPKG"
    if [ ! -z "$DOWNLOAD_SOURCE" ]; then
        TAR_DOWNLOAD_SOURCE="$DOWNLOAD_SOURCE"
    fi
    NEW_TARFILE="$TARFILE"
    TAR_GITHUB_NEW_COMMIT="$TAR_GITHUB_COMMIT"
    TAR_GITHUB_NEW_DOWNLOAD="$TAR_GITHUB_DOWNLOAD"
    TAR_GITHUB_NEW_VERSION="$TAR_GITHUB_VERSION"
    echo "Marking $(tput setaf 6)$TARPKG$(tput sgr0) for upgrade by force..."
    echo "$(tput setaf 6)New upgrade available for $TARPKG!$(tput sgr0)"
    tarsaveconffunc "tarupgrades/$TARPKG"
}

tarupgradecheckallfunc () { # Run a for loop to check all installed tar packages for upgrades
    for package in $(dir -C -w 1 "$CONFDIR"/tarinstalled); do
        TARPKG="$package"
        echo "Checking $(tput setaf 6)$package$(tput sgr0) version..."
        tarappcheckfunc "$package"
        checktarversionfunc
        if [ "$TAR_NEW_UPGRADE" = "TRUE" ]; then
            echo "$(tput setaf 6)$(tput bold)New upgrade available for $package -- $NEW_TARFILE !$(tput sgr0)"
            tarsaveconffunc "tarupgrades/$package"
        fi
    done
}

tarupgradecheckfunc () { # Check specified tar package for upgrade
    if ! echo "$TAR_LIST" | grep -qow "$1"; then
        echo "$(tput setaf 1)$1 is not in tar-pkgs.json; try running 'spm update'.$(tput sgr0)"
    else
        TARPKG="$1"
        echo "Checking $(tput setaf 6)$TARPKG$(tput sgr0) version..."
        tarappcheckfunc "$TARPKG"
        checktarversionfunc
        if [ "$TAR_NEW_UPGRADE" = "TRUE" ]; then
            echo "$(tput setaf 6)New upgrade available for $TARPKG -- $NEW_TARFILE !$(tput sgr0)"
            tarsaveconffunc "tarupgrades/$TARPKG"
        else
            echo "No new upgrade for $(tput setaf 6)$TARPKG$(tput sgr0)"
        fi
    fi
}

tarupdatelistfunc () { # Download tar-pkgs.json from github repo and run relevant upgradecheck function based on input
    echo "Downloading tar-pkgs.json from spm github repo..."
    rm "$CONFDIR"/tar-pkgs.json
    wget "https://raw.githubusercontent.com/simoniz0r/spm/master/tar-pkgs.json" -qO "$CONFDIR"/tar-pkgs.json
    echo "tar-pkgs.json updated!"
    if [ -z "$1" ]; then
        tarupgradecheckallfunc
    else
        tarupgradecheckfunc "$1"
    fi
}

tardesktopfilefunc () { # Download .desktop files for tar packages that do not include them from spm's github repo
    echo "Downloading $TARPKG.desktop from spm github repo..."
    wget --quiet "https://raw.githubusercontent.com/simoniz0r/spm/master/apps/$TARPKG/$TARPKG.desktop" -O "$CONFDIR"/cache/"$TARPKG".desktop  || { echo "wget $TARURI failed; exiting..."; rm -rf "$CONFDIR"/cache/*; exit 1; }
    echo "Moving $TARPKG.desktop to $INSTDIR ..."
    sudo mv "$CONFDIR"/cache/"$TARPKG".desktop "$INSTDIR"/"$TARPKG".desktop
    DESKTOP_FILE_PATH="$INSTDIR/$TARPKG.desktop"
    DESKTOP_FILE_NAME="$TARPKG.desktop"
}

tarinstallfunc () { # Move extracted tar from $CONFDIR/cache to /opt/PackageName, create symlinks for .desktop and bin files, and save config file for spm to keep track of it
    echo "Moving files to $INSTDIR..."
    EXTRACTED_DIR_NAME="$(ls -d "$CONFDIR"/cache/*/)"
    sudo mv "$EXTRACTED_DIR_NAME" "$INSTDIR" || { echo "Failed!"; rm -rf "$CONFDIR"/cache/*; exit 1; }
    DESKTOP_FILE_NAME="$(basename "$DESKTOP_FILE_PATH")"
    ICON_FILE_NAME="$(basename "$ICON_FILE_PATH")"
    EXECUTABLE_FILE_NAME="$(basename "$EXECUTABLE_FILE_PATH")"
    echo "Creating symlink for $EXECUTABLE_FILE_PATH to /usr/local/bin/$TARPKG ..."
    sudo ln -s "$EXECUTABLE_FILE_PATH" /usr/local/bin/"$TARPKG"
    echo "Creating symlink for $TARPKG.desktop to /usr/share/applications/ ..."
    case $DESKTOP_FILE_PATH in
        DOWNLOAD)
            tardesktopfilefunc "$TARPKG"
            sudo ln -s "$DESKTOP_FILE_PATH" /usr/share/applications/"$DESKTOP_FILE_NAME"
            ;;
        *NONE*)
            echo "Skipping .desktop file..."
            ;;
        *)
            sudo sed -i "s:Exec=.*:Exec="$EXECUTABLE_FILE_PATH":g" "$DESKTOP_FILE_PATH"
            sudo sed -i "s:Icon=.*:Icon="$ICON_FILE_PATH":g" "$DESKTOP_FILE_PATH"
            sudo ln -s "$DESKTOP_FILE_PATH" /usr/share/applications/"$DESKTOP_FILE_NAME"
            ;;
    esac
    echo "Creating config file for $(tput setaf 6)$TARPKG$(tput sgr0)..."
    tarsaveconffunc "tarinstalled/$TARPKG"
    echo "$(tput setaf 6)$TARPKG$(tput sgr0) has been installed to $INSTDIR !"
}

tarinstallstartfunc () { # Check to make sure another command by the same name is not on the system, tar package is in tar-pkgs.list, and tar package is not already installed
    if [ -f "$CONFDIR"/tarinstalled/"$TARPKG" ] || [ -f "$CONFDIR"/appimginstalled/"$TARPKG" ]; then # Exit if already installed by spm
        echo "$(tput setaf 1)$TARPKG is already installed."
        echo "Use 'spm upgrade' to install the latest version of $TARPKG.$(tput sgr0)"
        rm -rf "$CONFDIR"/cache/*
        exit 1
    fi
    if type >/dev/null 2>&1 "$TARPKG"; then
        echo "$(tput setaf 1)$TARPKG is already installed and not managed by spm; exiting...$(tput sgr0)"
        rm -rf "$CONFDIR"/cache/*
        exit 1
    fi
    if [ -d "/opt/$TARPKG" ]; then
        echo "$(tput setaf 1)/opt/$TARPKG exists; spm cannot install to existing directories!$(tput sgr0)"
        rm -rf "$CONFDIR"/cache/*
        exit 1
    fi
    tarappcheckfunc "$TARPKG"
    if [ "$KNOWN_TAR" = "FALSE" ];then
        echo "$(tput setaf 1)$TARPKG is not in tar-pkgs.json; try running 'spm update' to update tar-pkgs.json$(tput sgr0)."
        rm -rf "$CONFDIR"/cache/*
        exit 1
    else
        echo "tar package: $TARFILE"
        echo "$(tput setaf 6)$TARPKG$(tput sgr0) will be installed."
        read -p "Continue? Y/N " INSTANSWER
        case $INSTANSWER in
            N*|n*)
                echo "$(tput setaf 1)$TARPKG was not installed.$(tput sgr0)"
                rm -rf "$CONFDIR"/cache/*
                exit 0
                ;;
        esac
    fi
}

tarupgradefunc () { # Move new extracted tar from $CONFDIR/cache to /opt/PackageName and save new config file for it
    echo "Would you like to do a clean upgrade (remove all files in /opt/$TARPKG before installing) or an overwrite upgrade?"
    echo "Note: If you are using Discord with client modifications, it is recommended that you do a clean upgrade."
    read -p "Choice? Clean/Overwrite " PKGUPGDMETHODANSWER
    case $PKGUPGDMETHODANSWER in
        Clean|clean)
            echo "$(tput setaf 6)$TARPKG$(tput sgr0) will be upgraded to $TARFILE."
            echo "Removing files in $INSTDIR..."
            sudo rm -rf "$INSTDIR" || { echo "Failed!"; rm -rf "$CONFDIR"/cache/*; exit 1; }
            echo "Moving files to $INSTDIR..."
            EXTRACTED_DIR_NAME="$(ls -d "$CONFDIR"/cache/*/)"
            sudo mv "$EXTRACTED_DIR_NAME" "$INSTDIR"
            ;;
        Overwrite|overwrite)
            echo "$(tput setaf 6)$TARPKG$(tput sgr0) will be upgraded to $TARFILE."
            echo "Copying files to $INSTDIR..."
            EXTRACTED_DIR_NAME="$(ls -d "$CONFDIR"/cache/*/)"
            sudo cp -r "$EXTRACTED_DIR_NAME"/* "$INSTDIR"/ || { echo "Failed!"; rm -rf "$CONFDIR"/cache/*; exit 1; }
            ;;
        *)
            echo "$(tput setaf 1)Invalid choice; $(tput setaf 1)$TARPKG was not upgraded.$(tput sgr0)"
            rm -rf "$CONFDIR"/cache/*
            exit 1
            ;;
    esac
    case $DESKTOP_FILE_PATH in
        DOWNLOAD)
            tardesktopfilefunc "$TARPKG"
            sudo ln -sf "$DESKTOP_FILE_PATH" /usr/share/applications/"$DESKTOP_FILE_NAME"
            ;;
        *NONE*)
            echo "Skipping .desktop file..."
            ;;
        *)
            sudo sed -i "s:Exec=.*:Exec="$EXECUTABLE_FILE_PATH":g" "$DESKTOP_FILE_PATH"
            sudo sed -i "s:Icon=.*:Icon="$ICON_FILE_PATH":g" "$DESKTOP_FILE_PATH"
            sudo ln -sf "$DESKTOP_FILE_PATH" /usr/share/applications/"$DESKTOP_FILE_NAME"
            ;;
    esac
    echo "Creating config file for $(tput setaf 6)$TARPKG$(tput sgr0)..."
    tarsaveconffunc "tarinstalled/$TARPKG"
    echo "$(tput setaf 6)$TARPKG$(tput sgr0) has been upgraded to version $TARFILE!"
}

tarupgradestartallfunc () { # Run upgrades on all available tar packages
    if [ "$TARUPGRADES" = "FALSE" ]; then
        sleep 0
    else
        if [ "$(dir "$CONFDIR"/tarupgrades | wc -l)" = "1" ]; then
            echo "$(tput setaf 6)$(dir -C -w 1 "$CONFDIR"/tarupgrades | wc -l) new tar package upgrade available.$(tput sgr0)"
        else
            echo "$(tput setaf 6)$(dir -C -w 1 "$CONFDIR"/tarupgrades | wc -l) new tar package upgrades available.$(tput sgr0)"
        fi
        dir -C -w 1 "$CONFDIR"/tarupgrades | pr -tT --column=3 -w 125
        echo
        read -p "Continue? Y/N " UPGRADEALLANSWER
        case $UPGRADEALLANSWER in
            Y*|y*)
                for UPGRADE_PKG in $(dir -C -w 1 "$CONFDIR"/tarupgrades); do
                    TARPKG="$UPGRADE_PKG"
                    echo "Downloading $(tput setaf 6)$TARPKG$(tput sgr0)..."
                    tarappcheckfunc "$TARPKG"
                    if [ "$TAR_DOWNLOAD_SOURCE" = "GITHUB" ]; then
                        targithubinfofunc
                    fi
                    tardlfunc "$TARPKG"
                    tarcheckfunc
                    tarupgradefunc
                    rm "$CONFDIR"/tarupgrades/"$TARPKG"
                    rm -rf "$CONFDIR"/cache/*
                    echo
                done
                ;;
            N*|n*)
                echo "$(tput setaf 1)No packages were upgraded; exiting...$(tput sgr0)"
                rm -rf "$CONFDIR"/cache/*
                exit 0
                ;;
        esac
    fi
}

tarupgradestartfunc () { # Run upgrade on specified tar package
    echo "$(tput setaf 6)$TARPKG$(tput sgr0) will be upgraded to the latest version."
    read -p "Continue? Y/N " UPGRADEANSWER
    case $UPGRADEANSWER in
        Y*|y*)
            tarappcheckfunc "$TARPKG"
            if [ "$TAR_DOWNLOAD_SOURCE" = "GITHUB" ]; then
                targithubinfofunc
            fi
            tardlfunc "$TARPKG"
            tarcheckfunc
            tarupgradefunc
            rm "$CONFDIR"/tarupgrades/"$TARPKG"
            ;;
        N*|n*)
            echo "$(tput setaf 1)$TARPKG was not upgraded.$(tput sgr0)"
            ;;
    esac
}

tarremovefunc () { # Remove tar package, .desktop and bin files, and remove config file spm used to keep track of it
    . "$CONFDIR"/tarinstalled/"$REMPKG"
    echo "Removing $(tput setaf 6)$REMPKG$(tput sgr0)..."
    echo "All files in $INSTDIR will be removed!"
    read -p "Continue? Y/N " PKGREMANSWER
    case $PKGREMANSWER in
        N*|n*)
            echo "$(tput setaf 1)$REMPKG was not removed.$(tput sgr0)"
            rm -rf "$CONFDIR"/cache/*
            exit 0
            ;;
    esac
    if [ -f "$CONFDIR"/tarupgrades/$REMPKG ]; then
        rm "$CONFDIR"/tarupgrades/"$REMPKG"
    fi
    DESKTOP_FILE_NAME="$(basename "$DESKTOP_FILE_PATH")"
    ICON_FILE_NAME="$(basename "$ICON_FILE_PATH")"
    EXECUTABLE_FILE_NAME="$(basename "$EXECUTABLE_FILE_PATH")"
    echo "Removing $INSTDIR..."
    sudo rm -rf "$INSTDIR" || { echo "Failed!"; rm -rf "$CONFDIR"/cache/*; exit 1; }
    echo "Removing symlinks..."
    case $DESKTOP_FILE_PATH in
        NONE)
            echo "Skipping .desktop file..."
            ;;
        *)
            sudo rm /usr/share/applications/"$DESKTOP_FILE_NAME"
            ;;
    esac
    sudo rm /usr/local/bin/"$REMPKG"
    rm "$CONFDIR"/tarinstalled/"$REMPKG"
    echo "$(tput setaf 6)$REMPKG$(tput sgr0) has been removed!"
}

tarremovepurgefunc () { # Remove tar package, .desktop and bin files, package's config dir if listed in tar-pkgs.json, and remove config file spm used to keep track of it
    . "$CONFDIR"/tarinstalled/"$PURGEPKG"
    echo "Removing $(tput setaf 6)$PURGEPKG$(tput sgr0)..."
    echo "All files in $INSTDIR and $CONFIG_PATH will be removed!"
    read -p "Continue? Y/N " PKGREMANSWER
    case $PKGREMANSWER in
        N*|n*)
            echo "$(tput setaf 1)$PURGE was not removed.$(tput sgr0)"
            rm -rf "$CONFDIR"/cache/*
            exit 0
            ;;
    esac
    if [ -f "$CONFDIR"/tarupgrades/$PURGEPKG ]; then
        rm "$CONFDIR"/tarupgrades/"$PURGEPKG"
    fi
    DESKTOP_FILE_NAME="$(basename "$DESKTOP_FILE_PATH")"
    ICON_FILE_NAME="$(basename "$ICON_FILE_PATH")"
    EXECUTABLE_FILE_NAME="$(basename "$EXECUTABLE_FILE_PATH")"
    echo "Removing $INSTDIR..."
    sudo rm -rf "$INSTDIR" || { echo "Failed!"; rm -rf "$CONFDIR"/cache/*; exit 1; }
    echo "Removing symlinks..."
    case $DESKTOP_FILE_PATH in
        NONE)
            echo "Skipping .desktop file..."
            ;;
        *)
            sudo rm /usr/share/applications/"$DESKTOP_FILE_NAME"
            ;;
    esac
    sudo rm /usr/local/bin/"$PURGEPKG"
    echo "Removing $CONFIG_PATH..."
    if [ ! -z "$CONFIG_PATH" ]; then
        rm -rf "$CONFIG_PATH"
    else
        echo "No config path specified; skipping..."
    fi
    rm "$CONFDIR"/tarinstalled/"$PURGEPKG"
    echo "$(tput setaf 6)$PURGEPKG$(tput sgr0) has been removed!"
}
