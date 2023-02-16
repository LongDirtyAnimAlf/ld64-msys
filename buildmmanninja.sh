#!/usr/bin/env bash

set -e

BUILD_INSTALL=$PWD/build-mman-cmake
BUILD_LLVM=/mingw64
BUILD_CLANG=/mingw64
BUILD_SOURCE=$PWD/mman

mkdir -p $BUILD_INSTALL

CMAKE_EXTRA_ARGS=""
CMAKE_GENERATOR=""
HOST_TRIPLE=""

C_COMPILER="clang"

case "$OSTYPE" in
  darwin*)  CMAKE_GENERATOR=-G"Xcode" ;;
  linux*)   CMAKE_GENERATOR=-G"Unix Makefiles" ;;
  bsd*)     CMAKE_GENERATOR=-G"Unix Makefiles" ;;
  cygwin*)
            C_COMPILER=gcc
            HOST_TRIPLE=x86_64-pc-cygwin
            CMAKE_GENERATOR=-G"Unix Makefiles"
  ;;
  msys*)
            if [ "$(getconf LONG_BIT)" == "64" ]; then
              HOST_TRIPLE=x86_64-w64-windows-gnu
            else
              HOST_TRIPLE=i686-w64-windows-gnu
            fi
            CMAKE_GENERATOR=-G"Unix Makefiles"
  ;;
esac

# if [[ "$(which ninja)" != "" ]]
# then
#  CMAKE_GENERATOR=-G"Ninja"
#  NINJA=1
# fi

if [ -z "$INSTALLPREFIX" ]; then
#  INSTALLPREFIX="/usr/local/"
  INSTALLPREFIX=$PWD/target/
fi

INCLUDE_FIX="-Wno-incompatible-pointer-types "

cmake \
 -DCMAKE_C_FLAGS=$INCLUDE_FIX \
 -DCMAKE_C_COMPILER=$C_COMPILER \
 -DCMAKE_BUILD_TYPE=RELEASE \
 -DCMAKE_INSTALL_PREFIX=$INSTALLPREFIX \
 -Wno-dev \
 "$CMAKE_GENERATOR" -S $BUILD_SOURCE -B $BUILD_INSTALL \
 $CMAKE_EXTRA_ARGS

echo ""
echo "## Building mman"
echo ""
cmake --build $BUILD_INSTALL --target all -j 4

echo ""
echo "## Installing mman"
echo ""
cmake --build $BUILD_INSTALL --target install
