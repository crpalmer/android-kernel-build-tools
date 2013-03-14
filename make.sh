#!/bin/bash -e

. crpalmer-build-config

make    \
        ARCH=arm \
        CROSS_COMPILE="$CROSS_COMPILE" \
        HOST_CC="$HOST_CC" \
	$*
