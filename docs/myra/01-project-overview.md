# Project Overview

## What is ScarletDME?

ScarletDME is a multivalue database management system built from OpenQM 2.6-6. It represents a modern evolution of the original OpenQM GPL release, focusing on 64-bit platforms and cloud-native deployments.

## History

ScarletDME was created as a fork of OpenQM 2.6-6, which was originally released under GPL by Martin Phillips. The project aims to continue the legacy of OpenQM while modernizing it for contemporary infrastructure requirements.

### Key Milestones
- **Original Release**: OpenQM 2.6-6 GPL release
- **Fork Creation**: ScarletDME project initiated
- **64-bit Focus**: 32-bit code retired to legacy branches
- **Container Support**: Docker and Kubernetes deployment added
- **Documentation**: Sphinx-based documentation system adopted

## What is MultiValue?

MultiValue databases are a type of NoSQL database that have been in use since the 1960s. They are characterized by:

- **Nested Data Structures**: Fields can contain multiple values and sub-values
- **Dynamic Schema**: No rigid table structures required
- **Business Logic Integration**: Built-in programming language (BASIC variants)
- **Proven Reliability**: Decades of production use in mission-critical systems

## Key Features

### Database Engine
- **Dynamic Hashing**: Efficient data storage and retrieval
- **Transaction Support**: ACID-compliant transactions
- **Record Locking**: Multi-user concurrency control
- **Built-in Indexing**: B-tree indexes for fast queries

### Development Environment
- **BASIC Programming**: Full BASIC development environment
- **Built-in Compiler**: Compile BASIC programs to bytecode
- **Debugger**: Interactive debugging capabilities
- **Screen Handling**: Terminal I/O management

### Connectivity
- **QMClient API**: Native client API for external applications
- **QMServer**: Telnet-based server connections
- **Network File Access**: Remote file operations
- **Socket Support**: TCP/IP socket programming

### Modern Infrastructure
- **Docker Support**: Containerized deployment
- **Kubernetes Ready**: Helm charts for orchestration
- **Alpine Linux**: Minimal production images
- **Health Checks**: Built-in monitoring endpoints

## Architecture Philosophy

ScarletDME maintains the traditional MultiValue architecture while embracing modern deployment practices:

1. **Daemon Process**: Central `qmlnxd` daemon manages all database operations
2. **Shared Memory**: High-performance inter-process communication
3. **File-based Storage**: Direct filesystem access for database files
4. **Process Model**: Individual processes per user connection

## Use Cases

### Traditional Applications
- Business applications with complex data relationships
- Legacy system modernization
- Line-of-business applications
- ERP and inventory management systems

### Modern Applications
- Microservices needing embedded database
- Cloud-native applications requiring flexible schema
- IoT data collection with nested structures
- Time-series data with variable attributes

## Community

The ScarletDME project is supported by an active community:

- **Discord**: [ScarletDME Discord](https://discord.gg/H7MPapC2hK)
- **Google Group**: [ScarletDME Google Group](https://groups.google.com/g/scarletdme/)
- **GitHub**: Issue tracking and pull requests

### Broader MultiValue Community
- [Pick Google Group](https://groups.google.com/g/mvdbms)
- [OpenQM Google Group](https://groups.google.com/g/openqm)
- [Rocket Forums](https://community.rocketsoftware.com/forums/multivalue)

## License

ScarletDME is released under the GNU General Public License (GPL), maintaining compatibility with the original OpenQM GPL release.

## Project Goals

1. **Maintain Compatibility**: Preserve OpenQM compatibility where practical
2. **Modernize Infrastructure**: Support container and cloud deployments
3. **Improve Documentation**: Comprehensive documentation for all aspects
4. **Community Engagement**: Foster an active development community
5. **Code Quality**: Consistent formatting and clean code practices
6. **64-bit Focus**: Optimize for modern 64-bit architectures

## Next Steps

- [Architecture](02-architecture.md) - Understand the system architecture
- [Docker Deployment](03-docker-deployment.md) - Get started with containers
- [Development Guide](06-development-guide.md) - Start contributing to the project

