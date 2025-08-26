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