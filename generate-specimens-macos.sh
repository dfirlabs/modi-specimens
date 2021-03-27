#!/bin/bash
#
# Script to generate Mac OS disk image test files

EXIT_SUCCESS=0;
EXIT_FAILURE=1;

MACOS_VERSION=`sw_vers -productVersion`;

if test -d ${MACOS_VERSION};
then
	echo "Specimens directory: ${MACOS_VERSION} already exists.";

	exit ${EXIT_FAILURE};
fi

SPECIMENS_PATH="specimens/${MACOS_VERSION}";

mkdir -p ${SPECIMENS_PATH};

set -e;

# New Blank Image options:
#   SPARSEBUNDLE - sparse bundle disk image
#   SPARSE - sparse disk image
#   UDIF - read/write disk image
#   UDTO - DVD/CD master

IMAGE_TYPES=(SPARSEBUNDLE SPARSE UDIF UDTO);

for IMAGE_TYPE in ${IMAGE_TYPES[*]};
do
	IMAGE_NAME=`echo ${IMAGE_TYPE} | tr 'A-Z' 'a-z'`;
	IMAGE_NAME="blank-${IMAGE_NAME}";
	IMAGE_SIZE="4M";

	hdiutil create -size ${IMAGE_SIZE} -type ${IMAGE_TYPE} ${SPECIMENS_PATH}/${IMAGE_NAME};
done

# File System options:
#   UDF - Universal Disk Format (UDF)
#   MS-DOS FAT12 - MS-DOS (FAT12)
#   MS-DOS - MS-DOS (FAT)
#   MS-DOS FAT16 - MS-DOS (FAT16)
#   MS-DOS FAT32 - MS-DOS (FAT32)
#   HFS+ - Mac OS Extended
#   Case-sensitive HFS+ - Mac OS Extended (Case-sensitive)
#   Case-sensitive Journaled HFS+ - Mac OS Extended (Case-sensitive, Journaled)
#   Journaled HFS+ - Mac OS Extended (Journaled)
#   ExFAT - ExFAT
#   Case-sensitive APFS - APFS (Case-sensitive)
#   APFS - APFS

# Note that "MS-DOS FAT32" errors with "operation not permitted"

OLDIFS=${IFS};
IFS="
";

FS_TYPES=("UDF" "MS-DOS FAT12" "MS-DOS" "MS-DOS FAT16" "HFS+" "Case-sensitive HFS+" "Case-sensitive Journaled HFS+" "Journaled HFS+" "ExFAT" "Case-sensitive APFS" "APFS")

for FS_TYPE in ${FS_TYPES[*]};
do
	IMAGE_NAME=`echo ${FS_TYPE} | tr 'A-Z' 'a-z' | tr ' ' '_'`;
	IMAGE_NAME="fs-${IMAGE_NAME}";
	IMAGE_SIZE="4M";

	hdiutil create -fs ${FS_TYPE} -size ${IMAGE_SIZE} -type UDIF ${SPECIMENS_PATH}/${IMAGE_NAME};
done

IFS=${OLDIFS};

# Image from Folder options:
#   UDRO - read-only
#   UDCO - compressed (ADC)
#   UDZO - compressed
#   UDBZ - compressed (bzip2)
#   ULFO - compressed (lzfse)
#   ULMO - compressed (lzma)
#   UFBI - entire device
#   IPOD - iPod image
#   UDxx - UDIF stub
#   UDSB - sparsebundle
#   UDSP - sparse
#   UDRW - read/write
#   UDTO - DVD/CD master
#   DC42 - Disk Copy 4.2
#   RdWr - NDIF read/write
#   Rdxx - NDIF read-only
#   ROCo - NDIF compressed
#   Rken - NDIF compressed (KenCode)
#   UNIV - hybrid image (HFS+/ISO/UDF)
#   SPARSEBUNDLE - sparse bundle disk image
#   SPARSE - sparse disk image
#   UDIF - read/write disk image

# Note that UDxx, RdWr, Rdxx, ROCo and Rken fail on Big Sur with "function not implemented"
# Note that DC42 fails.

FORMAT_TYPES=(UDRO UDCO UDZO UDBZ ULFO ULMO UFBI IPOD UDSB UDSP UDRW UDTO UNIV SPARSEBUNDLE SPARSE UDIF);

SOURCE_FOLDER="srcfolder";

rm -rf ${SOURCE_FOLDER};
mkdir ${SOURCE_FOLDER};

cp README.md ${SOURCE_FOLDER};

for FORMAT_TYPE in ${FORMAT_TYPES[*]};
do
	IMAGE_NAME=`echo ${FORMAT_TYPE} | tr 'A-Z' 'a-z'`;
	IMAGE_NAME="folder-${IMAGE_NAME}";
	IMAGE_SIZE="4M";

	hdiutil create -srcfolder ${SOURCE_FOLDER} -size ${IMAGE_SIZE} -format ${FORMAT_TYPE} ${SPECIMENS_PATH}/${IMAGE_NAME};
done

rm -rf ${SOURCE_FOLDER};

# Image from Device options:
#   UDRO - read-only
#   UDCO - compressed (ADC)
#   UDZO - compressed
#   UDBZ - compressed (bzip2)
#   ULFO - compressed (lzfse)
#   UFBI - entire device
#   IPOD - iPod image
#   UDxx - UDIF stub
#   UDSB - sparsebundle
#   UDSP - sparse
#   UDRW - read/write
#   UDTO - DVD/CD master
#   DC42 - Disk Copy 4.2
#   RdWr - NDIF read/write
#   Rdxx - NDIF read-only
#   ROCo - NDIF compressed
#   Rken - NDIF compressed (KenCode)

exit ${EXIT_SUCCESS};

