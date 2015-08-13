#!/bin/bash -e

msg() {
    echo
    echo ==== $* ====
    echo
}

# -----------------------

CROSS_COMPILE=/home/crpalmer/cm-12.0/prebuilts/gcc/linux-x86/arm/arm-eabi-4.8/bin/arm-eabi-
HOST_CC=gcc
N_CORES=5

# -----------------------

if [ "$1" = "" ]; then
    . crpalmer-build-config
else
    . $1
    shift
fi

TOOLS_DIR=`dirname "$0"`
MAKE=$TOOLS_DIR/make-common.sh

# -----------------------

if [ "$USE_CCACHE" = 1 ]; then
   export CROSS_COMPILE="ccache $CROSS_COMPILE"
   export HOST_CC="ccache $HOST_CC"
else
   export CROSS_COMPILE="$CROSS_COMPILE"
   export HOST_CC="$HOST_CC"
fi

if [ "$O" != "" ]; then
   Oarg="O=$O"
   mkdir -p $O
else
   Oarg=""
fi

if [ "$BOOT_IMG" = "" ]; then
   export BOOT_IMG="$O/boot.img"
fi

if [ "$DEFCONFIG" = "" -a "$1" != "" ]; then
   export DEFCONFIG="$1"
   shift
fi

msg Building: $VERSION
echo "   Defconfig:       $DEFCONFIG"
echo "   Tools dir:       $TOOLS_DIR"
echo "   Cross compiler:  $CROSS_COMPILE"
echo "   Host compiler:   $HOST_CC"
echo
echo "   Object dir:      $O"
echo
echo "   Device tree img: $DT"
echo "   Initrd:          $INITRD"
echo "   Ramdisk:         $RAMDISK"
echo "   Boot img:        $BOOT_IMG"
echo

msg Generating defconfig

$MAKE $DEFCONFIG $Oarg

msg Compiling

$MAKE -j$N_CORES $Oarg $*

# -----------------------

if [ "$base_addr" != "" ]; then
    BASE="--base $base_addr"
fi

if [ "$page_size" != "" ]; then
    PAGESIZE="--pagesize $page_size"
fi

#if [ "$ramdisk_addr" != "" ]; then
    #RAMDISK_OFFSET="--ramdisk_offset $ramdisk_addr"
#fi

if [ "$CPIO_LIST" != "" ]; then
    msg "Building initrd.img from $CPIO_LIST"
    RAMDISK="$O"/initrd.img
    (set -x ; cd $INITRD; \
	$O/usr/gen_init_cpio $CPIO_LIST | gzip -n -9 -f > $RAMDISK)
elif [ "$RAMDISK" =  "" -a -d "$INITRD" ]; then
    msg "Building initrd.img"
    RAMDISK="$O"/initrd.img
    (set -x ; cd $INITRD ; \
	(find . -type d ; find . ! -type d -a '!' -name '.*') | \
	cpio -R 0:0 -H newc -o | gzip -n -9 -f > $RAMDISK)
fi

if [ "$DT" != "" ]; then
    DT_ARG="--dt $DT"
    ZIMAGE=zImage
else
    ZIMAGE=zImage-dtb
fi

msg Creating boot.img

(set -x
$TOOLS_DIR/mkbootimg \
	-o $BOOT_IMG \
	--kernel $O/arch/arm/boot/$ZIMAGE \
	--ramdisk $RAMDISK \
	--cmdline "$cmd_line" \
	$BASE $PAGESIZE $RAMDISK_OFFSET $DT_ARG
)

msg COMPLETE
echo $BOOT_IMG

