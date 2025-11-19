# Development Guide

## Getting Started

This guide helps you get started with developing ScarletDME, whether you're contributing to the core project or developing applications on the platform.

## Development Environment Setup

### Prerequisites

- Linux development machine (64-bit)
- Git
- GCC/G++ compiler
- Make
- Text editor or IDE
- GitHub account (for contributions)

### Clone the Repository

```bash
git clone https://github.com/geneb/ScarletDME.git
cd ScarletDME
```

### Checkout Development Branch

```bash
# For bleeding-edge development
git checkout dev

# For stable development
git checkout master
```

### Build for Development

```bash
# Clean build
make clean

# Build with default settings
make

# Install locally (creates qmsys user/group)
sudo make install

# Start in development mode
sudo make qmdev
```

## Development Workflow

### 1. Create a Feature Branch

```bash
git checkout dev
git pull origin dev
git checkout -b feature/my-new-feature
```

### 2. Make Changes

Edit source files in `gplsrc/` directory:

```bash
# Edit source
vim gplsrc/myfile.c

# Build to test
make

# Test changes
sudo make qmdev
```

### 3. Test Your Changes

```bash
# Run manual tests
qm

# Test specific functionality
qm -c "YOUR TEST COMMAND"

# Check for memory leaks (optional)
valgrind /usr/qmsys/bin/qm -c "TEST"
```

### 4. Commit Changes

```bash
# Stage changes
git add gplsrc/myfile.c

# Commit with meaningful message
git commit -m "Add feature: Brief description

Detailed explanation of what changed and why.

Fixes #123"  # Reference issue number
```

### 5. Push and Create Pull Request

```bash
# Push to your fork
git push origin feature/my-new-feature

# Create pull request on GitHub
# Must be tied to an Issue number
```

## Project Structure

### Source Code Organization

```
ScarletDME/
├── gplsrc/              # GPL source files
│   ├── *.c              # C source files
│   ├── *.h              # Header files
│   └── ...
├── gplobj/              # Compiled object files
│   └── *.o              # Object files
├── bin/                 # Output binaries
│   ├── qm               # Main executable
│   ├── qmlnxd           # Daemon
│   └── ...              # Utilities
├── qmsys/               # System data files
│   ├── BP/              # BASIC programs
│   ├── GPL.BP/          # GPL BASIC library
│   └── ...
├── docs/                # Documentation
│   └── source/          # Sphinx docs
├── docker/              # Docker files
├── helm/                # Kubernetes Helm charts
└── Makefile             # Build configuration
```

### Key Source Files

#### Core System

| File | Purpose |
|------|---------|
| `kernel.c` | Main kernel functions |
| `qm.c` | QM executive main entry point |
| `qmlnxd.c` | Daemon process |
| `sysseg.c` | Shared memory management |
| `qmsem.c` | Semaphore operations |

#### Database Engine

| File | Purpose |
|------|---------|
| `dh_*.c` | Dynamic hashing implementation |
| `dh_read.c` | Record reading |
| `dh_write.c` | Record writing |
| `dh_hash.c` | Hash algorithm |

#### Operations

| File | Purpose |
|------|---------|
| `op_*.c` | Opcode implementations |
| `op_dio*.c` | File I/O operations |
| `op_str*.c` | String operations |
| `op_sys.c` | System operations |

#### Headers

| File | Purpose |
|------|---------|
| `header.h` | Main header file |
| `qm.h` | QM definitions |
| `dh.h` | Dynamic hash definitions |
| `opcodes.h` | P-code opcodes |

## Code Style

### Formatting Standard

ScarletDME uses clang-format with Chromium style (modified):

```bash
# Format a file
clang-format -i gplsrc/myfile.c

# Check formatting (dry run)
clang-format --dry-run gplsrc/myfile.c
```

### .clang-format Settings

Located in project root:

```yaml
---
BasedOnStyle: Chromium
ReflowComments: false
SortIncludes: false
---
```

### Code Conventions

#### Naming Conventions

- **Functions**: `lowercase_with_underscores()`
- **Global variables**: `lowercase_with_underscores`
- **Constants**: `UPPERCASE_WITH_UNDERSCORES`
- **Structures**: `CamelCase`

#### Comments

```c
/* Single line comments use C-style */

/*
 * Multi-line comments use this format
 * with asterisks aligned
 */

// C++ style comments are acceptable for annotations
```

#### Header Guards

```c
#ifndef MYHEADER_H
#define MYHEADER_H

// ... header content ...

#endif  // MYHEADER_H
```

## Building and Testing

### Build Targets

```bash
# Clean build
make clean

# Build all
make

# Build specific component
make bin/qm

# Install system-wide
sudo make install

# Start daemon for development
sudo make qmdev

# Build documentation
make docs
```

### Debugging

#### GDB Debugging

```bash
# Build with debug symbols
make clean
make CFLAGS="-g -O0"

# Run with GDB
gdb /usr/qmsys/bin/qm

# Set breakpoints
(gdb) break main
(gdb) run

# Examine variables
(gdb) print variable_name
(gdb) backtrace
```

#### Valgrind Memory Check

```bash
# Check for memory leaks
valgrind --leak-check=full /usr/qmsys/bin/qm -c "COMMAND"

# Check for memory errors
valgrind --tool=memcheck /usr/qmsys/bin/qm
```

#### Logging

Add debug logging:

```c
#include <stdio.h>

// Simple logging
fprintf(stderr, "DEBUG: variable = %d\n", variable);

// Conditional compilation
#ifdef DEBUG
    fprintf(stderr, "DEBUG: %s\n", message);
#endif
```

Build with debug:

```bash
make CFLAGS="-DDEBUG -g"
```

## BASIC Programming

### BASIC Development Environment

