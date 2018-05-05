#compdef spm

_spm() {
    local curcontext="$curcontext" state line
    typeset -A opt_args
 
    _arguments \
        '1: :->args'\
        '2: :->input'
 
    case $state in
    args)
        _arguments '1:arguments:(list info search install get remove update revert freeze config man help --verbose --debug)'
        ;;
    *)
        case $words[2] in
        install|in|info|i|get)
            compadd "$@" $(dir -C -w 1 ~/.local/share/spm/list | sed 's%.json%%g')
            ;;
        remove|rm|update|up|revert|rev|freeze|fr)
            compadd "$@" $(dir -C -w 1 ~/.local/share/spm/installed)
            ;;
        esac
    esac
}

_spm
