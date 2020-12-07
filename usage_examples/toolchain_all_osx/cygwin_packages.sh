#!/usr/bin/env bash

echo ""
echo "*** Getting needed packages ***"
echo ""

#!/bin/bash
# Create a batch file to reinstall using setup-{ARCH}.exe
# all packages reported as incomplete

print_error=1

if [ $# -eq 1 ]
  then
    if [ $1 == "-I" ]
    then
      lista=$(mktemp)
      cygcheck -c | grep "Incomplete" > $lista
      print_error=0
    fi
    if [ $1 == "-A" ]
    then
      lista=$(mktemp)
      cygcheck -cd | sed -e "1,2d" > $lista
      print_error=0
    fi
fi

if [ $# -eq 2 ]
  then
    if [ $1 == "-f" ]
    then
      lista=$2
      print_error=0
    fi
fi

# error message if options are incorrect.
if [ $print_error -eq 1 ]
then
        echo -n "Usage : " $(basename $0)
        echo " [ -A | -I | -f filelist ]"
        echo "  create cyg-reinstall-{ARC}.bat from"
        echo "  options"
        echo "    -A  :  All packages as reported by cygcheck"
        echo "    -I  :  incomplete packages as reported by cygcheck"
        echo "    -f  :  packages in filelist (one per raw)"
        exit 1
fi

if [ $(arch) == "x86_64" ]
then
  A="x86_64"
else
  A="x86"
fi
# writing header
echo -n -e "setup-${A}.exe  " > cyg-reinstall-${A}.bat

# option  -x remove and  -P install
# for re-install packages we need both
if [ $1 == "-I" ]
then
  awk 'BEGIN{printf(" -x ")} NR==1{printf $1}{printf ",%s", $1}' ${lista} >> cyg-reinstall-${A}.bat
fi

awk 'BEGIN{printf(" -P ")} NR==1{printf $1}{printf ",%s", $1} END { printf "\r\n pause "}' ${lista} >> cyg-reinstall-${A}.bat

# execution permission for the script
chmod +x cyg-reinstall-${A}.bat


echo ""
echo "*** All done ***"
echo ""
