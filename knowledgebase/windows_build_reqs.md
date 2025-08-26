# Windows Build Requirements for PaperTanks

## Overview

This document outlines the requirements and modifications needed to build the PaperTanks Amiga project on Windows with VSCode. The current configuration is macOS-specific and requires several adaptations for Windows compatibility.

## Current Issues with Windows Build

### 1. Platform-Specific Paths

The current configuration uses macOS-specific paths that won't work on Windows:

**Current (macOS):**

```bash
# In configure.sh and cmake-kits.json
AMIGA_TOOLCHAIN_PATH="$HOME/.vscode/extensions/bartmanabyss.amiga-debug-1.7.9/bin/darwin/opt"
```

**Required for Windows:**

```powershell
# Windows equivalent
%USERPROFILE%\.vscode\extensions\bartmanabyss.amiga-debug-1.7.9\bin\win32\opt
```

### 2. Shell Script Dependencies

The current build system relies on bash scripts that require additional setup on Windows:

- **`configure.sh`**: Bash script using Unix commands (`ls`, `make`, etc.)
- **Build process**: Assumes Unix-style path separators and commands

### 3. Make System Requirements

Current configuration assumes Unix make is available at `/usr/bin/make`.

## Required Software Components

### 1. VSCode Extensions

**Required:**

- **Amiga C/C++** by BartmanAbyss (bartmanabyss.amiga-debug)
  - Provides the cross-compilation toolchain
  - Windows version uses `bin/win32/` instead of `bin/darwin/`

**Recommended:**

- **CMake Tools** by Microsoft
- **C/C++** by Microsoft
- Git for Windows (if not already installed)

### 2. Build Tools

**Option A: MSYS2/MinGW (Recommended)**

```powershell
# Install MSYS2 from https://www.msys2.org/
# Then install required packages:
pacman -S make
pacman -S cmake
pacman -S mingw-w64-x86_64-toolchain
```

**Option B: Visual Studio Build Tools**

- Install Visual Studio Build Tools 2022
- Include CMake and Windows 10/11 SDK
- May require additional Make tool (nmake or custom make)

**Option C: Windows Subsystem for Linux (WSL)**

- Install WSL2 with Ubuntu/Debian
- Follow Unix build instructions within WSL
- Note: May require special VSCode WSL extension setup

### 3. Git for Windows

Required for repository management and bash shell functionality.

## Required File Modifications

### 1. CMake Kits Configuration

**File:** `.vscode/cmake-kits.json`

**Current Issue:**

```json
{
  "name": "GCC Bartman m68k Win32",
  "environmentVariables": {
    "PATH": "${env:HOME}/.vscode/extensions/bartmanabyss.amiga-debug-1.7.9/bin/darwin/opt/bin;..."
  },
  "cmakeSettings": {
    "TOOLCHAIN_PATH": "${env:HOME}/.vscode/extensions/bartmanabyss.amiga-debug-1.7.9/bin/darwin/opt"
  }
}
```

**Required Windows Version:**

```json
{
  "name": "GCC Bartman m68k Win32",
  "environmentVariables": {
    "PATH": "${env:USERPROFILE}\\.vscode\\extensions\\bartmanabyss.amiga-debug-1.7.9\\bin\\win32\\opt\\bin;${env:PATH}"
  },
  "preferredGenerator": {
    "name": "MinGW Makefiles"
  },
  "cmakeSettings": {
    "M68K_CPU": "68020",
    "TOOLCHAIN_PREFIX": "m68k-amiga-elf",
    "TOOLCHAIN_PATH": "${env:USERPROFILE}\\.vscode\\extensions\\bartmanabyss.amiga-debug-1.7.9\\bin\\win32\\opt"
  }
}
```

### 2. Windows Configure Script

**File:** `configure.bat` (new file needed)

**Required Content:**

