#!/bin/bash
# Title: spm
# Description: Downloads and installs AppImages and precompiled tar archives.  Can also upgrade and remove installed packages.
# Dependencies: GNU coreutils, tar, wget, python3.x
# Author: simonizor
# Website: http://www.simonizor.gq
# License: GPL v2.0 only
# Generates spm-feed.json containing info for AppImages and precompiled tar packages

rm -f "$HOME"/github/index/spm-feed.json
cat >"$HOME"/github/index/spm-feed.json << EOL
{
  "version": 1,
  "home_page_url": "https://github.com/simoniz0r/spm",
  "feed_url": "http://www.simonizor.gq/spm-feed.json",
  "description": "json feed containing AppImage and precompiled tar package information for spm.",
  "updated_at": "$(date)",
  "expired": false,
  "appimages": [
EOL
for image in $(dir -C -w 1 $HOME/github/spm/appimages); do
    URL="$(grep -v '#' $HOME/github/spm/appimages/"$image" | grep '.*github*.' | cut -f-5 -d"/")"
    if [ ! -z "$URL" ]; then
        case $URL in
            *api.github*)
                REPO="$(echo $URL | cut -f5,6 -d"/")"
                URL="https://github.com/$REPO"
                ;;
            *)
                REPO="$(echo $URL | cut -f4,5 -d"/")"
                ;;
        esac
        # lower_image="$(echo "$image" | tr '[:upper:]' '[:lower:]' | tr -d '.')"
        cat >>"$HOME"/github/index/spm-feed.json << EOL
    {
      "name": "$image",
      "type": "AppImage",
      "description": "$(wget --quiet "$URL" -O - | grep -i '<meta name="description"' | cut -f4 -d'"' | tr -cd '[:alnum:] -')",
      "authors": [
        {
          "name": "$(echo $URL | cut -f4 -d'/')",
          "url": "$(echo $URL | cut -f-4 -d'/')"
        }
      ],
      "links": [
        {
          "type": "GitHub",
          "url": "$(echo $URL | cut -f4-5 -d'/')"
        },
        {
         "type": "Install",
          "url": "$URL/releases"
        }
      ]
    },
EOL
        echo "$(tput setaf 1)$image has been added to spm-feed.json$(tput sgr0)"
    fi
done
# Generate a list of AppImages from sites other than github with versions that cannot be managed
for image in $(dir -C -w 1 $HOME/github/spm/appimages); do
    URL="$(grep -v '#' $HOME/github/spm/appimages/"$image" | grep -v '.*github*.')"
    if [ ! -z "$URL" ]; then
        cat >>"$HOME"/github/index/spm-feed.json << EOL
    {
      "name": "$image",
      "type": "AppImage",
        "authors": [
        {
          "name": "N/A",
          "url": "N/A"
        }
      ],
      "links": [
        {
          "type": "Other",
          "url": "N/A"
        },
        {
          "type": "Install",
          "url": "$URL"
        }
      ]
    },
EOL
        echo "$(tput setaf 1)$image has been added to spm-feed.json$(tput sgr0)"
    fi
done

cat >>"$HOME"/github/index/spm-feed.json << EOL
    {
      "name": "END",
      "type": "END",
        "authors": [
        {
          "name": "END",
          "url": "END"
        }
      ],
      "links": [
        {
          "type": "END",
          "url": "END"
        },
        {
          "type": "END",
          "url": "END"
        }
      ]
    }
  ],
  "tars": [
EOL

for tar in $(dir -C -w 1 $HOME/github/spm/tar-github); do
    # tar_name="$(echo "$tar" | cut -f1 -d'.')"
    cat >>"$HOME"/github/index/spm-feed.json << EOL
    {
      "name": "$(yaml r "$HOME"/github/spm/tar-github/$tar name)",
      "type": "tar",
      "location": "Github",
      "instdir": "$(yaml r "$HOME"/github/spm/tar-github/$tar instdir)",
      "taruri": "$(yaml r "$HOME"/github/spm/tar-github/$tar taruri)",
      "apirui": "$(yaml r "$HOME"/github/spm/tar-github/$tar apirui)",
      "desktop_file_path": "$(yaml r "$HOME"/github/spm/tar-github/$tar desktop_file_path)",
      "icon_file_path": "$(yaml r "$HOME"/github/spm/tar-github/$tar icon_file_path)",
      "executable_file_path": "$(yaml r "$HOME"/github/spm/tar-github/$tar executable_file_path)",
      "bin_path": "$(yaml r "$HOME"/github/spm/tar-github/$tar bin_path)",
      "config_path": "$(yaml r "$HOME"/github/spm/tar-github/$tar config_path)",
      "description": "$(yaml r "$HOME"/github/spm/tar-github/$tar description | tr -d '\n')",
      "dependencies": "$(yaml r "$HOME"/github/spm/tar-github/$tar dependencies | tr -d '\n')"
    },
EOL
done

for tar in $(dir -C -w 1 $HOME/github/spm/tar-other); do
    cat >>"$HOME"/github/index/spm-feed.json << EOL
    {
      "name": "$(yaml r "$HOME"/github/spm/tar-other/$tar name)",
      "type": "tar",
      "location": "Other",
      "instdir": "$(yaml r "$HOME"/github/spm/tar-other/$tar instdir)",
      "taruri": "$(yaml r "$HOME"/github/spm/tar-other/$tar taruri)",
      "desktop_file_path": "$(yaml r "$HOME"/github/spm/tar-other/$tar desktop_file_path)",
      "icon_file_path": "$(yaml r "$HOME"/github/spm/tar-other/$tar icon_file_path)",
      "executable_file_path": "$(yaml r "$HOME"/github/spm/tar-other/$tar executable_file_path)",
      "bin_path": "$(yaml r "$HOME"/github/spm/tar-other/$tar bin_path)",
      "config_path": "$(yaml r "$HOME"/github/spm/tar-other/$tar config_path)",
      "description": "$(yaml r "$HOME"/github/spm/tar-other/$tar description | tr -d '\n')",
      "dependencies": "$(yaml r "$HOME"/github/spm/tar-other/$tar dependencies | tr -d '\n')"
    },
EOL
done

cat >>"$HOME"/github/index/spm-feed.json << EOL
    {
      "name": "END",
      "instdir": "END",
      "taruri": "END",
      "apirui": "END",
      "desktop_file_path": "END",
      "icon_file_path": "END",
      "executable_file_path": "END",
      "bin_path": "END",
      "config_path": "END",
      "description": "END",
      "dependencies": "END"
    }
  ]
}
EOL
