#!/usr/bin/env bash

export LC_ALL=C
pushd "${0%/*}" &>/dev/null

PLATFORM=$(uname -s)
OPERATING_SYSTEM=$(uname -o || echo "-")

set -e

function verbose_cmd
{
    echo "$@"
    eval "$@"
}

TARGETDIR="$PWD/../../target"
SDKDIR="$TARGETDIR/SDK"

mkdir -p $TARGETDIR
mkdir -p $TARGETDIR/bin

MIN_SDK_VERSION="10.8"
SDK_VERSION="11.0"
BASETRIPLE="apple-darwin19"

BASEOS="MacOSX"
WRAPPER_SDKDIR="$SDKDIR/$BASEOS$SDK_VERSION.sdk"

BASEARCH="x86_64"

verbose_cmd cc -O2 -Wall -Wextra -Wno-format-truncation -pedantic wrapper-clang-darwin.c \
    -DSDK_DIR=\"\\\"$WRAPPER_SDKDIR\\\"\" \
    -DTARGET_CPU=\"\\\"$BASEARCH\\\"\" \
    -DOS_VER_MIN=\"\\\"$MIN_SDK_VERSION\\\"\" \
    -o $TARGETDIR/bin/$BASEARCH-$BASETRIPLE-clang

pushd $TARGETDIR/bin &>/dev/null
verbose_cmd ln -sf $BASEARCH-$BASETRIPLE-clang $BASEARCH-$BASETRIPLE-clang++
popd &>/dev/null

verbose_cmd cc -O2 -Wall -Wextra -Wno-format-truncation -pedantic wrapper-ld.c -o $TARGETDIR/bin/$BASEARCH-$BASETRIPLE-ld
verbose_cmd cc -O2 -Wall -Wextra -Wno-format-truncation -pedantic wrapper-dsymutil.c -o $TARGETDIR/bin/$BASEARCH-$BASETRIPLE-dsymutil
verbose_cmd cc -O2 -Wall -Wextra -Wno-format-truncation -pedantic wrapper-strip.c -o $TARGETDIR/bin/$BASEARCH-$BASETRIPLE-strip

BASEARCH="aarch64"

verbose_cmd cc -O2 -Wall -Wextra -Wno-format-truncation -pedantic wrapper-clang-darwin.c \
    -DSDK_DIR=\"\\\"$WRAPPER_SDKDIR\\\"\" \
    -DTARGET_CPU=\"\\\"$BASEARCH\\\"\" \
    -DOS_VER_MIN=\"\\\"$MIN_SDK_VERSION\\\"\" \
    -o $TARGETDIR/bin/$BASEARCH-$BASETRIPLE-clang

pushd $TARGETDIR/bin &>/dev/null
verbose_cmd ln -sf $BASEARCH-$BASETRIPLE-clang $BASEARCH-$BASETRIPLE-clang++
popd &>/dev/null

verbose_cmd cc -O2 -Wall -Wextra -Wno-format-truncation -pedantic wrapper-ld.c -o $TARGETDIR/bin/$BASEARCH-$BASETRIPLE-ld
verbose_cmd cc -O2 -Wall -Wextra -Wno-format-truncation -pedantic wrapper-dsymutil.c -o $TARGETDIR/bin/$BASEARCH-$BASETRIPLE-dsymutil
verbose_cmd cc -O2 -Wall -Wextra -Wno-format-truncation -pedantic wrapper-strip.c -o $TARGETDIR/bin/$BASEARCH-$BASETRIPLE-strip

MIN_SDK_VERSION="10.4"
SDK_VERSION="10.13"
WRAPPER_SDKDIR="$SDKDIR/$BASEOS$SDK_VERSION.sdk"
BASEARCH="i386"

verbose_cmd cc -O2 -Wall -Wextra -Wno-format-truncation -pedantic wrapper-clang-darwin.c \
    -DSDK_DIR=\"\\\"$WRAPPER_SDKDIR\\\"\" \
    -DTARGET_CPU=\"\\\"$BASEARCH\\\"\" \
    -DOS_VER_MIN=\"\\\"$MIN_SDK_VERSION\\\"\" \
    -o $TARGETDIR/bin/$BASEARCH-$BASETRIPLE-clang

pushd $TARGETDIR/bin &>/dev/null
verbose_cmd ln -sf $BASEARCH-$BASETRIPLE-clang $BASEARCH-$BASETRIPLE-clang++
popd &>/dev/null

verbose_cmd cc -O2 -Wall -Wextra -Wno-format-truncation -pedantic wrapper-ld.c -o $TARGETDIR/bin/$BASEARCH-$BASETRIPLE-ld
verbose_cmd cc -O2 -Wall -Wextra -Wno-format-truncation -pedantic wrapper-dsymutil.c -o $TARGETDIR/bin/$BASEARCH-$BASETRIPLE-dsymutil
verbose_cmd cc -O2 -Wall -Wextra -Wno-format-truncation -pedantic wrapper-strip.c -o $TARGETDIR/bin/$BASEARCH-$BASETRIPLE-strip

BASEOS="iPhoneOS"

MIN_SDK_VERSION="9.0"
SDK_VERSION="13.7"
BASETRIPLE="apple-ios14"

WRAPPER_SDKDIR="$SDKDIR/$BASEOS$SDK_VERSION.sdk"

BASEARCH="aarch64"

verbose_cmd cc -O2 -Wall -Wextra -Wno-format-truncation -pedantic wrapper-clang-ios.c \
    -DSDK_DIR=\"\\\"$WRAPPER_SDKDIR\\\"\" \
    -DTARGET_CPU=\"\\\"$BASEARCH\\\"\" \
    -DOS_VER_MIN=\"\\\"$MIN_SDK_VERSION\\\"\" \
    -o $TARGETDIR/bin/$BASEARCH-$BASETRIPLE-clang

pushd $TARGETDIR/bin &>/dev/null
verbose_cmd ln -sf $BASEARCH-$BASETRIPLE-clang $BASEARCH-$BASETRIPLE-clang++
popd &>/dev/null

verbose_cmd cc -O2 -Wall -Wextra -Wno-format-truncation -pedantic wrapper-ld.c -o $TARGETDIR/bin/$BASEARCH-$BASETRIPLE-ld

MIN_SDK_VERSION="6.0"
SDK_VERSION="10.0"
BASETRIPLE="apple-ios10"

WRAPPER_SDKDIR="$SDKDIR/$BASEOS$SDK_VERSION.sdk"

BASEARCH="arm"

verbose_cmd cc -O2 -Wall -Wextra -Wno-format-truncation -pedantic wrapper-clang-ios.c \
    -DSDK_DIR=\"\\\"$WRAPPER_SDKDIR\\\"\" \
    -DTARGET_CPU=\"\\\"$BASEARCH\\\"\" \
    -DOS_VER_MIN=\"\\\"$MIN_SDK_VERSION\\\"\" \
    -o $TARGETDIR/bin/$BASEARCH-$BASETRIPLE-clang

pushd $TARGETDIR/bin &>/dev/null
verbose_cmd ln -sf $BASEARCH-$BASETRIPLE-clang $BASEARCH-$BASETRIPLE-clang++
popd &>/dev/null

verbose_cmd cc -O2 -Wall -Wextra -Wno-format-truncation -pedantic wrapper-ld.c -o $TARGETDIR/bin/$BASEARCH-$BASETRIPLE-ld

echo ""
echo "*** all wrappers done ***"
echo ""

