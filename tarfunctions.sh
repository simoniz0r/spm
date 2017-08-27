#!/bin/bash
# Title: spm
# Description: Excracts and moves tar archives to /opt/ and creates symlinks for their .desktop files.  Can also upgrade and remove installed tar packages.
# Dependencies: GNU coreutils, tar, wget, python3.x
# Author: simonizor
# Website: http://www.simonizor.gq
# License: GPL v2.0 only

X="0.0.8"
# Set spm version
TAR_LIST="$(cat $CONFDIR/tar-pkgs.json | python3 -c "import sys, json; data = json.load(sys.stdin); print (data['available'])")" #  | pr -tTw 125 -3

tarfunctionsexistfunc () {
    sleep 0
}

tarsaveconffunc () {
    if [ -z "$NEW_TARFILE" ]; then
        NEW_TARFILE="$TARFILE"
    fi
    SAVEDIR="$1"
    echo "INSTDIR="\"$INSTDIR\""" > "$CONFDIR"/"$SAVEDIR"
    if [ "$TAR_DOWNLOAD_SOURCE" != "LOCAL" ]; then
        echo "TAR_DOWNLOAD_SOURCE="\"$TAR_DOWNLOAD_SOURCE\""" >> "$CONFDIR"/"$SAVEDIR"
        echo "TARURI="\"$TARURI\""" >> "$CONFDIR"/"$SAVEDIR"
        echo "TARFILE="\"$NEW_TARFILE\""" >> "$CONFDIR"/"$SAVEDIR"
    fi
    if [ "$TAR_DOWNLOAD_SOURCE" = "GITHUB" ]; then
        echo "TAR_GITHUB_COMMIT="\"$TAR_GITHUB_NEW_COMMIT\""" >> "$CONFDIR"/"$SAVEDIR"
        echo "TAR_GITHUB_DOWNLOAD="\"$TAR_GITHUB_NEW_DOWNLOAD\""" >> "$CONFDIR"/"$SAVEDIR"
        echo "TAR_GITHUB_VERSION="\"$TAR_GITHUB_NEW_VERSION\""" >> "$CONFDIR"/"$SAVEDIR"
    fi
    echo "DESKTOP_FILE_PATH="\"$DESKTOP_FILE_PATH\""" >> "$CONFDIR"/"$SAVEDIR"
    echo "ICON_FILE_PATH="\"$ICON_FILE_PATH\""" >> "$CONFDIR"/"$SAVEDIR"
    echo "EXECUTABLE_FILE_PATH="\"$EXECUTABLE_FILE_PATH\""" >> "$CONFDIR"/"$SAVEDIR"
    echo "CONFIG_PATH="\"$CONFIG_PATH\""" >> "$CONFDIR"/"$SAVEDIR"
    echo "TAR_DESCRIPTION="\"$TAR_DESCRIPTION\""" >> "$CONFDIR"/"$SAVEDIR"
    echo "DEPENDENCIES="\"$DEPENDENCIES\""" >> "$CONFDIR"/"$SAVEDIR"
}

