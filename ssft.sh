#!/bin/sh -e
# --------
# File:        ssft.sh
# Description: Set of shell functions to implement frontends on scripts,
#              this file is executable to be loadable without hardcoding
#              a PATH.
# Author:      Sergio Talens-Oliag <sto@debian.org>
# Copyright:   (c) 2006-2016 Sergio Talens-Oliag <sto@debian.org>
# 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along 
# with this program; if not, write to the Free Software Foundation, Inc., 
# 51 Franklin St, Fifth Floor, Boston MA 02110-1301 USA
# --------

# =============== #
# Gettext Support #
# =============== #

# Try to load the real gettext.sh functions or define fake ones
if [ -n "`which gettext.sh 2> /dev/null`" ]; then
# ZSH fix, set NOFUNCTIONARGZERO before loading
NOFUNCTIONARGZERO="`set -o | awk '/^nofunctionargzero/ { print $2 }'`"
if [ "$NOFUNCTIONARGZERO" = "off" ]; then
    set -o NOFUNCTIONARGZERO
fi
. gettext.sh
# ZSH fix, unset NOFUNCTIONARGZERO if it was set
if [ "$NOFUNCTIONARGZERO" = "off" ]; then
    set +o NOFUNCTIONARGZERO
fi
else
gettext()  { printf "%s" "$1"; }
eval_gettext() { eval `echo printf \"%s\" \"$1\"`; }
ngettext() { [ "$3" -eq "1" ] && printf "%s" "$1" || printf "%s" "$2"; }
eval_ngettext() { 
    [ "$3" -eq "1" ] && _l_str="$1" || _l_str="$2";
    eval `echo printf \"%s\" \"$_l_str\"`; 
}
fi

# L10N Support #
# ============ #

# Function: ssft_set_textdomain
# 
# Description: Saves the current TEXTDOMAIN and sets it to ssft-runtime

ssft_set_textdomain() {
if [ "$TEXTDOMAIN" != "@PACKAGE@" ]; then
    SSFT_OLD_TEXTDOMAIN="$TEXTDOMAIN"
    TEXTDOMAIN="@PACKAGE@"
    export TEXTDOMAIN
    if [ "$TEXTDOMAINDIR" != "@LOCALEDIR@" ]; then
    SSFT_OLD_TEXTDOMAINDIR="$TEXTDOMAINDIR"
    TEXTDOMAINDIR="@LOCALEDIR@"
    export TEXTDOMAINDIR
    fi
fi
}

# Function: ssft_reset_textdomain
# 
# Description: Resets the TEXTDOMAIN to its old value (if there is one)

ssft_reset_textdomain() {
if [ -n "$SSFT_OLD_TEXTDOMAIN" ]; then
    TEXTDOMAIN="$SSFT_OLD_TEXTDOMAIN"
    export TEXTDOMAIN
    unset  SSFT_OLD_TEXTDOMAIN
    if [ -n "$TEXTDOMAINDIR" ]; then
    if [ -n "$SSFT_OLD_TEXTDOMAINDIR" ]; then
        TEXTDOMAINDIR="$SSFT_OLD_TEXTDOMAINDIR"
        export TEXTDOMAINDIR
        unset  SSFT_OLD_TEXTDOMAINDIR
    else
        unset  TEXTDOMAINDIR
    fi
    fi
fi
}


# ============ #
# Initial test #
# ============ #

# This script is primarily a shell function library, but it is put on the PATH
# to be able to load it using ". ssft.sh" (the idea was taken from the
# gettext.sh program).
#
# We use a function to test if the script has been called instead of sourced
# and in that later case we accept the --help and --version options.
# 
# The test is defined inside a function to be able to source the script from
# zsh, as this shell by default sets the option FUNCTION_ARGZERO that replaces
# the $0 variable for sourced scripts and functions; using a function we are
# sure that if FUNCTION_ARGZERO is set, $0 never takes the program name. Note
# that using this method if we execute the script using zsh the default
# options we will not see the --help or --version messages, but that is not
# important, as the executable script is run using '/bin/sh' and we get the
# desired efect when it is called directly.