```batch
@echo off
REM Configure CMake for Amiga development using Bartman toolchain on Windows
REM This script provides a maintainable way to configure the project

REM Check if the Amiga Debug extension is installed
set AMIGA_TOOLCHAIN_PATH=%USERPROFILE%\.vscode\extensions\bartmanabyss.amiga-debug-1.7.9\bin\win32\opt

if not exist "%AMIGA_TOOLCHAIN_PATH%" (
    echo Error: Amiga Debug VSCode extension not found at expected location:
    echo %AMIGA_TOOLCHAIN_PATH%
    echo.
    echo Please install the 'Amiga C/C++' extension by BartmanAbyss in VSCode
    echo or update this script with the correct path.
    exit /b 1
)

REM Check if the compiler exists
set COMPILER=%AMIGA_TOOLCHAIN_PATH%\bin\m68k-amiga-elf-gcc.exe
if not exist "%COMPILER%" (
    echo Error: Amiga compiler not found at:
    echo %COMPILER%
    exit /b 1
)

echo Found Amiga toolchain at: %AMIGA_TOOLCHAIN_PATH%
echo Configuring CMake...

REM Configure CMake with the correct toolchain settings
cmake --fresh ^
    -G "MinGW Makefiles" ^
    -DCMAKE_TOOLCHAIN_FILE=external/AmigaCMakeCrossToolchains/m68k-bartman.cmake ^
    -DTOOLCHAIN_PATH="%AMIGA_TOOLCHAIN_PATH%" ^
    -DTOOLCHAIN_PREFIX="m68k-amiga-elf" ^
    .

if %ERRORLEVEL% equ 0 (
    echo.
    echo ✅ CMake configuration successful!
    echo Building the project...
    echo.

    REM Build the project
    cmake --build .

    if %ERRORLEVEL% equ 0 (
        echo.
        echo 🎉 Build successful!
        echo.
        echo Executables created in .\bin\ directory:
        if exist ".\bin" (
            dir /b .\bin\hello.*
        )
        echo.
        echo Build artifacts organized in .\build\ directory:
        if exist ".\build" (
            echo   - ace\
            echo   - CMakeFiles\
            echo   - CPM_modules\
            echo   - _deps\
            echo   - Various CMake files
        )
        echo.
        echo You can also build manually with:
        echo   cmake --build .
        echo.
        echo Note: Build artifacts are automatically moved to .\build\ and executables to .\bin\ after compilation.
        echo This keeps the workspace root clean while maintaining ACE's in-source build requirements.
    ) else (
        echo.
        echo ❌ Build failed!
        exit /b 1
    )
) else (
    echo.
    echo ❌ CMake configuration failed!
    exit /b 1
)
```

### 3. PowerShell Alternative Script

**File:** `configure.ps1` (alternative to batch file)

**Required Content:**

```powershell
# Configure CMake for Amiga development using Bartman toolchain on Windows
# This script provides a maintainable way to configure the project

# Check if the Amiga Debug extension is installed
$AMIGA_TOOLCHAIN_PATH = "$env:USERPROFILE\.vscode\extensions\bartmanabyss.amiga-debug-1.7.9\bin\win32\opt"

if (-not (Test-Path $AMIGA_TOOLCHAIN_PATH)) {
    Write-Host "Error: Amiga Debug VSCode extension not found at expected location:" -ForegroundColor Red
    Write-Host $AMIGA_TOOLCHAIN_PATH -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install the 'Amiga C/C++' extension by BartmanAbyss in VSCode" -ForegroundColor Yellow
    Write-Host "or update this script with the correct path." -ForegroundColor Yellow
    exit 1
}

# Check if the compiler exists
$COMPILER = "$AMIGA_TOOLCHAIN_PATH\bin\m68k-amiga-elf-gcc.exe"
if (-not (Test-Path $COMPILER)) {
    Write-Host "Error: Amiga compiler not found at:" -ForegroundColor Red
    Write-Host $COMPILER -ForegroundColor Red
    exit 1
}

Write-Host "Found Amiga toolchain at: $AMIGA_TOOLCHAIN_PATH" -ForegroundColor Green
Write-Host "Configuring CMake..." -ForegroundColor Cyan

# Configure CMake with the correct toolchain settings
$cmakeArgs = @(
    "--fresh"
    "-G", "MinGW Makefiles"
    "-DCMAKE_TOOLCHAIN_FILE=external/AmigaCMakeCrossToolchains/m68k-bartman.cmake"
    "-DTOOLCHAIN_PATH=$AMIGA_TOOLCHAIN_PATH"
    "-DTOOLCHAIN_PREFIX=m68k-amiga-elf"
    "."
)

$configResult = Start-Process -FilePath "cmake" -ArgumentList $cmakeArgs -Wait -PassThru -NoNewWindow

if ($configResult.ExitCode -eq 0) {
    Write-Host ""
    Write-Host "✅ CMake configuration successful!" -ForegroundColor Green
    Write-Host "Building the project..." -ForegroundColor Cyan
    Write-Host ""

    # Build the project
    $buildResult = Start-Process -FilePath "cmake" -ArgumentList @("--build", ".") -Wait -PassThru -NoNewWindow

    if ($buildResult.ExitCode -eq 0) {
        Write-Host ""
        Write-Host "🎉 Build successful!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Executables created in .\bin\ directory:" -ForegroundColor Cyan
        if (Test-Path ".\bin") {
            Get-ChildItem .\bin\hello.* | Format-Table Name, Length, LastWriteTime
        }
        Write-Host ""
        Write-Host "Build artifacts organized in .\build\ directory:" -ForegroundColor Cyan
        if (Test-Path ".\build") {
            Write-Host "  - ace\" -ForegroundColor White
            Write-Host "  - CMakeFiles\" -ForegroundColor White
            Write-Host "  - CPM_modules\" -ForegroundColor White
            Write-Host "  - _deps\" -ForegroundColor White
            Write-Host "  - Various CMake files" -ForegroundColor White
        }
        Write-Host ""
        Write-Host "You can also build manually with:" -ForegroundColor Yellow
        Write-Host "  cmake --build ." -ForegroundColor White
        Write-Host ""
        Write-Host "Note: Build artifacts are automatically moved to .\build\ and executables to .\bin\ after compilation." -ForegroundColor Gray
        Write-Host "This keeps the workspace root clean while maintaining ACE's in-source build requirements." -ForegroundColor Gray
    } else {
        Write-Host ""
        Write-Host "❌ Build failed!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host ""
    Write-Host "❌ CMake configuration failed!" -ForegroundColor Red
    exit 1
}
```

