# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file LICENSE.rst or https://cmake.org/licensing for details.

cmake_minimum_required(VERSION ${CMAKE_VERSION}) # this file comes with cmake

# If CMAKE_DISABLE_SOURCE_CHANGES is set to true and the source directory is an
# existing directory in our source tree, calling file(MAKE_DIRECTORY) on it
# would cause a fatal error, even though it would be a no-op.
if(NOT EXISTS "/Users/matt.swart/Source/Amiga/PaperTanks/_deps/bartman_gcc_support-src")
  file(MAKE_DIRECTORY "/Users/matt.swart/Source/Amiga/PaperTanks/_deps/bartman_gcc_support-src")
endif()
file(MAKE_DIRECTORY
  "/Users/matt.swart/Source/Amiga/PaperTanks/_deps/bartman_gcc_support-build"
  "/Users/matt.swart/Source/Amiga/PaperTanks/_deps/bartman_gcc_support-subbuild/bartman_gcc_support-populate-prefix"
  "/Users/matt.swart/Source/Amiga/PaperTanks/_deps/bartman_gcc_support-subbuild/bartman_gcc_support-populate-prefix/tmp"
  "/Users/matt.swart/Source/Amiga/PaperTanks/_deps/bartman_gcc_support-subbuild/bartman_gcc_support-populate-prefix/src/bartman_gcc_support-populate-stamp"
  "/Users/matt.swart/Source/Amiga/PaperTanks/_deps/bartman_gcc_support-subbuild/bartman_gcc_support-populate-prefix/src"
  "/Users/matt.swart/Source/Amiga/PaperTanks/_deps/bartman_gcc_support-subbuild/bartman_gcc_support-populate-prefix/src/bartman_gcc_support-populate-stamp"
)

set(configSubDirs )
foreach(subDir IN LISTS configSubDirs)
    file(MAKE_DIRECTORY "/Users/matt.swart/Source/Amiga/PaperTanks/_deps/bartman_gcc_support-subbuild/bartman_gcc_support-populate-prefix/src/bartman_gcc_support-populate-stamp/${subDir}")
endforeach()
if(cfgdir)
  file(MAKE_DIRECTORY "/Users/matt.swart/Source/Amiga/PaperTanks/_deps/bartman_gcc_support-subbuild/bartman_gcc_support-populate-prefix/src/bartman_gcc_support-populate-stamp${cfgdir}") # cfgdir has leading slash
endif()
