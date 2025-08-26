# WSL2 Setup for PaperTanks Amiga Development

This guide provides step-by-step instructions for setting up the PaperTanks Amiga development environment using Windows Subsystem for Linux 2 (WSL2) with Ubuntu.

## Prerequisites

- Windows 10 version 2004 or higher, or Windows 11
- WSL2 installed and configured
- Ubuntu distribution installed in WSL2
- VSCode installed on Windows

## Quick Start

1. **Verify your setup**: Run the comprehensive verification script

   ```bash
   ./verify_wsl2_setup.sh
   ```

2. **Configure and build**: Use the WSL2-specific configure script

   ```bash
   ./configure-wsl2.sh
   ```

3. **Or use VSCode**: Open the project in WSL2 and use the CMake Tools extension

## Detailed Setup Instructions

### 1. Install Required VSCode Extensions

**On Windows VSCode:**

- Remote - WSL (`ms-vscode-remote.remote-wsl`)
- Remote Development (`ms-vscode-remote.vscode-remote-extensionpack`)

**In WSL2 (via VSCode Remote-WSL):**

- Amiga C/C++ (`bartmanabyss.amiga-debug`)
- CMake Tools (`ms-vscode.cmake-tools`)
- C/C++ (`ms-vscode.cpptools`)

### 2. Install Ubuntu Packages

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install essential build tools
sudo apt install -y build-essential git curl wget

# Install CMake (latest version)
wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | sudo tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null
sudo apt-add-repository 'deb https://apt.kitware.com/ubuntu/ jammy main'
sudo apt update
sudo apt install -y cmake

# Install additional tools
sudo apt install -y make ninja-build pkg-config autoconf automake libtool
```

### 3. Clone Project in WSL2

For best performance, clone the project directly in the WSL2 filesystem:

```bash
cd ~
mkdir -p projects
cd projects
git clone <repository-url> PaperTanks
cd PaperTanks
```

### 4. Connect VSCode to WSL2

```bash
# From WSL2 terminal
code .
```

This will:

- Connect VSCode to WSL2
- Install the VSCode server in WSL2
- Allow you to install extensions in the WSL2 context

### 5. Install Amiga Debug Extension in WSL2

1. With VSCode connected to WSL2, open the Extensions panel (`Ctrl+Shift+X`)
2. Search for "Amiga C/C++" by BartmanAbyss
3. Install the extension (it will install in WSL2)
4. Reload the VSCode window

Alternatively, use the command line:

```bash
code --install-extension bartmanabyss.amiga-debug
```

## Files Created

This setup creates the following files for WSL2 development:

### Scripts

- **`configure-wsl2.sh`** - WSL2-specific configuration and build script
- **`verify_wsl2_setup.sh`** - Comprehensive environment verification
- **`verify_toolchain_wsl2.sh`** - Simple toolchain verification

### VSCode Configuration

- **`.vscode/cmake-kits.json`** - Added WSL2-specific CMake kit
- **`.vscode/settings.json`** - Added WSL2-specific settings
- **`.vscode/tasks.json`** - Build tasks for WSL2 development

## Development Workflow

### First-time Setup

```bash
# Verify environment
./verify_wsl2_setup.sh

# Configure and build
./configure-wsl2.sh
```

### Daily Development

```bash
# Quick build
make -j$(nproc)

# Or use VSCode
# Ctrl+Shift+P -> "CMake: Build"
```

### Available VSCode Tasks

- **Configure Amiga Project (WSL2)** - Runs `./configure-wsl2.sh`
- **Build Amiga Project (WSL2)** - Runs `make -j$(nproc)` (default build task)
- **Clean Build (WSL2)** - Removes build and bin directories
- **Verify WSL2 Setup** - Runs the verification script

Access tasks via `Ctrl+Shift+P` -> "Tasks: Run Task"

## Toolchain Details

The WSL2 setup uses the Linux version of the Amiga toolchain:

- **Extension Path**: `~/.vscode-server/extensions/bartmanabyss.amiga-debug-*/`
- **Toolchain Path**: `~/.vscode-server/extensions/bartmanabyss.amiga-debug-*/bin/linux/opt`
- **Compiler**: `m68k-amiga-elf-gcc`
- **Target**: Amiga 68020 (configurable)

## File System Considerations

### Best Practice: Use WSL2 Native Filesystem

```bash
# Recommended - clone in WSL2 filesystem
cd ~/projects
git clone <repo> PaperTanks
```

### Alternative: Access Windows Files (Slower)

```bash
# Not recommended for active development
cd /mnt/c/Users/YourName/Documents/Projects/PaperTanks
```

**Note**: Development in the WSL2 native filesystem provides significantly better performance than accessing Windows files through `/mnt/c/`.

## Troubleshooting

### Extension Not Found

```bash
# Check if extension is installed in WSL2
code --list-extensions | grep amiga

# Install if missing
code --install-extension bartmanabyss.amiga-debug
```

### Toolchain Issues

```bash
# Verify toolchain installation
./verify_toolchain_wsl2.sh

# Check available platforms
find ~/.vscode-server/extensions -name "*amiga*" -exec ls -la {}/bin/ \;
```

### Permission Issues

```bash
# Fix script permissions
chmod +x *.sh

# Fix Git line endings
git config core.autocrlf false
git config core.eol lf
```

### Performance Issues

```bash
# Use all CPU cores for building
make -j$(nproc)

# Monitor resource usage
htop
```

## VSCode Remote Development Features

When connected to WSL2, you get:

- **Native Linux Environment**: Full access to Ubuntu packages and tools
- **Integrated Terminal**: Runs in WSL2 Ubuntu context
- **File Watching**: Automatic refresh when files change
- **Git Integration**: Uses WSL2 Git with proper line endings
- **IntelliSense**: Works with Linux toolchain
- **Extensions**: Run in WSL2 context for better compatibility

## Advantages of WSL2 Approach

1. **Unix Compatibility**: Use existing Unix-based build scripts
2. **Performance**: Native Linux filesystem performance
3. **Tool Availability**: Full access to Ubuntu package repositories
4. **VSCode Integration**: Seamless remote development experience
5. **Minimal Changes**: Existing project structure mostly unchanged

## Support

If you encounter issues:

1. Run `./verify_wsl2_setup.sh` to identify problems
2. Check the troubleshooting section above
3. Ensure all prerequisites are properly installed
4. Verify VSCode is properly connected to WSL2

For additional help, refer to the main `knowledgebase/windows_build_reqs.md` document.
