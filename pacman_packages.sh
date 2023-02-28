#!/usr/bin/env bash

echo ""
echo "*** Getting needed packages ***"
echo ""

HOST=i686

pacman -S mc git texinfo bison flex --noconfirm

pacman -S mingw-w64-$HOST-binutils --noconfirm
pacman -S mingw-w64-$HOST-gcc --noconfirm
pacman -S mingw-w64-$HOST-clang --noconfirm
pacman -S mingw-w64-$HOST-libtool --noconfirm
pacman -S mingw-w64-$HOST-cmake --noconfirm
pacman -S mingw-w64-$HOST-make --noconfirm
pacman -S mingw-w64-$HOST-zlib --noconfirm
pacman -S mingw-w64-$HOST-libxml2 --noconfirm
pacman -S mingw-w64-$HOST-dlfcn --noconfirm
pacman -S mingw-w64-$HOST-autotools --noconfirm

echo ""
echo "*** All done ***"
echo ""