## Toolchain Path Detection

### Extension Version Handling

The Amiga Debug extension version may vary. Create a detection mechanism:

**For Batch Script:**

```batch
REM Detect the latest Amiga Debug extension version
for /d %%i in ("%USERPROFILE%\.vscode\extensions\bartmanabyss.amiga-debug-*") do (
    set LATEST_EXTENSION=%%i
)
set AMIGA_TOOLCHAIN_PATH=%LATEST_EXTENSION%\bin\win32\opt
```

**For PowerShell:**

```powershell
# Detect the latest Amiga Debug extension version
$extensions = Get-ChildItem "$env:USERPROFILE\.vscode\extensions\bartmanabyss.amiga-debug-*" -Directory
$latestExtension = $extensions | Sort-Object Name -Descending | Select-Object -First 1
$AMIGA_TOOLCHAIN_PATH = "$($latestExtension.FullName)\bin\win32\opt"
```

## VSCode Settings

### Workspace Settings

**File:** `.vscode/settings.json` (add Windows-specific settings)

```json
{
  "cmake.generator": "MinGW Makefiles",
  "cmake.configureOnOpen": false,
  "cmake.buildDirectory": "${workspaceFolder}/build",
  "terminal.integrated.defaultProfile.windows": "PowerShell",
  "files.associations": {
    "*.cmake": "cmake"
  }
}
```

### Tasks Configuration

**File:** `.vscode/tasks.json` (for build tasks)

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Configure Amiga Project (Windows)",
      "type": "shell",
      "command": "powershell",
      "args": ["-ExecutionPolicy", "Bypass", "-File", ".\\configure.ps1"],
      "group": "build",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      },
      "problemMatcher": []
    },
    {
      "label": "Build Amiga Project",
      "type": "shell",
      "command": "cmake",
      "args": ["--build", "."],
      "group": {
        "kind": "build",
        "isDefault": true
      },
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      },
      "problemMatcher": "$gcc"
    }
  ]
}
```

## Path Separator Issues

### CMake Toolchain Compatibility

The `m68k-bartman.cmake` toolchain already handles Windows paths correctly:

```cmake
# From the toolchain file - already Windows-compatible
file(TO_CMAKE_PATH "${TOOLCHAIN_PATH}" TOOLCHAIN_PATH)

