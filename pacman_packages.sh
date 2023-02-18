#!/usr/bin/env bash

echo ""
echo "*** Getting needed packages ***"
echo ""

pacman -S mc git texinfo --noconfirm

pacman -S mingw-w64-x86_64-binutils --noconfirm
pacman -S mingw-w64-x86_64-gcc --noconfirm
pacman -S mingw-w64-x86_64-clang --noconfirm
pacman -S mingw-w64-x86_64-libtool --noconfirm
pacman -S mingw-w64-x86_64-cmake --noconfirm
pacman -S mingw-w64-x86_64-make --noconfirm
pacman -S mingw-w64-x86_64-zlib --noconfirm
pacman -S mingw-w64-x86_64-libxml2 --noconfirm
pacman -S mingw-w64-x86_64-dlfcn --noconfirm
pacman -S mingw-w64-x86_64-autotools --noconfirm

echo ""
echo "*** All done ***"
echo ""
