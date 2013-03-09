#!/bin/sh

cd initrd && find . | cpio --create --format='newc' | gzip -f > ../initrd.img
