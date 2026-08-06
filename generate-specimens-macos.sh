#!/bin/bash
#
# Script to generate Mac OS disk image test files

EXIT_SUCCESS=0
EXIT_FAILURE=1

# Checks the availability of a binary and exits if not available.
#
# Arguments:
#   a string containing the name of the binary
#
assert_availability_binary()
{
    local BINARY=$1

    which ${BINARY} > /dev/null 2>&1
    if test $? -ne ${EXIT_SUCCESS}
    then
        echo "Missing binary: ${BINARY}"
        echo ""

        exit ${EXIT_FAILURE}
    fi
}

# Returns the older (earlier) version of two versions
# Note that versions of Mac OS before 10.13 do not support "sort -V"
get_earliest_version()
{
    VERSION1="$1"
    VERSION2="$2"

    # Extract major and minor components using POSIX cut
    MAJOR_VERSION1=`echo "$VERSION1" | cut -d. -f1`
    MINOR_VERSION1=`echo "$VERSION1" | cut -d. -f2`
    MAJOR_VERSION2=`echo "$VERSION2" | cut -d. -f1`
    MINOR_VERSION2=`echo "$VERSION2" | cut -d. -f2`

    # Treat empty minor versions as 0
    [ -z "$MINOR_VERSION1" ] && MINOR_VERSION1=0
    [ -z "$MINOR_VERSION2" ] && MINOR_VERSION2=0

    # Mathematical evaluation using standard 'expr'
    if [ "$MAJOR_VERSION1" -lt "$MAJOR_VERSION2" ]; then
        echo "$VERSION1"
    elif [ "$MAJOR_VERSION1" -gt "$MAJOR_VERSION2" ]; then
        echo "$VERSION2"
    elif [ "$MINOR_VERSION1" -le "$MINOR_VERSION2" ]; then
        echo "$VERSION1"
    else
        echo "$VERSION2"
    fi
}

# Returns the newer (latest) version of two versions
# Note that versions of Mac OS before 10.13 do not support "sort -V"
get_latest_version()
{
    VERSION1="$1"
    VERSION2="$2"

    MAJOR_VERSION1=`echo "$VERSION1" | cut -d. -f1`
    MINOR_VERSION1=`echo "$VERSION1" | cut -d. -f2`
    MAJOR_VERSION2=`echo "$VERSION2" | cut -d. -f1`
    MINOR_VERSION2=`echo "$VERSION2" | cut -d. -f2`

    [ -z "$MINOR_VERSION1" ] && MINOR_VERSION1=0
    [ -z "$MINOR_VERSION2" ] && MINOR_VERSION2=0

    if [ "$MAJOR_VERSION1" -gt "$MAJOR_VERSION2" ]; then
        echo "$VERSION1"
    elif [ "$MAJOR_VERSION1" -lt "$MAJOR_VERSION2" ]; then
        echo "$VERSION2"
    elif [ "$MINOR_VERSION1" -ge "$MINOR_VERSION2" ]; then
        echo "$VERSION1"
    else
        echo "$VERSION2"
    fi
}

assert_availability_binary hdiutil
assert_availability_binary sw_vers

MACOS_VERSION=`sw_vers -productVersion`
SHORT_VERSION=`echo "${MACOS_VERSION}" | sed 's/^\([0-9][0-9]*[.][0-9][0-9]*\).*$/\1/'`

if test -d ${MACOS_VERSION}
then
    echo "Specimens directory: ${MACOS_VERSION} already exists."

    exit ${EXIT_FAILURE}
fi

SPECIMENS_PATH="specimens/${MACOS_VERSION}"

mkdir -p ${SPECIMENS_PATH}

set -e

# New Blank Image options:
#   SPARSEBUNDLE - sparse bundle disk image
#   SPARSE - sparse disk image
#   UDIF - read/write disk image
#   UDTO - DVD/CD master

IMAGE_TYPES=(SPARSEBUNDLE SPARSE UDIF UDTO)

for IMAGE_TYPE in ${IMAGE_TYPES[*]}
do
    IMAGE_NAME=`echo ${IMAGE_TYPE} | tr 'A-Z' 'a-z'`
    IMAGE_NAME="blank-${IMAGE_NAME}"

    echo "Creating: ${IMAGE_TYPE}"
    hdiutil create -size "4M" -type ${IMAGE_TYPE} ${SPECIMENS_PATH}/${IMAGE_NAME}
done

# File System options:
#   APFS - APFS
#   Case-sensitive APFS - APFS (Case-sensitive)
#   Case-sensitive HFS+ - Mac OS Extended (Case-sensitive)
#   Case-sensitive Journaled HFS+ - Mac OS Extended (Case-sensitive, Journaled)
#   ExFAT - ExFAT
#   HFS - Mac OS Standard
#   HFS+ - Mac OS Extended
#   Journaled HFS+ - Mac OS Extended (Journaled)
#   MS-DOS FAT12 - MS-DOS (FAT12)
#   MS-DOS FAT16 - MS-DOS (FAT16)
#   MS-DOS FAT32 - MS-DOS (FAT32)
#   MS-DOS - MS-DOS (FAT)
#   UDF - Universal Disk Format (UDF)
#   UFS - UNIX File System

