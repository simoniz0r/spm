## spm

spm is a command line package manager that mainly provides AppImages.
spm uses https://simoniz0r.github.io/spm-feed.json to get information about packages.

spm is not responsible for bugs within packages that have been
installed using spm.  Please report any bugs that are specific to
installed packages to their maintainers.

Dependencies: curl, jq (jq is included in the AppImage release)

## Arguments

```    
    list|l      - list all available packages
    
    info|i      - output information for an package
    
    search|se   - search for available packages
    
    install|in - install an package to $TARGET_DIR
    
    get         - install an package to $GET_DIR without managing it
    
    remove|rm   - remove an installed package
    
    update|up   - update list of packages and check installed packages for updates
    
    revert|rev  - revert an updated package to its previous version if available
    
    freeze|fr   - mark or unmark an package as FROZEN to preven update checks
    
    config|cf   - open spm's config file with $EDITOR
```

## Additional Arguments

```
    [list|info] --installed|-i   - show list or info for installed packages

    --verbose [option] [package] - add bash option 'set -v' for verbose output

    --debug [option] [package]   - add bash option 'set -x' for debugging
```

## Github Rate Limit

By default, Github's rate limit for API checks is 60 per hour.  When authenticated, the rate limit is increased to 5000 per hour.  To take advantage of the increased rate limit, it is suggested that you add your token to `spm.conf`.

It is recommended that you do not give this token access to ***any*** scopes as it will be stored in plain text in your config file.  It may even be a good idea to create a throwaway account for use with this.

To use authenticated Github API checks with spm, edit the following line in `~/.local/share/spm/spm.conf` to contain your token:
```
GITHUB_TOKEN="YOURTOKEN"
```
