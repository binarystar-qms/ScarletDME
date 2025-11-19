# Building from Source

## Overview

This guide provides detailed information about building ScarletDME from source code, including the build process, customization options, and troubleshooting.

## Prerequisites

### Required Tools

| Tool | Minimum Version | Purpose |
|------|----------------|---------|
| gcc | 4.8+ | C compiler |
| g++ | 4.8+ | C++ compiler |
| make | 3.82+ | Build automation |
| git | 2.0+ | Source control |

### Optional Tools

| Tool | Purpose |
|------|---------|
| clang-format | Code formatting |
| gdb | Debugging |
| valgrind | Memory checking |
| doxygen | Code documentation |

### System Libraries

Required development libraries:
- Standard C library (libc)
- C++ standard library (libstdc++)
- POSIX threads (pthread)
- Math library (libm)

## Getting the Source

### Clone Repository

```bash
# Clone from GitHub
git clone https://github.com/geneb/ScarletDME.git
cd ScarletDME
```

### Select Branch

```bash
# Master branch (stable)
git checkout master

# Development branch (latest)
git checkout dev

# Specific release
git checkout tags/v2.6-6
```

### Verify Source

```bash
# Check current branch
git branch

# View commit history
git log --oneline -10

# Check for updates
git remote update
git status
```

## Build Process

### Standard Build

```bash
# Clean any previous build
make clean

# Build all components
make
```

### Build Output

The build creates:

```
bin/
├── qm              # Main executable
├── qmlnxd          # Daemon
├── qmclilib.so     # Client library (shared)
├── libqmcli.so     # Client library (alternate name)
├── qmconv          # Conversion utility
├── qmfix           # File repair utility
├── qmidx           # Index utility
├── qmtic           # Terminfo compiler
└── pcode           # P-code definitions (copied)
```

### Build Stages

1. **Compilation**: C source files → object files
2. **Linking**: Object files → executables
3. **Library Creation**: Object files → shared libraries
4. **File Copying**: Static files → bin directory

## Makefile Targets

### Primary Targets

```bash
# Build everything
make all
make              # Same as 'make all'

# Clean build artifacts
make clean

# Install system-wide
sudo make install

# Start development instance
sudo make qmdev

# Build documentation
make docs
```

### Component Targets

```bash
# Build specific executable
make bin/qm
make bin/qmlnxd
make bin/qmconv

# Build libraries
make bin/qmclilib.so

# Compile specific object file
make gplobj/kernel.o
```

### Installation Targets

```bash
# Full installation
sudo make install

# Install data files (WARNING: overwrites)
sudo make datafiles

# Install systemd services
sudo make systemd

# Uninstall (if implemented)
sudo make uninstall
```

## Build Configuration

### Makefile Variables

Edit `Makefile` to customize:

```makefile
# Installation prefix
PREFIX = /usr/qmsys

# Compiler
CC = gcc
CXX = g++

# Compiler flags
CFLAGS = -O2 -Wall -D_FILE_OFFSET_BITS=64

# Linker flags
LDFLAGS = -lm -lpthread

# Library flags
LDLIBS = -ldl -lm -lpthread
```

### Compiler Flags

#### Optimization Levels

```makefile
# No optimization (debugging)
CFLAGS = -O0 -g

# Standard optimization
CFLAGS = -O2

# Maximum optimization
CFLAGS = -O3

# Size optimization
CFLAGS = -Os
```

#### Debug Builds

```makefile
# Debug symbols
CFLAGS += -g

# Debug with no optimization
CFLAGS = -g -O0

# Enable debug output
CFLAGS += -DDEBUG

# Verbose debugging
CFLAGS += -DDEBUG -DVERBOSE
```

#### Warning Flags

```makefile
# All warnings
CFLAGS += -Wall

# Extra warnings
CFLAGS += -Wall -Wextra

# Treat warnings as errors
CFLAGS += -Wall -Werror

# Specific warnings
CFLAGS += -Wall -Wno-unused-parameter
```

