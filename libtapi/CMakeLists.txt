#if(NOT APPLE)
#  message(FATAL_ERROR "Unsupported configuration.")
#endif()

cmake_minimum_required(VERSION 3.13.4)

if(NOT DEFINED LLVM_COMMON_CMAKE_UTILS)
  set(LLVM_COMMON_CMAKE_UTILS ${CMAKE_CURRENT_SOURCE_DIR}/../cmake)
endif()
# include(${LLVM_COMMON_CMAKE_UTILS}/Modules/CMakePolicy.cmake
#  NO_POLICY_SCOPE)

# If we are not building as a part of LLVM, build liptapi as an
# standalone project, using LLVM as an external library:
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
  project(libtapi)
  set(LIBTAPI_BUILT_STANDALONE TRUE)
  if ("${CMAKE_VERSION}" VERSION_LESS "3.20.0")
    message(WARNING
      "Your CMake version is ${CMAKE_VERSION}. Starting with LLVM 17.0.0, the "
      "minimum version of CMake required to build LLVM will become 3.20.0, and "
      "using an older CMake will become an error. Please upgrade your CMake to "
      "at least 3.20.0 now to avoid issues in the future!")
  endif()
endif()

# Must go below project(..)
include(GNUInstallDirs)

if(LIBTAPI_BUILT_STANDALONE)
  set(CMAKE_CXX_STANDARD 17 CACHE STRING "C++ standard to conform to")
  set(CMAKE_CXX_STANDARD_REQUIRED YES)

  if (CYGWIN)
    # Cygwin is a bit stricter and lack things like 'strdup', 'stricmp', etc in
    # c++xx mode.
    set(CMAKE_CXX_EXTENSIONS YES)
  else()
  set(CMAKE_CXX_EXTENSIONS NO)
  endif()

  if(NOT MSVC_IDE)
    set(LLVM_ENABLE_ASSERTIONS ${ENABLE_ASSERTIONS}
      CACHE BOOL "Enable assertions")
    # Assertions should follow llvm-config's.
    mark_as_advanced(LLVM_ENABLE_ASSERTIONS)
  endif()

  # If the user specifies a relative path to LLVM_DIR, the calls to include
  # LLVM modules fail. Append the absolute path to LLVM_DIR instead.
  # get_filename_component(LLVM_DIR_ABSOLUTE ${LLVM_DIR} REALPATH)
  # cmake_path(GET LLVM_DIR ROOT_PATH LLVM_DIR_ABSOLUTE)
  cmake_path(ABSOLUTE_PATH LLVM_ROOT NORMALIZE)
  message("-- LLVM_ROOT ${LLVM_ROOT}")
  list(APPEND CMAKE_MODULE_PATH "${LLVM_ROOT}")  
  list(APPEND CMAKE_MODULE_PATH "${LLVM_ROOT}/lib/cmake/llvm")
  # set( CMAKE_FIND_ROOT_PATH ${CMAKE_MODULE_PATH} )
  find_package(LLVM REQUIRED HINTS "${LLVM_CMAKE_DIR}")

  # Turn into CACHE PATHs for overwritting
  set(LLVM_INCLUDE_DIRS "${LLVM_INCLUDE_DIRS}" CACHE PATH "Path to llvm/include and any other header dirs needed")
  set(LLVM_BINARY_DIR "${LLVM_BINARY_DIR}" CACHE PATH "Path to LLVM build tree")
  set(LLVM_MAIN_SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../llvm" CACHE PATH "Path to LLVM source tree")
  set(LLVM_TOOLS_BINARY_DIR "${LLVM_TOOLS_BINARY_DIR}" CACHE PATH "Path to llvm/bin")
  set(LLVM_LIBRARY_DIR "${LLVM_LIBRARY_DIR}" CACHE PATH "Path to llvm/lib")

  find_program(LLVM_TABLEGEN_EXE "llvm-tblgen" ${LLVM_TOOLS_BINARY_DIR}
    NO_DEFAULT_PATH)

  # They are used as destination of target generators.
  set(LLVM_RUNTIME_OUTPUT_INTDIR ${CMAKE_BINARY_DIR}/${CMAKE_CFG_INTDIR}/bin)
  set(LLVM_LIBRARY_OUTPUT_INTDIR ${CMAKE_BINARY_DIR}/${CMAKE_CFG_INTDIR}/lib${LLVM_LIBDIR_SUFFIX})
  if(WIN32 OR CYGWIN)
    # DLL platform -- put DLLs into bin.
    set(LLVM_SHLIB_OUTPUT_INTDIR ${LLVM_RUNTIME_OUTPUT_INTDIR})
  else()
    set(LLVM_SHLIB_OUTPUT_INTDIR ${LLVM_LIBRARY_OUTPUT_INTDIR})
  endif()

  option(LLVM_INSTALL_TOOLCHAIN_ONLY
    "Only include toolchain files in the 'install' target." OFF)

  option(LLVM_FORCE_USE_OLD_HOST_TOOLCHAIN
    "Set to ON to force using an old, unsupported host toolchain." OFF)

  include(AddLLVM)
  include(TableGen)
  include(HandleLLVMOptions)
  include(VersionFromVCS)
  include(CheckAtomic)
  include(GetErrcMessages)
  include(LLVMDistributionSupport)

  set(PACKAGE_VERSION "${LLVM_PACKAGE_VERSION}")
  set(BUG_REPORT_URL "${LLVM_PACKAGE_BUGREPORT}" CACHE STRING
    "Default URL where bug reports are to be submitted.")

  include_directories(${LLVM_INCLUDE_DIRS})
  link_directories("${LLVM_LIBRARY_DIR}")

  set( CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin )
  set( CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib${LLVM_LIBDIR_SUFFIX} )
  set( CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib${LLVM_LIBDIR_SUFFIX} )

  # Users might specify a path to CLANG_DIR that's:
  #   * a full path, or
  #   * a path relative to the path of this script.
  # Append the absolute path to CLANG_DIR so that find_package works in both
  # cases.
  cmake_path(ABSOLUTE_PATH CLANG_ROOT NORMALIZE)
  message("-- CLANG_ROOT ${CLANG_ROOT}")
  list(APPEND CMAKE_MODULE_PATH "${CLANG_ROOT}")
  list(APPEND CMAKE_MODULE_PATH "${CLANG_ROOT}/lib/cmake/clang")
  # set( CMAKE_FIND_ROOT_PATH ${CMAKE_MODULE_PATH} )
  # find_package(Clang REQUIRED CONFIG)
  # if (NOT Clang_FOUND)
#    message(FATAL_ERROR "Failed to find Clang")
#  endif()

#  include(AddClang)

 # include_directories(${CLANG_INCLUDE_DIRS})
endif() # standalone

include(CheckLinkerFlag)
include(CheckCCompilerFlag)

set(TAPI_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})
set(TAPI_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR})

