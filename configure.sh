#!/bin/bash

# Configure CMake for Amiga development using Bartman toolchain
# This script provides a maintainable way to configure the project

# Check if the Amiga Debug extension is installed
AMIGA_TOOLCHAIN_PATH="$HOME/.vscode/extensions/bartmanabyss.amiga-debug-1.7.9/bin/darwin/opt"

if [ ! -d "$AMIGA_TOOLCHAIN_PATH" ]; then
    echo "Error: Amiga Debug VSCode extension not found at expected location:"
    echo "$AMIGA_TOOLCHAIN_PATH"
    echo ""
    echo "Please install the 'Amiga C/C++' extension by BartmanAbyss in VSCode"
    echo "or update this script with the correct path."
    exit 1
fi

# Check if the compiler exists
COMPILER="$AMIGA_TOOLCHAIN_PATH/bin/m68k-amiga-elf-gcc"
if [ ! -f "$COMPILER" ]; then
    echo "Error: Amiga compiler not found at:"
    echo "$COMPILER"
    exit 1
fi

echo "Found Amiga toolchain at: $AMIGA_TOOLCHAIN_PATH"
echo "Configuring CMake..."

# Configure CMake with the correct toolchain settings
# Note: The ACE library forces an in-source build, so files will be generated in the workspace root
cmake --fresh \
    -G "Unix Makefiles" \
    -DCMAKE_TOOLCHAIN_FILE=external/AmigaCMakeCrossToolchains/m68k-bartman.cmake \
    -DTOOLCHAIN_PATH="$AMIGA_TOOLCHAIN_PATH" \
    -DTOOLCHAIN_PREFIX="m68k-amiga-elf" \
    -DCMAKE_MAKE_PROGRAM="/usr/bin/make" \
    .

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ CMake configuration successful!"
    echo "Building the project..."
    echo ""
    
    # Build the project
    make
    
    if [ $? -eq 0 ]; then
        echo ""
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
        echo "You can also build manually with:"
        echo "  make"
        echo ""
        echo "Note: Build artifacts are automatically moved to ./build/ and executables to ./bin/ after compilation."
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