if(WIN32)
    set(CMAKE_C_COMPILER ${CMAKE_C_COMPILER}.exe)
    set(CMAKE_CXX_COMPILER ${CMAKE_CXX_COMPILER}.exe)
    # ... other .exe extensions
endif()
```

### Build Scripts Path Handling

Ensure all build scripts use appropriate path separators for the target platform.

## Testing on Windows

### Verification Steps

1. Install VSCode and required extensions
2. Install build tools (MSYS2/MinGW recommended)
3. Clone repository
4. Run configuration script:
   ```powershell
   .\configure.ps1
   ```
   Or:
   ```batch
   configure.bat
   ```
5. Verify build artifacts are created in `bin\` and `build\` directories
6. Test executable functionality (requires Amiga emulator)

### Common Issues and Solutions

**Issue 1: Extension not found**

- Solution: Verify Amiga Debug extension is installed and detect version automatically

**Issue 2: Make command not found**

- Solution: Install MSYS2/MinGW or use cmake --build instead of direct make calls

**Issue 3: Path separator issues**

- Solution: Use CMake's built-in path normalization functions

**Issue 4: PowerShell execution policy**

- Solution: Run `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

## Summary of Required Changes

### Files to Create:

- `configure.bat` - Windows batch configuration script
- `configure.ps1` - Windows PowerShell configuration script
- `.vscode/tasks.json` - Build tasks for VSCode

### Files to Modify:

- `.vscode/cmake-kits.json` - Update Windows kit with correct paths
- `.vscode/settings.json` - Add Windows-specific settings

### Dependencies to Install:

- Amiga C/C++ VSCode extension
- MSYS2/MinGW or Visual Studio Build Tools
- CMake (if not included with build tools)
- Git for Windows

### Key Differences from macOS:

- Use `win32` instead of `darwin` in extension paths
- Use `%USERPROFILE%` instead of `$HOME`
- Use `.exe` extensions for executables
- Use `MinGW Makefiles` generator instead of `Unix Makefiles`
- Handle Windows path separators properly

This documentation provides a complete roadmap for setting up the Windows build environment while maintaining compatibility with the existing macOS configuration.

---

## Option C Deep Dive: Windows Subsystem for Linux (WSL2) with Ubuntu

### Overview

WSL2 provides the most seamless experience for cross-platform development, allowing you to run the existing Unix-based build scripts with minimal modifications while maintaining full VSCode integration. This approach leverages the existing macOS/Linux toolchain and scripts.

### Prerequisites

- WSL2 is installed and configured
- Ubuntu distribution is installed and configured in WSL2
- Basic WSL2 functionality is working

### VSCode Integration with WSL2

#### 1. Required VSCode Extensions

**Install on Windows VSCode:**

```
- Remote - WSL (ms-vscode-remote.remote-wsl)
- Remote Development (ms-vscode-remote.vscode-remote-extensionpack)
```

**Install in WSL2 Ubuntu (via VSCode):**

```
- Amiga C/C++ (bartmanabyss.amiga-debug)
- CMake Tools (ms-vscode.cmake-tools)
- C/C++ (ms-vscode.cpptools)
- C/C++ Extension Pack (ms-vscode.cpptools-extension-pack)
```

#### 2. VSCode WSL2 Connection Setup

**Step 1: Connect to WSL2**

```bash
# From Windows Command Prompt or PowerShell
wsl

# Or directly open VSCode in WSL2
code .
```

**Step 2: Open Project in WSL2**

```bash
# Inside WSL2 Ubuntu terminal
cd /mnt/c/path/to/your/project  # If project is on Windows drive
# OR
cd ~/projects/PaperTanks        # If project is cloned in WSL2 filesystem
code .
```

**Important:** For best performance, clone the repository directly in the WSL2 filesystem rather than accessing it through `/mnt/c/`.

### WSL2 Ubuntu System Setup

#### 1. Update System Packages

```bash
# Update package lists and upgrade system
sudo apt update && sudo apt upgrade -y

# Install essential build tools
sudo apt install -y build-essential git curl wget
```

#### 2. Install CMake

```bash
# Option A: Install from Ubuntu repositories (may be older version)
sudo apt install -y cmake

# Option B: Install latest CMake from Kitware APT repository (recommended)
wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | sudo tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null
sudo apt-add-repository 'deb https://apt.kitware.com/ubuntu/ jammy main'
sudo apt update
sudo apt install -y cmake

# Verify installation
cmake --version  # Should be 3.14+ for this project
```