ssft_sh_fhs_test() {
# Function: ssft_sh_doc [FUNCTION_NAMES]
# Description: prints the list of functions exported by the ssft.sh script
# or shows the documentation related to it.
ssft_sh_doc() {
    _l_ssft_sh="$0"
    if [ "$#" -lt 1 ]; then
    awk '/^# Function:/ { print $3 }' $_l_ssft_sh
    else
    awk -v "name=$1" '/^# Function:/ { \
        if (($3 == name)) {              \
    do {                           \
        if (match($0, "^#")) {       \
        print substr($0,3);        \
        } else {                     \
        printf "\n"; break;        \
        }                            \
        } while (getline);             \
        }                                \
    }' $_l_ssft_sh
    fi
}
# Function: ssft_sh_usage
# Description: outputs to stdout the --help usage message.
ssft_sh_usage() {
    ssft_set_textdomain
    _l_MSG=$(eval_gettext \
"Shell Script Frontend Tool (version \$_l_version)
Usage: . ssft.sh

When called directly the program supports the following options:

-d,--doc [FUNCTIONS]  Prints the list of available functions. If function
                    names are given prints functions' documentation.
-h,--help             This message
-v,--version          File version
")
    ssft_reset_textdomain
    echo "$_l_MSG"
}
# Function: ssft_sh_version
# Description: outputs to stdout the --version message.
ssft_sh_version() {
    ssft_set_textdomain
    _l_MSG="`eval_gettext \
"Copyright (C) 2006-2016 Sergio Talens-Oliag <sto@debian.org>
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE."`"
    ssft_reset_textdomain
    echo "$_l_progname ($_l_package $_l_version)"
    echo "$_l_MSG"
}
case "$0" in
    ssft.sh | */ssft.sh | *\ssft.sh)
    _l_progname=$0
    _l_package="@PACKAGE@"
    _l_version="@VERSION@"
    if test $# -ge 1; then
        case "$1" in
    --doc | --do | --d | -d)
        shift; ssft_sh_doc "$@"; exit 0 ;;
        --help | --hel | --he | --h | -h)
            ssft_sh_usage; exit 0 ;;
        --version | --versio | --versi | --vers | --ver | --ve | --v | -v)
            ssft_sh_version; exit 0 ;;
        esac
    fi
    ssft_sh_usage 1>&2
    exit 1
    ;;
esac
# unset auxiliary functions
unset -f ssft_sh_doc
unset -f ssft_sh_usage
unset -f ssft_sh_version
}

# Execute the test function
ssft_sh_fhs_test "$@"

# Unset the test function (it is no longer needed)
unset -f ssft_sh_fhs_test

#############
# FUNCTIONS #
#############

# ================== #
# SSFT_PAGER support #
# ================== #

# Function: ssft_pager
# 
# Description: Calls the SSFT_PAGER program if the variable is set; if it isn't
# tries with 'sensible-pager' if it exist and is executable or falls back to
# using the PAGER variable or 'more' if it is not set.
#
# If the pager is LESS we make it behave like more for short files or menus
# (we call LESS with the options -FX)

ssft_pager() {
if [ -n "$SSFT_PAGER" ]; then
    LESS="-FX" eval `echo $SSFT_PAGER "$@"`
elif [ -x "/usr/bin/sensible-pager" ]; then
    LESS="-FX" /usr/bin/sensible-pager $@
elif [ -n "$PAGER" ]; then
    LESS="-FX" eval `echo $PAGER "$@"`
else
    more $@
fi
}

# ================== #
# FRONTEND FUNCTIONS #
# ================== #

# Function: ssft_choose_frontend
#
# Description: print the name of the preferred frontend, but don't set it

ssft_choose_frontend() {
_l_frontend=""
if [ -n "$DISPLAY" ]; then
    if [ -x "`which zenity 2> /dev/null`" ]; then
    _l_frontend="zenity"
    elif [ -x "`which pydialog 2> /dev/null`" ]; then
    _l_frontend="pydialog"
    fi
fi
if [ -z "$_l_frontend" ]; then
    if [ -x "`which dialog`" ]; then
    _l_frontend="dialog"
    else
    _l_frontend="text"
    fi
fi
echo "$_l_frontend"
}

# Function: ssft_print_text_title TITLE
#
# Description: auxiliary function to print titles on text and noninteractive
# frontends

ssft_print_text_title() {
if [ "$#" -gt "0" ]; then
    echo "$@"
    echo "$@" | sed -e 's/[^-]/-/g'
    echo ""
fi
}

# Function: ssft_display_message TITLE MESSAGE
#
# Description: Show a message to the user

ssft_display_message() {
# Local variables
_l_title="";
_l_message="";
ssft_set_textdomain
_l_CONTINUE_MSG="`gettext "Press ENTER to CONTINUE"`"
ssft_reset_textdomain

# Check arguments
if [ "$#" -lt 2 ]; then
    return 255
fi

# Set _l_variables
_l_title="$1";
shift;
_l_message="$@";

# Read values
case "$SSFT_FRONTEND" in
zenity)
    zenity --title "$_l_title" --info --text "$_l_message" 2> /dev/null;
;;
pydialog)
    pydialog --title "$_l_title" --msgbox "$_l_message" 2> /dev/null;
;;
dialog)
    dialog --stdout --title "$_l_title" --msgbox "$_l_message" 0 0;
;;
text)
    ssft_print_text_title "$_l_title"
    echo "$_l_message"
    echo ""
    printf "%s" "$_l_CONTINUE_MSG"
    read _l_foo
    echo ""
