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
  "feed_url": "https://simoniz0r.github.io/spm-feed.json",
  "description": "json feed containing package information for spm.",
  "updated_at": "$(date)",
  "expired": false,
  "appimages": [
EOL
for image in $(dir -C -w 1 $HOME/github/spm/appimages); do
    image="$(echo $image | rev | cut -f2- -d'.' | rev)"
    if [ -f "$HOME/github/spm/appimages/$image.json" ]; then
        URL="$(jq -r '.links[1].url' ~/github/spm/appimages/$image.json | grep '.*github*.')"
        if [ ! -z "$URL" ]; then
            echo "$image is in list; getting description from json..."
            cat >>"$HOME"/github/index/spm-feed.json << EOL
    {
      "name": "$(jq -r '.name' ~/github/spm/appimages/$image.json)",
      "type": "AppImage",
      "description": "$(jq -r '.description' ~/github/spm/appimages/$image.json)",
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
          "url": "$URL"
        }
      ]
    },
EOL
        fi
        echo "$(tput setaf 2)$image has been added to spm-feed.json$(tput sgr0)"
    elif [ -f "$HOME/github/spm/appimages/$image" ]; then
        echo "$image is not in list; grabbing info from github page..."
        URL="$(grep -v '#' $HOME/github/spm/appimages/"$image" | grep '.*github*.' | cut -f-5 -d"/")"
        if [ ! -z "$URL" ]; then
            cat >>"$HOME"/github/index/spm-feed.json << EOL
    {
      "name": "$image",
      "type": "AppImage",
      "description": "$(wget --quiet "$URL" -O - | tac | grep -m1 '<meta name="description"' | cut -f4 -d'"' | tr -cd '[:alnum:] -' | sed "s%39%'%g")",
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
            cat >>"$HOME"/github/spm/appimages/"$image".json << EOL
    {
      "name": "$image",
      "type": "AppImage",
      "description": "$(wget --quiet "$URL" -O - | tac | grep -m1 '<meta name="description"' | cut -f4 -d'"' | tr -cd '[:alnum:] -' | sed "s%39%'%g")",
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
    }
EOL
            rm ~/github/spm/appimages/"$image"
            echo "$(tput setaf 2)$image has been added to spm-feed.json$(tput sgr0)"
        fi
    fi
done
# Generate a list of AppImages from sites other than github with versions that cannot be managed
for image in $(dir -C -w 1 $HOME/github/spm/appimages); do
    image="$(echo $image | rev | cut -f2- -d'.' | rev)"
    if [ -f "$HOME/github/spm/appimages/$image.json" ]; then
        URL="$(jq -r '.links[1].url' ~/github/spm/appimages/$image.json | grep -v '.*github*.')"
        if [ ! -z "$URL" ]; then
            echo "$image is in list; getting description from json..."
            if [ -f "$HOME/github/appimage.github.io/apps/$(jq -r '.name' ~/github/spm/appimages/$image.json).md" ]; then
                DESCRIPTION="$(yq r ~/github/appimage.github.io/apps/$(jq -r '.name' ~/github/spm/appimages/$image.json).md 'description' | tr '\n' ' ')"
                AUTHOR="$(yq r ~/github/appimage.github.io/apps/$(jq -r '.name' ~/github/spm/appimages/$image.json).md 'authors')"
            else
                DESCRIPTION="AppImage for $(jq -r '.name' ~/github/spm/appimages/$image.json)"
                AUTHOR="$(echo $URL | rev | cut -f2- -d'/' | rev)"
            fi
            cat >>"$HOME"/github/index/spm-feed.json << EOL
    {
      "name": "$(jq -r '.name' ~/github/spm/appimages/$image.json)",
      "type": "AppImage",
      "description": "$DESCRIPTION",
      "authors": [
        {
          "name": "$AUTHOR",
          "url": "$(echo $URL | rev | cut -f2- -d'/' | rev)"
        }
      ],
      "links": [
        {
          "type": "Other",
          "url": "$(echo $URL | rev | cut -f2- -d'/' | rev)"
        },
        {
          "type": "Install",
          "url": "$URL"
        }
      ]
    },
EOL
            echo "$(tput setaf 2)$image has been added to spm-feed.json$(tput sgr0)"
        fi
    elif [ -f "$HOME/github/spm/appimages/$image" ]; then
        URL="$(grep -v '#' $HOME/github/spm/appimages/"$image" | grep -v '.*github*.')"
        if [ ! -z "$URL" ]; then
            echo "$image is in list; getting description from json..."
            if [ -f "$HOME/github/appimage.github.io/apps/$image.md" ]; then
                DESCRIPTION="$(yq r ~/github/appimage.github.io/apps/$image.md 'description' | tr '\n' ' ')"
                AUTHOR="$(yq r ~/github/appimage.github.io/apps/$image.md 'authors')"
            else
                DESCRIPTION="AppImage for $image"
                AUTHOR="$(echo $URL | rev | cut -f2- -d'/' | rev)"
            fi
            cat >>"$HOME"/github/index/spm-feed.json << EOL
    {
      "name": "$image",
      "type": "AppImage",
      "description": "$DESCRIPTION",
      "authors": [
        {
          "name": "$AUTHOR",
          "url": "$(echo $URL | rev | cut -f2- -d'/' | rev)"
        }
      ],
      "links": [
        {
          "type": "Other",
          "url": "$(echo $URL | rev | cut -f2- -d'/' | rev)"
        },
        {
          "type": "Install",
          "url": "$URL"
        }
      ]
    },
EOL
            cat >>"$HOME"/github/spm/appimages/"$image".json << EOL
    {
      "name": "$image",
      "type": "AppImage",
      "description": "$DESCRIPTION",
      "authors": [
        {
          "name": "$AUTHOR",
          "url": "$(echo $URL | rev | cut -f2- -d'/' | rev)"
        }
      ],
      "links": [
        {
          "type": "Other",
          "url": "$(echo $URL | rev | cut -f2- -d'/' | rev)"
        },
        {
          "type": "Install",
          "url": "$URL"
        }
      ]
    }
EOL
            rm ~/github/spm/appimages/"$image"
            echo "$(tput setaf 2)$image has been added to spm-feed.json$(tput sgr0)"
        fi
    fi
done

cat >>"$HOME"/github/index/spm-feed.json << EOL
    {
      "END": "END",
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
  ]
}
EOL
