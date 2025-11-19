# Traditional Installation

## Overview

This guide covers traditional installation of ScarletDME directly on Linux systems without containers. This method is suitable for bare-metal servers, development workstations, and environments where Docker/Kubernetes are not available.

## System Requirements

### Operating System
- Linux (64-bit)
- Supported distributions:
  - Ubuntu 18.04+
  - Debian 10+
  - CentOS 7+
  - RHEL 7+
  - Fedora 30+
  - Other systemd-based distributions

### Hardware Requirements
- **CPU**: x86_64 architecture
- **RAM**: Minimum 512MB, recommended 2GB+
- **Disk**: 500MB for installation, additional for data
- **Architecture**: 64-bit only (32-bit retired)

### Software Dependencies

#### Build Dependencies
- gcc (GNU C Compiler)
- g++ (GNU C++ Compiler)
- make
- Standard development headers

#### Runtime Dependencies
- bash
- Standard C/C++ libraries
- systemd (optional, for service management)
- inetd or xinetd (optional, for network services)

## Installation Steps

### 1. Install Build Dependencies

#### Ubuntu/Debian

```bash
sudo apt-get update
sudo apt-get install -y build-essential gcc g++ make
```

#### CentOS/RHEL/Fedora

```bash
sudo yum groupinstall "Development Tools"
sudo yum install gcc gcc-c++ make
```

Or with dnf:

```bash
sudo dnf groupinstall "Development Tools"
sudo dnf install gcc gcc-c++ make
```

### 2. Clone the Repository

```bash
git clone https://github.com/geneb/ScarletDME.git
cd ScarletDME
```

For stable release:

```bash
git checkout master
```

For development version:

```bash
git checkout dev
```

### 3. Build from Source

```bash
make clean  # Clean any previous build
make        # Compile the source
```

The build process compiles:
- Main executable (qm)
- Daemon (qmlnxd)
- Client library (qmclilib.so)
- Utility programs (qmconv, qmfix, qmidx, qmtic)

### 4. Install System-wide

```bash
sudo make install
```

This performs:
- Creates qmusers group
- Creates qmsys user account
- Installs binaries to `/usr/qmsys/bin`
- Copies data files to `/usr/qmsys`
- Installs configuration to `/etc/scarlet.conf`
- Sets up systemd service files (if systemd is detected)

### 5. Add Users to qmusers Group

Add your user account:

```bash
sudo usermod -aG qmusers $USER
```

Add other users:

```bash
sudo usermod -aG qmusers username
```

**Important:** Log out and log back in for group changes to take effect.

### 6. Start ScarletDME

#### Using systemd

```bash
# Start the service
sudo systemctl start scarletdme

# Enable auto-start on boot
sudo systemctl enable scarletdme

# Check status
sudo systemctl status scarletdme
```

#### Manual start

```bash
sudo qm -start
```

#### Development mode

For development, start as qmsys user:

```bash
sudo make qmdev
```

## Post-Installation Configuration

### Verify Installation

```bash
# Check if qmlnxd daemon is running
ps aux | grep qmlnxd

# Check shared memory segments
ipcs -m

# Test qm executable
qm
```

### Configure Network Services

#### Using systemd Socket Activation

The installation includes systemd socket files:

```bash
# Enable QMClient service
sudo systemctl enable qmclient.socket
sudo systemctl start qmclient.socket

# Enable QMServer service
sudo systemctl enable qmserver.socket
sudo systemctl start qmserver.socket

# Verify
sudo systemctl status qmclient.socket
sudo systemctl status qmserver.socket
```

#### Using xinetd (Alternative)

If using xinetd instead of systemd:

```bash
# Install xinetd
sudo apt-get install xinetd  # Ubuntu/Debian
sudo yum install xinetd      # CentOS/RHEL

# Copy configuration files
sudo cp etc/xinetd.d/qmclient /etc/xinetd.d/
sudo cp etc/xinetd.d/qmserver /etc/xinetd.d/

# Update services file
sudo cat etc/xinetd.d/services >> /etc/services

# Restart xinetd
sudo systemctl restart xinetd
```

### Configure Services File

Ensure `/etc/services` contains:

```
qmserver       4242/tcp                        # QM Server
qmclient       4243/tcp                        # QM Client
```

## Directory Structure

After installation:

```
/usr/qmsys/                 # Main installation directory
├── bin/                    # Executables and libraries
│   ├── qm
│   ├── qmlnxd
│   ├── qmclilib.so
│   ├── libqmcli.so
│   ├── qmconv
│   ├── qmfix
│   ├── qmidx
│   ├── qmtic
│   └── pcode
├── ACCOUNTS/               # Account registry
├── VOC/                    # Vocabulary
├── BP/                     # BASIC programs
├── BP.OUT/                 # Compiled programs
├── GPL.BP/                 # GPL library
├── SYSCOM/                 # System common blocks
├── MESSAGES/               # System messages
├── ERRMSG/                 # Error messages
├── terminfo/               # Terminal definitions
└── ...                     # Data files

/etc/scarlet.conf           # Configuration file

/usr/lib/systemd/system/    # Systemd service files
├── scarletdme.service
├── qmclient.socket
├── qmclient@.service
├── qmserver.socket
└── qmserver@.service
```

## User and Group Setup

### qmusers Group

All ScarletDME users must be members of the qmusers group:

```bash
# List members
getent group qmusers

# Add user
sudo usermod -aG qmusers username

# Remove user
sudo gpasswd -d username qmusers
```