;;
*)
    ssft_print_text_title "$_l_title"
    echo "$_l_message"
    echo ""
;;
esac
return 0
}

# Function: ssft_display_error TITLE MESSAGE
#
# Description: Show an error message to the user, the default frontend prints
# it on stderr

ssft_display_error() {
# MENU strings
ssft_set_textdomain
_l_CONTINUE_MSG="`gettext "Press ENTER to CONTINUE"`"
ssft_reset_textdomain

# Local variables
_l_title="";
_l_message="";

# Check arguments
if [ "$#" -lt 2 ]; then
    return 255
fi

# Set _l_variables
_l_title="$1";
shift;
_l_message="$@";

# Read values
case "$SSFT_FRONTEND" in
zenity)
    zenity --title "$_l_title" --error --text "$_l_message" 2> /dev/null;
;;
pydialog)
    pydialog --title "$_l_title" --error "$_l_message" 2> /dev/null;
;;
dialog)
    dialog --stdout --title "$_l_title" --msgbox "$_l_message" 0 0;
;;
text)
    ssft_print_text_title "$_l_title" >&2
    echo "$_l_message" >&2
    echo ""
    printf "%s" "$_l_CONTINUE_MSG"
    read _l_foo
    echo "" >&2
;;
*)
    ssft_print_text_title "$_l_title" >&2
    echo "$_l_message" >&2
    echo "" >&2
;;
esac
return 0
}

# Function: ssft_display_emsg TITLE MESSAGE
#
# Description: Call ssft_display_error for program error messages

ssft_display_emsg(){
_l_TIT="$1"
_l_EMSG="$2"
ssft_set_textdomain
_l_MSG=$(eval_gettext "The error message was:

\$_l_EMSG")
ssft_reset_textdomain
ssft_display_error "$_l_TIT" "$_l_MSG"
return 0
}

# Function: ssft_file_selection TITLE
#
# Description: Read a filepath from the user and store the value on the
# variable SSFT_RESULT. The function returns 0 if some value was set by the
# user and != 0 if it wasn't.

ssft_file_selection() {
# MENU strings
ssft_set_textdomain
_l_FNAME_STR="`gettext "Filename"`"
ssft_reset_textdomain

# Local variables
_l_title="";
_l_fpath="";

# Check arguments
if [ "$#" -lt 1 ]; then
    return 255
fi

# Set _l_variables
_l_title="$1";

# Read values
case "$SSFT_FRONTEND" in
zenity)
    _l_fpath=$(
    zenity --title "$_l_title" --file-selection 2> /dev/null
    );
;;
pydialog)
    _l_fpath=$(
    pydialog --title "$_l_title" --getopenfilename "`pwd`" "*" 2> /dev/null
    );
;;
dialog)
    _l_fpath=$( dialog --stdout --title "$_l_title" --fselect "`pwd`" 0 0 );
;;
text)
    ssft_print_text_title "$_l_title"
    printf "%s: " "$_l_FNAME_STR"
    read _l_fpath
    echo ""
;;
*)
    _l_fpath=""
;;
esac
SSFT_RESULT="$_l_fpath"
test -n "$_l_fpath"
return $?
}

# Function: ssft_directory_selection TITLE
#
# Description: Read a path from the user and store the value on the
# variable SSFT_RESULT. The function returns 0 if some value was set by the
# user and != 0 if it wasn't.

ssft_directory_selection() {
# MENU strings
ssft_set_textdomain
_l_FNAME_STR="`gettext "Directory"`"
ssft_reset_textdomain

# Local variables
_l_title="";
_l_fpath="";

# Check arguments
if [ "$#" -lt 1 ]; then
    return 255
fi

# Set _l_variables
_l_title="$1";

# Read values
case "$SSFT_FRONTEND" in
zenity)
    _l_fpath=$(
    zenity --title "$_l_title" --file-selection --directory 2> /dev/null
    );
;;
pydialog)
    _l_fpath=$(
    pydialog --title "$_l_title" --getexistingdirectory "`pwd`" 2> /dev/null
    );
;;
dialog)
    _l_fpath=$( dialog --stdout --title "$_l_title" --dselect "`pwd`" 0 0 );
;;
text)
    ssft_print_text_title "$_l_title"
    printf "%s: " "$_l_FNAME_STR"
    read _l_fpath
    echo ""
;;
*)
    _l_fpath=""
;;
esac
SSFT_RESULT="$_l_fpath"
test -n "$_l_fpath"
return $?
}

# Function: ssft_progress_bar TITLE [TEXT [INITIAL_%]]
#
# Description: Show a progress bar to the user; the input contains two lines
# per update, one for the % (integer between 0 and 100) and another for the
# message displayed. The dialog is closed when the input ends.

