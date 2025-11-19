# Configuration

## Overview

ScarletDME uses the `/etc/scarlet.conf` configuration file to control system behavior, resource limits, and operational parameters.

## Configuration File Location

**Default:** `/etc/scarlet.conf`

**Alternative locations:**
- `$QMSYS/scarlet.conf`
- `$HOME/.scarlet.conf`

The system searches in this order and uses the first file found.

## Configuration File Format

### Syntax

```ini
# Comments start with hash
PARAMETER=value

# Numeric values
MAXUSERS=50

# String values
LOGDIR=/var/log/scarletdme

# Boolean values (YES/NO, TRUE/FALSE, 1/0)
LOGGING=YES
```

### Case Sensitivity

- Parameter names are case-insensitive
- Values may be case-sensitive depending on parameter

## Core Parameters

### System Limits

#### MAXUSERS

Maximum number of concurrent users.

```ini
MAXUSERS=50
```

- **Type:** Integer
- **Default:** 32
- **Range:** 1-1000
- **Restart Required:** Yes

#### NUMFILES

Maximum number of open files per user.

```ini
NUMFILES=100
```

- **Type:** Integer
- **Default:** 40
- **Range:** 10-1000
- **Restart Required:** Yes

#### NETFILES

Maximum number of network file connections.

```ini
NETFILES=20
```

- **Type:** Integer
- **Default:** 10
- **Range:** 0-100
- **Restart Required:** Yes

### Memory Configuration

#### SHMEM

Shared memory segment size in MB.

```ini
SHMEM=64
```

- **Type:** Integer (MB)
- **Default:** 32
- **Range:** 16-2048
- **Restart Required:** Yes

#### BUFFERPOOL

Buffer pool size in MB for file I/O caching.

```ini
BUFFERPOOL=16
```

- **Type:** Integer (MB)
- **Default:** 8
- **Range:** 4-512
- **Restart Required:** Yes

#### SORTMEM

Memory allocated for sorting operations in MB.

```ini
SORTMEM=8
```

- **Type:** Integer (MB)
- **Default:** 4
- **Range:** 1-256
- **Restart Required:** No

### Process Configuration

#### MAXIDLEN

Maximum length of record IDs.

```ini
MAXIDLEN=255
```

- **Type:** Integer
- **Default:** 255
- **Range:** 32-4096
- **Restart Required:** Yes

#### DEADLOCK

Deadlock detection timeout in seconds.

```ini
DEADLOCK=60
```

- **Type:** Integer (seconds)
- **Default:** 60
- **Range:** 10-3600
- **Restart Required:** No

## Network Configuration

### Port Configuration

#### QMSERVER_PORT

Port for QMServer (telnet-style connections).

```ini
QMSERVER_PORT=4242
```

- **Type:** Integer
- **Default:** 4242
- **Range:** 1024-65535
- **Restart Required:** Yes

#### QMCLIENT_PORT

Port for QMClient (API connections).

```ini
QMCLIENT_PORT=4243
```

- **Type:** Integer
- **Default:** 4243
- **Range:** 1024-65535
- **Restart Required:** Yes

### Network Security

#### ALLOW_REMOTE

Allow remote network connections.

```ini
ALLOW_REMOTE=YES
```

- **Type:** Boolean
- **Default:** YES
- **Values:** YES/NO
- **Restart Required:** Yes

#### BIND_ADDRESS

IP address to bind network services.

```ini
BIND_ADDRESS=0.0.0.0
```

- **Type:** IP Address
- **Default:** 0.0.0.0 (all interfaces)
- **Restart Required:** Yes

#### ALLOWED_HOSTS

Comma-separated list of allowed client IPs.

```ini
ALLOWED_HOSTS=192.168.1.0/24,10.0.0.0/8
```

- **Type:** String (CIDR notation)
- **Default:** (all allowed)
- **Restart Required:** No

## Security Configuration

### Authentication

#### REQUIRE_PASSWORD

Require password authentication.

```ini
REQUIRE_PASSWORD=YES
```

- **Type:** Boolean
- **Default:** YES
- **Restart Required:** No

#### PASSWORD_EXPIRY

Password expiry in days (0 = never).

```ini
PASSWORD_EXPIRY=90
```

- **Type:** Integer (days)
- **Default:** 0
- **Range:** 0-365
- **Restart Required:** No

