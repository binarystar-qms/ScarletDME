# Code Structure

## Overview

This document provides a detailed map of the ScarletDME codebase, explaining what each component does and how they fit together.

## Source Directory Layout

```
ScarletDME/
├── gplsrc/              # GPL C source files
├── gplobj/              # Compiled object files
├── bin/                 # Executable binaries
├── qmsys/               # System and runtime files
├── docs/                # Documentation
├── docker/              # Docker deployment
├── helm/                # Kubernetes deployment
├── contrib/             # Contributed programs
├── info/                # Build and setup information
└── pcode_files/         # P-code reference files
```

## Core Source Files (gplsrc/)

### Main Entry Points

#### qm.c
The main QM executive program.

**Key Functions:**
- `main()` - Entry point
- `k_init()` - Initialize system
- `k_run_program()` - Execute programs
- `command_processor()` - Process interactive commands

**Purpose:**
- User interface
- Command interpretation
- Program execution control
- Interactive environment

#### qmlnxd.c
The ScarletDME daemon process.

**Key Functions:**
- `main()` - Daemon entry point
- `start_daemon()` - Initialize daemon
- `monitor_processes()` - Monitor child processes
- `cleanup_shared_memory()` - Resource cleanup

**Purpose:**
- Background service management
- Shared memory coordination
- Process monitoring
- System-wide resource management

#### qmclilib.c
Client library for external applications.

**Key Functions:**
- `QMConnect()` - Connect to server
- `QMDisconnect()` - Disconnect
- `QMExecute()` - Execute command
- `QMRead()` - Read record
- `QMWrite()` - Write record

**Purpose:**
- C API for external applications
- Network protocol handling
- Connection management

### Kernel and Core System

#### kernel.c
Core kernel functions.

**Key Components:**
- Process management
- User authentication
- Account management
- System initialization
- Error handling

**Important Functions:**
- `k_init()` - Initialize kernel
- `k_exit()` - Clean shutdown
- `k_call()` - Call subroutine
- `k_recurse()` - Recursive call handling

#### sysseg.c
Shared memory segment management.

**Key Components:**
- Shared memory creation
- Segment attachment
- User table management
- Buffer pool management

**Important Functions:**
- `init_shared_memory()` - Create segments
- `attach_shared_memory()` - Attach to segments
- `detach_shared_memory()` - Detach segments
- `shmem_lock()` - Lock operations

#### qmsem.c
Semaphore operations for synchronization.

**Key Components:**
- Semaphore creation
- Lock operations
- Deadlock prevention
- Wait/signal operations

**Important Functions:**
- `init_semaphores()` - Create semaphores
- `sem_wait()` - Wait on semaphore
- `sem_signal()` - Signal semaphore
- `sem_cleanup()` - Remove semaphores

### Dynamic Hashing System

The database engine uses dynamic hashing for data storage.

#### dh_hash.c
Hash algorithm implementation.

**Key Functions:**
- `hash_key()` - Hash a key to group number
- `hash_value()` - Calculate hash value
- Primary hashing algorithm

#### dh_file.c
File-level operations.

**Key Functions:**
- `dh_open()` - Open dynamic file
- `dh_close()` - Close file
- `dh_create()` - Create new file
- `dh_delete()` - Delete file

#### dh_read.c
Record reading operations.

**Key Functions:**
- `dh_read()` - Read a record
- `dh_read_group()` - Read group block
- `dh_scan()` - Scan for record
- Record retrieval and caching

#### dh_write.c
Record writing operations.

**Key Functions:**
- `dh_write()` - Write a record
- `dh_write_group()` - Write group block
- `dh_update()` - Update existing record
- Space management

#### dh_split.c
File splitting and growth.

**Key Functions:**
- `split_group()` - Split a full group
- `overflow_create()` - Create overflow block
- Dynamic file expansion

#### dh_del.c
Record deletion.

**Key Functions:**
- `dh_delete()` - Delete a record
- `dh_delete_group_entry()` - Remove from group
- Space reclamation

#### dh_ak.c
Alternate key (index) management.

**Key Functions:**
- `create_ak()` - Create alternate key index
- `update_ak()` - Update index
- `delete_ak()` - Delete index entry
- B-tree index operations

#### dh_misc.c
Miscellaneous file operations.

**Key Functions:**
- `dh_configure()` - Configure file parameters
- `dh_clear()` - Clear file
- `dh_stats()` - File statistics

### Operation Code Implementations

P-code instruction implementations (op_*.c files).

#### op_dio1.c through op_dio4.c
File I/O operations.

