#!/bin/bash
#===============================================================================
#
#          FILE:  generic.sh
#
#         USAGE:  . generic.sh
#
#   DESCRIPTION:  Include this library in any script to handle:
#                 - Nice printing functionality
#
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Samuel Gabrielsson (samuel.gabrielsson@gmail.com)
#       COMPANY:  ---
#       VERSION:  1.0
#       CREATED:  2015-09-22 09:00:00 CET
#      REVISION:  ---
#       CHANGES:  ---
#
#===============================================================================

#===============================================================================
# A function to print nice to screen:
# <TIMESTAMP> [<STATUS>] <NAME>: <MESSAGE>
#
# Usage:
# print <MESSAGE>                   Print INFO string message as default
# print -fail <MESSAGE>             Print FAIL in red color and a message
# print -ok <MESSAGE>               Print OK in green color and a message
# print -skip <MESSAGE>             Print SKIP in blue color and a message
# print -warn <MESSAGE>             Print WARN in yellow color and a message
#===============================================================================
print_msg()
{
    # Set default verbosity level
    local v=3

    # Define colors
    local normalize="\033[0m"
    local red="\033[31m"
    local green="\033[32m"
    local yellow="\033[33m"
    local blue="\033[34m"

    local fail="${red}FAIL${normalize}"
    local info="${blue}INFO${normalize}"
    local ok="${green} OK ${normalize}"
    local skip="${blue}SKIP${normalize}"
    local warn="${yellow}WARN${normalize}"

    # Define timestamp part of prompt
    local timestamp="$(date +"%Y-%m-%d %H:%M:%S")"

    # Initialize an empty status indicator field
    local status="[${info}]"

    # Define program part of prompt
    local program="${yellow}${prog}${normalize}"

    # Print with color
    while true; do
        case "${1}" in
            -fail)
                status="[${fail}]"; v=2; shift
                ;;
            -warn)
                status="[${warn}]"; v=2; shift
                ;;
            -ok)
                status="[${ok}]";   v=3; shift
                ;;
            -info)
                status="[${info}]"; v=4; shift
                ;;
            -skip)
                status="[${skip}]"; v=4; shift
                ;;
            *)
                # Print the rest and break the while loop
                printf "%b\n" "${timestamp} ${status} ${program}: ${1}" >&${v}

                # Exit the program if on a fail
                if [ "${status}" = "[${fail}]" ]; then
                    exit 1
                fi
                break
                ;;
        esac
    done
}

#===============================================================================
# Pushd silent mode
#===============================================================================
pushd()
{
    command pushd "$@" > /dev/null
}

#===============================================================================
# Popd silent mode
#===============================================================================
popd()
{
    command popd "$@" > /dev/null
}
