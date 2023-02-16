cmake_minimum_required(VERSION 3.13.4)

project(BlocksRuntime)

# Must go below project(..)
include(GNUInstallDirs)

set(CMAKE_CXX_STANDARD 17 CACHE STRING "C++ standard to conform to")
set(CMAKE_CXX_STANDARD_REQUIRED YES)

if (CYGWIN)
  # Cygwin is a bit stricter and lack things like 'strdup', 'stricmp', etc in
  # c++xx mode.
  set(CMAKE_CXX_EXTENSIONS YES)
else()
  set(CMAKE_CXX_EXTENSIONS NO)
endif()

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS}")
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

SET( SRCS
 src/runtime.c
 src/data.c
 )

ADD_LIBRARY( ${PROJECT_NAME} SHARED ${SRCS})
SET_TARGET_PROPERTIES( ${PROJECT_NAME} PROPERTIES
  INSTALL_NAME_DIR ${CMAKE_INSTALL_PREFIX}/lib )

INSTALL(TARGETS ${PROJECT_NAME}
  COMPONENT ${PROJECT_NAME}
  LIBRARY DESTINATION lib
  ARCHIVE DESTINATION lib
  RUNTIME DESTINATION bin)

INSTALL( FILES src/Block.h src/Block_private.h DESTINATION include )