### Platform-Specific Builds

#### 64-bit (Default)

```makefile
CFLAGS += -m64
LDFLAGS += -m64
```

#### Custom Architecture

```makefile
# ARM
CFLAGS += -march=armv8-a

# x86-64 with specific features
CFLAGS += -march=x86-64 -mtune=generic
```

## Build Customization

### Custom Installation Directory

```bash
# Edit Makefile or override
make PREFIX=/opt/scarletdme
sudo make install PREFIX=/opt/scarletdme
```

### Custom Compiler

```bash
# Use specific compiler
make CC=clang CXX=clang++

# Use compiler from specific path
make CC=/usr/local/bin/gcc-12
```

### Cross-Compilation

```bash
# For ARM target on x86 host
make CC=arm-linux-gnueabihf-gcc \
     CXX=arm-linux-gnueabihf-g++ \
     ARCH=arm
```

### Static Linking

```bash
# Static executables
make LDFLAGS="-static"
```

### Custom Flags

```bash
# Add custom defines
make CFLAGS="-O2 -DCUSTOM_FEATURE -DMAX_USERS=100"

# Override all flags
make CFLAGS="-O3 -march=native -flto"
```

## Parallel Builds

### Multi-core Compilation

```bash
# Use all cores
make -j$(nproc)

# Use specific number of jobs
make -j4

# Unlimited parallel jobs (not recommended)
make -j
```

### Speed Comparison

| Cores | Build Time |
|-------|------------|
| 1 | ~5 minutes |
| 2 | ~3 minutes |
| 4 | ~2 minutes |
| 8 | ~1.5 minutes |

## Build Types

### Production Build

```bash
make clean
make CFLAGS="-O2 -DNDEBUG"
sudo make install
```

### Development Build

```bash
make clean
make CFLAGS="-O0 -g -DDEBUG"
sudo make install
```

### Debug Build

```bash
make clean
make CFLAGS="-O0 -g3 -DDEBUG -DVERBOSE -Wall -Wextra"
sudo make install
```

### Profile Build

```bash
make clean
make CFLAGS="-O2 -pg"
sudo make install
# Run program to generate gmon.out
gprof /usr/qmsys/bin/qm gmon.out > analysis.txt
```

## Dependency Management

### Automatic Dependencies

The Makefile should handle dependencies:

```makefile
# Depend on headers
gplobj/%.o: gplsrc/%.c gplsrc/*.h
	$(CC) $(CFLAGS) -c $< -o $@
```

### Manual Dependency Check

```bash
# Check dependencies with gcc
gcc -MM gplsrc/kernel.c

# Generate dependency file
gcc -MM gplsrc/*.c > dependencies.mk
```

### Rebuild on Header Changes

```bash
# Force rebuild if headers changed
touch gplsrc/*.h
make
```

## Build Artifacts

### Object Files

```
gplobj/
├── kernel.o
├── qm.o
├── qmlnxd.o
├── dh_*.o
├── op_*.o
└── ...
```

### Cleaning

```bash
# Remove object files
make clean

# Remove all generated files
make distclean  # If implemented

# Remove specific objects
rm gplobj/kernel.o
```

## Installation Process

### Installation Steps

```bash
# 1. Build
make

# 2. Install
sudo make install
```

### What Gets Installed

```
/usr/qmsys/               # Installation root
├── bin/                  # Executables
├── VOC/                  # Vocabulary
├── BP/                   # BASIC programs
├── ACCOUNTS/             # Accounts
└── ...                   # System files

/etc/scarlet.conf         # Configuration

/usr/lib/systemd/system/  # Service files
├── scarletdme.service
├── qmclient.socket
└── qmserver.socket
```

### Installation Permissions

Files are installed with:
- Owner: qmsys
- Group: qmusers
- Permissions: 755 (executables), 644 (data)

