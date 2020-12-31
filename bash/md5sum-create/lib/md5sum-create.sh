#!/bin/bash
#===============================================================================
#
#         FILE: md5sum-create.sh
#
#        USAGE: . md5sum-crate.sh
#
#  DESCRIPTION: Library file for md5sum-create.sh
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#  ORIG AUTHOR: Samuel Gabrielsson <samuel.gabrielsson@gmail.com>
# ORGANIZATION: ---
#      VERSION: 1.0
#      CREATED: 2020-01-16 14:28:51
#     REVISION: ---
#      CHANGES: ---
#
#===============================================================================

#===============================================================================
# Function will print out help and usage
#
# Usage:
# print_usage                   Print program information to the screen
#===============================================================================
print_usage()
{
    print_prog_name
    printf "${prog} will rename media files.

Options:
    -v|--verbose           Run program in verbose mode up to [-v[v[v]]]
    -d|--debug             Show debug information
    -h|--help              Show this help text

Usage:
    ${prog} [options] path

Example:
Rename files in verbose and debug mode
    ${prog} -v -d mydir/

Report bugs to samuel.gabrielsson@gmail.com\n" >&2
}

#===============================================================================
# Function will parse arguments from commandline using getopt and set the
# args_rest variable.
#
# Usage:
# parse_args <list>             Parse all the args from list
#===============================================================================
parse_args()
{
    # Level 1 and 2 are standards (stdout/stderr). Start counting at 2 so that
    # any increase to this will result in a minimum of file descriptor 3.
    # You should leave this alone.
    verbosity=2

    # The highest verbosity we use/allow to be displayed. Feel free to adjust.
    maxverbosity=5

    SHORTOPTS=":vdh"
    LONGOPTS=":verbose,debug,help"
    OPTS=$(getopt --name "$0" \
                  --options ${SHORTOPTS} \
                  --longoptions ${LONGOPTS} \
                  -- "$@")
    # Print error and quit if exit status of getopt returns an error
    if [ $? != 0 ]; then
        exit 1
    fi

    eval set -- "${OPTS}"
    while true; do
        case "${1}" in
        -v|--verbose)
            # Enable verbose mode
            (( verbosity=verbosity+1 ))
            shift
            ;;
        -d|--debug)
            # Enable shell debug mode
            set -x
            shift
            ;;
        -h|--help)
            # Print out help message
            help_="true"
            shift
            ;;
        --)
            # Shift opts and break the while loop
            shift
            break
            ;;
        *)
            # For everything else just break the while loop
            break
            ;;
        esac
    done

    # Start counting from 3 since 1 and 2 are standards (stdout/stderr)
    for v in $(seq 3 $verbosity); do
        # Don't change anything higher than the maximum verbosity allowed
        (( "$v" <= "$maxverbosity" )) && eval exec "$v>&2"
    done

    # From the verbosity level one higher than requested, through the maximum;
    for v in $(seq $(( verbosity+1 )) $maxverbosity ); do
        # Redirect these to bitbucket, provided that they don't match stdout and stderr.
        (( "$v" > "2" )) && eval exec "$v>/dev/null"
    done

    path="${@}"
}

#===============================================================================
# Function will print out the program name in ASCII
#
# Usage:
# print_prog_name               Print ascii art to screen
#===============================================================================
print_prog_name()
{
    ascii_art='
███╗   ███╗██████╗ ███████╗███████╗██╗   ██╗███╗   ███╗       ██████╗██████╗ ███████╗ █████╗ ████████╗███████╗
████╗ ████║██╔══██╗██╔════╝██╔════╝██║   ██║████╗ ████║      ██╔════╝██╔══██╗██╔════╝██╔══██╗╚══██╔══╝██╔════╝
██╔████╔██║██║  ██║███████╗███████╗██║   ██║██╔████╔██║█████╗██║     ██████╔╝█████╗  ███████║   ██║   █████╗
██║╚██╔╝██║██║  ██║╚════██║╚════██║██║   ██║██║╚██╔╝██║╚════╝██║     ██╔══██╗██╔══╝  ██╔══██║   ██║   ██╔══╝
██║ ╚═╝ ██║██████╔╝███████║███████║╚██████╔╝██║ ╚═╝ ██║      ╚██████╗██║  ██║███████╗██║  ██║   ██║   ███████╗
╚═╝     ╚═╝╚═════╝ ╚══════╝╚══════╝ ╚═════╝ ╚═╝     ╚═╝       ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝
By Samuel Gabrielsson (samuel.gabrielsson@gmail.com)\n'

    print_msg "${ascii_art}"
}

#===============================================================================
# Function will cleanup after program exit
#===============================================================================
function on_exit
{
    # Cleanup
    print_msg -info "Cleaing up before exiting..."
}
trap on_exit EXIT
