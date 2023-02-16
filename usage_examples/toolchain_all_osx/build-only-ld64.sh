#!/usr/bin/env bash

export LC_ALL=C
pushd "${0%/*}" &>/dev/null

PLATFORM=$(uname -s)
# OPERATING_SYSTEM=$(uname -s | cut -f 1 -d '_')
OPERATING_SYSTEM=$(uname -o || echo "-")

SDK_VERSION="10.13"
MIN_SDK_VERSION="10.8"
BASEARCH="x86_64"
BASEOS="MacOSX"

if [ $OPERATING_SYSTEM == "Android" ]; then
  export CC="clang -D__ANDROID_API__=26"
  export CXX="clang++ -D__ANDROID_API__=26"
fi

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

function extract()
{
    echo "extracting $(basename $1) ..."
    local tarflags="xf"

    case $1 in
        *.tar.xz)
            xz -dc $1 | tar $tarflags -
            ;;
        *.tar.gz)
            gunzip -dc $1 | tar $tarflags -
            ;;
        *.tar.bz2)
            bzip2 -dc $1 | tar $tarflags -
            ;;
        *)
            echo "unhandled archive type" 1>&2
            exit 1
            ;;
    esac
}

function git_clone_repository
{
    local url=$1
    local branch=$2
    local directory

    directory=$(basename $url)
    directory=${directory/\.git/}

    if [ -n "$CCTOOLS_IOS_DEV" ]; then
        rm -rf $directory
        cp -r $CCTOOLS_IOS_DEV/$directory .
        return
    fi

    if [ ! -d $directory ]; then
        local args=""
        test "$branch" = "master" && args="--depth 1"
        git clone $url $args
    fi

    pushd $directory &>/dev/null

    git reset --hard
    git clean -fdx
    git checkout $branch
    git pull origin $branch

    popd &>/dev/null
}

TMPDIR="$PWD/tmp"
mkdir -p $TMPDIR

TARGETDIR="$PWD/../../target"
SDKDIR="$TARGETDIR/SDK"

PATCH_DIR=$PWD/../../patches

mkdir -p $TARGETDIR
mkdir -p $TARGETDIR/bin
mkdir -p $SDKDIR

# export CC="$TARGETDIR/bin/clang"
# export CXX="$TARGETDIR/bin/clang++"

echo ""
echo "*** building ld64 ***"
echo ""

pushd tmp &>/dev/null
mkdir -p ld64
pushd ld64 &>/dev/null
# $GNUMAKE distclean
#./../../../../ld64/configure --prefix=$TARGETDIR --with-libtapi=$TARGETDIR CXXFLAGS="-Wl,--allow-multiple-definition"
# $GNUMAKE clean
#3$GNUMAKE -j$JOBS
#$GNUMAKE install
popd &>/dev/null
popd &>/dev/null

if [ "$OSTYPE" == "cygwin" ]; then
    cp /bin/cygcrypto-1.1.dll $TARGETDIR/bin
    cp /bin/cygiconv-2.dll $TARGETDIR/bin
    cp /bin/cygintl-8.dll $TARGETDIR/bin
    cp /bin/cygstdc++-6.dll $TARGETDIR/bin
    cp /bin/cyguuid-1.dll $TARGETDIR/bin
    cp /bin/cygwin1.dll $TARGETDIR/bin
    cp /bin/cygz.dll $TARGETDIR/bin
    # cp /bin/cyggcc_s-seh-1.dll $TARGETDIR/bin
    cp /bin/cyggcc_s-1.dll $TARGETDIR/bin
fi
if [ "$OSTYPE" == "msys" ]; then
    cp /mingw64/bin/clang++.exe $TARGETDIR/bin
    cp /mingw64/bin/clang.exe $TARGETDIR/bin
    cp /mingw64/bin/libclang-cpp.dll $TARGETDIR/bin
    cp /mingw64/bin/libclang.dll $TARGETDIR/bin
    cp /mingw64/bin/libffi-8.dll $TARGETDIR/bin
    cp /mingw64/bin/libgcc_s_seh-1.dll $TARGETDIR/bin
    cp /mingw64/bin/libiconv-2.dll $TARGETDIR/bin
    cp /mingw64/bin/libLLVM-15.dll $TARGETDIR/bin
    cp /mingw64/bin/liblzma-5.dll $TARGETDIR/bin
    cp /mingw64/bin/libstdc++-6.dll $TARGETDIR/bin
    cp /mingw64/bin/libwinpthread-1.dll $TARGETDIR/bin
    cp /mingw64/bin/libxml2-2.dll $TARGETDIR/bin
    cp /mingw64/bin/libzstd.dll $TARGETDIR/bin
    cp /mingw64/bin/zlib1.dll $TARGETDIR/bin
fi

echo ""
echo "*** All done ***"
echo ""
