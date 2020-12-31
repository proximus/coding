#!/bin/sh
#===============================================================================
#
#         FILE: flash.sh
#
#        USAGE: . flash.sh
#
#  DESCRIPTION: Library file for flash.
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#  ORIG AUTHOR: Samuel Gabrielsson <samuel.gabrielsson@gmail.com>
# ORGANIZATION: ---
#      VERSION: 1.0
#      CREATED: 2017-08-30 16:58:51
#     REVISION: ---
#      CHANGES: ---
#
#===============================================================================

#===============================================================================
# Function will print out the program name in ASCII
#
# Usage:
# print_prog_name               Print ascii art to screen
#===============================================================================
print_prog_name()
{
    ascii_art='
███████╗██╗      █████╗ ███████╗██╗  ██╗
██╔════╝██║     ██╔══██╗██╔════╝██║  ██║
█████╗  ██║     ███████║███████╗███████║
██╔══╝  ██║     ██╔══██║╚════██║██╔══██║
██║     ███████╗██║  ██║███████║██║  ██║
╚═╝     ╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝
By Samuel Gabrielsson (samuel.gabrielsson@gmail.com)'

    printf "${ascii_art}\n"
}

#===============================================================================
# Function will print out help and usage
#
# Usage:
# print_usage                   Print program information to the screen
#===============================================================================
print_usage()
{
    echo "
${prog} will flash the NAND chip on your board.

Options:
    -c,     --copy \"<image> <partition>\"  Copy image file to MTD partition
    -e,     --erase-bootstrap             Erase only bootstrap partition
    -p,     --prepare-data                Format data partition and create a UBI volume
    -f,     --config-file <file>          Use config file. Default is flash.cfg
    -s,     --show-config                 Print config file
    -v,     --verbose                     Run program in verbose mode
    -q,     --quiet                       Run program in quiet mode
    -d,     --debug                       Show debug information
    -h,     --help                        Show this help text

Usage:
    ${prog} [options]

Examples:
Copy over images to Flash Memory and run in verbose
    ${prog} -v

Erase bootstrap
    ${prog} -e

Report bugs to samuel.gabrielsson@gmail.com" >&2
}

#===============================================================================
# Function will print out configuration file
#
# Usage:
# print_config                  Print program configuration file to the screen
#===============================================================================
print_config()
{
    local cfg_file="${1}"
    local divider="==================="

    divider=${divider}${divider}${divider}${divider}
    header="\n %-40s %15s\n"
    format=" %-40s %15s\n"
    width=57

    printf "$header" "IMAGE FILE" "MTD PARTITION"

    printf "%$width.${width}s\n" "$divider"

    printf "$format" ${IMAGES}

    printf "\nSee config file in %s\n" "${cfg_file}"
}

#===============================================================================
# Function will do a sanity check before continuing.
#
# Usage:
# sanity_check <list>               Do a sanity check on list
#===============================================================================
sanity_check()
{
    local list="${1}"

    local file=""
    local mtd=""

    printf "\nRunning sanity checks:\n"
    if [ -z "${list}" ]; then
        print_msg "ERROR: Length of string is zero"
        print_msg -fail; handle_exit
    fi

    set -- $list
    while [ ! -z "${1}" ]; do
        # Take two elements at a time from the list (see config file)
        file="${1}"
        mtd="${2}"

        # Check if the file exists
        if [ ! -f "${file}" ]; then
            print_msg "ERROR: File \"${file}\" does not exist"
            print_msg -fail; handle_exit
        fi

        # Check if the device exists
        if [ ! -c "${mtd}" ]; then
            print_msg "ERROR: MTD \"${mtd}\" does not exist"
            print_msg -fail; handle_exit
        fi

        shift 2
    done

    print_msg "Verify the integrity of copied files with md5sum"
    run_cmd "cd /tmp/images"
    run_cmd "md5sum -c MD5SUM"
    run_cmd "cd -"
    print_msg -ok
}

#===============================================================================
# Function will iterate through all MTD partitions and erase them.
#
# Usage:
# flash_erase <list>            Erase entire MTD partitions
#===============================================================================
flash_erase()
{
    local list="${1}"

    local mtd=""

    printf "\nErasing contents on MTD:\n"
    if [ -z "${list}" ]; then
        print_msg "ERROR: Length of string is zero"
        print_msg -fail; exit 1
    fi

    # Iterate through all the devices and erase the partitions one by one
    set -- $list
    while [ ! -z "${1}" ]; do
        mtd="${2}"

        # Check if the device exists
        if [ ! -c "${mtd}" ]; then
            print_msg "ERROR: MTD \"${mtd}\" does not exist"
            print_msg -fail; exit 1
        fi

        print_msg "Trying to erase MTD \"${mtd}\""
        run_cmd "flash_eraseall ${mtd}"
        print_msg -ok

        shift 2
    done
}