set(TAPI_FULL_VERSION "2.0.0" CACHE STRING "Specify tapi version.")
message(STATUS "TAPI version: ${TAPI_FULL_VERSION}")

string(REGEX REPLACE "([0-9]+)\\.[0-9]+(\\.[0-9]+)*" "\\1" TAPI_VERSION_MAJOR
  ${TAPI_FULL_VERSION})
string(REGEX REPLACE "[0-9]+\\.([0-9]+)(\\.[0-9]+)*" "\\1" TAPI_VERSION_MINOR
  ${TAPI_FULL_VERSION})

if(${TAPI_FULL_VERSION} MATCHES "[0-9]+\\.[0-9]+(\\.[0-9]+)+")
  string(REGEX REPLACE "[0-9]+\\.[0-9]+\\.([0-9]+)(\\.[0-9]+)*" "\\1" TAPI_VERSION_PATCH
         ${TAPI_FULL_VERSION})
else()
  set(TAPI_VERSION_PATCH 0)
endif()
set(TAPI_VERSION "${TAPI_VERSION_MAJOR}.${TAPI_VERSION_MINOR}.${TAPI_VERSION_PATCH}")

set(TAPI_REPOSITORY_STRING "" CACHE STRING
  "Vendor-specific text for showing the repository the source is taken from.")

if(TAPI_REPOSITORY_STRING)
  add_definitions(-DTAPI_REPOSITORY_STRING="${TAPI_REPOSITORY_STRING}")
endif()

set(TAPI_VENDOR ${PACKAGE_VENDOR} CACHE STRING
  "Vendor-specific text for showing with version information.")

if (TAPI_VENDOR)
  add_definitions( -DTAPI_VENDOR="${TAPI_VENDOR} ")