**Operations:**
- OPEN - Open file
- CLOSE - Close file
- READ - Read record
- WRITE - Write record
- DELETE - Delete record
- MATREAD - Read array
- MATWRITE - Write array
- READU/WRITEU - Locked I/O

#### op_str1.c through op_str5.c
String operations.

**Operations:**
- String concatenation
- Substring extraction
- String matching
- Case conversion
- Trimming and padding
- Field extraction (multivalue)
- Value/subvalue handling

#### op_arith.c
Arithmetic operations.

**Operations:**
- Addition, subtraction
- Multiplication, division
- Modulo
- Negation
- Increment/decrement

#### op_logic.c
Logical operations.

**Operations:**
- AND, OR, NOT
- Comparison (EQ, NE, LT, GT, LE, GE)
- Boolean operations
- Matching operators

#### op_jumps.c
Control flow operations.

**Operations:**
- Conditional jumps
- Unconditional jumps
- Call/return
- Loop control

#### op_sys.c
System operations.

**Operations:**
- DATE, TIME
- SYSTEM functions
- Environment access
- Process control

#### op_exec.c
Execute operations.

**Operations:**
- EXECUTE
- PERFORM
- CHAIN
- External program execution

#### op_find.c
String search operations.

**Operations:**
- INDEX - Find substring
- LOCATE - Find in list
- FINDSTR - Pattern matching

#### op_locat.c
LOCATE operation implementation.

#### op_sort.c
Sorting operations.

**Operations:**
- Array sorting
- Dynamic array sorting
- Sort by keys

#### op_array.c
Array operations.

**Operations:**
- Array assignment
- Array sizing
- MAT operations

#### op_mvfun.c
Multivalue functions.

**Operations:**
- DCOUNT - Count delimiters
- EXTRACT - Extract field/value/subvalue
- INSERT - Insert field/value/subvalue
- DELETE - Delete field/value/subvalue
- REPLACE - Replace field/value/subvalue

#### op_iconv.c and op_oconv.c
Input and output conversions.

**Conversions:**
- Date conversions
- Time conversions
- Numeric formatting
- Text conversions
- Pattern matching

#### op_misc.c
Miscellaneous operations.

**Operations:**
- Type conversions
- Utility functions
- System utilities

### Utility Programs

#### qmconv.c
File conversion utility.

**Purpose:**
- Convert between file formats
- Data migration
- Format translation

#### qmfix.c
Database repair utility.

**Purpose:**
- Repair corrupted files
- Rebuild indexes
- Fix inconsistencies

#### qmidx.c
Index management utility.

**Purpose:**
- Build indexes
- Rebuild indexes
- Verify index integrity

#### qmtic.c
Terminfo compiler.

**Purpose:**
- Compile terminfo definitions
- Terminal capability management

### I/O and Platform-Specific

#### linuxio.c
Linux I/O operations.

**Functions:**
- Low-level file I/O
- Directory operations
- File locking
- Sequential file I/O

#### linuxlb.c
Linux line buffer management.

**Functions:**
- Terminal I/O
- Line editing
- Command history
- Screen management

#### linuxprt.c
Linux printer interface.

**Functions:**
- Print job management
- Printer device handling
- Spooling

#### lnx.c
Linux-specific implementations.

**Functions:**
- Process management
- Signal handling
- User/group operations

### Terminal and Network

#### telnet.c
Telnet protocol implementation.

**Functions:**
- Telnet negotiation
- Option handling
- Terminal emulation

#### netfiles.c
Network file operations.

**Functions:**
- Remote file access
- Network protocol
- Client/server communication

#### qmtermlb.c
Terminal library.

**Functions:**
- Screen I/O
- Cursor control
- Color management
- Terminal capabilities

### Message and Error Handling

#### messages.c
System message handling.

**Functions:**
- Load messages
- Format messages
- Display errors
- Multi-language support

#### k_error.c
Error handling.

**Functions:**
- Error reporting
- Error codes
- Error recovery
- Stack traces

### Compiler and Runtime

#### object.c
Object code management.

**Functions:**
- Load compiled programs
- Program cache
- Object code validation

#### objprog.c
Object program execution.

**Functions:**
- P-code interpretation
- Program control flow
- Stack management

#### analyse.c
Source code analysis.

**Functions:**
- Syntax checking
- Tokenization
- Parse trees

### Supporting Functions

#### strings.c
String utility functions.

**Functions:**
- String allocation
- String copying
- String comparison
- Memory management

#### ctype.c
Character type functions.

