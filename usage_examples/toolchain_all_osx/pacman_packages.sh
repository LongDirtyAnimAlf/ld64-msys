#!/usr/bin/env bash

echo ""
echo "*** Getting needed packages ***"
echo ""

pacman -S mc git --noconfirm
pacman -S binutils patch make coreutils --noconfirm
pacman -S $MINGW_PACKAGE_PREFIX-python $MINGW_PACKAGE_PREFIX-python-pygments $MINGW_PACKAGE_PREFIX-python-yaml --noconfirm
pacman -S $MINGW_PACKAGE_PREFIX-binutils --noconfirm
pacman -S $MINGW_PACKAGE_PREFIX-clang --noconfirm
pacman -S $MINGW_PACKAGE_PREFIX-lld --noconfirm
pacman -S $MINGW_PACKAGE_PREFIX-libsystre --noconfirm
pacman -S $MINGW_PACKAGE_PREFIX-openssl --noconfirm
pacman -S $MINGW_PACKAGE_PREFIX-make --noconfirm
pacman -S $MINGW_PACKAGE_PREFIX-cmake --noconfirm
pacman -S $MINGW_PACKAGE_PREFIX-libtool --noconfirm
pacman -S $MINGW_PACKAGE_PREFIX-dlfcn --noconfirm
# pacman -S $MINGW_PACKAGE_PREFIX-automake --noconfirm
# pacman -S $MINGW_PACKAGE_PREFIX-autoconf --noconfirm

echo ""
echo "*** All done ***"
echo ""
