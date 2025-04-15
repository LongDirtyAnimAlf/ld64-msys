#!/usr/bin/env bash

set -e

TAPI_REPOSITORY=1100.0.11
TAPI_VERSION=11.0.0 # ?!

BUILD_TAPI=$PWD/build-tapi-cmake
BUILD_LLVM=/mingw64
BUILD_CLANG=/mingw64
# SOURCE_LLVM=$PWD/llvm-project/llvm
# SOURCE_TAPI=$PWD/llvm-project/libtapi
SOURCE_TAPI=$PWD/libtapi

mkdir -p $BUILD_TAPI

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
#              HOST_TRIPLE=x86_64-w64-windows-gnu
              HOST_TRIPLE=x86_64-w64-mingw32
              BUILD_LLVM=/mingw64
              BUILD_CLANG=/mingw64
            else
#              HOST_TRIPLE=i686-w64-windows-gnu
              HOST_TRIPLE=i686-w64-mingw32
              BUILD_LLVM=/mingw32
              BUILD_CLANG=/mingw32
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

INCLUDE_FIX="-fPIC "
# INCLUDE_FIX="-I $LIBTAPI_SOURCE_DIR/src/llvm/projects/clang/include -I $PWD/projects/clang/include"
INCLUDE_FIX+="-Wno-error=implicit-fallthrough "
INCLUDE_FIX+="-Wno-error=unused-function "
INCLUDE_FIX+="-Wno-error=switch "
INCLUDE_FIX+="-Wno-error=return-type "
INCLUDE_FIX+="-Wno-error=unused-variable "
INCLUDE_FIX+="-Wno-error=uninitialized "
INCLUDE_FIX+="-Wno-error=implicit-fallthrough "
INCLUDE_FIX+="-Wno-uninitialized "
INCLUDE_FIX+="-Wno-array-bounds "
INCLUDE_FIX+="-Wno-unknown-pragmas "
INCLUDE_FIX+="-Wno-unused-variable "
INCLUDE_FIX+="-Wno-deprecated-declarations "
INCLUDE_FIX+="-Wno-cast-function-type "
INCLUDE_FIX+="-Wno-free-nonheap-object "
# INCLUDE_FIX+="-Wno-stringop-overflow "
INCLUDE_FIX+="-Wno-ignored-attributes "
INCLUDE_FIX+="-Wno-nonnull"

echo -n $INSTALLPREFIX > INSTALLPREFIX

cmake \
 -DCMAKE_C_FLAGS="$INCLUDE_FIX" \
 -DCMAKE_CXX_FLAGS="$INCLUDE_FIX" \
 -DCMAKE_C_COMPILER=$C_COMPILER \
 -DCMAKE_CXX_COMPILER=$CXX_COMPILER \
 -DCMAKE_BUILD_TYPE=RELEASE \
 -DHAVE_CXX_ATOMICS64_WITHOUT_LIB=1 \
 -DCMAKE_INSTALL_PREFIX=$INSTALLPREFIX \
 -DLLVM_HOST_TRIPLE=$HOST_TRIPLE \
 -DTAPI_REPOSITORY_STRING=$TAPI_REPOSITORY \
 -DTAPI_FULL_VERSION=$TAPI_VERSION \
 -Wno-dev \
 -DLLVM_ROOT=$BUILD_LLVM \
 -DCLANG_ROOT=$BUILD_CLANG \
 "$CMAKE_GENERATOR" -S $SOURCE_TAPI -B $BUILD_TAPI \
 $CMAKE_EXTRA_ARGS

echo ""
echo "## Building libtapi ##"
echo ""
cmake --build $BUILD_TAPI -j 4

echo ""
echo "## Installing libtapi ##"
echo ""

cmake --build $BUILD_TAPI --target install-libtapi
cmake --build $BUILD_TAPI --target install-tapi-headers
