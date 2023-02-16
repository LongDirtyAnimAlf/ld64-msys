#!/usr/bin/env bash

set -e

TAPI_REPOSITORY=1100.0.11
TAPI_VERSION=11.0.0 # ?!

BUILD_LLVM=$PWD/build-llvm-cmake
BUILD_CLANG=$PWD/build-clang-cmake
LLVM=$PWD/llvm-project

mkdir -p $BUILD_CLANG

CMAKE_EXTRA_ARGS=""
CMAKE_GENERATOR=""
HOST_TRIPLE=""

case "$OSTYPE" in
  darwin*)  CMAKE_GENERATOR=-G"Xcode" ;;
  linux*)   CMAKE_GENERATOR=-G"Unix Makefiles" ;;
  bsd*)     CMAKE_GENERATOR=-G"Unix Makefiles" ;;
  cygwin*)
            HOST_TRIPLE=x86_64-pc-cygwin
            CMAKE_GENERATOR=-G"Unix Makefiles"
  ;;
  msys*)
            if [ "$(getconf LONG_BIT)" == "64" ]; then
              HOST_TRIPLE=x86_64-pc-mingw64
            else
              HOST_TRIPLE=x86_64-pc-mingw32
            fi
            CMAKE_GENERATOR=-G"MSYS Makefiles"
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

mkdir -p $INSTALLPREFIX

INCLUDE_FIX=""
# INCLUDE_FIX+="_D_GNU_SOURCE=1 "
# INCLUDE_FIX+="-std=gnu++17 "
# INCLUDE_FIX+="-stdlib=gnu++17 "
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
INCLUDE_FIX+="-Wno-nonnull "
INCLUDE_FIX+="-Wno-parentheses "
INCLUDE_FIX+="-Wno-stringop-overread "
INCLUDE_FIX+="-Wno-maybe-uninitialized "
INCLUDE_FIX+="-Wno-stringop-overflow"

echo -n $INSTALLPREFIX > INSTALLPREFIX

# INCLUDE_FIX+=" -I${LLVM_INCLUDE_DIRS}"
# INCLUDE_FIX+=" -I${LLVM_LIBRARY_DIRS}"
# -DCMAKE_C_FLAGS="$INCLUDE_FIX -std=gnu17" \
# -DCMAKE_CXX_FLAGS="$INCLUDE_FIX -std=gnu++17" \

cmake \
 -DCMAKE_C_FLAGS="$INCLUDE_FIX" \
 -DCMAKE_CXX_FLAGS="$INCLUDE_FIX" \
 -DCMAKE_C_COMPILER=gcc \
 -DCMAKE_CXX_COMPILER=g++ \
 -DCLANG_PLUGIN_SUPPORT=OFF \
 -DCLANG_ENABLE_STATIC_ANALYZER=OFF \
 -DCLANG_ENABLE_ARCMT=OFF \
 -DENABLE_X86_RELAX_RELOCATIONS=NO \
 -DCMAKE_BUILD_TYPE=RELEASE \
 -DHAVE_CXX_ATOMICS64_WITHOUT_LIB=1 \
 -DLLVM_ENABLE_THREADS=OFF \
 -DLLVM_ENABLE_EXPENSIVE_CHECKS=OFF \
 -DCLANG_BUILD_TOOLS=ON \
 -DCLANG_INCLUDE_DOCS=OFF \
 -DCLANG_INCLUDE_TESTS=OFF \
 -DCLANG_DEFAULT_CXX_STDLIB=libc++ \
 -DCMAKE_INSTALL_PREFIX=$INSTALLPREFIX \
 -Wno-dev \
 -DLLVM_ROOT=$BUILD_LLVM \
 "$CMAKE_GENERATOR" -S $LLVM/clang -B $BUILD_CLANG \
 $CMAKE_EXTRA_ARGS


# -DLLVM_BINARY_DIR=$BUILD_LLVM \
# -DCLANG_DEFAULT_CXX_STDLIB=libc++ \
# -DCLANG_DEFAULT_CXX_STDLIB=libc++ \
# -DCMAKE_CXX_FLAGS="$INCLUDE_FIX -std=gnu++17" \
# -DCMAKE_CXX_STANDARD=11 \


echo ""
echo "## Building clang ##"
echo ""

if [[ $NINJA -eq 1 ]]
then
  ninja -C $BUILD_CLANG install
else
  cmake --build $BUILD_CLANG --target install
fi
