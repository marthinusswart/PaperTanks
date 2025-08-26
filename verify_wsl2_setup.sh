#!/bin/bash
# WSL2 Amiga Development Environment Verification Script
# This script verifies that all components are properly installed and configured for WSL2 development

echo "🔍 WSL2 Amiga Development Environment Verification"
echo "=================================================="
echo ""

# Function to print status with emoji
print_status() {
    local status=$1
    local message=$2
    if [ "$status" = "ok" ]; then
        echo "✅ $message"
    elif [ "$status" = "warn" ]; then
        echo "⚠️  $message"
    else
        echo "❌ $message"
    fi
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Initialize status counters
total_checks=0
passed_checks=0
failed_checks=0

# Check 1: Verify we're running in WSL2
echo "1. Checking WSL2 Environment..."
total_checks=$((total_checks + 1))
if [ -f /proc/version ] && grep -q "microsoft" /proc/version; then
    if grep -q "WSL2" /proc/version || [ -d /mnt/wsl ]; then
        print_status "ok" "Running in WSL2 environment"
        passed_checks=$((passed_checks + 1))
    else
        print_status "warn" "Running in WSL1 (WSL2 recommended for better performance)"
        passed_checks=$((passed_checks + 1))
    fi
else
    print_status "error" "Not running in WSL environment"
    failed_checks=$((failed_checks + 1))
fi
echo ""

# Check 2: Verify essential build tools
echo "2. Checking Build Tools..."
essential_tools=("make" "cmake" "git" "gcc")
for tool in "${essential_tools[@]}"; do
    total_checks=$((total_checks + 1))
    if command_exists "$tool"; then
        version_info=$($tool --version 2>/dev/null | head -1)
        print_status "ok" "$tool is installed: $version_info"
        passed_checks=$((passed_checks + 1))
    else
        print_status "error" "$tool is not installed"
        failed_checks=$((failed_checks + 1))
    fi
done
echo ""

# Check 3: Verify CMake version
echo "3. Checking CMake Version..."
total_checks=$((total_checks + 1))
if command_exists "cmake"; then
    cmake_version=$(cmake --version | head -1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
    required_version="3.14.0"
    if [ "$(printf '%s\n' "$required_version" "$cmake_version" | sort -V | head -n1)" = "$required_version" ]; then
        print_status "ok" "CMake version $cmake_version meets requirement (>= $required_version)"
        passed_checks=$((passed_checks + 1))
    else
        print_status "error" "CMake version $cmake_version is below required version $required_version"
        failed_checks=$((failed_checks + 1))
    fi
else
    print_status "error" "CMake is not installed"
    failed_checks=$((failed_checks + 1))
fi
echo ""

# Check 4: Verify VSCode extensions directory
echo "4. Checking VSCode Server Extensions..."
total_checks=$((total_checks + 1))
if [ -d "$HOME/.vscode-server/extensions" ]; then
    print_status "ok" "VSCode server extensions directory exists"
    passed_checks=$((passed_checks + 1))
    
    # List installed extensions
    extension_count=$(ls -1 "$HOME/.vscode-server/extensions" | wc -l)
    echo "   📁 Found $extension_count extensions installed"
else
    print_status "error" "VSCode server extensions directory not found"
    print_status "warn" "Make sure you've connected VSCode to WSL2 at least once"
    failed_checks=$((failed_checks + 1))
fi
echo ""

# Check 5: Verify Amiga Debug extension
echo "5. Checking Amiga Debug Extension..."
total_checks=$((total_checks + 1))
EXTENSION_PATH=$(find ~/.vscode-server/extensions -name "bartmanabyss.amiga-debug-*" -type d | sort -V | tail -1)

if [ -n "$EXTENSION_PATH" ]; then
    extension_version=$(basename "$EXTENSION_PATH" | sed 's/bartmanabyss.amiga-debug-//')
    print_status "ok" "Amiga Debug extension found (version $extension_version)"
    echo "   📁 Extension path: $EXTENSION_PATH"
    passed_checks=$((passed_checks + 1))
    
    # Check for Linux toolchain
    total_checks=$((total_checks + 1))
    TOOLCHAIN_PATH="$EXTENSION_PATH/bin/linux/opt"
    if [ -d "$TOOLCHAIN_PATH" ]; then
        print_status "ok" "Linux toolchain directory exists"
        echo "   📁 Toolchain path: $TOOLCHAIN_PATH"
        passed_checks=$((passed_checks + 1))
        
        # Check for compiler
        total_checks=$((total_checks + 1))
        COMPILER="$TOOLCHAIN_PATH/bin/m68k-amiga-elf-gcc"
        if [ -f "$COMPILER" ]; then
            compiler_version=$($COMPILER --version 2>/dev/null | head -1)
            print_status "ok" "Amiga compiler found: $compiler_version"
            passed_checks=$((passed_checks + 1))
        else
            print_status "error" "Amiga compiler not found at: $COMPILER"
            failed_checks=$((failed_checks + 1))
        fi
        
        # Check other tools
        tools=("m68k-amiga-elf-g++" "m68k-amiga-elf-ld" "m68k-amiga-elf-ar")
        for tool in "${tools[@]}"; do
            total_checks=$((total_checks + 1))
            if [ -f "$TOOLCHAIN_PATH/bin/$tool" ]; then
                print_status "ok" "$tool found"
                passed_checks=$((passed_checks + 1))
            else
                print_status "error" "$tool not found"
                failed_checks=$((failed_checks + 1))
            fi
        done
    else
        print_status "error" "Linux toolchain directory not found: $TOOLCHAIN_PATH"
        print_status "warn" "Available platforms:"
        if [ -d "$EXTENSION_PATH/bin" ]; then
            ls -la "$EXTENSION_PATH/bin/" | grep "^d" | awk '{print "   - " $9}'
        fi
        failed_checks=$((failed_checks + 1))
    fi
else
    print_status "error" "Amiga Debug extension not found"
    print_status "warn" "Install it via: code --install-extension bartmanabyss.amiga-debug"
    failed_checks=$((failed_checks + 1))
fi
echo ""

# Check 6: Verify project structure
echo "6. Checking Project Structure..."
required_dirs=("external/ACE" "external/AmigaCMakeCrossToolchains" "src" ".vscode")
for dir in "${required_dirs[@]}"; do
    total_checks=$((total_checks + 1))
    if [ -d "$dir" ]; then
        print_status "ok" "Directory exists: $dir"
        passed_checks=$((passed_checks + 1))
    else
        print_status "error" "Missing directory: $dir"
        failed_checks=$((failed_checks + 1))
    fi
done

required_files=("CMakeLists.txt" "configure.sh" "configure-wsl2.sh" ".vscode/cmake-kits.json")
for file in "${required_files[@]}"; do
    total_checks=$((total_checks + 1))
    if [ -f "$file" ]; then
        print_status "ok" "File exists: $file"
        passed_checks=$((passed_checks + 1))
    else
        print_status "error" "Missing file: $file"
        failed_checks=$((failed_checks + 1))
    fi
done
echo ""

# Check 7: Test toolchain functionality
echo "7. Testing Toolchain Functionality..."
if [ -n "$EXTENSION_PATH" ] && [ -f "$TOOLCHAIN_PATH/bin/m68k-amiga-elf-gcc" ]; then
    total_checks=$((total_checks + 1))
    
    # Create a simple test program
    test_dir="/tmp/amiga_test_$$"
    mkdir -p "$test_dir"
    cat > "$test_dir/test.c" << 'EOF'
int main() {
    return 0;
}
EOF
    
    # Try to compile it
    if "$TOOLCHAIN_PATH/bin/m68k-amiga-elf-gcc" -o "$test_dir/test.elf" "$test_dir/test.c" 2>/dev/null; then
        print_status "ok" "Toolchain can compile simple C program"
        passed_checks=$((passed_checks + 1))
    else
        print_status "error" "Toolchain compilation test failed"
        failed_checks=$((failed_checks + 1))
    fi
    
    # Clean up
    rm -rf "$test_dir"
else
    print_status "warn" "Skipping toolchain test (toolchain not available)"
fi
echo ""

# Summary
echo "=========================================="
echo "📊 Verification Summary"
echo "=========================================="
echo "Total checks: $total_checks"
echo "Passed: $passed_checks"
echo "Failed: $failed_checks"
echo ""

if [ $failed_checks -eq 0 ]; then
    echo "🎉 All checks passed! Your WSL2 environment is ready for Amiga development."
    echo ""
    echo "🚀 Quick Start:"
    echo "  1. Run: ./configure-wsl2.sh"
    echo "  2. Or use VSCode CMake Tools extension"
    echo "  3. Build with: make -j\$(nproc)"
    exit 0
elif [ $failed_checks -lt 3 ]; then
    echo "⚠️  Minor issues detected. The environment should mostly work, but consider fixing the failed checks."
    exit 1
else
    echo "❌ Multiple critical issues detected. Please fix the failed checks before proceeding."
    echo ""
    echo "🔧 Common Solutions:"
    echo "  - Install missing tools: sudo apt update && sudo apt install -y build-essential cmake git"
    echo "  - Install Amiga extension: code --install-extension bartmanabyss.amiga-debug"
    echo "  - Connect VSCode to WSL2: code . (from WSL2 terminal)"
    exit 2
fi