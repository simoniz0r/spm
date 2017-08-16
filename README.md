# appimgman
![appimgman](/Screenshot.png)

Usage: appimgman [option] [AppImage]

appimgman is a commandline [AppImage](https://github.com/AppImage) manager that installs AppImages to /usr/local/bin. AppImages are
downloaded from the URI provided from https://dl.bintray.com/probono/AppImages/ or from the latest
release on the app's github page.  This allows appimgman to easily provide a list of AppImages to
install, and it also allows appimgman to check for [AppImage](https://github.com/AppImage) upgrades just by checking the version of
the [AppImage](https://github.com/AppImage) from [Bintray](https://bintray.com/probono/AppImages) and latest github releases.

AppImages are installed to '/usr/local/bin/AppImageName'. Information for installed AppImages is stored in
'~/.config/appimgman/installed'.

Packages on your system should not conflict with AppImages installed through appimgman, but appimgman will not
allow AppImages that have the same name as existing commands on your system to be installed.

Arguments:
- list (-l) - list all installed AppImages and all AppImages known by appimgman or info about the specified AppImage
- list-installed (-li) - list all installed AppImages and install info
- install (-i) - install an AppImage
- remove (-r) - remove an installed AppImage
- update (-upd) - update AppImages-bintray.lst from appimgman's github repo and check for AppImage upgrades
- update-force (-updf) - add specified AppImage to upgrade-list without checking versions
- upgrade (-upg) - upgrade AppImages with available upgrades or upgrade the specified AppImage to the latest version

appimgman is not responsible for bugs within applications that have been
installed using appimgman.  Please report any bugs that are specific to
installed applications to their maintainers.

# What is an [AppImage](https://github.com/AppImage)?

An [AppImage](https://github.com/AppImage) is a downloadable file for Linux that contains an application and everything the application needs to run (e.g., libraries, icons, fonts, translations, etc.) that cannot be reasonably expected to be part of each target system.

# How can I integrate AppImages with the system?

Using the optional appimaged daemon, you can easily integrate AppImages with the system. The daemon puts AppImages into the menus, registers MIME types, icons, all on the fly. You can download it using appimgman or from the [AppImageKit](https://github.com/AppImage/AppImageKit) repository, but it is entirely optional.

# Where can I request AppImages?

If there is no [AppImage](https://github.com/AppImage) of your favorite application available, please request it from the author(s) of the application, e.g., as a feature request in the issue tracker of the application. For example, if you would like to see an [AppImage](https://github.com/AppImage) of Mozilla Firefox, then please leave a comment at https://bugzilla.mozilla.org/show_bug.cgi?id=1249971. The more people request an [AppImage](https://github.com/AppImage) from the upstream authors, the more likely is that an [AppImage](https://github.com/AppImage) will be provided.

If there is an [AppImage](https://github.com/AppImage) available for an application that is not in appimgman's list, feel free to create an [issue here](https://github.com/simoniz0r/appimgman/issues/new) to request that application be added.

Support for a list of custom [AppImages](https://github.com/AppImage) that the user can [AppImages](https://github.com/AppImage) manually is planned, but not yet implemented.  Also, please note that appimgman currently only supports 64-bit AppImages and AppImages that are not in `Pre-release` status.  Support for 32-bit and versions other than the latest stable release is also planned.

# Where do I get support?

For issues related to appimgman, feel free to create an [issue here](https://github.com/simoniz0r/appimgman/issues/new) describing your problem and the distro you are running.

For support related to [AppImages](https://github.com/AppImage), please visit http://discourse.appimage.org/. You can log in using your existing Google or GitHub account, no sign-up needed.

# How can I contribute?

If you would like to contribute to appimgman, feel free contact me by creating an [issue here](https://github.com/simoniz0r/appimgman/issues/new) describing how you would like to contribute or just go ahead and make a pull request!

Curious about [AppImage](https://github.com/AppImage) development? Want to contribute? [AppImage](https://github.com/AppImage) welcomes pull requests addressing any of the open issues and/or other bugfixes and/or feature additions. In the case of complex feature additions, it is best to contact [AppImage](https://github.com/AppImage) first, before you spend much time. See [AppImage's](https://github.com/AppImage) list of issues and get in touch with [AppImage](https://github.com/AppImage) in #AppImage on irc.freenode.net.