#### 3. Install Make and Build Tools

```bash
# Install GNU Make and additional build tools
sudo apt install -y make ninja-build

# Install Git (if not already installed)
sudo apt install -y git

# Install additional development tools
sudo apt install -y pkg-config autoconf automake libtool
```

#### 4. Node.js and npm (for VSCode extensions that might need it)

```bash
# Install Node.js via NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

# Verify installation
node --version
npm --version
```

### Amiga Toolchain Setup in WSL2

#### 1. VSCode Extension Installation in WSL2

**Method 1: Via VSCode Remote-WSL**

1. Connect to WSL2 via VSCode Remote-WSL
2. Open Extensions panel (`Ctrl+Shift+X`)
3. Install "Amiga C/C++" by BartmanAbyss
4. The extension will install in the WSL2 environment

**Method 2: Via Command Line**

```bash
# Install VSCode extensions for WSL2
code --install-extension bartmanabyss.amiga-debug
code --install-extension ms-vscode.cmake-tools
code --install-extension ms-vscode.cpptools
```

#### 2. Verify Toolchain Installation

```bash
# Check if Amiga toolchain is available
ls ~/.vscode-server/extensions/bartmanabyss.amiga-debug-*/bin/

# The structure should show different platforms:
# - darwin/ (macOS)
# - linux/ (Linux - this is what we need)
# - win32/ (Windows)
```

#### 3. Toolchain Path Detection

**Expected WSL2 Path:**

```bash
~/.vscode-server/extensions/bartmanabyss.amiga-debug-1.7.9/bin/linux/opt
```

**Verification Script:**

```bash
#!/bin/bash
# verify_toolchain.sh
EXTENSION_PATH=$(find ~/.vscode-server/extensions -name "bartmanabyss.amiga-debug-*" -type d | head -1)
if [ -n "$EXTENSION_PATH" ]; then
    TOOLCHAIN_PATH="$EXTENSION_PATH/bin/linux/opt"
    echo "Extension found at: $EXTENSION_PATH"
    echo "Toolchain path: $TOOLCHAIN_PATH"

    if [ -d "$TOOLCHAIN_PATH" ]; then
        echo "✅ Toolchain directory exists"
        COMPILER="$TOOLCHAIN_PATH/bin/m68k-amiga-elf-gcc"
        if [ -f "$COMPILER" ]; then
            echo "✅ Compiler found: $COMPILER"
            $COMPILER --version
        else
            echo "❌ Compiler not found at: $COMPILER"
        fi
    else
        echo "❌ Toolchain directory not found: $TOOLCHAIN_PATH"
    fi
else
    echo "❌ Amiga Debug extension not found"
fi
```

### Project Configuration for WSL2

#### 1. Modified configure.sh for WSL2

**Create `configure-wsl2.sh`:**

