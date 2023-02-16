#!/usr/bin/env bash

set -e

BUILD_LLVM=$PWD/build-llvm-cmake
LLVM=$PWD/llvm-project

mkdir -p $BUILD_LLVM

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
 # CMAKE_GENERATOR=-G"Ninja"
 # NINJA=1
# fi

if [ -z "$INSTALLPREFIX" ]; then
#  INSTALLPREFIX="/usr/local/"
  INSTALLPREFIX=$PWD/target/
fi

mkdir -p $INSTALLPREFIX

INCLUDE_FIX=""
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
INCLUDE_FIX+="-Wno-stringop-overflow "
INCLUDE_FIX+="-Wno-unknown-warning-option"

echo -n $INSTALLPREFIX > INSTALLPREFIX

cmake \
 -DCMAKE_C_FLAGS="$INCLUDE_FIX" \
 -DCMAKE_CXX_FLAGS="$INCLUDE_FIX -std=gnu++17" \
 -DCMAKE_C_COMPILER=gcc \
 -DCMAKE_CXX_COMPILER=g++ \
 -DLLVM_INCLUDE_TESTS=OFF \
 -DLLVM_INSTALL_BINUTILS_SYMLINKS=ON \
 -DLLVM_ENABLE_BINDINGS=OFF \
 -DLLVM_ENABLE_ASSERTIONS=OFF \
 -DLLVM_ENABLE_TERMINFO=OFF \
 -DLLVM_ENABLE_UNWIND_TABLES=OFF \
 -DLLVM_ENABLE_TERMINFO=OFF \
 -DLLVM_ENABLE_Z3_SOLVER=OFF \
 -DLLVM_INCLUDE_EXAMPLES=OFF \
 -DLLVM_INCLUDE_BENCHMARKS=OFF \
 -DLLVM_ENABLE_DIA_SDK=OFF \
 -DLLVM_ENABLE_PER_TARGET_RUNTIME_DIR=OFF \
 -DCMAKE_BUILD_TYPE=RELEASE \
 -DHAVE_CXX_ATOMICS64_WITHOUT_LIB=1 \
 -DLLVM_ENABLE_THREADS=OFF \
 -DLLVM_ENABLE_EXPENSIVE_CHECKS=OFF \
 -DLLVM_ENABLE_BACKTRACES=OFF \
 -DLLVM_BUILD_UTILS=OFF \
 -DLLVM_INCLUDE_UTILS=OFF \
 -DLLVM_INSTALL_UTILS=OFF \
 -DLLVM_BUILD_TOOLS=ON \
 -DLLVM_INCLUDE_TOOLS=ON \
 -DLLVM_INCLUDE_TESTS=OFF \
 -DLLVM_INCLUDE_DOCS=OFF \
 -DLLVM_INCLUDE_RUNTIMES=OFF \
 -DCMAKE_INSTALL_PREFIX=$INSTALLPREFIX \
 -DLLVM_INFERRED_HOST_TRIPLE=$HOST_TRIPLE \
 -DLLVM_TOOLCHAIN_TOOLS="dsymutil;llvm-ar;llvm-nm;llvm-objcopy;llvm-objdump;llvm-readelf;llvm-size;llvm-strings;llvm-strip;llvm-windres;ar;nm;objcopy;objdump;readelf;size;strings;strip;windres;" \
 -DLLVM_TARGETS_TO_BUILD="AArch64;ARM;X86" \
 -DLLVM_ENABLE_PROJECTS="clang" \
 -DLLVM_INSTALL_TOOLCHAIN_ONLY=ON \
 -Wno-dev \
 "$CMAKE_GENERATOR" -S $LLVM/llvm -B $BUILD_LLVM \
 $CMAKE_EXTRA_ARGS

# echo ""
# echo "## Building llvm-tools ##"
# echo ""
# -DLLVM_TOOLCHAIN_TOOLS="dsymutil;llvm-ar;llvm-nm;llvm-objcopy;llvm-objdump;llvm-readelf;llvm-size;llvm-strings;llvm-strip;llvm-windres;addr2line;ar;ranlib;nm;objcopy;objdump;readelf;size;strings;strip" \

