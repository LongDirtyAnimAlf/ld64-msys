#!/usr/bin/env bash

set -e

BUILD_BLOCKS=$PWD/build-blocks-cmake
BUILD_LLVM=/mingw64
BUILD_CLANG=/mingw64
# SOURCE_LLVM=$PWD/llvm-project/llvm
SOURCE_BLOCKS=$PWD/blocks

mkdir -p $BUILD_BLOCKS

CMAKE_EXTRA_ARGS=""
CMAKE_GENERATOR=""
HOST_TRIPLE=""

C_COMPILER="clang"
CXX_COMPILER="clang++"

case "$OSTYPE" in
  darwin*)
            export PATH="/Applications/CMake.app/Contents/bin":"$PATH"
            CMAKE_GENERATOR=-G"Unix Makefiles"
  ;;
  linux*)   CMAKE_GENERATOR=-G"Unix Makefiles" ;;
  bsd*)     CMAKE_GENERATOR=-G"Unix Makefiles" ;;
  cygwin*)
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
 -DCMAKE_CXX_FLAGS=$INCLUDE_FIX \
 -DCMAKE_C_COMPILER=$C_COMPILER \
 -DCMAKE_CXX_COMPILER=$CXX_COMPILER \
 -DCMAKE_BUILD_TYPE=RELEASE \
 -DCMAKE_INSTALL_PREFIX=$INSTALLPREFIX \
 -Wno-dev \
 "$CMAKE_GENERATOR" -S $SOURCE_BLOCKS -B $BUILD_BLOCKS \
 $CMAKE_EXTRA_ARGS

echo ""
echo "## Building Blocks"
echo ""

cmake --build $BUILD_BLOCKS -j 4

echo ""
echo "## Installing Blocks"
echo ""

cmake --build $BUILD_BLOCKS --target install