```bash
#!/bin/bash
# Configure CMake for Amiga development using Bartman toolchain in WSL2
# This script provides a maintainable way to configure the project

echo "🐧 Configuring for WSL2 Ubuntu environment..."

# Detect Amiga Debug extension in WSL2
EXTENSION_PATH=$(find ~/.vscode-server/extensions -name "bartmanabyss.amiga-debug-*" -type d | sort -V | tail -1)

if [ -z "$EXTENSION_PATH" ]; then
    echo "❌ Error: Amiga Debug VSCode extension not found in WSL2"
    echo "Please install the 'Amiga C/C++' extension by BartmanAbyss in VSCode while connected to WSL2"
    echo ""
    echo "Steps to install:"
    echo "1. Connect VSCode to WSL2 (code . in WSL2 terminal)"
    echo "2. Install the Amiga C/C++ extension"
    echo "3. Reload VSCode window"
    exit 1
fi

AMIGA_TOOLCHAIN_PATH="$EXTENSION_PATH/bin/linux/opt"

if [ ! -d "$AMIGA_TOOLCHAIN_PATH" ]; then
    echo "❌ Error: Amiga toolchain not found at expected location:"
    echo "$AMIGA_TOOLCHAIN_PATH"
    echo ""
    echo "Available platforms in extension:"
    ls -la "$EXTENSION_PATH/bin/" 2>/dev/null || echo "No bin directory found"
    exit 1
fi

# Check if the compiler exists
COMPILER="$AMIGA_TOOLCHAIN_PATH/bin/m68k-amiga-elf-gcc"
if [ ! -f "$COMPILER" ]; then
    echo "❌ Error: Amiga compiler not found at:"
    echo "$COMPILER"
    exit 1
fi

echo "✅ Found Amiga toolchain at: $AMIGA_TOOLCHAIN_PATH"
echo "✅ Compiler version:"
$COMPILER --version | head -1
echo ""
echo "🔧 Configuring CMake..."

# Configure CMake with the correct toolchain settings
cmake --fresh \
    -G "Unix Makefiles" \
    -DCMAKE_TOOLCHAIN_FILE=external/AmigaCMakeCrossToolchains/m68k-bartman.cmake \
    -DTOOLCHAIN_PATH="$AMIGA_TOOLCHAIN_PATH" \
    -DTOOLCHAIN_PREFIX="m68k-amiga-elf" \
    -DCMAKE_MAKE_PROGRAM="$(which make)" \
    .

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ CMake configuration successful!"
    echo "🔨 Building the project..."
    echo ""

    # Build the project
    make -j$(nproc)

    if [ $? -eq 0 ]; then
        echo ""
        echo "🎉 Build successful!"
        echo ""
        echo "📁 Executables created in ./bin/ directory:"
        if [ -d "./bin" ]; then
            ls -la ./bin/hello.elf ./bin/hello.exe 2>/dev/null || ls -la ./bin/hello* 2>/dev/null
        fi
        echo ""
        echo "📁 Build artifacts organized in ./build/ directory:"
        if [ -d "./build" ]; then
            echo "  - ace/"
            echo "  - CMakeFiles/"
            echo "  - CPM_modules/"
            echo "  - _deps/"
            echo "  - Various CMake files"
        fi
        echo ""
        echo "🛠️  You can also build manually with:"
        echo "  make -j$(nproc)"
        echo ""
        echo "📝 Note: Build artifacts are automatically moved to ./build/ and executables to ./bin/ after compilation."
        echo "This keeps the workspace root clean while maintaining ACE's in-source build requirements."
    else
        echo ""
        echo "❌ Build failed!"
        exit 1
    fi
else
    echo ""
    echo "❌ CMake configuration failed!"
    exit 1
fi
```

#### 2. WSL2-Specific CMake Kit

**Add to `.vscode/cmake-kits.json`:**

```json
{
  "name": "GCC Bartman m68k WSL2",
  "toolchainFile": "${workspaceFolder}/external/AmigaCMakeCrossToolchains/m68k-bartman.cmake",
  "environmentVariables": {
    "PATH": "${env:HOME}/.vscode-server/extensions/bartmanabyss.amiga-debug-1.7.9/bin/linux/opt/bin:${env:PATH}"
  },
  "preferredGenerator": {
    "name": "Unix Makefiles"
  },
  "cmakeSettings": {
    "M68K_CPU": "68020",
    "TOOLCHAIN_PREFIX": "m68k-amiga-elf",
    "TOOLCHAIN_PATH": "${env:HOME}/.vscode-server/extensions/bartmanabyss.amiga-debug-1.7.9/bin/linux/opt"
  },
  "keep": true
}
```

#### 3. WSL2-Specific VSCode Settings

**Add to `.vscode/settings.json`:**

```json
{
  "cmake.configureOnOpen": false,
  "cmake.buildDirectory": "${workspaceFolder}/build",
  "terminal.integrated.defaultProfile.linux": "bash",
  "remote.WSL.fileWatcher.polling": true,
  "files.watcherExclude": {
    "**/build/**": true,
    "**/bin/**": true,
    "**/.git/**": true
  }
}
```

### Development Workflow in WSL2

#### 1. Daily Development Process

```bash
# Start development session
cd ~/projects/PaperTanks  # Or /mnt/c/path/to/project
code .

# Configure and build (first time or after clean)
./configure-wsl2.sh

# Subsequent builds
make -j$(nproc)

# Or use VSCode CMake Tools extension
# Ctrl+Shift+P -> "CMake: Build"
```

#### 2. File System Considerations

**Best Practice: Use WSL2 Native Filesystem**

