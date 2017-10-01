# spm

[![asciicast](/spmvidpreview.png)](https://asciinema.org/a/OY8FwYH8I9j590or2iPTiid0O)

Dependencies: coreutils, tar, bc,  wget (bc and wget are bundled in the AppImage release)

Usage: spm [option] [package]

spm is a simple commandline package manager that installs AppImages and
precompiled tar archives. Using the lists generated from spm's repo, spm
provides a variety of AppImages and precompiled tars for install. spm keeps
track of installed packages and their versions, so spm can also be used to
upgrade and remove packages installed by spm.

spm does not handle installing dependencies for tar packages that are installed through spm. A list of dependencies
will be outputted on install and will also be saved to '~/.config/spm/tarinstalled/PackageName'. If you find that
you are missing dependencies needed for a package installed through spm, you can look there for some help.

AppImages, on the other hand, contain all dependencies that are necessary for the app to run as long as
those dependencies would not be on a normal Linux system.  This means that AppImages should "just work"
without having to install any additional packages!

Arguments:
- list (-l) - list all packages known by spm or info about the specified package
- list-installed (-li) - list all installed packages and install info
- search (-s) - search package lists for packages matching input
- install (-i) - install an AppImage or precompiled tar archive
- remove (-r) - remove an installed AppImage or precompiled tar archive
- update (-upd) - update package lists and check for package upgrades
- appimg-update-force (-auf) - mark specified AppImage or tar archive for upgrade without checking version
- upgrade (-upg) - upgrade all installed packages that are marked for upgrade or just the specified package
- man - show spm man page

spm is not responsible for bugs within applications that have been
installed using spm.  Please report any bugs that are specific to
installed applications to their maintainers."

To use the AppImage for spm, simply download it, `chmod a+x /path/to/spm-VERSION-x86_64.AppImage`, and execute `/path/to/spm-VERSION-x86_64.AppImage`.  The AppImage release for spm has wget and bc bundled in.

It is recommended that you use spm to install the AppImage or tar version of spm by executing `/path/to/spm -i spm`.  This will allow spm to upgrade itself when a new version is released.

# Github Rate Limit

By default, Github's rate limit for API checks is 60 per hour.  When authenticated, the rate limit is increased to 5000 per hour.  To take advantage of the increased rate limit, it is suggested that you add [your token](https://github.com/settings/tokens) to `spm.conf`.

It is recommended that you do not give this token access to ***any*** scopes as it will be stored in plain text in your config file.  It may even be a good idea to create a throwaway account for use with this.

To use authenticated Github API checks with spm, add the following line to `~/.config/spm/spm.conf` :
```
GITHUB_TOKEN="YOURTOKEN"
```

# Goals

The main goal is for spm to be a distro agnostic package manager that distributes AppImages which should run on any Linux distro and precompiled tar archives with dependencies that are available for install on most Linux distros.  spm aims to fill the gap that is left by many Linux distro's package managers by providing software not available in their repos and/or providing packages that may be more up to date than those in the distro's repos.

spm will only provide optional packages that are not needed for a distro to run; spm has no intention of becoming a full replacement for traditional package managers.  spm also has no plans of installing dependencies for package types other than AppImages (AppImages include dependencies).  spm will always be **simple package manager** that provides optional packages that either need no dependencies to run or have a small amount dependencies that are widely available.

# What is an [AppImage](https://github.com/AppImage)?

An AppImage is a downloadable file for Linux that contains an application and everything the application needs to run (e.g., libraries, icons, fonts, translations, etc.) that cannot be reasonably expected to be part of each target system.


# Where can I request AppImages?

If there is an AppImage available for an application that is not in spm's list, feel free to create an [issue here](https://github.com/simoniz0r/spm/issues/new) to request that application be added.

Support for a list of custom AppImages that the user can AppImages manually is planned, but not yet implemented.  Also, please note that spm currently only supports 64-bit AppImages and AppImages.

# Where do I get support?

For issues related to spm, you can either [join the Discord server](https://discord.gg/FFWVWPA) and ask for help in #spm or create an [issue here](https://github.com/simoniz0r/spm/issues/new) describing your problem and the distro you are running.

# How can I contribute?

If you would like to contribute to spm, feel free contact me by creating an [issue here](https://github.com/simoniz0r/spm/issues/new) describing how you would like to contribute or just go ahead and make a pull request!
