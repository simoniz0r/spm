# appimgman
![appimgman](/Screenshot.png)

Usage: appimgman [option] [AppImage]

appimgman is a commandline AppImage manager that installs AppImages to /usr/local/bin. AppImages are
downloaded from the URI provided from https://dl.bintray.com/probono/AppImages/ or from the latest
release on the app's github page.  This allows appimgman to easily provide a list of AppImages to
install, and it also allows appimgman to check for AppImage upgrades just by checking the version of
the AppImage from bintray and latest github releases.

AppImages are installed to '/usr/local/bin/AppImageName'. Information for installed AppImages is stored in
'~/.config/appimgman/installed'.

Packages on your system should not conflict with AppImages installed through appimgman, but appimgman will not
allow AppImages that have the same name as existing commands on your system to be installed.

Arguments:
- list - list all installed AppImages and all AppImages known by appimgman or info about the specified AppImage
- list-installed - list all installed AppImages and install info
- install - install an AppImage automatically if in AppImages-bintray.lst
- remove - remove an installed AppImage
- update - update AppImages-bintray.lst from appimgman's github repo and check for AppImage upgrades
- update-force - add specified AppImage to upgrade-list without checking versions
- upgrade - upgrade AppImages with available upgrades or upgrade the specified AppImage to the latest version

See https://github.com/simoniz0r/appimgman for more help or to report issues.

appimgman is not responsible for bugs within applications that have been
installed using appimgman.  Please report any bugs that are specific to
installed applications to their maintainers.
