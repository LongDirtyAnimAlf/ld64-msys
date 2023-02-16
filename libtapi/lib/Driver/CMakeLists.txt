add_tapi_library(tapiDriver
  API2XPIConverter.cpp
  ArchiveDriver.cpp
  Configuration.cpp
  ConfigurationFileReader.cpp
  DirectoryScanner.cpp
  Driver.cpp
  DriverOptions.cpp
  DriverUtils.cpp
  GenerateAPITestsDriver.cpp
  Glob.cpp
  HeaderGlob.cpp
  InstallAPIDriver.cpp
  Options.cpp
  ReexportDriver.cpp
  StubDriver.cpp
  Snapshot.cpp
  SnapshotFileSystem.cpp

  DEPENDS
  TapiDriverOptions

  LINK_LIBS
  tapiConfig
  tapiCore
  tapiDiagnostics
  tapiFrontend
  )

if(WIN32 OR CYGWIN)
  target_link_libraries(tapiDriver PRIVATE
    clangBasic
    )
endif()
