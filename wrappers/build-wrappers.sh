#!/usr/bin/env bash

set -e

mkdir -p fpc-wrappers
mkdir -p fpc-wrappers/lib

echo ""
echo "## Building wrappers ##"
echo ""

FPC=fpc

TARGET=clang
$FPC -damd64_darwin -dCLANG -o./fpc-wrappers/x86_64-apple-darwin19-$TARGET -FU./fpc-wrappers/lib wrapper.lpr
$FPC -darm64_darwin -dCLANG -o./fpc-wrappers/aarch64-apple-darwin19-$TARGET -FU./fpc-wrappers/lib wrapper.lpr
$FPC -di386_darwin -dCLANG -o./fpc-wrappers/i386-apple-darwin19-$TARGET -FU./fpc-wrappers/lib wrapper.lpr
$FPC -darm64_ios -dCLANG -o./fpc-wrappers/aarch64-apple-ios14-$TARGET -FU./fpc-wrappers/lib wrapper.lpr
$FPC -darm_ios -dCLANG -o./fpc-wrappers/arm-apple-ios10-$TARGET -FU./fpc-wrappers/lib wrapper.lpr

TARGET=ld
$FPC -damd64_darwin -dLD -o./fpc-wrappers/x86_64-apple-darwin19-$TARGET -FU./fpc-wrappers/lib wrapper.lpr
$FPC -darm64_darwin -dLD -o./fpc-wrappers/aarch64-apple-darwin19-$TARGET -FU./fpc-wrappers/lib wrapper.lpr
$FPC -di386_darwin -dLD -o./fpc-wrappers/i386-apple-darwin19-$TARGET -FU./fpc-wrappers/lib wrapper.lpr
$FPC -darm64_ios -dLD -o./fpc-wrappers/aarch64-apple-ios14-$TARGET -FU./fpc-wrappers/lib wrapper.lpr
$FPC -darm_ios -dLD -o./fpc-wrappers/arm-apple-ios10-$TARGET -FU./fpc-wrappers/lib wrapper.lpr

echo CLANG
echo DSYMUTIL
echo LD
echo STRIP

echo "Done !"