## Verification

### Test Build

```bash
# Quick test
./bin/qm -v

# Verbose test
./bin/qm -help

# Library test
ldd bin/qm
```

### Smoke Test

```bash
# Start daemon (as root)
sudo ./bin/qmlnxd -start

# Test connection
./bin/qm -c "LIST VOC"

# Stop daemon
sudo ./bin/qmlnxd -stop
```

### Regression Test

```bash
# Run test suite (if available)
make test

# Manual testing
sudo make qmdev
qm -c "RUN TEST ALL"
```

## Troubleshooting

### Build Failures

#### Missing Dependencies

```bash
# Error: gcc: command not found
sudo apt-get install build-essential

# Error: cannot find -lpthread
sudo apt-get install libc6-dev
```

#### Compilation Errors

```bash
# Syntax errors
# Check compiler version
gcc --version

# Try older standard
make CFLAGS="-std=c99"
```

#### Linker Errors

```bash
# Undefined reference
# Check library order
make LDLIBS="-lpthread -lm -ldl"

# Missing symbols
# Rebuild all
make clean
make
```

### Common Issues

#### Makefile Not Found

```bash
# Ensure in correct directory
cd ScarletDME
ls -l Makefile
```

#### Permission Denied

```bash
# Use sudo for installation
sudo make install

# Check file permissions
ls -l Makefile
```

#### Out of Memory

```bash
# Reduce parallel jobs
make -j1

# Add swap space
sudo fallocate -l 2G /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

#### Stale Object Files

```bash
# Clean and rebuild
make clean
make
```

## Advanced Techniques

### Incremental Builds

```bash
# Rebuild only changed files
make

# Force rebuild specific file
touch gplsrc/kernel.c
make
```

### Dependency Tracking

```bash
# Generate dependencies
gcc -M gplsrc/kernel.c

# Include in Makefile
-include $(DEPS)
```

### Build Optimization

```bash
# Use ccache for faster rebuilds
export CC="ccache gcc"
make

# Use distcc for distributed builds
export CC="distcc gcc"
make -j20
```

### Link-Time Optimization

```bash
# LTO for smaller, faster binaries
make CFLAGS="-O2 -flto" LDFLAGS="-flto"
```

## Docker Build

### Build Docker Image

```bash
# Build from Dockerfile
docker build -t scarletdme:latest .

# Multi-stage build
# Stage 1: Compile
# Stage 2: Production image
```

### Build Arguments

```bash
# Custom base image
docker build --build-arg ALPINE_VERSION=3.19 -t scarletdme .

# Build options
docker build \
  --build-arg CFLAGS="-O3" \
  --build-arg MAKEFLAGS="-j4" \
  -t scarletdme:optimized .
```

## Continuous Integration

### CI Build Script

```bash
#!/bin/bash
set -e

# Clean build
make clean

# Build with warnings as errors
make CFLAGS="-Wall -Werror -O2"

# Run tests
make test

# Build docs
make docs
```

### GitHub Actions Example

```yaml
name: Build

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Install dependencies
        run: sudo apt-get install -y build-essential
      - name: Build
        run: make
      - name: Test
        run: make test
```

## Performance Tuning

### Build Performance

```bash
# Parallel build
make -j$(nproc)

# Use faster linker (gold)
make LDFLAGS="-fuse-ld=gold"

# Use ccache
export CC="ccache gcc"
make clean
make
```

### Runtime Performance

```bash
# Profile-guided optimization
# 1. Build with profiling
make CFLAGS="-O2 -fprofile-generate"

# 2. Run representative workload
./bin/qm < benchmark.qm

# 3. Rebuild with profile data
make CFLAGS="-O2 -fprofile-use"
```

## Next Steps

- [Development Guide](06-development-guide.md) - Start developing
- [Code Structure](07-code-structure.md) - Understand the code
- [Traditional Installation](05-traditional-installation.md) - Install the build

