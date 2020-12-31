#!/bin/sh
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
#        AUTHOR:  Samuel Gabrielsson (samuel.gabrielsson@ericsson.com)
#       COMPANY:  ---
#       VERSION:  1.0
#       CREATED:  2015-09-22 09:00:00 CET
#      REVISION:  ---
#       CHANGES:  ---
#
#===============================================================================

#===============================================================================
# The function will:
# 1. First save the current cursor position
# 2. Move the cursor up one line
# 3. Move the cursor to the beginning of the line
# 4. Move the cursor N columns to the right
# 5. Print the status message
# 6. Finally it will restore the cursor to its original position
#
# Usage:
# print_pos <message>               Print status message to screen
#===============================================================================
print_pos()
{
    local msg="${1}"

    # Control the cursor
    local cursor_save="\033[s"
    local cursor_up="\033[1A"
    local cursor_start="\r"
    local cursor_print_position=22
    local cursor_at_print_position="\033[${cursor_print_position}C"
    local cursor_restore="\033[u"

    # Save the cursor position
    printf $cursor_save

    # Go up one line
    printf $cursor_up

    # Position the cursor at the beginning of the line
    printf $cursor_start

    # Move the cursor forward N columns
    printf $cursor_at_print_position

    # Print message
    printf "$msg"

    # Restore cursor position
    printf $cursor_restore
}

#===============================================================================
# A function to print nice to screen.
#
# Usage:
# print <message>                   Print string message as default
# print -fail                       Print FAIL in red color and exit
# print -ok                         Print OK in green color
# print -skip                       Print SKIP in blue color
# print -warn                       Print WARN in yellow color
#===============================================================================
print_msg()
{
    # Handle argument as message or flag to print
    local msg="${1}"

    # Define colors
    local normalize="\033[0m"
    local red="\033[31m"
    local green="\033[32m"
    local yellow="\033[33m"
    local blue="\033[34m"

    # Define timestamp part of prompt
    local timestamp="[${green}$(date +"%Y-%m-%d %H:%M:%S")${normalize}]"

    # Define program part of prompt
    local program="${yellow}${prog}${normalize}:"

    # Initialize an empty status indicator field
    local status="[    ]"

    # Print with color
    case "${msg}" in
        -fail)
            print_pos "${red}FAIL${normalize}"
            ;;
        -ok)
            print_pos "${green} OK ${normalize}"
            ;;
        -skip)
            print_pos "${blue}SKIP${normalize}"
            ;;
        -warn)
            print_pos "${yellow}WARN${normalize}"
            ;;
        *)
            printf "${timestamp}${status} ${program} $msg\n"
            ;;
    esac
}

#===============================================================================
# Function will return MTD erase size in decimal.
#
# Usage:
# get_erase_size "MTD"              Return erase size number for MTD
#
# Example:
# get_erase_size "mtd0"
#===============================================================================
get_erase_size()
{
    local mtd="${1}"
    local erase_size=0

    # Check if function argument is ok
    if [ -z "${mtd}" ]; then
        print_msg "ERROR: No MTD name defined"
        print_msg -fail; exit 1
    fi

    # Check /proc/mtd
    if [ ! -e "/proc/mtd" ]; then
        print_msg "ERROR: /proc/mtd does not exist"
        print_msg -fail; exit 1
    fi

    # Get erase size from /proc/mtd
    erase_size=$(grep "${mtd}" /proc/mtd | awk '{ print $3}')

    # Fix the hex
    erase_size="0x${erase_size}"

    # Convert it from hex to dec
    erase_size=$(printf "%d\n" ${erase_size})

    # If the variable is empty or equal to zero, then something is wrong
    if [ -z "${erase_size}" ] || [ "${erase_size}" -eq 0 ]; then
        print_msg "ERROR: Failed to aquire erase size of MTD ${mtd}"
        print_msg -fail; exit 1
    fi

    # Return the size
    echo "${erase_size}"
}

#===============================================================================
# Function will return the file size in decimal.
#
# Usage:
# get_file_size "file"              Return file size
#===============================================================================
get_file_size()
{
    local file="${1}"
    local file_size=0

    # Check for file
    if [ ! -f "${file}" ]; then
        print_msg "ERROR: Can not find file ${file}"
        print_msg -fail; exit 1
    fi

    # Get file size using wc
    file_size=$(wc -c < ${file})

    # If the variable is empty or equal to zero, then something is wrong
    if [ -z "${file_size}" ] || [ "${file_size}" -eq 0 ]; then
        print_msg "ERROR: Failed to aquire size of file ${file}"
        print_msg -fail; exit 1
    fi

    # Return the size
    echo "${file_size}"
}
