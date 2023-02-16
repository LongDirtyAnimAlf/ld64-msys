mkdir .\fpc-wrappers
mkdir .\fpc-wrappers\lib
del .\fpc-wrappers\lib\wrapper.o

set FPC="C:\fpcupsystems\trunk\fpc\bin\i386-win32\fpc.exe"

call %FPC% -damd64_darwin -dCLANG -o.\fpc-wrappers\x86_64-apple-darwin19-clang.exe -FU.\fpc-wrappers\lib wrapper.lpr
call %FPC% -darm64_darwin -dCLANG -o.\fpc-wrappers\aarch64-apple-darwin19-clang.exe -FU.\fpc-wrappers\lib wrapper.lpr
call %FPC% -di386_darwin -dCLANG -o.\fpc-wrappers\i386-apple-darwin19-clang.exe -FU.\fpc-wrappers\lib wrapper.lpr
call %FPC% -darm64_ios -dCLANG -o.\fpc-wrappers\aarch64-apple-ios14-clang.exe -FU.\fpc-wrappers\lib wrapper.lpr
call %FPC% -darm_ios -dCLANG -o.\fpc-wrappers\arm-apple-ios10-clang.exe -FU.\fpc-wrappers\lib wrapper.lpr

call %FPC% -damd64_darwin -dLD -o.\fpc-wrappers\x86_64-apple-darwin19-ld.exe -FU.\fpc-wrappers\lib wrapper.lpr
call %FPC% -darm64_darwin -dLD -o.\fpc-wrappers\aarch64-apple-darwin19-ld.exe -FU.\fpc-wrappers\lib wrapper.lpr
call %FPC% -di386_darwin -dLD -o.\fpc-wrappers\i386-apple-darwin19-ld.exe -FU.\fpc-wrappers\lib wrapper.lpr
call %FPC% -darm64_ios -dLD -o.\fpc-wrappers\aarch64-apple-ios14-ld.exe -FU.\fpc-wrappers\lib wrapper.lpr
call %FPC% -darm_ios -dLD -o.\fpc-wrappers\arm-apple-ios10-ld.exe -FU.\fpc-wrappers\lib wrapper.lpr

echo CLANG
echo DSYMUTIL
echo LD
echo STRIP



echo "Done !"