# Note that "MS-DOS FAT32" errors with "operation not permitted"

OLDIFS=${IFS}
IFS="
"

FS_TYPES=("UDF" "MS-DOS FAT12" "MS-DOS" "HFS+" "Case-sensitive HFS+" "Case-sensitive Journaled HFS+" "Journaled HFS+")

for FS_TYPE in ${FS_TYPES[*]}
do
    IMAGE_NAME=`echo ${FS_TYPE} | tr 'A-Z' 'a-z' | tr ' ' '_'`
    IMAGE_NAME="fs-${IMAGE_NAME}"

    echo "Creating: ${FS_TYPE}"
    hdiutil create -fs ${FS_TYPE} -size "4M" -type UDIF ${SPECIMENS_PATH}/${IMAGE_NAME}
done

echo "Creating: MS-DOS FAT16"
hdiutil create -fs "MS-DOS FAT16" -size "16M" -type UDIF "${SPECIMENS_PATH}/ms-dos_fat16"

echo "Creating: MS-DOS FAT32"
hdiutil create -fs "MS-DOS FAT32" -size "64M" -type UDIF "${SPECIMENS_PATH}/ms-dos_fat32"

MINIMUM_VERSION=`get_earliest_version "${SHORT_VERSION}" "10.6"`

# ExFAT was introduced in Mac OS 10.6
if test "${MINIMUM_VERSION}" = "10.6"
then
    FS_TYPE="ExFat"

    IMAGE_NAME=`echo ${FS_TYPE} | tr 'A-Z' 'a-z' | tr ' ' '_'`
    IMAGE_NAME="fs-${IMAGE_NAME}"

    echo "Creating: ${FS_TYPE}"
    hdiutil create -fs ${FS_TYPE} -size "4M" -type UDIF ${SPECIMENS_PATH}/${IMAGE_NAME}
fi

MAXIMUM_VERSION=`get_latest_version "${SHORT_VERSION}" "10.5"`

# HFS was removed in Mac OS 10.6
if test "${MAXIMUM_VERSION}" = "10.5"
then
    FS_TYPE="HFS"

    IMAGE_NAME=`echo ${FS_TYPE} | tr 'A-Z' 'a-z' | tr ' ' '_'`
    IMAGE_NAME="fs-${IMAGE_NAME}"

    echo "Creating: ${FS_TYPE}"
    hdiutil create -fs ${FS_TYPE} -size "4M" -type UDIF ${SPECIMENS_PATH}/${IMAGE_NAME}
fi

MAXIMUM_VERSION=`get_latest_version "${SHORT_VERSION}" "10.6"`

# UFS was removed in Mac OS 10.7
if test "${MAXIMUM_VERSION}" = "10.6"
then
    FS_TYPE="UFS"

    IMAGE_NAME=`echo ${FS_TYPE} | tr 'A-Z' 'a-z' | tr ' ' '_'`
    IMAGE_NAME="fs-${IMAGE_NAME}"

    echo "Creating: ${FS_TYPE}"
    hdiutil create -fs ${FS_TYPE} -size "4M" -type UDIF ${SPECIMENS_PATH}/${IMAGE_NAME}
fi

MINIMUM_VERSION=`get_earliest_version "${SHORT_VERSION}" "10.13"`

# APFS was introduced in Mac OS 10.13
if test "${MINIMUM_VERSION}" = "10.13"
then
    FS_TYPES=("Case-sensitive APFS" "APFS")

    for FS_TYPE in ${FS_TYPES[*]}
    do
        IMAGE_NAME=`echo ${FS_TYPE} | tr 'A-Z' 'a-z' | tr ' ' '_'`
        IMAGE_NAME="fs-${IMAGE_NAME}"

        echo "Creating: ${FS_TYPE}"
        hdiutil create -fs ${FS_TYPE} -size "4M" -type UDIF ${SPECIMENS_PATH}/${IMAGE_NAME}
    done
fi

IFS=${OLDIFS}

# Image from Folder options:
#   DC42 - Disk Copy 4.2
#   IPOD - iPod image
#   RdWr - NDIF read/write
#   Rdxx - NDIF read-only
#   Rken - NDIF compressed (KenCode)
#   ROCo - NDIF compressed
#   SPARSEBUNDLE - sparse bundle disk image
#   SPARSE - sparse disk image
#   UDBZ - compressed (bzip2)
#   UDCO - compressed (ADC)
#   UDIF - read/write disk image
#   UDRO - read-only
#   UDRW - read/write
#   UDSB - sparsebundle
#   UDSP - sparse
#   UDTO - DVD/CD master
#   UDxx - UDIF stub
#   UDZO - compressed
#   UFBI - entire device
#   ULFO - compressed (lzfse)
#   ULMO - compressed (lzma)
#   UNIV - hybrid image (HFS+/ISO/UDF)