ssft_progress_bar() {
# Local variables
_l_title="";
_l_percent=0;

# Check arguments
if [ "$#" -lt 1 ]; then
    return 255
fi

# Set _l_variables
_l_title="$1";
if [ "$2" != "" ]; then
    _l_percent="$2";
fi

# Read values
case "$SSFT_FRONTEND" in
zenity)
    while read _l_line; do
    echo "$_l_line" | sed -e '/^[0-9][0-9]*$/! {
        s/^/# /g;
    };' 
    done | zenity --progress --title "$_l_title" --text "" \
                --percentage "$_l_percent" --auto-close  \
                2> /dev/null
;;
pydialog)
    _l_kdpbref="/tmp/kdpbdc-$PID.`date +"%s"`"
    pydialog --title "$_l_title" --progressbar 100 > "$_l_kdpbref" 2> /dev/null
    if grep -q '^DCOPRef' $_l_kdpbref; then
    DCOPREF="$(
        sed -n -e '/^DCOPRef/ { s/DCOPRef(\(.*\),ProgressDialog)/\1/; p }' \
            $_l_kdpbref
    )";
    rm -f "$_l_kdpbref"
    dcop $DCOPREF ProgressDialog setAutoClose true 2> /dev/null 1>&2
    while read _l_line; do
        _l_percent="`echo $_l_line | sed -n -e '/^[0-9][0-9]*/ { p; };'`"
        if [ -z "$_l_percent" ]; then
        dcop $DCOPREF ProgressDialog setLabel "$_l_line" \
            2> /dev/null 1>&2;
        else
        dcop $DCOPREF ProgressDialog setProgress "$_l_percent" \
            2> /dev/null 1>&2;
        fi
    done
    else
    DBUSREF="$(cat $_l_kdpbref)"
    rm -f "$_l_kdpbref"
    qdbus $DBUSREF Set org.kde.kdialog.ProgressDialog autoClose true \
            2> /dev/null 1>&2
    while read _l_line; do
        _l_percent="`echo $_l_line | sed -n -e '/^[0-9][0-9]*/ { p; };'`"
        if [ -z "$_l_percent" ]; then
        qdbus $DBUSREF org.kde.kdialog.ProgressDialog.setLabelText "$_l_line" \
                2> /dev/null 1>&2;
        else
        qdbus $DBUSREF Set org.kde.kdialog.ProgressDialog value "$_l_percent" \
                2> /dev/null 1>&2;
        fi
    done
    fi
;;
dialog)
    while read _l_line; do
    echo "$_l_line" | sed -e '/^[0-9][0-9]*$/! {
        s/^\(.*\)$/XXX\n\1\nXXX/;
    };'
    done | dialog --stdout --title "$_l_title" --gauge "" 0 0 $_l_percent;
;;
text|*)
    ssft_print_text_title "$_l_title"
    while read _l_line; do
    _l_percent="`echo $_l_line | sed -n -e '/^[0-9][0-9]*/ { p; };'`"
    if [ -z "$_l_percent" ]; then
        _l_text="$_l_line"
        echo "$_l_text"
    else
        printf " [%3s%%] " "$_l_percent"
    fi
    done
    echo ""
;;
esac
return 0
}

# Function: ssft_read_string TITLE QUESTION
#
# Description: Read a string from the user and save the value on the variable
# SSFT_RESULT. The function returns 0 if some value was set by the user and !=
# 0 if it wasn't. If the variable SSFT_DEFAULT is set when this function is
# called its value is used as the default string value. Note that the variable
# SSFT_DEFAULT is unset after it is used.

ssft_read_string() {
# Local variables
_l_title="";
_l_question="";
_l_string="";
_l_default="";

# Unset result
unset SSFT_RESULT
# Save default and unset SSFT_DEFAULT
_l_default="$SSFT_DEFAULT";
unset SSFT_DEFAULT

# Check arguments
if [ "$#" -lt 2 ]; then
    return 255
fi

# Set _l_variables
_l_title="$1";
shift;
_l_question="$@";

# Read values
case "$SSFT_FRONTEND" in
zenity)
    _l_string=$( zenity --title "$_l_title" --entry --text "$_l_question" \
                --entry-text "$_l_default" 2> /dev/null );
;;
pydialog)
    _l_string=$( pydialog --title "$_l_title" --inputbox "$_l_question" \
                "$_l_default" 2> /dev/null );
;;
dialog)
    _l_string=$( dialog --stdout --title "$_l_title" --inputbox \
                "$_l_question" 0 0 "$_l_default" );