### qmsys User

System account for ScarletDME:
- Home directory: `/usr/qmsys`
- Shell: `/bin/bash`
- Ownership of system files

### File Permissions

```bash
# System files
drwxrwxr-x  qmsys qmusers  /usr/qmsys/
-rwxr-xr-x  qmsys qmusers  /usr/qmsys/bin/*
-rw-rw-r--  qmsys qmusers  /usr/qmsys/VOC/*

# Configuration
-rw-r--r--  root  root     /etc/scarlet.conf
```

## Updating ScarletDME

### Update to Latest Version

```bash
# Navigate to source directory
cd ScarletDME

# Pull latest changes
git pull

# Rebuild
make clean
make

# Stop the service
sudo systemctl stop scarletdme

# Reinstall (be careful with datafiles)
sudo make install

# Restart the service
sudo systemctl start scarletdme
```

### Preserve Data Files

**Warning:** `make datafiles` will overwrite system data. Never run this on a live system!

To update binaries only:

```bash
# After building
sudo cp bin/* /usr/qmsys/bin/
sudo systemctl restart scarletdme
```

## Uninstallation

### Stop Services

```bash
# Stop main service
sudo systemctl stop scarletdme
sudo systemctl disable scarletdme

# Stop network services
sudo systemctl stop qmclient.socket qmserver.socket
sudo systemctl disable qmclient.socket qmserver.socket
```

### Remove Files

```bash
# Backup data first!
sudo tar czf /backup/qmsys-backup.tar.gz /usr/qmsys

# Remove installation
sudo rm -rf /usr/qmsys
sudo rm /etc/scarlet.conf
sudo rm /usr/lib/systemd/system/scarletdme.service
sudo rm /usr/lib/systemd/system/qm*.socket
sudo rm /usr/lib/systemd/system/qm*@.service

# Reload systemd
sudo systemctl daemon-reload
```

### Remove Users and Groups (Optional)

```bash
# Remove qmsys user
sudo userdel qmsys

# Remove qmusers group
sudo groupdel qmusers
```

## Troubleshooting Installation

### Build Failures

#### Missing Dependencies

```bash
# Error: gcc: command not found
sudo apt-get install build-essential

# Error: make: command not found
sudo apt-get install make
```

#### Compilation Errors

```bash
# Clean and retry
make clean
make

# Check for error messages
make 2>&1 | tee build.log
```

### Installation Failures

#### Permission Denied

```bash
# Ensure using sudo
sudo make install

# Check if root
whoami
```

#### Group Already Exists

If qmusers group already exists (from previous installation):

```bash
# Continue installation
sudo make install

# Verify group
getent group qmusers
```

### Runtime Issues

#### $LOGIN Error

User not in qmusers group:

```bash
# Add to group
sudo usermod -aG qmusers $USER

# Log out and back in
exit
```

#### Daemon Won't Start

```bash
# Check logs
sudo journalctl -u scarletdme -n 50

# Check for running daemon
ps aux | grep qmlnxd

# Check shared memory
ipcs -m

# Start manually for debugging
sudo /usr/qmsys/bin/qmlnxd -start
```

#### Shared Memory Issues

```bash
# List shared memory segments
ipcs -m

# Remove stale segments
sudo ipcrm -M <key>

# Increase system limits if needed
sudo sysctl -w kernel.shmmax=68719476736
sudo sysctl -w kernel.shmall=4294967296
```

### Network Service Issues

#### Port Already in Use

```bash
# Check what's using the ports
sudo netstat -tlnp | grep -E '4242|4243'
sudo lsof -i :4242
sudo lsof -i :4243

# Stop conflicting service
sudo systemctl stop <service>
```

#### Socket Activation Not Working

```bash
# Check socket status
sudo systemctl status qmclient.socket
sudo systemctl status qmserver.socket

# Check socket files
sudo ls -la /usr/lib/systemd/system/qm*

# Reload systemd
sudo systemctl daemon-reload
sudo systemctl restart qmclient.socket
```

## Manual Build Options

### Build for Development

```bash
# Build with debug symbols
make CFLAGS="-g -O0"

# Build with specific options
make CFLAGS="-DDEBUG -Wall"
```

### Custom Installation Prefix

Edit Makefile to change installation directory:

```makefile
# Default is /usr/qmsys
PREFIX=/opt/scarletdme
```

Then build and install:

```bash
make
sudo make install PREFIX=/opt/scarletdme
```

## Integration with Existing Systems

### Firewall Configuration

```bash
# UFW (Ubuntu)
sudo ufw allow 4242/tcp
sudo ufw allow 4243/tcp

# firewalld (CentOS/RHEL)
sudo firewall-cmd --permanent --add-port=4242/tcp
sudo firewall-cmd --permanent --add-port=4243/tcp
sudo firewall-cmd --reload

# iptables
sudo iptables -A INPUT -p tcp --dport 4242 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 4243 -j ACCEPT
```

### SELinux Configuration (CentOS/RHEL)

```bash
# Check SELinux status
getenforce

# If enforcing, add policies
sudo semanage port -a -t unreserved_port_t -p tcp 4242
sudo semanage port -a -t unreserved_port_t -p tcp 4243
```

## Next Steps

- [Configuration](09-configuration.md) - Configure ScarletDME
- [Security](10-security.md) - Secure your installation
- [Development Guide](06-development-guide.md) - Start developing