targithubinfofunc () {
    TAR_LATEST_RELEASE="$(wget --quiet "$TARURI" -O - | grep -i -m 1 '.*/download/*..*.tar*.' | cut -f2 -d'"' | sed 's:download:tag:g;' | cut -f-6 -d"/")"
    wget --quiet "https://www.github.com/$TAR_LATEST_RELEASE" -O "$CONFDIR"/cache/"$TARPKG".latest
    TAR_GITHUB_NEW_DOWNLOAD="$(grep -i -m 1 '.*/download/*..*linux*..*64*..*tar*.' "$CONFDIR"/cache/"$TARPKG".latest | cut -f2 -d'"')"
    TAR_GITHUB_NEW_COMMIT="$(grep '.*/commit//*.' "$CONFDIR"/cache/"$TARPKG".latest | cut -f5 -d"/" | tr -d '>"')"
    TAR_GITHUB_NEW_VERSION="$(grep -i -m 1 '.*/download/*..*linux*..*64*..*tar*.' "$CONFDIR"/cache/"$TARPKG".latest | cut -f2 -d'"' | cut -f6 -d"/")"
    TAR_DOWNLOAD_SOURCE="GITHUB"
    tarsaveconffunc "cache/$TARPKG.conf"
    . "$CONFDIR"/cache/"$TARPKG".conf
    if [ -z "$TAR_GITHUB_NEW_DOWNLOAD" ]; then
        TAR_GITHUB_NEW_DOWNLOAD="$(grep -i -m 1 '.*/download/*..*linux*..*tar*.' "$CONFDIR"/cache/"$TARPKG".latest | cut -f2 -d'"')"
        TAR_GITHUB_NEW_COMMIT="$(grep '.*/commit//*.' "$CONFDIR"/cache/"$TARPKG".latest | cut -f5 -d"/" | tr -d '>"')"
        TAR_GITHUB_NEW_VERSION="$(grep -i -m 1 '.*/download/*..*linux*..*tar*.' "$CONFDIR"/cache/"$TARPKG".latest | cut -f2 -d'"' | cut -f6 -d"/")"
        TAR_DOWNLOAD_SOURCE="GITHUB"
        tarsaveconffunc "cache/$TARPKG.conf"
        . "$CONFDIR"/cache/"$TARPKG".conf
    fi
    if [ -z "$TAR_GITHUB_NEW_DOWNLOAD" ]; then
        TAR_GITHUB_NEW_DOWNLOAD="$(grep -i -m 1 '.*/download/*..*64*..*tar*.' "$CONFDIR"/cache/"$TARPKG".latest | cut -f2 -d'"')"
        TAR_GITHUB_NEW_COMMIT="$(grep '.*/commit//*.' "$CONFDIR"/cache/"$TARPKG".latest | cut -f5 -d"/" | tr -d '>"')"
        TAR_GITHUB_NEW_VERSION="$(grep -i -m 1 '.*/download/*..*64*..*tar*.' "$CONFDIR"/cache/"$TARPKG".latest | cut -f2 -d'"' | cut -f6 -d"/")"
        TAR_DOWNLOAD_SOURCE="GITHUB"
        tarsaveconffunc "cache/$TARPKG.conf"
        . "$CONFDIR"/cache/"$TARPKG".conf
    fi
    if [ -z "$TAR_GITHUB_NEW_DOWNLOAD" ]; then
        TAR_GITHUB_NEW_DOWNLOAD="$(grep -v '.*ia32*.'  "$CONFDIR"/cache/"$TARPKG".latest | grep -i -m 1 '.*/download/*..*.tar*.' | cut -f2 -d'"')"
        TAR_GITHUB_NEW_COMMIT="$(grep -v '.*ia32*.'  "$CONFDIR"/cache/"$TARPKG".latest | grep '.*/commit//*.' | cut -f5 -d"/" | tr -d '>"')"
        TAR_GITHUB_NEW_VERSION="$(grep -v '.*ia32*.'  "$CONFDIR"/cache/"$TARPKG".latest | grep -i -m 1 '.*/download/*..*.tar*.' | cut -f2 -d'"' | cut -f6 -d"/")"
        TAR_DOWNLOAD_SOURCE="GITHUB"
        tarsaveconffunc "cache/$TARPKG.conf"
        . "$CONFDIR"/cache/"$TARPKG".conf
    fi
    NEW_TARFILE="${TAR_GITHUB_NEW_DOWNLOAD##*/}"
    if [ -z "$TAR_GITHUB_NEW_DOWNLOAD" ]; then
        echo "$(tput setaf 1)Error finding latest tar for $TARPKG!$(tput sgr0)"
        GITHUB_DOWNLOAD_ERROR="TRUE"
    fi
}