;;
text)
    if [ -n "$_l_default" ]; then
    ssft_set_textdomain
    _l_DEFAULT_STR=$( eval_gettext " (defaults to '\$_l_default')" )
    ssft_reset_textdomain
    fi
    ssft_print_text_title "$_l_title"
    printf "%s$_l_DEFAULT_STR: " "$_l_question"
    read _l_string
    if [ -z "$_l_string" ]; then
    _l_string="$_l_default"
    fi
    echo ""
;;
*)
    ssft_print_text_title "$_l_title"
    echo "$_l_question: "
    _l_string=""
;;
esac
SSFT_RESULT="$_l_string"
test -n "$_l_string"
return $?
}

# Function: ssft_read_password TITLE QUESTION
#
# Description: Read a password from the user (without echo) and save the value
# on the variable SSFT_RESULT. The function returns 0 if the value was set
# by the user and != 0 if it wasn't.

ssft_read_password() {
# Local variables
_l_title="";
_l_question="";
_l_string="";

# Unset result
unset SSFT_RESULT

# Check arguments
if [ "$#" -lt 2 ]; then
    return 255
fi

# Set _l_variables
_l_title="$1";
shift;
_l_question="$@";

# Read values
case "$SSFT_FRONTEND" in
zenity)
    _l_string=$(
    zenity --title "$_l_title" --entry --hide-text --text "$_l_question" \
            2> /dev/null
    )
;;
pydialog)
    _l_string=$(
    pydialog --title "$_l_title" --password "$_l_question" 2> /dev/null
    )
;;
dialog)
    _l_string=$(
    dialog --stdout --title "$_l_title" --passwordbox "$_l_question" 0 0
    )
;;
text)
    ssft_print_text_title "$_l_title"
    printf "%s: " "$_l_question"
    _l_old_stty_mode=`stty -g`
    stty -echo
    read _l_string
    stty "$_l_old_stty_mode"
    echo ""
;;
*)
    ssft_print_text_title "$_l_title"
    echo "$_l_question: "
    _l_string="";
;;
esac
SSFT_RESULT="$_l_string"
test -n "$_l_string"
return $?
}

# Function: ssft_select_multiple TITLE QUESTION ITEMS_LIST
#
# Description: Select one or multiple items from the ITEMS_LIST and save the
# values on SSFT_RESULT. The function returns 0 if the value was set and != 0
# if it wasn't. If the variable SSFT_DEFAULT is set when this function is
# called and it contains the names of valid options (one by line) they are
# used as the default selection. Note that the variable SSFT_DEFAULT is unset
# after it is used.

ssft_select_multiple() {
# MENU strings
ssft_set_textdomain
_l_PROMPT_STR="`gettext "Option number (0 ends)"`"
_l_OPTIONS_STR="`gettext "Options"`"
ssft_reset_textdomain

# Local variables
_l_title="";
_l_question="";
_l_string="";
_l_option=0;
_l_numitems=0;
_l_count=0;

# Unset result
unset SSFT_RESULT

# Save default and unset SSFT_DEFAULT
_l_default="$SSFT_DEFAULT";
unset SSFT_DEFAULT

# Check args
if [ "$#" -lt 3 ]; then
    return 255;
fi

# Set arguments 
_l_title="$1"; 
_l_question="$2";
shift 2;
_l_numitems=$#;

# Read values 
case "$SSFT_FRONTEND" in
zenity)
    _l_zitems="";
    _l_out="";
    for _l_item in "$@"; do
    _l_selected=$(
        echo "$_l_default" | while read _l_line; do
        if [ "$_l_item" = "$_l_line" ]; then echo "TRUE"; break; fi
        done
    ) 
    if [ -z "$_l_selected" ]; then
        _l_selected="FALSE";
    fi
    if [ -z "$_l_zitems" ]; then
        _l_zitems="$_l_selected '$_l_item'"
    else
        _l_zitems="$_l_zitems $_l_selected '$_l_item'"
    fi
    done
    _l_out=$(
    echo "$_l_zitems" \
    | xargs zenity --title "$_l_title" --list --checklist \
                    --text "$_l_question" --column ""      \
                    --column "$_l_OPTIONS_STR" 2> /dev/null
    )
    _l_string=$( echo $_l_out | sed -n -e '/^..*$/ { s/|/\n/g; p; };' );
;;
pydialog)
    _l_zitems="";
    _l_out="";
    for _l_item in "$@"; do
    _l_selected=$(
        echo "$_l_default" | while read _l_line; do
        if [ "$_l_item" = "$_l_line" ]; then echo "on"; break; fi
        done
    )
    if [ -z "$_l_selected" ]; then
        _l_selected="off";
    fi
    if [ -z "$_l_zitems" ]; then
        _l_zitems="'$_l_item' '$_l_item' $_l_selected"
    else
        _l_zitems="$_l_zitems '$_l_item' '$_l_item' $_l_selected"
    fi
    done
    _l_out=$(
    echo "$_l_zitems" \
    | xargs pydialog --title "$_l_title" --checklist "$_l_question" \
        2> /dev/null
    )
    _l_string=$( echo $_l_out | sed -e 's/^"//; s/"$//; s/" "/\n/g;' );
