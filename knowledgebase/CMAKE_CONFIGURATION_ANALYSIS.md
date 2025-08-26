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