tarcustominfofunc () {
    INSTDIR="/opt/$TARPKG"
    echo "Input the path to the desktop file."
    echo "If you do not want an entry added to your menu, enter 'NONE'"
    echo "If the tar archive does not include a .desktop file, enter 'create' to have spm generate a .desktop file."
    read -p "$INSTDIR/" DESKTOP_FILE_PATH
    if [ "${DESKTOP_FILE_PATH:-1}" = "/" ]; then
        DESKTOP_FILE_PATH="${DESKTOP_FILE_PATH::-1}"
    fi
    echo
    DESKTOP_FILE_PATH="$INSTDIR/$DESKTOP_FILE_PATH"
    DESKTOP_FILE_NAME="$(basename "$DESKTOP_FILE_PATH")"
    read -p "Input the path to the icon file: $INSTDIR/" ICON_FILE_PATH
    if [ "${ICON_FILE_PATH:-1}" = "/" ]; then
        ICON_FILE_PATH="${ICON_FILE_PATH::-1}"
    fi
    echo
    ICON_FILE_PATH="$INSTDIR/$ICON_FILE_PATH"
    ICON_FILE_NAME="$(basename "$ICON_FILE_PATH")"
    read -p "Input the path to the executable file: $INSTDIR/" EXECUTABLE_FILE_PATH
    if [ "${EXECUTABLE_FILE_PATH:-1}" = "/" ]; then
        EXECUTABLE_FILE_PATH="${EXECUTABLE_FILE_PATH::-1}"
    fi
    echo
    EXECUTABLE_FILE_PATH="$INSTDIR/$EXECUTABLE_FILE_PATH"
    EXECUTABLE_FILE_NAME="$(basename "$EXECUTABLE_FILE_PATH")"
    echo
    echo "Input the config directory for $TARPKG. If you don't know the path, you can leave this field blank."
    read -p "Ex: ~/.config/$TARPKG " CONFIG_PATH
    if [ "${CONFIG_PATH:-1}" = "/" ]; then
        CONFIG_PATH="${CONFIG_PATH::-1}"
    fi
    echo
}

tarappcheckfunc () { # check user input against list of known apps here
    echo "$TAR_LIST" | grep -qiw "$1"
    TAR_STATUS="$?"
    case $TAR_STATUS in
        0)
            KNOWN_TAR="TRUE"
            TARPKG_NAME="$1"
            INSTDIR="$(cat $CONFDIR/tar-pkgs.json | python3 $RUNNING_DIR/jsonparse.py $1 instdir)"
            TAR_DOWNLOAD_SOURCE="$(cat $CONFDIR/tar-pkgs.json | python3 $RUNNING_DIR/jsonparse.py $1 download_source)"
            TARURI="$(cat $CONFDIR/tar-pkgs.json | python3 $RUNNING_DIR/jsonparse.py $1 taruri)"
            DESKTOP_FILE_PATH="$(cat $CONFDIR/tar-pkgs.json | python3 $RUNNING_DIR/jsonparse.py $1 desktop_file_path)"
            ICON_FILE_PATH="$(cat $CONFDIR/tar-pkgs.json | python3 $RUNNING_DIR/jsonparse.py $1 icon_file_path)"
            EXECUTABLE_FILE_PATH="$(cat $CONFDIR/tar-pkgs.json | python3 $RUNNING_DIR/jsonparse.py $1 executable_file_path)"
            BIN_PATH="$(cat $CONFDIR/tar-pkgs.json | python3 $RUNNING_DIR/jsonparse.py $1 instdir)"
            CONFIG_PATH="$(cat $CONFDIR/tar-pkgs.json | python3 $RUNNING_DIR/jsonparse.py $1 config_path)"
            TAR_DESCRIPTION="$(cat $CONFDIR/tar-pkgs.json | python3 $RUNNING_DIR/jsonparse.py $1 description)"
            DEPENDENCIES="$(cat $CONFDIR/tar-pkgs.json | python3 $RUNNING_DIR/jsonparse.py $1 dependencies)"
            if [ "$TAR_DOWNLOAD_SOURCE" = "GITHUB" ]; then
                targithubinfofunc
            fi
            ;;
        *)
            if [ -f "$CONFDIR"/tarinstalled/$1 ]; then
                . "$CONFDIR"/tarinstalled/$1
            fi
            KNOWN_TAR="FALSE"
            ;;
    esac
}