;;
dialog)
    _l_ditems="";
    for _l_item in "$@"; do
    _l_selected=$(
        echo "$_l_default" | while read _l_line; do
        if [ "$_l_item" = "$_l_line" ]; then echo "on"; break; fi
        done
    ) 
    if [ -z "$_l_selected" ]; then
        _l_selected="off";
    fi
    if [ -z "$_l_ditems" ]; then
        _l_ditems="'$_l_item' '' $_l_selected"
    else
        _l_ditems="$_l_ditems '$_l_item' '' $_l_selected"
    fi
    done
    _l_out=$(
    echo "$_l_ditems" \
    | xargs dialog --stdout --title "$_l_title" \
                    --checklist "$_l_question" 0 0 5 2> /dev/null
    );
    _l_string=$( echo $_l_out | sed -e 's/^"//; s/"$//; s/" "/\n/g;' );
;;
text)
    ssft_print_text_title "$_l_title"
    _l_selected_items=""
    _l_ss=""
    _l_count=0;
    for _l_item in "$@"; do
    _l_selected=$(
        echo "$_l_default" | while read _l_line; do
        if [ "$_l_item" = "$_l_line" ]; then echo "x"; break; fi
        done
    )
    if [ -z "$_l_selected" ]; then
        _l_selected=" ";
    fi
    _l_selected_items="$_l_selected_items$_l_selected"
    _l_count=$(( $_l_count + 1 ))
    done
    while true; do
    _l_count=0;
    for _l_item in "$@"; do
        if [ "$_l_count" -eq "0" ]; then
        echo "$_l_question"
        echo ""
        fi
        _l_count=$(( $_l_count + 1 ))
        _l_ss="$( echo "$_l_selected_items" | cut -b $_l_count )"
        printf " (%s) %2s. %s\n" "$_l_ss" "$_l_count" "$_l_item"
    done | ssft_pager
    echo ""
    printf "%s: " "$_l_PROMPT_STR"
    read _l_option
    _l_option=$(
        echo $_l_option \
        | sed -n -e '/^[[:space:]]*[0-9][0-9]*[[:space:]]*$/ {
            s/[^0-9]//g; p;
        };'
    )
    if [ -n "$_l_option" ]; then
        if [ "$_l_option" -eq "0" ]; then
        _l_ret=0
        _l_count=0
        for _l_item in "$@"; do
            _l_count=$(( $_l_count + 1 ))
            _l_ss="$( echo "$_l_selected_items" | cut -b $_l_count )"
            if [ "$_l_ss" = "x" ]; then
            if [ -z "$_l_string" ]; then
                _l_string="$_l_item"
            else
                _l_string="`printf "%s\n%s" "$_l_string" "$_l_item"`"
            fi
            fi
        done
        break;
        elif [ "$_l_option" -le "$_l_numitems" ]; then
        _l_prefix=""
        if [ "$_l_option" -gt "1" ]; then
            _l_prefix="$(
            echo "$_l_selected_items" | cut -b -$(( $_l_option - 1 ))
            )"
        fi
        _l_suffix="$(
            echo "$_l_selected_items" | cut -b $(( $_l_option + 1 ))-
        )"
        _l_ss="$( echo "$_l_selected_items" | cut -b $_l_option )"
        if [ "$_l_ss" = " " ]; then
            _l_selected_items="${_l_prefix}x${_l_suffix}"
        else
            _l_selected_items="${_l_prefix} ${_l_suffix}"
        fi
        fi
    fi
    done
    echo ""
;;
*)
    ssft_print_text_title "$_l_title"
    echo "$_l_question"
    echo ""
    _l_count=0;
    for _l_item in "$@"; do
    _l_count=$(( $_l_count + 1 ))
    printf " ( ) %2s. %s\n" "$_l_count" "$_l_item"
    done
    echo ""
    echo "$_l_PROMPT_STR: 0"
    _l_string="";
;;
esac
SSFT_RESULT="$_l_string"
test -n "$_l_string"
return $?
}

# Function: ssft_select_single TITLE QUESTION ITEMS_LIST
#
# Description: Select one item from the ITEMS_LIST and save the
# value on SSFT_RESULT. The function returns 0 if the value was set and
# != 0 if it wasn't. If the variable SSFT_DEFAULT is set when this function is
# called and it contains the name of a valid option it is used as the default
# selection. Note that the variable SSFT_DEFAULT is unset after it is used.

