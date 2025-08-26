cmake_minimum_required(VERSION 3.14.0)
project(hello LANGUAGES C)

# Lowercase project name for binaries and packaging
string(TOLOWER ${PROJECT_NAME} PROJECT_NAME_LOWER)

# Create build directory for organizing build artifacts
set(BUILD_DIR "${CMAKE_SOURCE_DIR}/build")
file(MAKE_DIRECTORY ${BUILD_DIR})

if(NOT AMIGA)
	message(SEND_ERROR "This project only compiles for Amiga")
endif()

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DAMIGA -Wall -Wextra -fomit-frame-pointer")
file(GLOB_RECURSE SOURCES src/*.c)
file(GLOB_RECURSE HEADERS src/*.h)

include_directories(${PROJECT_SOURCE_DIR}/src)

# Debugging flag exposed via CMake specifically for your game code
if(GAME_DEBUG)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DGAME_DEBUG")
endif()

# ACE
add_subdirectory(external/ACE ace)
include_directories(external/ACE/include)
# If you built standalone and installed ACE, use following instead:
# find_package(ace REQUIRED)
# include_directories(${ace_INCLUDE_DIRS})

# Force lower-case binary name for Linux etc.
set(TARGET_NAME ${PROJECT_NAME_LOWER})

if(ELF2HUNK)
  # Add elf2hunk step for Bartman compiler
  set(GAME_LINKED ${TARGET_NAME}.elf) # Intermediate executable
  set(GAME_EXE ${TARGET_NAME}.exe) # Use this to launch the game
  add_executable(${GAME_LINKED} ${SOURCES} ${HEADERS})
  add_custom_command(
    TARGET ${GAME_LINKED} POST_BUILD
    COMMAND ${ELF2HUNK} ${GAME_LINKED} ${GAME_EXE}
  )
else()
  # Just produce the executable with Bebbo compiler
  SET(GAME_LINKED ${TARGET_NAME})
  SET(GAME_EXE ${TARGET_NAME})
  add_executable(${GAME_LINKED} ${SOURCES} ${HEADERS})
endif()

target_link_libraries(${GAME_LINKED} ace)

# Post-build step to organize build artifacts
add_custom_command(
  TARGET ${GAME_LINKED} POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E echo "Organizing build artifacts..."
  
  # Move ace directory to build folder
  COMMAND ${CMAKE_COMMAND} -E copy_directory
    "${CMAKE_SOURCE_DIR}/ace"
    "${BUILD_DIR}/ace"
  COMMAND ${CMAKE_COMMAND} -E remove_directory "${CMAKE_SOURCE_DIR}/ace"
  
  # Move CMakeFiles directory to build folder
  COMMAND ${CMAKE_COMMAND} -E copy_directory
    "${CMAKE_SOURCE_DIR}/CMakeFiles"
    "${BUILD_DIR}/CMakeFiles"
  COMMAND ${CMAKE_COMMAND} -E remove_directory "${CMAKE_SOURCE_DIR}/CMakeFiles"
  
  # Move CPM_modules directory to build folder
  COMMAND ${CMAKE_COMMAND} -E copy_directory
    "${CMAKE_SOURCE_DIR}/CPM_modules"
    "${BUILD_DIR}/CPM_modules"
  COMMAND ${CMAKE_COMMAND} -E remove_directory "${CMAKE_SOURCE_DIR}/CPM_modules"
  
  # Move other build artifacts
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "${CMAKE_SOURCE_DIR}/cmake_install.cmake"
    "${BUILD_DIR}/cmake_install.cmake"
  COMMAND ${CMAKE_COMMAND} -E remove -f "${CMAKE_SOURCE_DIR}/cmake_install.cmake"
  
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "${CMAKE_SOURCE_DIR}/CMakeCache.txt"
    "${BUILD_DIR}/CMakeCache.txt"
  COMMAND ${CMAKE_COMMAND} -E remove -f "${CMAKE_SOURCE_DIR}/CMakeCache.txt"
  
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "${CMAKE_SOURCE_DIR}/Makefile"
    "${BUILD_DIR}/Makefile"
  COMMAND ${CMAKE_COMMAND} -E remove -f "${CMAKE_SOURCE_DIR}/Makefile"
  
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "${CMAKE_SOURCE_DIR}/cpm-package-lock.cmake"
    "${BUILD_DIR}/cpm-package-lock.cmake"
  COMMAND ${CMAKE_COMMAND} -E remove -f "${CMAKE_SOURCE_DIR}/cpm-package-lock.cmake"
  
  # Move _deps directory to build folder
  COMMAND ${CMAKE_COMMAND} -E copy_directory
    "${CMAKE_SOURCE_DIR}/_deps"
    "${BUILD_DIR}/_deps"
  COMMAND ${CMAKE_COMMAND} -E remove_directory "${CMAKE_SOURCE_DIR}/_deps"
  
  COMMENT "Moving build artifacts to build directory"
  VERBATIM
)