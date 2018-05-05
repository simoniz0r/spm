__spm() {
    local cur prev opts base
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    #
    #  The basic options we'll complete.
    #
    opts="list info install get remove update revert freeze config man help --verbose --debug"


    #
    #  Complete the arguments to some of the basic commands.
    #
    case "${prev}" in
        install|in|info|i|get)
            local packagelist="$(dir -C -w 1 ~/.local/share/spm/list | sed 's%.json%%g')"
            COMPREPLY=( $(compgen -W "${packagelist}" -- ${cur}) )
            return 0
            ;;
        remove|rm|update|up|revert|rev|freeze|fr)
            local packagesinstalled="$(dir -C -w 1 ~/.local/share/spm/installed)"
            COMPREPLY=( $(compgen -W "${packagesinstalled}" -- ${cur}) )
            return 0
            ;;
        *)
        ;;
    esac

   COMPREPLY=($(compgen -W "${opts}" -- ${cur}))  
   return 0
}

complete -F __spm spm