```bash
# Clone directly in WSL2 for best performance
cd ~
mkdir -p projects
cd projects
git clone <repository-url> PaperTanks
```

**Alternative: Access Windows Files (Slower)**

```bash
# Access Windows filesystem (not recommended for active development)
cd /mnt/c/Users/YourName/Documents/Projects/PaperTanks
```

#### 3. VSCode Integration Features

**Remote Development Benefits:**

- IntelliSense works with Linux toolchain
- Integrated terminal runs in WSL2 Ubuntu
- File watching and auto-completion work seamlessly
- Extensions run in WSL2 context
- Git integration works with WSL2 Git

**VSCode Tasks for WSL2:**

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Configure Amiga Project (WSL2)",
      "type": "shell",
      "command": "./configure-wsl2.sh",
      "group": "build",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      },
      "problemMatcher": []
    },
    {
      "label": "Build Amiga Project (WSL2)",
      "type": "shell",
      "command": "make",
      "args": ["-j$(nproc)"],
      "group": {
        "kind": "build",
        "isDefault": true
      },
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false,
        "panel": "shared"
      },
      "problemMatcher": "$gcc"
    },
    {
      "label": "Clean Build (WSL2)",
      "type": "shell",
      "command": "rm",
      "args": ["-rf", "build", "bin"],
      "group": "build"
    }
  ]
}
```

### Troubleshooting WSL2 Setup

#### 1. Extension Installation Issues

**Problem:** Amiga Debug extension not installing in WSL2
**Solution:**

```bash
# Ensure VSCode is connected to WSL2
code --version  # Should show WSL2 context

# Install extension manually
code --install-extension bartmanabyss.amiga-debug

# Check installation
code --list-extensions | grep amiga
```

#### 2. Toolchain Path Issues

**Problem:** Toolchain not found after extension installation
**Solution:**

```bash
# Find extension installation path
find ~/.vscode-server/extensions -name "*amiga-debug*" -type d

# Check available platforms
ls ~/.vscode-server/extensions/bartmanabyss.amiga-debug-*/bin/

# Update configure script with correct path
```

#### 3. Permission Issues

**Problem:** Build fails with permission errors
**Solution:**

```bash
# Fix file permissions
chmod +x configure-wsl2.sh
chmod +x external/ACE/tools/build_tools.sh  # If it exists

# Ensure proper Git line endings
git config core.autocrlf false
git config core.eol lf
```

#### 4. Performance Optimization

**File System Performance:**

```bash
# Use WSL2 native filesystem for best performance
# Avoid /mnt/c/ for active development

# Enable file system metadata
sudo mount -t drvfs C: /mnt/c -o metadata
```

**Memory and CPU Usage:**

```bash
# Use all available CPU cores for building
make -j$(nproc)

# Monitor resource usage
htop
```

### WSL2 Advantages

1. **Native Unix Environment**: Use existing bash scripts without modification
2. **Better Performance**: Native Linux filesystem performance for builds
3. **Tool Compatibility**: All Unix tools work out of the box
4. **VSCode Integration**: Seamless remote development experience
5. **Git Integration**: Native Git with proper line ending handling
6. **Package Management**: Full access to Ubuntu APT repositories

### WSL2 Considerations

1. **Learning Curve**: Requires familiarity with Linux commands
2. **File System**: Best performance when using WSL2 filesystem, not Windows mounts
3. **Resource Usage**: WSL2 uses additional memory and CPU
4. **Windows Integration**: Some Windows-specific tools may not work directly

### Summary

WSL2 with Ubuntu provides the most robust and Unix-like development environment for the PaperTanks Amiga project on Windows. It allows you to use the existing build scripts with minimal modifications while providing excellent VSCode integration and development experience.

**Key Benefits:**

- Use existing `configure.sh` with minor WSL2-specific modifications
- Full Unix toolchain compatibility
- Excellent VSCode Remote Development integration
- Native Linux performance for builds
- Access to Ubuntu package repositories for additional tools

**Setup Summary:**

1. Install VSCode Remote-WSL extension
2. Install required packages in Ubuntu WSL2
3. Install Amiga Debug extension in WSL2 context
4. Use WSL2-specific configure script
5. Develop with full Unix compatibility

This approach provides the best development experience for Unix-based cross-platform projects on Windows.