tarlistfunc () {
    if [ -z "$LISTPKG" ]; then
        echo "$(dir "$CONFDIR"/tarinstalled | wc -w) installed tar packages:"
        dir -C -w 1 "$CONFDIR"/tarinstalled | pr -tT --column=3 -w 125
        echo
        echo "$(echo "$TAR_LIST" | wc -l) tar packages for install:"
        echo "$TAR_LIST" | pr -tTw 125 -3
    else
        if [ -f "$CONFDIR"/tarinstalled/"$LISTPKG" ]; then
            echo "Current installed $LISTPKG information:"
            cat "$CONFDIR"/tarinstalled/"$LISTPKG"
            echo "INSTALLED=\"YES\""
            echo "BIN_PATH=\"/usr/local/bin/$LISTPKG\""
        elif echo "$TAR_LIST" | grep -qiw "$LISTPKG"; then
            echo "$LISTPKG tar package information:"
            tarappcheckfunc "$LISTPKG"
            tarsaveconffunc "cache/$LISTPKG.conf"
            cat "$CONFDIR"/cache/"$LISTPKG".conf
            echo "INSTALLED=\"NO\""
        else
            echo "Package not found!"
            rm -rf "$CONFDIR"/cache/*
        fi
    fi
}

tarlistinstalledfunc () {
    echo "$(dir -C -w 1 "$CONFDIR"/tarinstalled | wc -l) tar packages installed:"
    dir -C -w 1 "$CONFDIR"/tarinstalled | pr -tT --column=3 -w 125
    echo
    for tarpkg in $(dir -C -w 1 "$CONFDIR"/tarinstalled); do
        echo "$tarpkg installed information:"
        cat "$CONFDIR"/tarinstalled/"$tarpkg"
        echo "INSTALLED=\"YES\""
        echo
    done
}

tarcustomdlfunc () {
    if [ -f "$CONFDIR"/tarinstalled/$1 ]; then
        . "$CONFDIR"/tarinstalled/$1
        cd "$CONFDIR"/cache
        wget --quiet --read-timeout=30 --show-progress --trust-server-names "$TARURI" || { echo "wget $TARURI failed; exiting..."; rm -rf "$CONFDIR"/cache/*; exit 1; }
        TARFILE="$(dir "$CONFDIR"/cache/*.tar*)"
        TARFILE="${TARFILE##*/}"
    else
        read -p "Input the source type for the download GITHUB/DIRECT/LOCAL " TAR_DOWNLOAD_SOURCE
        case $TAR_DOWNLOAD_SOURCE in
            github|Github|GITHUB)
                TAR_DOWNLOAD_SOURCE="GITHUB"
                ;;
            direct|Direct|DIRECT)
                TAR_DOWNLOAD_SOURCE="DIRECT"
                ;;
            local|Local|LOCAL)
                TAR_DOWNLOAD_SOURCE="LOCAL"
                ;;
        esac
        if [ "$TAR_DOWNLOAD_SOURCE" = "GITHUB" ]; then
            echo "Input the link to the latest releases page for $1"
            read -p "Ex: https://github.com/simoniz0r/spm/releases " TARURI
        else
            read -p "Input uri to tar archive : " TARURI
        fi
        echo
        case $TAR_DOWNLOAD_SOURCE in
            LOCAL)
                read -p "Input the path to the tar archive (Ex: /home/$USER/Downloads/archive.tar.gz): " TARFILE
                if [[ "$TARFILE" != /* ]]; then
                    echo "The path to the tar archive must be the full path; exiting..."
                    rm -rf "$CONFDIR"/cache/*
                    exit 1
                fi
                if [ "${TARFILE:-1}" = "/" ]; then
                    TARFILE="${TARFILE::-1}"
                fi
                ;;
            GITHUB)
                targithubinfofunc
                TARURI="https://github.com/$TAR_GITHUB_NEW_DOWNLOAD"
                cd "$CONFDIR"/cache
                wget --read-timeout=30 --quiet --show-progress "$TARURI" || { echo "wget $TARURI failed; exiting..."; rm -rf "$CONFDIR"/cache/*; exit 1; }
                TARFILE="$(dir "$CONFDIR"/cache/*.tar*)"
                TARFILE="${TARFILE##*/}"
                ;;
            DIRECT)
                cd "$CONFDIR"/cache
                wget --read-timeout=30 --quiet --show-progress "$TARURI" || { echo "wget $TARURI failed; exiting..."; rm -rf "$CONFDIR"/cache/*; exit 1; }
                TARFILE="$(dir "$CONFDIR"/cache/*.tar*)"
                TARFILE="${TARFILE##*/}"
                ;;
        esac
    fi
}

tardlfunc () {
    if [[ "$KNOWN_TAR" != "FALSE" ]]; then
        case $TAR_DOWNLOAD_SOURCE in
            GITHUB)
                TARURI="https://github.com/$TAR_GITHUB_NEW_DOWNLOAD"
                cd "$CONFDIR"/cache
                wget --quiet --read-timeout=30 --show-progress "$TARURI" || { echo "wget $TARURI failed; exiting..."; rm -rf "$CONFDIR"/cache/*; exit 1; }
                ;;
            DIRECT)
                cd "$CONFDIR"/cache
                wget --quiet --read-timeout=30 --show-progress --trust-server-names "$TARURI" || { echo "wget $TARURI failed; exiting..."; rm -rf "$CONFDIR"/cache/*; exit 1; }
                ;;
        esac
        TARFILE="$(dir "$CONFDIR"/cache/*.tar*)"
        TARFILE="${TARFILE##*/}"
        NEW_TARFILE="$TARFILE"
    else
        tarcustomdlfunc
    fi
}

