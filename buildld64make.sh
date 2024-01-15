#!/usr/bin/env bash

export LC_ALL=C
pushd "${0%/*}" &>/dev/null

GITREPO=https://github.com/LongDirtyAnimAlf/ld64-msys.git
# git clone $GITREPO

PLATFORM=$(uname -s)
# OPERATING_SYSTEM=$(uname -s | cut -f 1 -d '_')
OPERATING_SYSTEM=$(uname -o || echo "-")

GNUMAKE="make"
if [ $OPERATING_SYSTEM == "FreeBSD" ] || [ $OPERATING_SYSTEM == "OpenBSD" ] || [ $OPERATING_SYSTEM == "NetBSD" ] || [ $OPERATING_SYSTEM == "Solaris" ]; then
  GNUMAKE="gmake"
fi

if [ -z "$LLVM_DSYMUTIL" ]; then
    LLVM_DSYMUTIL=llvm-dsymutil
fi

if [ -z "$LLVM_GSYMUTIL" ]; then
    LLVM_GSYMUTIL=llvm-gsymutil
fi

if [ -z "$JOBS" ]; then
    JOBS=$(nproc 2>/dev/null || ncpus 2>/dev/null || echo 1)
fi

set -e

function verbose_cmd
{
    echo "$@"
    eval "$@"
}

TAPIINCDIR="$PWD/libtapi/include/tapi"
TARGETDIR="$PWD/target"
SDKDIR="$TARGETDIR/SDK"

mkdir -p $TARGETDIR
mkdir -p $TARGETDIR/bin
mkdir -p $TARGETDIR/include
mkdir -p $SDKDIR

if [ $PLATFORM == "Darwin" ]; then
    echo "*** copy tapi headers ***"
    mkdir -p $TARGETDIR/include/tapi
    cp $TAPIINCDIR/APIVersion.h $TARGETDIR/include/tapi
    cp $TAPIINCDIR/Defines.h $TARGETDIR/include/tapi
    cp $TAPIINCDIR/LinkerInterfaceFile.h $TARGETDIR/include/tapi
    cp $TAPIINCDIR/PackedVersion32.h $TARGETDIR/include/tapi
    cp $TAPIINCDIR/Symbol.h $TARGETDIR/include/tapi
    cp $TAPIINCDIR/tapi.h $TARGETDIR/include/tapi
    cp $TAPIINCDIR/Version.h $TARGETDIR/include/tapi
    cp $TAPIINCDIR/Version.inc $TARGETDIR/include/tapi
fi

echo ""
echo "*** building ld64 ***"
echo ""

mkdir -p build-ld64-make
pushd build-ld64-make &>/dev/null

case "$OSTYPE" in
  darwin)
    ./../ld64/configure --prefix=$TARGETDIR --with-libtapi=/Library/Developer/CommandLineTools/usr CXXFLAGS="-I$TARGETDIR/include -Wl,-L$TARGETDIR/lib"
    # ./../ld64/configure --prefix=$TARGETDIR --with-libtapi=$TARGETDIR CXXFLAGS="-I$TARGETDIR/include -Wl,-L$TARGETDIR/lib,-L/Library/Developer/CommandLineTools/usr/lib"
  ;;
  msys*)
    ./../ld64/configure --prefix=$TARGETDIR --with-libtapi=$TARGETDIR CXXFLAGS="-Wl,--allow-multiple-definition"
  ;;
  *)
    ./../ld64/configure --prefix=$TARGETDIR --with-libtapi=$TARGETDIR CXXFLAGS="-Wl,--allow-multiple-definition" LDFLAGS="-Wl,-rpath,\\\$\$ORIGIN/../lib,--enable-new-dtags"
  ;;
esac

# $GNUMAKE distclean
# $GNUMAKE clean
$GNUMAKE -j$JOBS
$GNUMAKE install
popd &>/dev/null

echo ""
echo "*** All done ***"
echo ""
