#!/usr/bin/env bash

set -e

pushd "${0%/*}" &>/dev/null

rm -rf build
mkdir build

pushd build &>/dev/null

CMAKE_EXTRA_ARGS=""
CMAKE_GENERATOR=""
HOST_TRIPLE=""

case "$OSTYPE" in
  darwin*)  CMAKE_GENERATOR=-G"Xcode" ;;
  linux*)   CMAKE_GENERATOR=-G"Unix Makefiles" ;;
  bsd*)     CMAKE_GENERATOR=-G"Unix Makefiles" ;;
  msys*)
            if [ "$(getconf LONG_BIT)" == "64" ]; then
              HOST_TRIPLE=x86_64-pc-mingw64
            else
              HOST_TRIPLE=x86_64-pc-mingw32
            fi
            CMAKE_GENERATOR=-G"MSYS Makefiles"
  ;;
esac

if [ "$(which ninja)" != "" ]; then
  CMAKE_GENERATOR=-G"Ninja"
  NINJA=1
fi

if [ -z "$INSTALLPREFIX" ]; then
  INSTALLPREFIX="./localinstall/"
fi

INCLUDE_FIX="-Wno-incompatible-pointer-types "

cmake .. \
 -DCMAKE_C_FLAGS=$INCLUDE_FIX \
 -DCMAKE_CXX_FLAGS=$INCLUDE_FIX \
 -DCMAKE_C_COMPILER=clang \
 -DCMAKE_CXX_COMPILER=clang++ \
 -DCMAKE_BUILD_TYPE=RELEASE \
 -DLLVM_INCLUDE_TESTS=OFF \
 -DCMAKE_INSTALL_PREFIX=$INSTALLPREFIX \
 -DLLVM_TARGETS_TO_BUILD="AArch64;ARM;PowerPC;X86" \
 -DLLVM_INFERRED_HOST_TRIPLE=$HOST_TRIPLE \
 "$CMAKE_GENERATOR" \
 $CMAKE_EXTRA_ARGS

echo ""
echo "## Building Blocks"
echo ""

cmake --build . --target all

echo ""
echo "## Installing Blocks"
echo ""

cmake --build . --target install

popd &>/dev/null
popd &>/dev/null
