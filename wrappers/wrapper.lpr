program wrapper;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, process;

const
  {$I targets.inc}

var
  i: integer;
  AProcess: TProcess;
  aExe,aCPU,aExePath,aSDKPathBase,aSDKPath:string;

begin
  aExePath:=ExtractFilePath(ParamStr(0));

  {$if DECLARED(EXEWRAPPER)}
  aExe:=aExePath+EXEWRAPPER;
  {$ifdef MSWINDOWS}
  aExe:=aExe+'.exe';
  {$endif}
  {$ifdef UNIX}
  if NOT FileExists(aExe) then
  begin
    //if EXEWRAPPER='clang' then
    begin
      aExe:='/usr/bin/'+EXEWRAPPER;
    end;
  end;
  {$endif}
  if FileExists(aExe) then
  begin
    AProcess:=TProcess.Create(nil);

    AProcess.Executable:=aExe;
    APRocess.Options := [poWaitOnExit];

    {$if DECLARED(TARGETCPU)}
    aCPU:=TARGETCPU;
    {$endif}

    if EXEWRAPPER='clang' then
    begin
      {$if DECLARED(TARGETTRIPLE)}
      APRocess.Parameters.Append('-target');
      APRocess.Parameters.Append(TARGETTRIPLE);
      {$endif}
    end;

    aSDKPath:='';
    aSDKPathBase:=aExePath+'..\..\..\lib\';
    if DirectoryExists(aSDKPathBase) then
    begin
      {$if defined(amd64_darwin) OR defined(arm64_darwin) OR defined(i386_darwin)}
      {$if DECLARED(SDKDIR)}
      if NOT DirectoryExists(aSDKPath) then aSDKPath:=aSDKPathBase+'all-darwin\'+SDKDIR;
      {$endif}
      if NOT DirectoryExists(aSDKPath) then aSDKPath:=aSDKPathBase+'all-darwin\SDK';
      if NOT DirectoryExists(aSDKPath) then aSDKPath:=aSDKPathBase+'all-darwin';
      {$if DECLARED(SDKDIR)}
      if NOT DirectoryExists(aSDKPath) then aSDKPath:=aSDKPathBase+TARGETCPU+'-darwin\'+SDKDIR;
      {$endif}
      if NOT DirectoryExists(aSDKPath) then aSDKPath:=aSDKPathBase+TARGETCPU+'-darwin\SDK';
      if NOT DirectoryExists(aSDKPath) then aSDKPath:=aSDKPathBase+TARGETCPU+'-darwin';
      if NOT DirectoryExists(aSDKPath) then aSDKPath:='';
      {$endif}
      {$if defined(arm64_ios) OR defined(arm_ios)}
      {$if DECLARED(SDKDIR)}
      if NOT DirectoryExists(aSDKPath) then aSDKPath:=aSDKPathBase+'all-ios\'+SDKDIR;
      {$endif}
      if NOT DirectoryExists(aSDKPath) then aSDKPath:=aSDKPathBase+'all-ios\SDK';
      if NOT DirectoryExists(aSDKPath) then aSDKPath:=aSDKPathBase+'all-ios';
      {$if DECLARED(SDKDIR)}
      if NOT DirectoryExists(aSDKPath) then aSDKPath:=aSDKPathBase+TARGETCPU+'-ios\'+SDKDIR;
      {$endif}
      if NOT DirectoryExists(aSDKPath) then aSDKPath:=aSDKPathBase+TARGETCPU+'-ios\SDK';
      if NOT DirectoryExists(aSDKPath) then aSDKPath:=aSDKPathBase+TARGETCPU+'-ios';
      if NOT DirectoryExists(aSDKPath) then aSDKPath:='';
      {$endif}
    end;

    aSDKPathBase:=aExePath+'..\..\lib\';
    if DirectoryExists(aSDKPathBase) then
    begin
      {$if defined(amd64_darwin) OR defined(arm64_darwin) OR defined(i386_darwin)}
      {$if DECLARED(SDKDIR)}
      if NOT DirectoryExists(aSDKPath) then aSDKPath:=aSDKPathBase+'all-darwin\'+SDKDIR;
      {$endif}
      if NOT DirectoryExists(aSDKPath) then aSDKPath:=aSDKPathBase+'all-darwin\SDK';
      if NOT DirectoryExists(aSDKPath) then aSDKPath:=aSDKPathBase+'all-darwin';
      {$if DECLARED(SDKDIR)}
      if NOT DirectoryExists(aSDKPath) then aSDKPath:=aSDKPathBase+TARGETCPU+'-darwin\'+SDKDIR;
      {$endif}
      if NOT DirectoryExists(aSDKPath) then aSDKPath:=aSDKPathBase+TARGETCPU+'-darwin\SDK';
      if NOT DirectoryExists(aSDKPath) then aSDKPath:=aSDKPathBase+TARGETCPU+'-darwin';
      if NOT DirectoryExists(aSDKPath) then aSDKPath:='';
      {$endif}
      {$if defined(arm64_ios) OR defined(arm_ios)}
      {$if DECLARED(SDKDIR)}
      if NOT DirectoryExists(aSDKPath) then aSDKPath:=aSDKPathBase+'all-ios\'+SDKDIR;
      {$endif}
      if NOT DirectoryExists(aSDKPath) then aSDKPath:=aSDKPathBase+'all-ios\SDK';
      if NOT DirectoryExists(aSDKPath) then aSDKPath:=aSDKPathBase+'all-ios';
      {$if DECLARED(SDKDIR)}
      if NOT DirectoryExists(aSDKPath) then aSDKPath:=aSDKPathBase+TARGETCPU+'-ios\'+SDKDIR;
      {$endif}
      if NOT DirectoryExists(aSDKPath) then aSDKPath:=aSDKPathBase+TARGETCPU+'-ios\SDK';
      if NOT DirectoryExists(aSDKPath) then aSDKPath:=aSDKPathBase+TARGETCPU+'-ios';
      if NOT DirectoryExists(aSDKPath) then aSDKPath:='';
      {$endif}
    end;

    if (DirectoryExists(aSDKPathBase) AND DirectoryExists(aSDKPath)) then
    begin
      APRocess.Parameters.Append('-isysroot');
      APRocess.Parameters.Append(aSDKPath);
    end;

    for i:=1 to ParamCount() do APRocess.Parameters.Append(ParamStr(i));

    aCPU:='';
    for i:=0 to Pred(APRocess.Parameters.Count) do
    begin
      if APRocess.Parameters[i]='-arch' then
      begin
        aCPU:='We got a CPU target';
        break
      end;
    end;

    if (Length(aCPU)=0) then
    begin
      {$if DECLARED(TARGETCPU)}
      APRocess.Parameters.Append('-arch');
      {$if defined(arm64_darwin) OR defined(arm64_ios)}
      APRocess.Parameters.Append('arm64');
      {$else}
      APRocess.Parameters.Append(TARGETCPU);
      {$endif}
      {$endif}
    end;

    if EXEWRAPPER='clang' then
    begin
      //-mmacosx-version-min=osmin
      //-miphoneos-version-min=osmin
      APRocess.Parameters.Append('-mlinker-version=690');
      //APRocess.Parameters.Append('-Wl,-adhoc_codesign');
      APRocess.Parameters.Append('-Wno-unused-command-line-argument');
      APRocess.Parameters.Append('-Wno-overriding-t-option');
    end;

    AProcess.Execute;

    AProcess.Free;
  end
  else
  begin
    writeln('Error: could not find '+EXEWRAPPER);
  end;
  {$endif}
end.