# Note that UDxx fails on Big Sur with "function not implemented"

SOURCE_FOLDER="srcfolder"

rm -rf ${SOURCE_FOLDER}
mkdir ${SOURCE_FOLDER}

cp README.md ${SOURCE_FOLDER}

FORMAT_TYPES=(UDIF UNIV SPARSEBUNDLE SPARSE)

for FORMAT_TYPE in ${FORMAT_TYPES[*]}
do
    IMAGE_NAME=`echo ${FORMAT_TYPE} | tr 'A-Z' 'a-z'`
    IMAGE_NAME="folder-${IMAGE_NAME}"

    echo "Creating: ${FORMAT_TYPE} of folder"
    # Note: older versions of hdiutil require -fs argument
    hdiutil create -srcfolder ${SOURCE_FOLDER} -fs HFS+ -size "4M" -format ${FORMAT_TYPE} ${SPECIMENS_PATH}/${IMAGE_NAME}
done

MAXIMUM_VERSION=`get_latest_version "${SHORT_VERSION}" "10.10"`

# DC42 and NDIF support was removed in Mac OS 10.11
if test "${MAXIMUM_VERSION}" = "10.10"
then
    echo "Creating: DC42 of folder"
    hdiutil create -srcfolder ${SOURCE_FOLDER} -fs MS-DOS -size "1440K" -format DC42 ${SPECIMENS_PATH}/folder-dc42

    FORMAT_TYPES=(RdWr Rdxx ROCo Rken)

    for FORMAT_TYPE in ${FORMAT_TYPES[*]}
    do
        IMAGE_NAME=`echo ${FORMAT_TYPE} | tr 'A-Z' 'a-z'`
        IMAGE_NAME="folder-${IMAGE_NAME}"

        echo "Creating: ${FORMAT_TYPE} of folder"
        # Note: older versions of hdiutil require -fs argument
        hdiutil create -srcfolder ${SOURCE_FOLDER} -fs MS-DOS -size "4M" -format ${FORMAT_TYPE} ${SPECIMENS_PATH}/${IMAGE_NAME}
    done
fi

rm -rf ${SOURCE_FOLDER}

FORMAT_TYPES=(UDRO UDCO UDZO UDBZ ULFO ULMO UFBI IPOD UDSB UDSP UDRW UDTO)

BASE_IMAGE_NAME="folder-udif"

for FORMAT_TYPE in ${FORMAT_TYPES[*]}
do
    IMAGE_NAME=`echo ${FORMAT_TYPE} | tr 'A-Z' 'a-z'`
    IMAGE_NAME="folder-${IMAGE_NAME}"

    echo "Creating: ${FORMAT_TYPE}"
    hdiutil convert ${SPECIMENS_PATH}/${BASE_IMAGE_NAME}.dmg -format ${FORMAT_TYPE} -o ${SPECIMENS_PATH}/${IMAGE_NAME}
done

# Image from Device options:
#   DC42 - Disk Copy 4.2
#   IPOD - iPod image
#   RdWr - NDIF read/write
#   Rdxx - NDIF read-only
#   Rken - NDIF compressed (KenCode)
#   ROCo - NDIF compressed
#   UDBZ - compressed (bzip2)
#   UDCO - compressed (ADC)
#   UDRO - read-only
#   UDRW - read/write
#   UDSB - sparsebundle
#   UDSP - sparse
#   UDTO - DVD/CD master
#   UDxx - UDIF stub
#   UDZO - compressed
#   UFBI - entire device
#   ULFO - compressed (lzfse)

# Note encryption format 1 support presumably removed in macOS 13 (Ventura) "-tgtimagekey encrypted-encoding-version=1"

echo -n testMODI | hdiutil convert ${SPECIMENS_PATH}/${BASE_IMAGE_NAME}.dmg -encryption AES-128 -format UDZO -stdinpass -o ${SPECIMENS_PATH}/folder-udzo-aes128

echo -n testMODI | hdiutil convert ${SPECIMENS_PATH}/${BASE_IMAGE_NAME}.dmg -encryption AES-256 -format UDZO -stdinpass -o ${SPECIMENS_PATH}/folder-udzo-aes256

# TODO: -segmentSize
# hdiutil create -srcdevice /dev/rdisk# -segmentSize 1M segments
# hdiutil: WARNING: -segmentSize is deprecated

# Creating a UDIF with a resource fork, only works with older versions of hdiutil.
# Tested on Mac OS 10.4 (Lion).
#
# hdiutil unflatten test.dmg
# hdiutil flatten -noxml test.dmg

exit ${EXIT_SUCCESS}