**Functions:**
- Character classification
- Case conversion
- Character properties

#### time.c
Time and date functions.

**Functions:**
- Date calculations
- Time conversions
- Julian dates

#### b64.c
Base64 encoding/decoding.

**Functions:**
- Base64 encode
- Base64 decode
- Binary data handling

## Header Files

### Primary Headers

#### header.h
Main header file included by all sources.

**Contains:**
- System includes
- Platform-specific defines
- Common macros
- Global declarations

#### qm.h
Core QM definitions.

**Contains:**
- Data structures
- Function prototypes
- Global variables
- System constants

#### dh.h
Dynamic hash definitions.

**Contains:**
- File structures
- Group formats
- Hash parameters
- I/O functions

#### opcodes.h
P-code opcode definitions.

**Contains:**
- Opcode enumeration
- Instruction formats
- Stack operations

### Supporting Headers

#### kernel.h
Kernel function declarations.

#### dh_int.h
Internal dynamic hash structures.

#### syscom.h
System common block definitions.

#### err.h
Error code definitions.

#### debug.h
Debugging support.

#### options.h
Compile-time options.

## BASIC Program Library

### qmsys/BP/
User BASIC programs.

### qmsys/GPL.BP/
GPL'd BASIC library.

**Key Programs:**
- System utilities
- File management
- Report generators
- Utility functions

### qmsys/SYSCOM/
System common blocks (headers).

**Key Files:**
- COMMON.H - Common variables
- KEYS.H - Key definitions
- ERR.H - Error codes
- Various system include files

## Data Files

### System Files

| File | Purpose |
|------|---------|
| VOC | Vocabulary (command definitions) |
| ACCOUNTS | Account registry |
| ERRMSG | Error messages |
| MESSAGES | System messages |

### Dictionary Files

- *.DIC files contain field definitions
- Define data extraction
- Specify conversions
- Define correlations

## Build System

### Makefile
Main build configuration.

**Targets:**
- `all` - Build everything
- `clean` - Clean object files
- `install` - Install system
- `qmdev` - Development mode
- `docs` - Build documentation

**Variables:**
- Compiler flags
- Installation paths
- System configuration

## P-code System

### pcode_files/
P-code instruction reference.

**Contents:**
- Instruction definitions
- Opcode documentation
- Bytecode format

### bin/pcode
Compiled P-code instruction set.

**Purpose:**
- Define instruction behavior
- Interpreter reference
- Execution model

## Documentation Structure

### docs/source/
Sphinx documentation source.

**Contents:**
- Installation guide
- SMA reference
- User documentation

### docs/myra/
Comprehensive project documentation.

**Contents:**
- Architecture
- Deployment guides
- Development guide
- API reference

## Configuration Files

### scarlet.conf
System configuration.

**Settings:**
- Maximum users
- File limits
- Network settings
- Security options

## Container Files

### Dockerfile
Multi-stage Docker build.

### docker-entrypoint.sh
Container initialization script.

### docker-inetd.conf
Network service configuration.

## Kubernetes Files

### helm/scarletdme/
Helm chart for Kubernetes.

**Contents:**
- Deployment templates
- Service definitions
- ConfigMaps
- Values configuration

## Code Flow Examples

### Starting ScarletDME

```
main() in qm.c
  └─> k_init() in kernel.c
      ├─> attach_shared_memory() in sysseg.c
      ├─> init_semaphores() in qmsem.c
      ├─> load_config() 
      └─> authenticate_user()
```

### Reading a Record

```
READ opcode in op_dio1.c
  └─> dh_read() in dh_read.c
      ├─> hash_key() in dh_hash.c
      ├─> dh_read_group() in dh_read.c
      ├─> dh_scan() in dh_read.c
      └─> cache_record()
```

### Writing a Record

```
WRITE opcode in op_dio1.c
  └─> dh_write() in dh_write.c
      ├─> hash_key() in dh_hash.c
      ├─> dh_read_group() in dh_read.c
      ├─> check_space()
      ├─> split_group() if needed (dh_split.c)
      └─> dh_write_group() in dh_write.c
```

### Executing a BASIC Program

```
EXECUTE or RUN command
  └─> k_run_program() in kernel.c
      ├─> load_object() in object.c
      ├─> setup_stack()
      └─> interpret_pcode() in objprog.c
          └─> execute opcodes via op_*.c
```

## Next Steps

- [Building from Source](08-building-from-source.md) - Build process details
- [Development Guide](06-development-guide.md) - Start contributing
- [Architecture](02-architecture.md) - System design overview