#===============================================================================
# Prepare UBI partition for data storage
#===============================================================================
format_data()
{
    printf "\nPreparing UBI partition for data storage:\n"

    if [ -z "$MTD_DATA" ]; then
        print_msg "ERROR: No MTD defined for data partition"
        print_msg -fail; exit 1
    fi

    # Format data partition and preserve erase counters
    print_msg "Trying to format data partition \"${MTD_DATA}\""
    run_cmd "ubiformat ${MTD_DATA} -q"
    print_msg -ok

    # Attach device
    print_msg "Trying to attach device"
    run_cmd "ubiattach /dev/ubi_ctrl -p ${MTD_DATA}"
    print_msg -ok

    # Create the volume
    print_msg "Trying to create the volume"
    run_cmd "ubimkvol /dev/ubi0 -N data -m"
    print_msg -ok

    # Detach device
    print_msg "Trying to detach device"
    run_cmd "ubidetach -p ${MTD_DATA}"
    print_msg -ok
}

#===============================================================================
# Function will mount a device where the images reside.
#
# Usage:
# mount_device                  Mount device
#===============================================================================
mount_device()
{
    local device="${MOUNT_DEVICE}"
    local directory="${MOUNT_DIRECTORY}"

    printf "\nMounting partition:\n"
    # Check if the device exists
    if [ ! -e "${device}" ]; then
        print_msg "ERROR: Device \"${device}\" does not exist"
        print_msg -fail; exit 1
    fi

    # Create the mount directory
    run_cmd "mkdir -p ${directory}"

    # Mount the device but check first if it is already mounted
    print_msg "Trying to mount \"${device}\" on \"${directory}\""
    if ! $(mountpoint -q "${directory}"); then

        # Run first fsck on the unmounted device just in case
        run_cmd "dosfsck -a ${device}"

        # Now mount the device
        run_cmd "mount ${device} ${directory}"
        print_msg -ok
    else
        print_msg -skip
    fi
}

#===============================================================================
# Function will unmount a device
#
# Usage:
# umount_device                 Unmount device
#===============================================================================
umount_device()
{
    local directory="${MOUNT_DIRECTORY}"

    printf "\nUnounting partition:\n"
    # Check if the directory exists
    if [ ! -d "${directory}" ]; then
        print_msg "ERROR: Directory \"${directory}\" does not exist"
        print_msg -fail; exit 1
    fi

    # Unmount the device but check first if it is already mounted
    print_msg "Trying to unmount \"${directory}\""
    if $(mountpoint -q "${directory}"); then
        run_cmd "umount ${directory}"
        print_msg -ok
    else
        print_msg -skip
    fi
}

#===============================================================================
# Function will copy images to target directory.
#
# Usage:
# copy_images <list> <directory>    Copy images to directory
#===============================================================================
copy_images()
{
    local dir="${IMAGES_DIRECTORY}"
    local dir_target="/tmp/images"

    local list="${1}"

    printf "\nCopying images to target:\n"

    # Create the target directory
    run_cmd "mkdir -p ${dir_target}"

    # Copy images to target directory
    print_msg "Copy images from ${dir} to ${dir_target}"
    run_cmd "cp -r ${dir}/* ${dir_target}"
    print_msg -ok

    # Replace images directory path with target directory path in IMAGES
    print_msg "Replace ${dir} with ${dir_target} in IMAGES variable"
    IMAGES=$(echo "${list}" | sed -e "s|${dir}|${dir_target}|g")
    print_msg -ok
}