### Access Control

#### ADMIN_USERS

Comma-separated list of administrative users.

```ini
ADMIN_USERS=root,qmsys,admin
```

- **Type:** String (comma-separated)
- **Default:** root,qmsys
- **Restart Required:** No

#### RESTRICTED_COMMANDS

Disable specific commands.

```ini
RESTRICTED_COMMANDS=DELETE-FILE,CLEAR-FILE
```

- **Type:** String (comma-separated)
- **Default:** (none)
- **Restart Required:** No

## Logging Configuration

### Log Settings

#### LOGGING

Enable system logging.

```ini
LOGGING=YES
```

- **Type:** Boolean
- **Default:** NO
- **Restart Required:** No

#### LOGDIR

Directory for log files.

```ini
LOGDIR=/var/log/scarletdme
```

- **Type:** String (path)
- **Default:** /usr/qmsys/logs
- **Restart Required:** No

#### LOGLEVEL

Logging verbosity level.

```ini
LOGLEVEL=INFO
```

- **Type:** String
- **Default:** INFO
- **Values:** DEBUG, INFO, WARNING, ERROR
- **Restart Required:** No

#### LOGROTATE

Enable automatic log rotation.

```ini
LOGROTATE=YES
LOGSIZE=10M
LOGKEEP=7
```

- **LOGROTATE:** Enable rotation (YES/NO)
- **LOGSIZE:** Max size before rotation (e.g., 10M, 1G)
- **LOGKEEP:** Number of old logs to keep

## Performance Configuration

### File System

#### FILERULE

Default file sizing rule.

```ini
FILERULE=1
```

- **Type:** Integer
- **Default:** 1
- **Range:** 1-5
- **Restart Required:** No

**Rules:**
1. Small (< 1000 records)
2. Medium (1000-10000 records)
3. Large (10000-100000 records)
4. Very Large (> 100000 records)
5. Custom

#### SPLIT_LOAD

Load factor for automatic file splitting.

```ini
SPLIT_LOAD=80
```

- **Type:** Integer (percentage)
- **Default:** 80
- **Range:** 50-95
- **Restart Required:** No

### Caching

#### CACHE_ENABLE

Enable record caching.

```ini
CACHE_ENABLE=YES
```

- **Type:** Boolean
- **Default:** YES
- **Restart Required:** No

#### CACHE_SIZE

Number of cached records per file.

```ini
CACHE_SIZE=100
```

- **Type:** Integer
- **Default:** 100
- **Range:** 0-10000
- **Restart Required:** No

## Backup Configuration

### Backup Settings

#### BACKUP_DIR

Default backup directory.

```ini
BACKUP_DIR=/backup/scarletdme
```

- **Type:** String (path)
- **Default:** /usr/qmsys/backup
- **Restart Required:** No

#### AUTO_BACKUP

Enable automatic backups.

```ini
AUTO_BACKUP=YES
BACKUP_TIME=02:00
BACKUP_RETAIN=7
```

- **AUTO_BACKUP:** Enable automatic backups
- **BACKUP_TIME:** Time to run backup (HH:MM)
- **BACKUP_RETAIN:** Days to retain backups

## Example Configurations

### Minimal Configuration

```ini
# Minimal production config
MAXUSERS=20
NUMFILES=50
SHMEM=32
LOGGING=YES
```

### Development Configuration

```ini
# Development environment
MAXUSERS=5
NUMFILES=100
SHMEM=64
BUFFERPOOL=16
LOGGING=YES
LOGLEVEL=DEBUG
```

### Production Configuration

```ini
# Production server
MAXUSERS=100
NUMFILES=200
NETFILES=50
SHMEM=256
BUFFERPOOL=64
SORTMEM=16

# Network
QMSERVER_PORT=4242
QMCLIENT_PORT=4243
ALLOW_REMOTE=YES
BIND_ADDRESS=0.0.0.0

# Security
REQUIRE_PASSWORD=YES
PASSWORD_EXPIRY=90
ADMIN_USERS=root,qmsys

# Logging
LOGGING=YES
LOGDIR=/var/log/scarletdme
LOGLEVEL=INFO
LOGROTATE=YES
LOGSIZE=100M
LOGKEEP=30

# Performance
FILERULE=3
SPLIT_LOAD=80
CACHE_ENABLE=YES
CACHE_SIZE=1000

# Backup
BACKUP_DIR=/backup/scarletdme
AUTO_BACKUP=YES
BACKUP_TIME=02:00
BACKUP_RETAIN=14
```