tarcheckfunc () {
    case $TARFILE in
        *tar.gz)
            tar -xvzf "$CONFDIR"/cache/"$TARFILE" || { echo "tar $TARFILE failed; exiting..."; rm -rf "$CONFDIR"/cache/*; exit 1; }
            ;;
        *tar.bz2|*tar.tbz|*tar.tb2|*tar)
            tar -xvf "$CONFDIR"/cache/"$TARFILE" || { echo "tar $TARFILE failed; exiting..."; rm -rf "$CONFDIR"/cache/*; exit 1; }
            ;;
        *)
            echo "Unknown file type!"
            rm -rf "$CONFDIR"/cache/*
            exit 1
            ;;
    esac
}

checktarversionfunc () {
    . "$CONFDIR"/tarinstalled/"$TARPKG"
    if [ -f "$CONFDIR"/cache/"$TARPKG".conf ]; then
        . "$CONFDIR"/cache/"$TARPKG".conf
    fi
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

tarupdateforcefunc () {
    if [ -f "$CONFDIR"/tarinstalled/"$TARPKG" ]; then
        cat "$CONFDIR"/tarinstalled/"$TARPKG"
    else
        echo "Package not found!"
        rm -rf "$CONFDIR"/cache/*
        exit 1
    fi
    if [ -f "$CONFDIR"/tarupgrades/$TARPKG ]; then
        echo "$(tput setaf 2)$TARPKG is already marked for upgrade!"
        echo "Run 'spm upgrade $TARPKG' to upgrade $TARPKG$(tput sgr0)"
        rm -rf "$CONFDIR"/cache/*
        exit 0
    fi
    echo "Marking $TARPKG for upgrade by force..."
    TAR_FORCE_UPGRADE="TRUE"
    # tarappcheckfunc "$TARPKG"
    checktarversionfunc
    if [ "$TAR_NEW_UPGRADE" = "TRUE" ]; then
        echo "$(tput setaf 2)New upgrade available for $TARPKG!$(tput sgr0)"
        tarsaveconffunc "tarupgrades/$TARPKG"
    else
        echo "No new upgrade for $TARPKG"
    fi
}

tarupgradecheckallfunc () {
    for package in $(dir -C -w 1 "$CONFDIR"/tarinstalled); do
        TARPKG="$package"
        echo "Checking $package version..."
        tarappcheckfunc "$package"
        checktarversionfunc
        if [ "$TAR_NEW_UPGRADE" = "TRUE" ]; then
            echo "$(tput setaf 2)New upgrade available for $package -- $NEW_TARFILE !$(tput sgr0)"
            tarsaveconffunc "tarupgrades/$package"
        fi
    done
    echo
    if [ "$(dir "$CONFDIR"/tarupgrades | wc -l)" = "1" ]; then
        echo "$(tput setaf 2)$(dir -C -w 1 "$CONFDIR"/tarupgrades | wc -l) new tar package upgrade available.$(tput sgr0)"
    elif [ "$(dir "$CONFDIR"/tarupgrades | wc -l)" = "0" ]; then
        echo "No new tar package upgrades available."
    else
        echo "$(tput setaf 2)$(dir -C -w 1 "$CONFDIR"/tarupgrades | wc -l) new tar package upgrades available.$(tput sgr0)"
    fi
}

tarupgradecheckfunc () {
    if ! echo "$TAR_LIST" | grep -qiw "$LISTPKG"; then
        echo "$1 is not in tar-pkgs.json; try running 'spm update'."
    else
        TARPKG="$1"
        echo "Checking $TARPKG version..."
        tarappcheckfunc "$TARPKG"
        checktarversionfunc
        if [ "$TAR_NEW_UPGRADE" = "TRUE" ]; then
            echo "$(tput setaf 2)New upgrade available for $TARPKG -- $NEW_TARFILE !$(tput sgr0)"
            tarsaveconffunc "tarupgrades/$TARPKG"
        else
            echo "No new upgrade for $TARPKG"
        fi
    fi
}

tarupdatelistfunc () {
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

tardesktopfilefunc () {
    case $1 in
        create)
            echo "Creating .desktop file for $TARPKG ..."
            echo "[Desktop Entry]" > /tmp/"$TARPKG".desktop
            echo "Name=$TARPKG" >> /tmp/"$TARPKG".desktop
            echo "Comment="$TAR_DESCRIPTION"" >> /tmp/"$TARPKG".desktop
            echo "Exec=/usr/local/bin/$TARPKG" >> /tmp/"$TARPKG".desktop
            echo "Terminal=false" >> /tmp/"$TARPKG".desktop
            echo "Type=Application" >> /tmp/"$TARPKG".desktop
            echo "Icon=$ICON_FILE_PATH" >> /tmp/"$TARPKG".desktop
            echo "Categories=Utility;" >> /tmp/"$TARPKG".desktop
            sudo mv /tmp/"$TARPKG".desktop "$INSTDIR"/"$TARPKG".desktop
            DESKTOP_FILE_PATH="$INSTDIR/$TARPKG.desktop"
            DESKTOP_FILE_NAME="$TARPKG.desktop"
            ;;
        *)
            echo "Downloading $TARPKG.desktop from spm github repo..."
            wget "https://raw.githubusercontent.com/simoniz0r/tar-pkg/master/apps/$TARPKG/$TARPKG.desktop" --show-progress -qO "$CONFDIR"/cache/"$TARPKG".desktop  || { echo "wget $TARURI failed; exiting..."; rm -rf "$CONFDIR"/cache/*; exit 1; }
            echo "Moving $TARPKG.desktop to $INSTDIR ..."
            sudo mv "$CONFDIR"/cache/"$TARPKG".desktop "$INSTDIR"/"$TARPKG".desktop
            DESKTOP_FILE_PATH="$INSTDIR/$TARPKG.desktop"
            DESKTOP_FILE_NAME="$TARPKG.desktop"
            ;;
    esac
}

tarcustomappfunc () {
    echo "Moving files to $INSTDIR..."
    EXTRACTED_DIR_NAME="$(ls -d "$CONFDIR"/cache/*/)"
    sudo mv "$EXTRACTED_DIR_NAME" "$INSTDIR"
    echo "Creating symlink for $EXECUTABLE_FILE_PATH to /usr/local/bin/$TARPKG ..."
    sudo ln -s "$EXECUTABLE_FILE_PATH" /usr/local/bin/"$TARPKG"
    echo "Creating symlink for $TARPKG.desktop to /usr/share/applications/ ..."
    case $DESKTOP_FILE_NAME in
        *create|*Create)
            tardesktopfilefunc "create"
            sudo ln -s "$DESKTOP_FILE_PATH" /usr/share/applications/"$DESKTOP_FILE_NAME"
            ;;
        *NONE*)
            echo "Skipping .desktop file..."
            ;;
        *)
            sudo sed -i "s:Exec=.*:Exec=/usr/local/bin/$TARPKG:g" "$DESKTOP_FILE_PATH"
            sudo sed -i "s:Icon=.*:Icon="$ICON_FILE_PATH":g" "$DESKTOP_FILE_PATH"
            sudo ln -s "$DESKTOP_FILE_PATH" /usr/share/applications/"$DESKTOP_FILE_NAME"
            ;;
    esac
    echo "Creating config file for $TARPKG..."
    tarsaveconffunc "tarinstalled/$TARPKG"
    echo "$TARPKG has been installed to $INSTDIR !"
    rm -rf "$CONFDIR"/cache/*
    tarcustomappsubmitfunc
}

tarcustomappsubmitfunc () {
    read -p "Would you like to submit the config file for this app to the github repo for others to use (no personal data will be shared)? Y/N " CUSTOMAPPANSWER
    case $CUSTOMAPPANSWER in
        Y|y)
            cat "$CONFDIR"/tarinstalled/"$TARPKG"
            echo "Copy the file above and submit it as an issue to spm's github page"
            echo "https://github.com/simoniz0r/spm/issues/new"
            echo "Thanks for taking the time to contribute!"
            ;;
        *)
            echo "Install finished!"
            ;;
    esac
}

tarcustomstartfunc () {
    if [ -f "$CONFDIR"/tarinstalled/"$TARPKG" ]; then
        echo "$TARPKG is already installed."
        echo "Use 'spm upgrade' to install the latest version of $TARPKG."
        rm -rf "$CONFDIR"/cache/*
        exit 1
    fi
    if type >/dev/null 2>&1 "$TARPKG"; then
        echo "$TARPKG is already installed and not managed by spm; exiting..."
        rm -rf "$CONFDIR"/cache/*
        exit 1
    fi
    if [ -d "/opt/$TARPKG" ]; then
        echo "/opt/$TARPKG exists; spm cannot install to existing directories!"
        rm -rf "$CONFDIR"/cache/*
        exit 1
    fi
    tarappcheckfunc "$TARPKG"
    if [ "$KNOWN_TAR" = "FALSE" ];then
        echo "$TARPKG is not in tar-pkgs.json; You can try updating tar-pkgs.json or you can be guided through the custom install."
        read -p "Continue with custom install? Y/N " APPCHKINSTANSWER
        case $APPCHKINSTANSWER in
            N*|n*)
                echo "Exiting..."
                echo "Try running 'spm update' to update the tar-pkgs.json."
                rm -rf "$CONFDIR"/cache/*
                exit 0
                ;;
        esac
    else
        echo "$TARPKG is in tar-pkgs.json; use 'spm install $TARPKG'."
        rm -rf "$CONFDIR"/cache/*
        exit 1
    fi
}

tarinstallfunc () {
    echo "Moving files to $INSTDIR..."
    EXTRACTED_DIR_NAME="$(ls -d "$CONFDIR"/cache/*/)"
    sudo mv "$EXTRACTED_DIR_NAME" "$INSTDIR"
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
            sudo sed -i "s:Exec=.*:Exec=/usr/local/bin/$TARPKG:g" "$DESKTOP_FILE_PATH"
            sudo sed -i "s:Icon=.*:Icon="$ICON_FILE_PATH":g" "$DESKTOP_FILE_PATH"
            sudo ln -s "$DESKTOP_FILE_PATH" /usr/share/applications/"$DESKTOP_FILE_NAME"
            ;;
    esac
    echo "Creating config file for $TARPKG..."
    tarsaveconffunc "tarinstalled/$TARPKG"
    echo "$TARPKG has been installed to $INSTDIR !"
}

