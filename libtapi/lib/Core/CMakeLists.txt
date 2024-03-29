set( LLVM_LINK_COMPONENTS
  Object
  BinaryFormat
  )

add_tapi_library(tapiCore
  Architecture.cpp
  ArchitectureSet.cpp
  API.cpp
  APIJSONSerializer.cpp
  APIPrinter.cpp
  APIVisitor.cpp
  AvailabilityInfo.cpp
  FakeSymbols.cpp
  FileListReader.cpp
  FileManager.cpp
  FileSystem.cpp
  Framework.cpp
  HeaderFile.cpp
  InterfaceFile.cpp
  InterfaceFileManager.cpp
  MachODylibReader.cpp
  MachOReader.cpp
  PackedVersion.cpp
  Path.cpp
  Platform.cpp
  ReexportFileWriter.cpp
  Registry.cpp
  TapiError.cpp
  Target.cpp
  TextStub.cpp
  TextStubv4.cpp
  TextStubCommon.cpp
  Utils.cpp
  XPI.cpp
  XPISet.cpp
  YAMLReaderWriter.cpp
  )

if(WIN32 OR CYGWIN)
  target_link_libraries(tapiCore PRIVATE
    clangBasic
    )
endif()