ssft_select_single() {
# MENU strings
ssft_set_textdomain
_l_PROMPT_STR="`gettext "Option number"`"
_l_OPTIONS_STR="`gettext "Options"`"
ssft_reset_textdomain

# Local variables
_l_title="";
_l_question="";
_l_ret=255;
_l_string="";
_l_option=0;
_l_numitems=0;
_l_count=0;

# Unset result
unset SSFT_RESULT

# Save default and unset SSFT_DEFAULT
_l_default="$SSFT_DEFAULT";
unset SSFT_DEFAULT

# Check args
if [ "$#" -lt 3 ]; then
    return $_l_ret;
fi

# Set arguments 
_l_title="$1"; 
_l_question="$2";
shift 2;
_l_numitems=$#;

# Read values 
case "$SSFT_FRONTEND" in
zenity)
    _l_zitems="";
    _l_out="";
    for _l_item in "$@"; do
    if [ "$_l_item" = "$_l_default" ]; then
        _l_selected="TRUE";
    else
        _l_selected="FALSE";
    fi
    if [ -z "$_l_zitems" ]; then
        _l_zitems="$_l_selected '$_l_item'"
    else
        _l_zitems="$_l_zitems $_l_selected '$_l_item'"
    fi
    done
    _l_string=$(
    echo "$_l_zitems" \
    | xargs zenity --title "$_l_title" --list --radiolist --text "$_l_question" \
    --column "" --column "$_l_OPTIONS_STR" 2> /dev/null
    )
;;
pydialog)
    _l_zitems="";
    _l_out="";
    for _l_item in "$@"; do
    if [ "$_l_item" = "$_l_default" ]; then
        _l_selected="on";
    else
        _l_selected="off";
    fi
    if [ -z "$_l_zitems" ]; then
        _l_zitems="'$_l_item' '$_l_item' $_l_selected"
    else
        _l_zitems="$_l_zitems '$_l_item' '$_l_item' $_l_selected"
    fi
    done
    _l_out=$(
    echo "$_l_zitems" \
    | xargs pydialog --title "$_l_title" --radiolist "$_l_question" \
        2> /dev/null
    )
    _l_string=$( echo $_l_out | sed -e 's/^"//; s/"$//; s/" "/\n/g;' );
;;
dialog)
    _l_ditems="";
    for _l_item in "$@"; do
    if [ "$_l_item" = "$_l_default" ]; then
        _l_selected="on";
    else
        _l_selected="off";
    fi
    if [ -z "$_l_ditems" ]; then
        _l_ditems="'$_l_item' '' $_l_selected"
    else
        _l_ditems="$_l_ditems '$_l_item' '' $_l_selected"
    fi
    done
    _l_out=$(
    echo "$_l_ditems" \
    | xargs dialog --stdout --title "$_l_title" \
    --radiolist "$_l_question" 0 0 5 2> /dev/null 
    );
    _l_string=$( echo $_l_out | sed -e 's/^"//; s/"$//; s/" "/\n/g;' );
;;
text)
    ssft_print_text_title "$_l_title"
    while true; do
    _l_count=0;
    for _l_item in "$@"; do
        if [ "$_l_count" -eq "0" ]; then
        echo "$_l_question"
        echo ""
        fi
        _l_count=$(( $_l_count + 1 ))
        if [ "$_l_item" = "$_l_default" ]; then
        _l_selected="*"
        else
        _l_selected=" "
        fi
        printf "%s %2s. %s\n" "$_l_selected" "$_l_count" "$_l_item"
    done | ssft_pager
    echo ""
    printf "%s: " "$_l_PROMPT_STR"
    read _l_option
    if [ -n "$_l_default" ] && [ "$_l_option" = "" ]; then
        _l_string="$_l_default"
        _l_ret=0
        break;
    fi
    _l_option=$(
        echo $_l_option \
        | sed -n -e '/^[[:space:]]*[0-9][0-9]*[[:space:]]*$/ {
        s/[^0-9]//g;
        p;
        };'
    )
    if [ -n "$_l_option" ]; then
        if [ "$_l_option" -le "0" ]; then
            sleep 0
        elif [ "$_l_option" -le "$_l_numitems" ]; then
        _l_ret=0
        break;
        fi
    fi
    done
    echo ""
;;
*)
    ssft_print_text_title "$_l_title"
    echo "$_l_question"
    _l_count=0;
    for _l_item in "$@"; do
    _l_count=$(( $_l_count + 1 ))
    if [ "$_l_item" = "$_l_default" ]; then
        _l_selected="*"
    else
        _l_selected=" "
    fi
    printf "%s %2s. %s\n" "$_l_selected" "$_l_count" "$_l_item"
    done
    echo ""
    if [ -n "$_l_default" ]; then
    echo "$_l_PROMPT_STR: ."
    _l_string="$_l_default"
    _l_ret=0
    else
    echo "$_l_PROMPT_STR: 0"
    _l_ret=1
    fi
