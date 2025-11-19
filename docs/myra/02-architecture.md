# Architecture

## System Architecture Overview

ScarletDME follows a traditional UNIX daemon architecture with modern enhancements for containerized deployments.

## Core Components

### 1. QM Daemon (qmlnxd)

The central daemon process that manages all database operations.

**Responsibilities:**
- Shared memory segment management
- Process coordination
- License validation
- System-wide resource management

**Lifecycle:**
- Started by root or via systemd
- Runs continuously as a background process
- Creates and manages shared memory segments
- Monitors child processes

**Location:** `/usr/qmsys/bin/qmlnxd`

### 2. QM Executive (qm)

The user-facing executable that provides the interactive environment.

**Capabilities:**
- Interactive command line interface
- BASIC program execution
- Database operations
- Account management

**Usage Modes:**
- Interactive: `qm`
- Command execution: `qm -c "LIST VOC"`
- Account login: `qm ACCOUNT`

**Location:** `/usr/qmsys/bin/qm`

### 3. Utility Programs

#### qmconv
File conversion utility for migrating data between formats.

#### qmfix
Database repair and maintenance tool.

#### qmidx
Index management utility for building and rebuilding indexes.

#### qmtic
Terminfo compiler for terminal definitions.

### 4. Client Libraries

#### QMClient Library (qmclilib.so)
Shared library for external applications to connect to ScarletDME.

**Features:**
- C API for database operations
- Network protocol handling
- Connection pooling support
- Error handling

**Network Ports:**
- **4242**: QMServer (telnet-style connections)
- **4243**: QMClient (API connections)

## Data Architecture

### File System Layout

```
/usr/qmsys/
├── bin/                    # Executables and shared libraries
│   ├── qm                  # Main executable
│   ├── qmlnxd              # Daemon
│   ├── qmclilib.so         # Client library
│   ├── pcode               # P-code instruction set
│   └── ...                 # Utilities
├── ACCOUNTS/               # Account registry
├── VOC/                    # Vocabulary file (command definitions)
├── BP/                     # BASIC source programs
├── BP.OUT/                 # Compiled BASIC programs
├── GPL.BP/                 # GPL'd BASIC library
├── SYSCOM/                 # System common blocks
├── MESSAGES/               # System messages
├── ERRMSG/                 # Error messages
├── terminfo/               # Terminal definitions
└── ...                     # Data files and directories
```

### File Types

#### Dynamic Files (Hashed Files)
The primary storage mechanism for data.

**Structure:**
- Header block with file parameters
- Group blocks containing record data
- Overflow blocks for hash collisions
- Dynamic expansion as data grows

**File Components:**
- Primary data file (no extension)
- Optional overflow file (`~n` suffix)

#### Directory Files
Standard UNIX directories containing records as individual files.

**Use Cases:**
- Small files with few records
- Files requiring filesystem tools access
- Temporary storage

#### Sequential Files
Traditional sequential access files.

**Use Cases:**
- Reports and output
- Data import/export
- Log files

### Dictionary Files

Every data file can have an associated dictionary file (`.DIC` suffix) that defines:

- Field positions and extraction
- Correlations between fields
- Input/output conversions
- Field validation rules
- Cross-references

**Example:**
```
Data file: CUSTOMERS
Dictionary: CUSTOMERS.DIC
```

## Memory Architecture

### Shared Memory Segments

ScarletDME uses shared memory for high-performance inter-process communication.

**Segments:**
1. **Primary Segment**: Core system data structures
2. **Buffer Cache**: File I/O buffer pool
3. **Lock Table**: Record and file locks
4. **User Table**: Connected user information

**Management:**
- Created by qmlnxd daemon on startup
- Accessed by all qm processes
- Cleaned up on daemon shutdown

### Process Memory

Each qm process has:
- Private stack and heap
- Mapped shared memory segments
- Open file descriptors
- Program workspace

## Process Model

### Single-User Mode
- Direct execution without daemon
- Limited functionality
- Development and testing only

### Multi-User Mode
- Requires qmlnxd daemon
- Shared memory coordination
- Full locking and concurrency

### Process Lifecycle

