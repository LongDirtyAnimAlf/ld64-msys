  {$if defined(amd64_darwin) OR defined(arm64_darwin)}
  MIN_SDK_VERSION='10.8';
  SDK_VERSION='11.0';
  BASETRIPLE='-apple-darwin19';
  BASEOS='MacOSX';
  {$endif}
  {$if defined(i386_darwin)}
  MIN_SDK_VERSION='10.4';
  SDK_VERSION='10.13';
  BASETRIPLE='-apple-darwin19';
  BASEOS='MacOSX';
  {$endif}
  {$ifdef arm64_ios}
  MIN_SDK_VERSION='9.0';
  SDK_VERSION='13.7';
  BASETRIPLE='-apple-ios14';
  BASEOS='iPhoneOS';
  {$endif}
  {$ifdef arm_ios}
  MIN_SDK_VERSION='6.0';
  SDK_VERSION='10.0';
  BASETRIPLE='-apple-ios10';
  BASEOS='iPhoneOS';
  {$endif}

  {$ifdef amd64_darwin}
  TARGETCPU='x86_64';
  {$endif}
  {$if defined(arm64_darwin) OR defined(arm64_ios)}
  TARGETCPU='aarch64';
  {$endif}
  {$ifdef i386_darwin}
  TARGETCPU='i386';
  {$endif}
  {$ifdef arm_ios}
  TARGETCPU='arm';
  {$endif}

  {$ifdef CLANG}
  EXEWRAPPER='clang';
  {$endif}
  {$ifdef DSYMUTIL}
  EXEWRAPPER='dsymutil';
  {$endif}
  {$ifdef LD}
  EXEWRAPPER='ld';
  {$endif}
  {$ifdef STRIP}
  EXEWRAPPER='strip';
  {$endif}

  {$if DECLARED(TARGETCPU) AND DECLARED(BASETRIPLE)}
  TARGETTRIPLE=TARGETCPU+BASETRIPLE;
  {$endif}
  {$if DECLARED(BASEOS) AND DECLARED(SDK_VERSION)}
  SDKDIR=BASEOS+SDK_VERSION+'.sdk';
  {$endif}