endif()

if(DEFINED ENV{RC_SUPPORTED_ARCHS})
  string(REPLACE " " ";" TAPI_SUPPORTED_ARCHS $ENV{RC_SUPPORTED_ARCHS})
elseif(NOT DEFINED TAPI_SUPPORTED_ARCHS)
  set(TAPI_SUPPORTED_ARCHS i386 x86_64 x86_64h armv4t armv6 armv5 armv7 armv7s armv7k armv6m armv7m armv7em arm64 arm64e)
endif()
message(STATUS "Supported Architectures: ${TAPI_SUPPORTED_ARCHS}")

set(KNOWN_ARCHS i386 x86_64 x86_64h armv4t armv6 armv5 armv7 armv7s armv7k armv6m armv7m armv7em arm64 arm64e)

set (CONFIG_FILE ${CMAKE_CURRENT_BINARY_DIR}/include/tapi/Core/ArchitectureConfig.h)
file(WRITE ${CONFIG_FILE} "#ifndef TAPI_CORE_ARCHITECTURE_CONFIG_H\n")
file(APPEND ${CONFIG_FILE} "#define TAPI_CORE_ARCHITECTURE_CONFIG_H\n\n")

foreach(arch ${TAPI_SUPPORTED_ARCHS})
  if(arch IN_LIST KNOWN_ARCHS)
    string(TOUPPER ${arch} ARCH)
    file(APPEND ${CONFIG_FILE} "#define SUPPORT_ARCH_${ARCH} 1\n")
  else()
    message(FATAL_ERROR "unknown architecture: ${arch}")
  endif()
endforeach(arch)

file(APPEND ${CONFIG_FILE} "\n#endif // TAPI_CORE_ARCHITECTURE_CONFIG_H\n")

# Configure the Version.inc file.
configure_file(
  ${CMAKE_CURRENT_SOURCE_DIR}/include/tapi/Version.inc.in
  ${CMAKE_CURRENT_BINARY_DIR}/include/tapi/Version.inc)

# Check if the linker support -no_inits.
check_linker_flag(CXX "-Wl,-no_inits" LINKER_SUPPORTS_NO_INITS)

# MARZIPAN RENAME: We might need to update this. This will also require an
# update of the linker on the CI bots.
# Check if the linker has iosmac support.
check_linker_flag(CXX "-Wl,-iosmac_version_min,12.0" LINKER_SUPPORTS_IOSMAC)
# MARZIPAN RENAME

# Check if i386 is supported.
SET(CMAKE_OLD_REQUIRED_FLAGS ${CMAKE_REQUIRED_FLAGS})
SET(CMAKE_OLD_LINKER_FLAGS ${CMAKE_EXE_LINKER_FLAGS})
SET(CMAKE_REQUIRED_FLAGS "-arch i386")
SET(CMAKE_EXE_LINKER_FLAGS "-Wl,-arch_errors_fatal -Wl,-framework,Foundation")
check_c_compiler_flag("" SDK_SUPPORTS_I386)
SET(CMAKE_REQUIRED_FLAGS ${CMAKE_OLD_REQUIRED_FLAGS})
SET(CMAKE_EXE_LINKER_FLAGS ${CMAKE_OLD_LINKER_FLAGS})