### High-Security Configuration

```ini
# High-security environment
MAXUSERS=50
REQUIRE_PASSWORD=YES
PASSWORD_EXPIRY=30
ALLOW_REMOTE=NO
BIND_ADDRESS=127.0.0.1
RESTRICTED_COMMANDS=DELETE-FILE,CLEAR-FILE,DELETE-ACCOUNT

# Comprehensive logging
LOGGING=YES
LOGLEVEL=INFO
LOGDIR=/var/log/scarletdme
AUDIT_LOGGING=YES
AUDIT_LEVEL=ALL
```

## Configuration Management

### Viewing Current Configuration

```bash
# Display current settings
qm -c "SHOW-CONFIG"

# Check specific parameter
qm -c "SHOW-CONFIG MAXUSERS"

# Display all parameters
cat /etc/scarlet.conf
```

### Modifying Configuration

```bash
# Edit configuration file
sudo nano /etc/scarlet.conf

# Restart to apply changes requiring restart
sudo systemctl restart scarletdme

# Or reload for runtime changes
sudo systemctl reload scarletdme
```

### Testing Configuration

```bash
# Test configuration syntax
qm -test-config /etc/scarlet.conf

# Validate parameters
qm -validate-config
```

### Backup Configuration

```bash
# Backup current config
sudo cp /etc/scarlet.conf /etc/scarlet.conf.backup

# Dated backup
sudo cp /etc/scarlet.conf /etc/scarlet.conf.$(date +%Y%m%d)
```

## Environment Variables

### QMSYS

Installation directory.

```bash
export QMSYS=/usr/qmsys
```

### LD_LIBRARY_PATH

Library search path.

```bash
export LD_LIBRARY_PATH=/usr/qmsys/bin:$LD_LIBRARY_PATH
```

### QMCONFIG

Alternative config file location.

```bash
export QMCONFIG=/etc/custom/scarlet.conf
```

### QMTERM

Terminal type override.

```bash
export QMTERM=vt100
```

## Docker Configuration

### Environment Variables

```yaml
environment:
  - MAXUSERS=50
  - NUMFILES=100
  - LOGGING=YES
```

### ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: scarletdme-config
data:
  scarlet.conf: |
    MAXUSERS=50
    NUMFILES=100
    LOGGING=YES
```

### Mounting Configuration

```yaml
volumeMounts:
  - name: config
    mountPath: /etc/scarlet.conf
    subPath: scarlet.conf
volumes:
  - name: config
    configMap:
      name: scarletdme-config
```

## Troubleshooting Configuration

### Configuration Not Loading

```bash
# Check file exists
ls -l /etc/scarlet.conf

# Check permissions
sudo chmod 644 /etc/scarlet.conf

# Check syntax
qm -test-config
```

### Parameter Not Taking Effect

```bash
# Check if restart required
grep "Restart Required: Yes" docs/myra/09-configuration.md

# Restart service
sudo systemctl restart scarletdme

# Verify setting
qm -c "SHOW-CONFIG PARAMETER"
```

### Invalid Values

```bash
# Check logs for errors
sudo journalctl -u scarletdme | grep -i "config"

# Validate configuration
qm -validate-config

# Reset to defaults
sudo mv /etc/scarlet.conf /etc/scarlet.conf.old
sudo systemctl restart scarletdme
```

## Best Practices

### Configuration Management

1. **Version Control**: Keep configs in git
2. **Documentation**: Comment non-obvious settings
3. **Backup**: Always backup before changes
4. **Testing**: Test in development first
5. **Monitoring**: Watch for issues after changes

### Security Practices

1. Restrict file permissions (644 for config)
2. Use minimal privileges
3. Enable logging and auditing
4. Regularly review security settings
5. Keep passwords out of config files

### Performance Tuning

1. Start with defaults
2. Monitor resource usage
3. Adjust incrementally
4. Test under load
5. Document changes and rationale

## Next Steps

- [Security](10-security.md) - Security configuration
- [Monitoring](11-monitoring.md) - Monitor system performance
- [Troubleshooting](14-troubleshooting.md) - Solve configuration issues

