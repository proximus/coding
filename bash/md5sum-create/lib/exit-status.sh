#!/bin/bash
#===============================================================================
#
#          FILE:  exit-status.sh
#
#         USAGE:  . exit-status.sh
#
#   DESCRIPTION:  Include this library in any script to execute commands and
#                 handle exit status in a controlled way.
#
#       OPTIONS:  ---
#  REQUIREMENTS:  eval, rev, cut
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Samuel Gabrielsson (samuel.gabrielsson@gmail.com)
#       COMPANY:  ---
#       VERSION:  1.0
#       CREATED:  2015-06-01 09:00:00 CET
#      REVISION:  ---
#       CHANGES:  ---
#
#      EXAMPLES:  run_cmd
#                 run_cmd -c -v "ls -l"
#                 run_cmd
#                 run_cmd -c "foo"
#                 run_cmd -c "fdisk"
#                 run_cmd "ls -lh"
#                 run_cmd
#                 handle_exit
#
#===============================================================================

#===============================================================================
# Function will run any command and save its exit status. If the argument -m has
# been given and the command returns an error exit status, then print out the
# command summary and exit the program immediately.
#
# Usage: run_cmd <command>      # Run command but exit program if command fails
#        run_cmd -c <command>   # Continue running program even if command fails
#        run_cmd -v <command>   # Run command in verbose mode
#===============================================================================
run_cmd()
{
    local args="${1}"
    local do_continue="false"
    local command="n/a"

    if [ -z "${args}" ]; then
        print_msg -info "ERROR: Length of args is zero"
        print_msg -fail; exit 1
    fi

    while [ ! -z "${args}" ]; do
        case "${1}" in
        -c)
            # Continue on fail
            do_continue="true";
            shift
            ;;
        -e)
            # Exit on fail
            do_continue="false";
            shift
            ;;
        -v)
            # This global variable will enable verbose printing to screen
            local do_verbose="true";
            shift
            ;;
        -*)
            echo "ERROR! Unknown run command argument ..."
            break; exit 1
            ;;
        *)
            # We assume everything else is the command to execute
            command="${1}"
            break
            ;;
        esac
    done

    # Execute the command and save the exit status
    if [ ! -z ${do_verbose+x} ]; then
        eval "${command}"
    else
        eval "${command} > /dev/null 2>&1"
    fi
    status=$(exit_status)

    # Append the command to list of commands. Basically just save a history
    # of commands that has been executed.
    statuses="$statuses $status"
    commands="$commands $command"
    summary="${summary}${cmd_index}:${status}:${command}:"

    # Print summary and exit if the command failed to run properly
    if [ ${status} -ne 0 ]; then
        if [ "${do_verbose}" == "true" ]; then
            print_summary
        fi

        printf "ERROR: Failed to execute command #%d:\n" $cmd_index
        echo ${command}

        if [ "${do_continue}" == "false" ]; then
            exit "$status"
        fi
    fi

    # Iterate the index
    cmd_index=$((cmd_index+1))
}

#===============================================================================
# Function appends the exit status of an evaluated command to an array.
#
# Usage: <execute command>
#===============================================================================
exit_status()
{
    local status=$(echo $?)
    echo $status
}

#===============================================================================
# Function prints a summary of the currently executed commands.
#
# Usage: print_summary          # Print summary of exit status and commands
#===============================================================================
print_summary()
{
    divider===============================
    divider=$divider$divider$divider

    header="\n%-5s\t%-13s\t%-s\n"
    format="%-5d\t%-13d\t%-s\n"

    width=80

    printf "%$width.${width}s\n" "$divider"
    printf "RUN COMMAND SUMMARY:\n"
    printf "$header" "INDEX" "EXIT STATUS" "COMMAND"

    printf "%$width.${width}s\n" "$divider"

    # We don't want to change the IFS globally, so we run the command within
    # a subshell created with ().
    summary=$(echo $summary)    # Filter out white spaces
    (IFS=':'; printf "$format" ${summary})

    printf "%$width.${width}s\n" "$divider"
}

#===============================================================================
# If a command in the list failed to execute and returned an error exit status,
# then exit the whole program with an unsuccessful exit code.
#
# Usage: handle_exit
#===============================================================================
handle_exit()
{
    local my_exit=0
    local status=""

    if [ "${do_verbose}" = true ]; then
        print_summary
    fi
    for status in ${statuses}; do
        if [ ${status} -ne 0 ]; then
            my_exit=1
        fi
    done
    exit ${my_exit}
}

# Initialize our global command index counter
cmd_index=0

# Initialize our global list of command exit status
statuses=""

# Initialize our global list of commands
commands=""

# Initialize our global list of summary
summary=""
