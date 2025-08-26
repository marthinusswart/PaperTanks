#!/bin/bash
# verify_toolchain_wsl2.sh - Simple toolchain verification for WSL2
# This script quickly checks if the Amiga toolchain is properly installed

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
            echo "Compiler version:"
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