1. **Startup**: User launches qm
2. **Daemon Check**: Verifies qmlnxd is running
3. **Shared Memory**: Attaches to shared segments
4. **User Table**: Registers in user table
5. **Execution**: Processes commands and programs
6. **Cleanup**: Deregisters and detaches on exit

## Network Architecture

### Daemon Services

Managed by inetd, xinetd, or systemd socket activation:

```
Port 4242 (qmserver):  Telnet-style connections
Port 4243 (qmclient):  API connections
```

### Client Connection Flow

1. Client connects to port 4243
2. System launches qm process for connection
3. Authentication and account login
4. Command/API request processing
5. Response returned to client
6. Connection maintained or closed

### Security Model

- **User Authentication**: Linux user accounts
- **Group Membership**: qmusers group required
- **File Permissions**: Standard UNIX permissions
- **Network Access**: TCP port access controls

## Container Architecture

### Docker Architecture

**Multi-Stage Build:**
1. **Builder Stage**: Compile source code
2. **Production Stage**: Minimal runtime image

**Runtime Characteristics:**
- Alpine Linux base (minimal footprint)
- Non-privileged user execution
- Health check monitoring
- Volume mounts for persistence

**Key Processes:**
- PID 1: docker-entrypoint.sh
- Daemon: qmlnxd (launched by entrypoint)
- Services: inetd (for network connections)

### Kubernetes Architecture

**Components:**
- **Deployment**: ScarletDME pod management
- **Service**: Network endpoint exposure
- **ConfigMap**: Configuration file injection
- **PersistentVolume**: Data persistence
- **StatefulSet**: For clustered deployments (future)

**Pod Structure:**
```
Pod:
  └── Container: scarletdme
      ├── Port: 4242 (qmserver)
      ├── Port: 4243 (qmclient)
      ├── Volume: /usr/qmsys (data)
      └── Health: qmlnxd process check
```

## Compilation Architecture

### Build Process

**Source Organization:**
```
gplsrc/     # GPL source code (.c and .h files)
gplobj/     # Compiled object files (.o files)
bin/        # Final executables and libraries
```

**Build Flow:**
1. `make` compiles all .c files to .o files
2. Links object files into executables
3. Creates shared libraries
4. Installs to /usr/qmsys/bin

### P-Code System

ScarletDME uses a bytecode interpreter for BASIC programs.

**Components:**
- **Compiler**: Translates BASIC to P-code
- **P-code File**: Instruction set definitions
- **Interpreter**: Executes P-code instructions

**Advantages:**
- Platform independence
- Runtime performance
- Compact program storage

## Security Architecture

### User Security

**Required Setup:**
```
Group: qmusers
User:  qmsys (system account)
       + user accounts in qmusers group
```

**Permission Model:**
- System files: owned by qmsys:qmusers
- User files: owned by user:qmusers
- Shared files: group-writable

### Configuration Security

**Config File:** `/etc/scarlet.conf`
- System parameters
- Resource limits
- Network settings
- Security options

**Permissions:** 644 (readable by all, writable by root)

### Network Security

**Access Controls:**
- Port-based firewalling
- IP address restrictions (configurable)
- Authentication required for all connections
- Encrypted connections (future enhancement)

## Scalability Considerations

### Current Limits
- Single-node deployment
- Shared memory constraints
- File locking on local filesystem

### Future Enhancements
- Clustered deployments
- Distributed locking
- Replication support
- Load balancing

## Performance Characteristics

### Strengths
- Fast direct file access
- Efficient hashing algorithm
- Shared memory communication
- Compiled program execution

### Bottlenecks
- Disk I/O for file operations
- Shared memory segment size limits
- Single daemon process
- Lock contention under heavy load

## Monitoring and Observability

### Health Checks
- Process monitoring (qmlnxd)
- Port availability
- Shared memory status
- Lock table status

### Logging
- System logs via syslog
- Application logs in /usr/qmsys
- Error messages in ERRMSG file
- Audit trails (configurable)

## Next Steps

- [Docker Deployment](03-docker-deployment.md) - Deploy in containers
- [Configuration](09-configuration.md) - Configure system parameters
- [Security](10-security.md) - Security best practices