#===============================================================================
# Function will resize/expand files with zeroes.
#
# Usage:
# file_resize <list>            Resize file by padding with zeroes
#===============================================================================
file_resize()
{
    local list="${1}"

    local file=""
    local mtd=""

    local file_size=0
    local erase_size=0

    printf "\nResizing images:\n"
    if [ -z "${list}" ]; then
        print_msg "ERROR: No image(s) to resize"
        print_msg -fail; exit 1
    fi

    # Iterate through the list two elements at the time. By using split --
    # <list>, we assign each element in <list> to the bash variables $1, $2, $3,
    # etc. In the end, we use shift to jump two elements on every loop, i.e. we
    # move the values of $3 to $1, and $4 to $2, etc. The while loop ends when
    # the last shifted element $1 is empty.
    set -- $list
    while [ ! -z "${1}" ]; do
        # Take two elements at a time from the list (see config file)
        # The first element is the file name and the second is the MTD.
        file="${1}"
        mtd="${2##*/}"

        # Check if the file exists
        if [ ! -f "${file}" ]; then
            print_msg "ERROR: File \"${file}\" does not exist"
            print_msg -fail; exit 1
        fi

        # Check if the device exists
        if [ -z "${mtd}" ]; then
            print_msg "ERROR: Length of string is zero"
            print_msg -fail; exit 1
        fi

        file_size=$(get_file_size "${file}")
        erase_size=$(get_erase_size "${mtd}")

        # Get the number of blocks as integer whole numbers
        blocks=$((file_size/erase_size + 1))

        # The new file size should be a multiple of the erase size
        file_size_new=$((blocks * erase_size - 1))

        # Skip resizing image file if it is divisible by erase size and if the
        # image file is in UBI format.
        print_msg "Trying to resize file \"${file}\""
        if [ $((file_size % erase_size)) != 0 ] && [ "$(head -c 4 ${file})" != "UBI#" ]; then
            run_cmd "dd if=/dev/zero of=${file} bs=1 count=1 seek=${file_size_new}"
            print_msg -ok
        else
            print_msg -skip
        fi

        shift 2
    done
}

#===============================================================================
# Function will copy bootstrap image in a safe way.
#
# Usage:
# flash_copy_bootstrap <file> <device>  Copy image file to mtd partition
#===============================================================================
flash_copy_bootstrap()
{
    local file="${1}"
    local mtd="${2}"

    local file_part1="/tmp/boot.bin_part1"
    local file_part2="/tmp/boot.bin_part2"

    local status=1

    # Check if the file exists
    if [ ! -f "${file}" ]; then
        print_msg "ERROR: File \"${file}\" does not exist"
        print_msg -fail; exit 1
    fi

    # Check if the device exists
    if [ ! -c "${mtd}" ]; then
        print_msg "ERROR: MTD \"${mtd}\" does not exist"
        print_msg -fail; exit 1
    fi

    # Split bootstrap into two parts
    # 1. First file includes the first 28 bytes
    # 2. Second file consists of the upper part of 32 740 bytes.
    run_cmd "dd if=${file} of=${file_part1} bs=1 skip=0 count=28"
    run_cmd "dd if=${file} of=${file_part2} bs=1 skip=28 count=32740"

    # Write 32768-28=32740bytes (0x7fe4) from 0x1C to 0x8000
    run_cmd "mtd_debug write ${mtd} 0x1c 32740 ${file_part2}"

    # Write only the first 0x1C=28bytes from 0x0 to 0x1C. If the command fails,
    # then erase the partition so that we still can boot from the SD/MMC.
    mtd_debug write ${mtd} 0x0 28 ${file_part1} > /dev/null 2>&1
    status=$?
    if [ ${status} != 0 ]; then
        print_msg "ERROR: mtd_debug write failed!"; print_msg -fail
        run_cmd "mtd_debug erase ${mtd} 0 0x8000"
        exit 1
    fi
}

#===============================================================================
# Function will copy image to flash partition.
#
# Usage:
# flash_copy <list>             Copy image file to mtd partition
#===============================================================================
flash_copy()
{
    local list="${1}"

    local file=""
    local mtd=""

    printf "\nCopying contents to flash:\n"
    if [ -z "${list}" ]; then
        print_msg "ERROR: Length of string is zero"
        print_msg -fail; exit 1
    fi

    set -- $list
    while [ ! -z "${1}" ]; do
        # Take two elements at a time from the list (see config file)
        file="${1}"
        mtd="${2}"

        # Check if the file exists
        if [ ! -f "${file}" ]; then
            print_msg "ERROR: File \"${file}\" does not exist"
            print_msg -fail; exit 1
        fi

        # Check if the device exists
        if [ ! -c "${mtd}" ]; then
            print_msg "ERROR: MTD \"${mtd}\" does not exist"
            print_msg -fail; exit 1
        fi

        # Detect image format:
        # 1. If file is a UBI image, then run ubiformat to copy the image.
        # 2. If file is a AT91 bootstrap image, then copy it in a safe way.
        # 3. For all other files, copy the image with flashcp.
        print_msg "Trying to copy file \"${file}\" to device \"${mtd}\""
        if [ "$(head -c 4 ${file})" = "UBI#" ]; then
            run_cmd "ubiformat --flash-image=${file} ${mtd}"
        elif [ "$(head -c 3000 ${file} | grep "^AT91Bootstrap" | awk '{ print $1}')" = "AT91Bootstrap" ]; then
            flash_copy_bootstrap "${file}" "${mtd}"
        else
            run_cmd "flashcp -v ${file} ${mtd}"
        fi
        print_msg -ok

        shift 2
    done
}
