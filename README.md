# spm
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
those dependencies would not be on a normal Linux system.  This means that AppImages should "just work"
without having to install any additional packages!

Arguments:
- list (-l) - list all installed AppImages and all AppImages known by spm or info about the specified AppImage
- list-installed (-li) - list all installed AppImages and install info
- appimg-install (-ai) - install an AppImage
- tar-install (-ti - install a precompiled tar archive
- appimg-remove (-ar) - remove an installed AppImage
- tar-remove (-tr) remove an installed precompiled tar archive
- update (-upd) - update package lists and check for new AppImage and precompiled tar archive versions
- appimg-update-force (-auf) - add specified AppImage to upgrade-list without checking versions
- tar-update-force (-tuf) - add specified precompiled tar archive to list of upgrades without checking versions
- upgrade (-upg) - upgrade all installed packages that are marked for upgrade or just the specified package

See https://github.com/simoniz0r/appimgman for more help or to report issues.

spm is not responsible for bugs within applications that have been
installed using spm.  Please report any bugs that are specific to
installed applications to their maintainers."

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