;;
esac
# Get the string for the dialog and text frontends
if [ "$_l_ret" = "0" ] && [ -z "$_l_string" ]; then
    _l_count=0;
    for _l_item in "$@"; do
    _l_count=$(( $_l_count + 1 ))
    if [ "$_l_option" = "$_l_count" ]; then
        _l_string="$_l_item";
        break;
    fi
    done
fi
SSFT_RESULT="$_l_string"
test -n "$_l_string"
return "$?"
}

# Function: ssft_yesno TITLE QUESTION
# 
# Description: returns 0 if the answer was afirmative and !=0 if it was no or
# cancelled (cancel is usually 255)

ssft_yesno() {
# YES/NO strings
ssft_set_textdomain
_l_YES_STR="`gettext "Yes"`"
_l_NO_STR="`gettext "No"`"
_l_CANCEL_STR="`gettext "Cancel"`"
ssft_reset_textdomain

# Local variables
_l_title="";
_l_question="";
_l_ret=255;

# Check arguments
if [ "$#" -lt 2 ]; then
    return $_l_ret
fi

# Set _l_variables
_l_title="$1";
shift;
_l_question="$@";

# Read values
case "$SSFT_FRONTEND" in
zenity)
    zenity --title "$_l_title" --question --text "$_l_question" 2> /dev/null;
    _l_ret=$?
;;
pydialog)
    pydialog --title "$_l_title" --yesno "$_l_question" 2> /dev/null;
    _l_ret=$?
;;
dialog)
    dialog --stdout --title "$_l_title" --yesno "$_l_question" 0 0;
    _l_ret=$?
;;
text)
    ssft_print_text_title "$_l_title"
    while true; do
    printf "%s [%s|%s|%s]: " "$_l_question" "$_l_YES_STR" "$_l_NO_STR" \
                            "$_l_CANCEL_STR"
    read _l_rep
    _l_yes_rep=`echo ${_l_YES_STR} | grep -i "^$_l_rep"`
    _l_no_rep=`echo ${_l_NO_STR} | grep -i "^$_l_rep"`
    _l_cancel_rep=`echo ${_l_CANCEL_STR} | grep -i "^$_l_rep"`
    if [ -n "$_l_yes_rep" ] && [ -z "$_l_no_rep" ] \
        && [ -z "$_l_cancel_rep" ]; then
        _l_ret=0;
    break;
    elif [ -z "$_l_yes_rep" ] && [ -n "$_l_no_rep" ] \
        && [ -z "$_l_cancel_rep" ]; then
        _l_ret=1;
    break;
    elif [ -z "$_l_yes_rep" ] && [ -z "$_l_no_rep" ] \
        && [ -n "$_l_cancel_rep" ]; then
        _l_ret=255;
    break;
    fi
    done
    echo ""
;;
*)
    ssft_print_text_title "$_l_title"
    echo "$_l_question [$_l_YES_STR|$_l_NO_STR|$_l_CANCEL_STR]: $_l_NO_STR"
    _l_ret=255;
;;
esac
return $_l_ret;
}

# Function: ssft_show_file TITLE FILENAME
#
# Description: Show the contents of the file to the user; if the file does not
# exist the function returns 1

ssft_show_file() {
# Local variables
_l_title="";
_l_file="";

# Check arguments
if [ "$#" -lt 2 ]; then
    return 255
fi

# Set local variables
_l_title="$1";
_l_file="$2";

# Test if the file is readable 
test -r "$_l_file" || return 1

# Compute X11 window width & height -- fall back to 800x600
_l_dimensions="800x600"
case "$SSFT_FRONTEND" in
zenity|pydialog)
    if [ -x "$(which xrandr)" ]; then
    _l_dimensions="$( xrandr | awk '/\*/ { print $1 }' )"
    elif [ -x "$(which xdpyinfo)" ]; then
    _l_dimensions="$( xdpyinfo | awk '/dimensions:/ { print $2 }' )"
    fi
    ;;
esac
_l_width="${_l_dimensions%x*}"
_l_height="${_l_dimensions#*x}"

# Show file 
case "$SSFT_FRONTEND" in
zenity)
    zenity --title "$_l_title" --text-info --filename "$_l_file" \
        --width="$_l_width" --height="$_l_height" 2> /dev/null 
;;
pydialog)
    pydialog --title "$_l_title" --textbox "$_l_file" "$_l_width" "$_l_height" \
            2> /dev/null;
;;
dialog)
    dialog --stdout --title "$_l_title" --textbox "$_l_file" 0 0;
;;
text)
    ssft_print_text_title "$_l_title"
    ssft_pager "$_l_file"
    echo ""
;;
*)
    ssft_print_text_title "$_l_title"
    cat "$_l_file"
    echo ""
;;
esac
return 0
}

# ------
# ssft.sh @VERSION@
