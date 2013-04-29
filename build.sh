#!/bin/bash -e

msg() {
    echo
    echo ==== $* ====
    echo
}

# -----------------------

. crpalmer-build-config

TOOLS_DIR=`dirname "$0"`
MAKE=$TOOLS_DIR/make.sh

# -----------------------

ZIP=$TARGET_DIR/update-$VERSION.zip

UPDATE_ROOT=$LOCAL_BUILD_DIR/update
KEYS=$LOCAL_BUILD_DIR/keys
CERT=$KEYS/certificate.pem
KEY=$KEYS/key.pk8

msg Building: $VERSION
echo "   Defconfig:       $DEFCONFIG"
echo "   Local build dir: $LOCAL_BUILD_DIR"
echo "   Target dir:      $TARGET_DIR"
echo "   Tools dir:       $TOOLS_DIR"
echo
echo "   Target system partition: $SYSTEM_PARTITION"
echo

if [ -e $CERT -a -e $KEY ]
then
    msg Reusing existing $CERT and $KEY
else
    msg Regenerating keys, pleae enter the required information.

    (
	mkdir -p $KEYS
	cd $KEYS
	openssl genrsa -out key.pem 1024 && \
	openssl req -new -key key.pem -out request.pem && \
	openssl x509 -req -days 9999 -in request.pem -signkey key.pem -out certificate.pem && \
	openssl pkcs8 -topk8 -outform DER -in key.pem -inform PEM -out key.pk8 -nocrypt
    )
fi

if [ -e $UPDATE_ROOT ]
then
    rm -rf $UPDATE_ROOT
fi

if [ -e $LOCAL_BUILD_DIR/update.zip ]
then
    rm -f $LOCAL_BUILD_DIR/update.zip
fi

$MAKE $DEFCONFIG

perl -pi -e 's/(CONFIG_LOCALVERSION="[^"]*)/\1-'"$VERSION"'"/' .config

$MAKE -j$N_CORES

msg Kernel built successfully, building $ZIP

mkdir -p $UPDATE_ROOT/system/lib/modules
find . -name '*.ko' -exec cp {} $UPDATE_ROOT/system/lib/modules/ \;

mkdir -p $UPDATE_ROOT/META-INF/com/google/android
cp $TOOLS_DIR/update-binary $UPDATE_ROOT/META-INF/com/google/android
(
    cat <<EOF
$BANNER
EOF
  sed -e "s|@@SYSTEM_PARTITION@@|$SYSTEM_PARTITION|" \
      -e "s|@@FLASH_BOOT@@|$FLASH_BOOT|" \
      < $TOOLS_DIR/updater-script
) > $UPDATE_ROOT/META-INF/com/google/android/updater-script

if [ "$INITRD_FROM" == "" ]; then
    INITRD=$LOCAL_BUILD_DIR/initrd.img
else
    INITRD=$LOCAL_BUILD_DIR/initrd.tmp
    abootimg -x "$INITRD_FROM" /dev/null /dev/null $INITRD /dev/null
fi

abootimg --create $UPDATE_ROOT/boot.img -k arch/arm/boot/zImage -f $LOCAL_BUILD_DIR/bootimg.cfg -r $INITRD
(
    cd $UPDATE_ROOT
    zip -r ../update.zip .
)
java -jar $TOOLS_DIR/signapk.jar $CERT $KEY $LOCAL_BUILD_DIR/update.zip $ZIP

msg COMPLETE