# -DLLVM_TABLEGEN=/usr/local/bin/llvm-tblgen \
# -DCLANG_TABLEGEN=/usr/local/bin/clang-tblgen \
# -DLLVM_EXTERNAL_PROJECTS="libtapi"
# -DLLVM_EXTERNAL_LIBTAPI_SOURCE_DIR=projects/libtapi
#  -DCLANG_DEFAULT_LINKER=lld \
#  -DLLVM_ENABLE_LLD=ON \
# -DLLVM_ENABLE_PROJECTS="clang;compiler-rt;lld" \
# -DCOMPILER_RT_SANITIZERS_TO_BUILD=asan;dfsan;msan;hwasan;tsan;cfi \
# -DCOMPILER_RT_BUILD_BUILTINS=OFF \
# -DCMAKE_LEGACY_CYGWIN_WIN32=1
# -DLLVM_TABLEGEN=/usr/local/bin/llvm-tblgen \
# -DCLANG_TABLEGEN=/usr/local/bin/clang-tblgen \
# -DCLANG_BUILD_TOOLS=OFF \
# -DLLVM_INSTALL_TOOLCHAIN_ONLY=ON \

# -DTAPI_REPOSITORY_STRING=$TAPI_REPOSITORY \
# -DTAPI_FULL_VERSION=$TAPI_VERSION \

# -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi" \

# -DLLVM_ENABLE_PROJECTS="clang" \
# -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi" \
# -DLLVM_INCLUDE_RUNTIMES=ON \
# -DLIBCXX_ENABLE_SHARED=OFF \
# -DLIBCXX_STATICALLY_LINK_ABI_IN_SHARED_LIBRARY=ON \
# -DLIBCXXABI_ENABLE_SHARED=OFF \

# -DLLVM_TOOLCHAIN_TOOLS="llvm-ar;llvm-ranlib;llvm-objdump;llvm-nm;llvm-strings;llvm-readobj;llvm-dlltool;llvm-pdbutil;llvm-objcopy;llvm-strip;llvm-addr2line;llvm-mc" \
# -DLLVM_ENABLE_RUNTIMES=ld64
# a rutime is build with the new clang compiler !!

# cmake --build . --target dsymutil -- -j 4
# cmake --build . --target llvm-ar -- -j 4
# cmake --build . --target llvm-nm -- -j 4
# cmake --build . --target llvm-objcopy -- -j 4
# cmake --build . --target llvm-objdump -- -j 4
# cmake --build . --target llvm-strip -- -j 4

echo ""
echo "## Building llvm ##"
echo ""

# if [[ -n "$NINJA" ]]
if [[ $NINJA -eq 1 ]]
then
  ninja -C $BUILD_LLVM install
else
  cmake --build $BUILD_LLVM -- -j 4

#  cmake --build $BUILD_LLVM --target X86 -- -j 4
#  cmake --build $BUILD_LLVM --target ARM -- -j 4
#  cmake --build $BUILD_LLVM --target AArch64 -- -j 4

#  cmake --build $BUILD_LLVM --target dsymutil -- -j 4



#  cmake --build $BUILD_LLVM --target llvm-ar -- -j 4
#  cmake --build $BUILD_LLVM --target llvm-nm -- -j 4
#  cmake --build $BUILD_LLVM --target llvm-objcopy -- -j 4
#  cmake --build $BUILD_LLVM --target llvm-objdump -- -j 4
#  cmake --build $BUILD_LLVM --target llvm-readelf -- -j 4
#  cmake --build $BUILD_LLVM --target llvm-size -- -j 4
#  cmake --build $BUILD_LLVM --target llvm-strings -- -j 4
#  cmake --build $BUILD_LLVM --target llvm-strip -- -j 4
#  cmake --build $BUILD_LLVM --target llvm-windres -- -j 4

#  cmake --build $BUILD_LLVM --target ar -- -j 4
#  cmake --build $BUILD_LLVM --target nm -- -j 4
# cmake --build $BUILD_LLVM --target objcopy -- -j 4
# cmake --build $BUILD_LLVM --target objdump -- -j 4
# cmake --build $BUILD_LLVM --target readelf -- -j 4
# cmake --build $BUILD_LLVM --target size -- -j 4
# cmake --build $BUILD_LLVM --target strings -- -j 4
# cmake --build $BUILD_LLVM --target strip -- -j 4
# cmake --build $BUILD_LLVM --target windres -- -j 4

  cmake --build $BUILD_LLVM --target install/fast
fi
