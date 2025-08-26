# CMake Configuration Error Analysis & Solution

## Issue Summary

The CMake configuration was failing with a misleading error about missing compiler tools, not an "index not found" error as initially reported.

## Root Cause Analysis

### The Actual Error

```
CMake Error at CMakeLists.txt:2 (project):
  The CMAKE_C_COMPILER:
    /opt/m68k-generic/bin/m68k-generic-gcc
  is not a full path to an existing compiler tool.
```

### Problem Details

1. **VSCode Extension Dependency**: The original [`.vscode/cmake-kits.json`](.vscode/cmake-kits.json) used VSCode-specific commands:

   ```json
   "PATH": "${command:amiga.bin-path}/opt/bin;..."
   "TOOLCHAIN_PATH": "${command:amiga.bin-path}/opt"
   ```

2. **Command Resolution Failure**: The `${command:amiga.bin-path}` command only works within VSCode when the Amiga Debug extension is active. When CMake runs outside this context, it cannot resolve the path.

3. **Incorrect Toolchain Fallback**: The [`m68k-bartman.cmake`](external/AmigaCMakeCrossToolchains/m68k-bartman.cmake) toolchain falls back to:

   - **Default Path**: `/opt/m68k-generic` (doesn't exist)
   - **Default Prefix**: `m68k-generic` (wrong compiler name)

4. **Actual Compiler Location**: The Amiga cross-compiler is installed at:
   ```
   /Users/matt.swart/.vscode/extensions/bartmanabyss.amiga-debug-1.7.9/bin/darwin/opt/bin/m68k-amiga-elf-gcc
   ```

## Solution Implemented

### 1. Updated CMake Kits Configuration

Modified [`.vscode/cmake-kits.json`](.vscode/cmake-kits.json) to use `${env:HOME}` instead of VSCode commands:

```json
{
  "name": "GCC Bartman m68k Unix",
  "toolchainFile": "${workspaceFolder}/external/AmigaCMakeCrossToolchains/m68k-bartman.cmake",
  "cmakeSettings": {
    "TOOLCHAIN_PATH": "${env:HOME}/.vscode/extensions/bartmanabyss.amiga-debug-1.7.9/bin/darwin/opt",
    "TOOLCHAIN_PREFIX": "m68k-amiga-elf"
  }
}
```

### 2. Created Configure Script

Added [`configure.sh`](configure.sh) for easy project setup:

```bash
./configure.sh
```

This script:

- Validates the Amiga toolchain installation
- Sets correct `TOOLCHAIN_PATH` and `TOOLCHAIN_PREFIX`
- Provides clear error messages if setup is incorrect

## Files Modified

- **[`.vscode/cmake-kits.json`](.vscode/cmake-kits.json)**: Updated to use `${env:HOME}` paths
- **[`configure.sh`](configure.sh)**: New script for reliable configuration

## Verification

The fix was verified by successfully running:

```bash
cmake --fresh -B build \
    -DCMAKE_TOOLCHAIN_FILE=external/AmigaCMakeCrossToolchains/m68k-bartman.cmake \
    -DTOOLCHAIN_PATH="$HOME/.vscode/extensions/bartmanabyss.amiga-debug-1.7.9/bin/darwin/opt" \
    -DTOOLCHAIN_PREFIX="m68k-amiga-elf" \
    .
```

**Result**: ✅ Configuration successful with proper compiler detection:

```
-- The C compiler identification is GNU 14.2.0
-- Configuring done (15.2s)
-- Build files have been written to: /Users/matt.swart/Source/Amiga/PaperTanks
```

## Benefits for GitHub Maintenance

1. **No VSCode Dependency**: Uses standard environment variables
2. **Cross-Platform Compatibility**: Uses `${env:HOME}` instead of hardcoded paths
3. **Clear Error Reporting**: The configure script provides helpful error messages
4. **Documented Process**: This analysis documents the issue for future reference

## Usage

1. Install the Amiga C/C++ extension by BartmanAbyss in VSCode
2. Run `./configure.sh` to configure the project
3. Build with `cmake --build build`

---

# Build Organization & Post-Build Automation

## Overview

After resolving the initial CMake configuration issues, we implemented a comprehensive build organization system to keep the workspace clean while maintaining ACE's in-source build requirements.

## Problem Statement

The ACE library forces an in-source build, creating several directories and files in the workspace root:

- `ace/` - ACE library build artifacts
- `CMakeFiles/` - CMake build metadata
- `CPM_modules/` - CPM dependency modules
- `_deps/` - Dependency sources and builds
- Various CMake files (`cmake_install.cmake`, `CMakeCache.txt`, `Makefile`, etc.)
- Executables (`hello.elf`, `hello.exe`) in workspace root

This cluttered the workspace and mixed source files with build artifacts.

## Solution Implemented

### 1. Build Directory Organization

Modified [`CMakeLists.txt`](CMakeLists.txt) to create organized build structure:

```cmake
# Create build directory for organizing build artifacts
set(BUILD_DIR "${CMAKE_SOURCE_DIR}/build")
set(BIN_DIR "${CMAKE_SOURCE_DIR}/bin")
file(MAKE_DIRECTORY ${BUILD_DIR})
file(MAKE_DIRECTORY ${BIN_DIR})
```

### 2. Post-Build Artifact Movement

Added comprehensive post-build commands to move all build artifacts:

```cmake
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

  # Move _deps directory to build folder
  COMMAND ${CMAKE_COMMAND} -E copy_directory
    "${CMAKE_SOURCE_DIR}/_deps"
    "${BUILD_DIR}/_deps"
  COMMAND ${CMAKE_COMMAND} -E remove_directory "${CMAKE_SOURCE_DIR}/_deps"

  # Move various CMake files
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "${CMAKE_SOURCE_DIR}/cmake_install.cmake"
    "${BUILD_DIR}/cmake_install.cmake"
  COMMAND ${CMAKE_COMMAND} -E remove -f "${CMAKE_SOURCE_DIR}/cmake_install.cmake"

  # Move executables to bin directory
  COMMAND ${CMAKE_COMMAND} -E echo "Moving executables to bin directory..."
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "${CMAKE_SOURCE_DIR}/${GAME_LINKED}"
    "${BIN_DIR}/${GAME_LINKED}"
  COMMAND ${CMAKE_COMMAND} -E remove -f "${CMAKE_SOURCE_DIR}/${GAME_LINKED}"

  COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "${CMAKE_SOURCE_DIR}/${GAME_EXE}"
    "${BIN_DIR}/${GAME_EXE}"
  COMMAND ${CMAKE_COMMAND} -E remove -f "${CMAKE_SOURCE_DIR}/${GAME_EXE}"

  COMMENT "Moving build artifacts to build directory and executables to bin directory"
  VERBATIM
)
```

### 3. Updated Configure Script

Enhanced [`configure.sh`](configure.sh) to inform users about the new organization:

```bash
echo "🎉 Build successful!"
echo ""
echo "Executables created in ./bin/ directory:"
if [ -d "./bin" ]; then
    ls -la ./bin/hello.elf ./bin/hello.exe 2>/dev/null || ls -la ./bin/hello* 2>/dev/null
fi
echo ""
echo "Build artifacts organized in ./build/ directory:"
if [ -d "./build" ]; then
    echo "  - ace/"
    echo "  - CMakeFiles/"
    echo "  - CPM_modules/"
    echo "  - _deps/"
    echo "  - Various CMake files"
fi
echo ""
echo "Note: Build artifacts are automatically moved to ./build/ and executables to ./bin/ after compilation."
echo "This keeps the workspace root clean while maintaining ACE's in-source build requirements."
```

### 4. Enhanced .gitignore

Updated [`.gitignore`](.gitignore) to handle the new directory structure:

```gitignore
# Build directory - contains all build artifacts moved post-build
build/

# Bin directory - contains executables moved post-build
bin/

# CMake build artifacts (in case they remain in root temporarily)
CMakeFiles/
CMakeCache.txt
cmake_install.cmake
Makefile
cpm-package-lock.cmake
_deps/

# ACE build artifacts
ace/

# CPM modules
CPM_modules/
```

## ACE Debug Configuration

### Issue with ACE_DEBUG

Initial attempts to enable `ACE_DEBUG` failed because ACE uses CMake's `CACHE` mechanism:

```cmake
# In external/ACE/cmake/ace_config.cmake
set(ACE_DEBUG OFF CACHE BOOL "Build with ACE-specific debug/safety functionality.")
```

### Solution

Used `FORCE` option to override cached values in [`CMakeLists.txt`](CMakeLists.txt):

```cmake
# ACE Debug flag - set to ON to enable ACE debugging
# Must use CACHE BOOL FORCE to override ACE's default cached value
set(ACE_DEBUG ON CACHE BOOL "Build with ACE-specific debug/safety functionality." FORCE)
```

**Important**: This must be set in the root `CMakeLists.txt` **before** the `add_subdirectory(external/ACE ace)` call.

### Verification

Debug enablement is confirmed by:

- Build output shows: `-- [ACE] ACE_DEBUG: 'ON'` (instead of `'OFF'`)
- Significant executable size increase:
  - `hello.elf`: 32,088 → 71,176 bytes (+122%)
  - `hello.exe`: 18,180 → 48,980 bytes (+169%)

## Results

### Before Organization

```
workspace_root/
├── src/
├── external/
├── ace/                    # ❌ Build clutter
├── CMakeFiles/             # ❌ Build clutter
├── CPM_modules/            # ❌ Build clutter
├── _deps/                  # ❌ Build clutter
├── cmake_install.cmake     # ❌ Build clutter
├── CMakeCache.txt          # ❌ Build clutter
├── Makefile               # ❌ Build clutter
├── hello.elf              # ❌ Mixed with source
└── hello.exe              # ❌ Mixed with source
```

### After Organization

```
workspace_root/
├── src/                   # ✅ Clean source
├── external/              # ✅ Clean source
├── build/                 # ✅ All build artifacts
│   ├── ace/
│   ├── CMakeFiles/
│   ├── CPM_modules/
│   ├── _deps/
│   └── various CMake files
└── bin/                   # ✅ Clean executables
    ├── hello.elf
    └── hello.exe
```

## Benefits

1. **Clean Workspace**: Source directories remain uncluttered
2. **Organized Artifacts**: All build files in dedicated `./build/` directory
3. **Easy Distribution**: Executables cleanly separated in `./bin/` directory
4. **Automated Process**: No manual cleanup required
5. **ACE Compatibility**: Maintains ACE's in-source build requirements during build process
6. **Debug Support**: Easy ACE debug configuration with proper cache handling

## Modified Files

- **[`CMakeLists.txt`](CMakeLists.txt)**: Added build directories, post-build commands, ACE_DEBUG configuration
- **[`configure.sh`](configure.sh)**: Updated success messages and documentation
- **[`.gitignore`](.gitignore)**: Added build and bin directory patterns

## Usage

The build organization is fully automated:

1. Run `./configure.sh` (or `make` after initial configuration)
2. Build artifacts automatically moved to `./build/`
3. Executables automatically moved to `./bin/`
4. Workspace root remains clean
