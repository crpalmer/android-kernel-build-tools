android-kernel-build-tools
==========================

To build your kernel you need to have a file in the top level
directory that contains the following configuration variables
(with the defaults that I use to build my dna kernel as an
example):

N_CORES=4
CROSS_COMPILE="ccache /opt/toolchains/linaro-4.7/bin/arm-eabi-"
HOST_CC="ccache gcc"
LOCAL_BUILD_DIR=dna
TARGET_DIR=~/dna/updates
SYSTEM_PARTITION="/dev/block/mmcblk0p32"

The file is "crpalmer-build-config".  In the LOCAL_BUILD_DIR you
must have the following files:

version
initrd.img
bootimg.cfg

The version file contains the local version information, for example

-crpalmer-1.0.20