tarinstallstartfunc () {
    if [ -f "$CONFDIR"/tarinstalled/"$TARPKG" ]; then
        echo "$TARPKG is already installed."
        echo "Use 'spm upgrade' to install the latest version of $TARPKG."
        rm -rf "$CONFDIR"/cache/*
        exit 1
    fi
    if type >/dev/null 2>&1 "$TARPKG"; then
        echo "$TARPKG is already installed and not managed by spm; exiting..."
        rm -rf "$CONFDIR"/cache/*
        exit 1
    fi
    if [ -d "/opt/$TARPKG" ]; then
        echo "/opt/$TARPKG exists; spm cannot install to existing directories!"
        rm -rf "$CONFDIR"/cache/*
        exit 1
    fi
    tarappcheckfunc "$TARPKG"
    if [ "$KNOWN_TAR" = "FALSE" ];then
        echo "$TARPKG is not in tar-pkgs.json; You can try updating tar-pkgs.json or run 'spm tar-custom'."
        rm -rf "$CONFDIR"/cache/*
        exit 1
    else
        cat "$CONFDIR"/cache/"$TARPKG".conf
        echo
        echo "$TARPKG will be installed to /opt/$TARPKG"
        read -p "Continue? Y/N " INSTANSWER
        case $INSTANSWER in
            N*|n*)
                echo "$TARPKG was not installed."
                rm -rf "$CONFDIR"/cache/*
                exit 0
                ;;
        esac
    fi
}

tarupgradefunc () {
    echo "Would you like to do a clean upgrade (remove all files in /opt/$TARPKG before installing) or an overwrite upgrade?"
    echo "Note: If you are using Discord with client modifications, it is recommended that you do a clean upgrade."
    read -p "Choice? Clean/Overwrite " PKGUPGDMETHODANSWER
    case $PKGUPGDMETHODANSWER in
        Clean|clean)
            echo "$TARPKG will be upgraded to $TARFILE."
            echo "Removing files in $INSTDIR..."
            sudo rm -rf "$INSTDIR"
            echo "Moving files to $INSTDIR..."
            EXTRACTED_DIR_NAME="$(ls -d "$CONFDIR"/cache/*/)"
            sudo mv "$EXTRACTED_DIR_NAME" "$INSTDIR"
            ;;
        Overwrite|overwrite)
            echo "$TARPKG will be upgraded to $TARFILE."
            echo "Copying files to $INSTDIR..."
            EXTRACTED_DIR_NAME="$(ls -d "$CONFDIR"/cache/*/)"
            sudo cp -r "$EXTRACTED_DIR_NAME"/* "$INSTDIR"/
            ;;
        *)
            echo "Invalid choice; $TARPKG was not upgraded."
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
            sudo sed -i "s:Exec=.*:Exec=/usr/local/bin/$TARPKG:g" "$DESKTOP_FILE_PATH"
            sudo sed -i "s:Icon=.*:Icon="$ICON_FILE_PATH":g" "$DESKTOP_FILE_PATH"
            sudo ln -sf "$DESKTOP_FILE_PATH" /usr/share/applications/"$DESKTOP_FILE_NAME"
            ;;
    esac
    echo "Creating config file for $TARPKG..."
    tarsaveconffunc "tarinstalled/$TARPKG"
    echo "$TARPKG has been upgraded to $TARFILE!"
}

tarupgradestartallfunc () {
    if [ "$TARUPGRADES" = "FALSE" ]; then
        sleep 0
    else
        dir -C -w 1 "$CONFDIR"/tarupgrades | pr -tT --column=3 -w 125
        echo
        read -p "Continue? Y/N " UPGRADEALLANSWER
        case $UPGRADEALLANSWER in
            Y*|y*)
                for UPGRADE_PKG in $(dir -C -w 1 "$CONFDIR"/tarupgrades); do
                    TARPKG="$UPGRADE_PKG"
                    echo "Downloading $TARPKG..."
                    tarappcheckfunc "$TARPKG"
                    . "$CONFDIR"/cache/"$TARPKG".conf
                    . "$CONFDIR"/tarupgrades/"$TARPKG"
                    if [ "$TAR_DOWNLOAD_SOURCE" = "GITHUB" ]; then
                        targithubinfofunc
                    fi
                    tardlfunc "$TARPKG"
                    tarcheckfunc
                    tarupgradefunc
                    rm -rf "$CONFDIR"/cache/*
                    echo
                done
                rm -f "$CONFDIR"/tarupgrades/*
                ;;
            N*|n*)
                echo "No packages were upgraded; exiting..."
                rm -rf "$CONFDIR"/cache/*
                exit 0
                ;;
        esac
    fi
}

tarupgradestartfunc () {
    echo "$TARPKG will be upgraded to the latest version."
    read -p "Continue? Y/N " UPGRADEANSWER
    case $UPGRADEANSWER in
        Y*|y*)
            tarappcheckfunc "$TARPKG"
            . "$CONFDIR"/cache/"$TARPKG".conf
            . "$CONFDIR"/tarupgrades/"$TARPKG"
            if [ "$TAR_DOWNLOAD_SOURCE" = "GITHUB" ]; then
                targithubinfofunc
            fi
            tardlfunc "$TARPKG"
            tarcheckfunc
            tarupgradefunc
            rm "$CONFDIR"/tarupgrades/"$TARPKG"
            ;;
        N*|n*)
            echo "$TARPKG was not upgraded."
            ;;
    esac
}

tarremovefunc () {
    . "$CONFDIR"/tarinstalled/"$REMPKG"
    echo "Removing $REMPKG..."
    echo "All files in $INSTDIR will be removed!"
    read -p "Continue? Y/N " PKGREMANSWER
    case $PKGREMANSWER in
        N*|n*)
            echo "$REMPKG was not removed."
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
    sudo rm -rf "$INSTDIR"
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
    echo "$REMPKG has been removed!"
}

tarremovepurgefunc () {
    . "$CONFDIR"/tarinstalled/"$PURGEPKG"
    echo "Removing $PURGEPKG..."
    echo "All files in $INSTDIR and $CONFIG_PATH will be removed!"
    read -p "Continue? Y/N " PKGREMANSWER
    case $PKGREMANSWER in
        N*|n*)
            echo "$PURGEPKG was not removed."
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
    sudo rm -rf "$INSTDIR"
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
    echo "$PURGEPKG has been removed!"
}
