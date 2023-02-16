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

TARGETDIR="$PWD/target"
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
./../ld64/configure --prefix=$TARGETDIR --with-libtapi=$TARGETDIR CXXFLAGS="-Wl,--allow-multiple-definition"
# $GNUMAKE clean
$GNUMAKE -j$JOBS
$GNUMAKE install
popd &>/dev/null
popd &>/dev/null

echo ""
echo "*** All done ***"
echo ""