```bash
# Start QM
qm

# Edit BASIC program
:ED BP MYPROG

# Compile
:BASIC BP MYPROG

# Run
:RUN BP MYPROG

# Catalog (make executable)
:CATALOG BP MYPROG

# Run cataloged
MYPROG
```

### Example BASIC Program

```basic
* HELLO - Simple test program
PROGRAM HELLO

* Display message
PRINT "Hello from ScarletDME!"

* Get user input
PRINT "Enter your name: ":
INPUT NAME

* Respond
PRINT "Hello, ":NAME:"!"

* Access database
OPEN "MYFILE" TO FILE.VAR ELSE STOP "Cannot open MYFILE"

* Read a record
READ REC FROM FILE.VAR, "KEY1" ELSE
  PRINT "Record not found"
  STOP
END

PRINT "Record contents: ":REC

STOP
END
```

### GPL.BP Library

The GPL.BP directory contains GPL'd BASIC programs:

```bash
# List available programs
qm -c "LIST GPL.BP"

# View source
qm -c "ED GPL.BP PROGRAM.NAME"

# Use in your programs
$INCLUDE GPL.BP USEFUL.ROUTINE
```

## Contributing Guidelines

### Before You Start

1. **Check existing issues** on GitHub
2. **Create an issue** describing what you want to do
3. **Discuss approach** with maintainers
4. **Fork the repository**
5. **Create feature branch** from `dev`

### Pull Request Requirements

1. **Tied to an Issue**: All PRs must reference an issue number
2. **Tests**: Include tests if adding new functionality
3. **Documentation**: Update docs for user-facing changes
4. **Code Style**: Follow clang-format style
5. **Commit Messages**: Clear, descriptive commit messages
6. **No Breaking Changes**: Maintain backward compatibility

### Commit Message Format

```
Type: Brief description (50 chars or less)

More detailed explanation if needed. Wrap at 72 characters.
Explain what changed, why it changed, and any important details.

Fixes #123
Relates to #456
```

**Types:**
- `Fix:` Bug fixes
- `Feature:` New features
- `Refactor:` Code restructuring
- `Docs:` Documentation changes
- `Build:` Build system changes
- `Test:` Test additions or changes

### Code Review Process

1. **Submit PR** with clear description
2. **Automated checks** must pass
3. **Maintainer review** for code quality
4. **Address feedback** if requested
5. **Approval** from maintainer
6. **Merge** to dev branch

## IDE Setup

### Visual Studio Code

Recommended setup:

**Extensions:**
- C/C++ (Microsoft)
- C/C++ IntelliSense
- Clang-Format
- GitLens

**settings.json:**

```json
{
  "editor.formatOnSave": true,
  "C_Cpp.clang_format_style": "file",
  "C_Cpp.default.configurationProvider": "ms-vscode.cpptools",
  "files.associations": {
    "*.h": "c",
    "*.c": "c"
  }
}
```

**c_cpp_properties.json:**

```json
{
  "configurations": [
    {
      "name": "Linux",
      "includePath": [
        "${workspaceFolder}/gplsrc",
        "/usr/include"
      ],
      "defines": [],
      "compilerPath": "/usr/bin/gcc",
      "cStandard": "c11",
      "intelliSenseMode": "linux-gcc-x64"
    }
  ],
  "version": 4
}
```

### Vim/Neovim

Recommended plugins:

```vim
" .vimrc
Plugin 'vim-syntastic/syntastic'
Plugin 'rhysd/vim-clang-format'
Plugin 'tpope/vim-fugitive'

" Auto-format on save
autocmd FileType c,cpp ClangFormatAutoEnable
```

## Testing

### Manual Testing

```bash
# Start QM
qm

# Run test commands
:LIST VOC

# Test file operations
:CREATE.FILE TEST
:WRITE "TEST DATA" TO TEST,"KEY1"
:READ DATA FROM TEST,"KEY1" ELSE STOP
:PRINT DATA
```

### Automated Testing

Create test scripts in `qmsys/TEST/`:

```bash
# Run test script
qm -c "RUN TEST TEST.SCRIPT"
```

### Regression Testing

Before submitting PR:

1. Build clean
2. Run existing tests
3. Test your changes
4. Check for memory leaks
5. Verify no regressions

## Documentation

### Updating Documentation

Documentation is in `docs/source/`:

```bash
# Edit RST files
vim docs/source/mypage.rst

# Build HTML docs
cd docs
make html

# View docs
firefox build/html/index.html
```

### Sphinx Documentation

**Install Sphinx:**

```bash
pip install sphinx
```

**Build formats:**

```bash
cd docs
make html    # HTML output
make pdf     # PDF output
make epub    # EPUB output
```

## Release Process

### Version Numbering

ScarletDME follows semantic versioning based on OpenQM:

```
Major.Minor-Release (64 bit)
Example: 2.6-6 (64 bit)
```

### Creating a Release

1. Update version in `gplsrc/revstamp.h`
2. Update CHANGELOG
3. Tag release: `git tag v2.6-7`
4. Build and test
5. Create GitHub release
6. Build Docker image
7. Update documentation

## Getting Help

### Community Resources

- **Discord**: [ScarletDME Discord](https://discord.gg/H7MPapC2hK)
- **Google Group**: [ScarletDME Google Group](https://groups.google.com/g/scarletdme/)
- **GitHub Issues**: Report bugs and request features

### Developer Communication

- Use GitHub issues for bug reports
- Use pull requests for code contributions
- Join Discord for real-time discussion
- Post to Google Group for general questions

## Next Steps

- [Code Structure](07-code-structure.md) - Deep dive into codebase
- [Building from Source](08-building-from-source.md) - Detailed build info
- [Architecture](02-architecture.md) - Understand the system