macro(add_tapi_library name)
  cmake_parse_arguments(ARG
    "SHARED"
    ""
    "ADDITIONAL_HEADERS"
    ${ARGN})
  set(srcs)
  if(MSVC_IDE OR XCODE)
    # Add public headers
    file(RELATIVE_PATH lib_path
      ${TAPI_SOURCE_DIR}/lib/
      ${CMAKE_CURRENT_SOURCE_DIR}
    )
    if(NOT lib_path MATCHES "^[.][.]")
      file( GLOB_RECURSE headers
        ${TAPI_SOURCE_DIR}/include/tapi/${lib_path}/*.h
        ${CLANG_SOURCE_DIR}/include/tapi/${lib_path}/*.def
      )
      set_source_files_properties(${headers} PROPERTIES HEADER_FILE_ONLY ON)

      file( GLOB_RECURSE tds
        ${TAPI_SOURCE_DIR}/include/tapi/${lib_path}/*.td
      )
      source_group("TableGen descriptions" FILES ${tds})
      set_source_files_properties(${tds}} PROPERTIES HEADER_FILE_ONLY ON)

      if(headers OR tds)
        set(srcs ${headers} ${tds})
      endif()
    endif()
  endif(MSVC_IDE OR XCODE)
  if(srcs OR ARG_ADDITIONAL_HEADERS)
    set(srcs
      ADDITIONAL_HEADERS
      ${srcs}
      ${ARG_ADDITIONAL_HEADERS} # It may contain unparsed unknown args.
      )
  endif()
  if(ARG_SHARED)
    set(ARG_ENABLE_SHARED SHARED)
  endif()
  llvm_add_library(${name} ${ARG_ENABLE_SHARED} ${ARG_UNPARSED_ARGUMENTS} ${srcs})

  if(TARGET ${name})
    target_link_libraries(${name} INTERFACE ${LLVM_COMMON_LIBS})

    if (NOT LLVM_INSTALL_TOOLCHAIN_ONLY)
      if(${name} IN_LIST LLVM_DISTRIBUTION_COMPONENTS OR
          NOT LLVM_DISTRIBUTION_COMPONENTS)
        set(export_to_tapitargets EXPORT TapiTargets)
      endif()

      install(TARGETS ${name}
        COMPONENT ${name}
        ${export_to_tapitargets}
        LIBRARY DESTINATION lib${LLVM_LIBDIR_SUFFIX}
        ARCHIVE DESTINATION lib${LLVM_LIBDIR_SUFFIX}
        RUNTIME DESTINATION bin)

      if (${ARG_SHARED} AND NOT CMAKE_CONFIGURATION_TYPES)
        add_llvm_install_targets(install-${name}
                                 DEPENDS ${name}
                                 COMPONENT ${name})
      endif()
    endif()

    set_property(GLOBAL APPEND PROPERTY TAPI_EXPORTS ${name})
  else()
    # Add empty "phony" target
    add_custom_target(${name})
  endif()

  set_target_properties(${name} PROPERTIES FOLDER "Tapi libraries")
endmacro(add_tapi_library)

macro(add_tapi_executable name)
  add_llvm_executable(${name} ${ARGN})
  set_target_properties(${name} PROPERTIES FOLDER "Tapi executables")
endmacro(add_tapi_executable)

# TODO: Remove when libclangDriver is lifted out of Clang
if(LIBTAPI_STANDALONE_BUILD)
  set(CLANG_INCLUDE_DIR ${CLANG_INCLUDE_DIRS} )
  # No need to specify TableGen output dir as that's embedded in CLANG_DIR
else()
  set(CLANG_INCLUDE_DIR ${LLVM_MAIN_SRC_DIR}/../clang/include )
  # Specify TableGen output dir for things like DiagnosticCommonKinds.inc,
  # DiagnosticDriverKinds.inc (required for reporting diagnostics)
  set(CLANG_TABLEGEN_OUTPUT_DIR ${CMAKE_BINARY_DIR}/tools/clang/include)
  include_directories(SYSTEM ${CLANG_TABLEGEN_OUTPUT_DIR})
endif()
include_directories(SYSTEM ${CLANG_INCLUDE_DIR})

if(LIBTAPI_STANDALONE_BUILD)
  set(LLVM_RUNTIME_OUTPUT_INTDIR ${CMAKE_BINARY_DIR}/bin)
  set(LLVM_LIBRARY_OUTPUT_INTDIR ${CMAKE_BINARY_DIR}/lib)
endif()

include_directories(BEFORE
  ${CMAKE_CURRENT_BINARY_DIR}/include
  ${CMAKE_CURRENT_SOURCE_DIR}/include
  )

option(TAPI_INCLUDE_TESTS "Generate build targets for the TAPI unit tests."
       ${LLVM_INCLUDE_TESTS})
option(TAPI_INCLUDE_DOCS "Generate build targets for the TAPI docs."
      ${LLVM_INCLUDE_DOCS})

# Include must go first.
add_subdirectory(include)
# All targets below may depend on all tablegen'd files.
#get_property(TAPI_TABLEGEN_TARGETS GLOBAL PROPERTY TAPI_TABLEGEN_TARGETS)
#list(APPEND LLVM_COMMON_DEPENDS ${TAPI_TABLEGEN_TARGETS})
add_subdirectory(lib)
add_subdirectory(tools)
