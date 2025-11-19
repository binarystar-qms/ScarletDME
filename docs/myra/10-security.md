# Security

## Overview

This document covers security considerations, best practices, and configuration for ScarletDME deployments.

## Security Model

### Multi-Layer Security

ScarletDME security operates at multiple levels:

1. **Operating System**: Linux user/group permissions
2. **Network**: Port access and firewall rules
3. **Application**: User authentication and authorization
4. **Data**: File permissions and record-level security

## User and Group Security

### qmusers Group

All ScarletDME users must belong to the `qmusers` group.

#### Add User to Group

```bash
# Add existing user
sudo usermod -aG qmusers username

# Verify membership
groups username
getent group qmusers
```

#### Remove User from Group

```bash
sudo gpasswd -d username qmusers
```

### qmsys User

System account that owns ScarletDME files.

**Properties:**
- Home directory: `/usr/qmsys`
- Shell: `/bin/bash` 
- No password login (system account)

**Security Guidelines:**
- Never log in directly as qmsys
- Use `sudo` for administrative tasks
- Restrict `sudo` access to qmsys account

### File Permissions

#### System Files

```bash
# Binary executables
-rwxr-xr-x  qmsys:qmusers  /usr/qmsys/bin/qm

# Data files
-rw-rw-r--  qmsys:qmusers  /usr/qmsys/VOC/*

# Directories
drwxrwxr-x  qmsys:qmusers  /usr/qmsys/
```

#### Configuration Files

```bash
# Configuration (world-readable, root-writable)
-rw-r--r--  root:root  /etc/scarlet.conf

# Sensitive configs (restricted)
-rw-------  root:root  /etc/scarlet.d/secrets.conf
```

#### User Data

```bash
# User-owned files
-rw-rw-r--  user:qmusers  /usr/qmsys/MYACCOUNT/*

# Shared files
-rw-rw-r--  qmsys:qmusers  /usr/qmsys/SHARED/*
```

### Permission Best Practices

```bash
# Set correct ownership
sudo chown -R qmsys:qmusers /usr/qmsys

# Set directory permissions (775)
sudo find /usr/qmsys -type d -exec chmod 775 {} \;

# Set file permissions (664)
sudo find /usr/qmsys -type f -exec chmod 664 {} \;

# Set executable permissions (755)
sudo chmod 755 /usr/qmsys/bin/*
```

## Network Security

### Firewall Configuration

#### UFW (Ubuntu/Debian)

```bash
# Default deny
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH
sudo ufw allow 22/tcp

# Allow ScarletDME ports
sudo ufw allow 4242/tcp comment 'QMServer'
sudo ufw allow 4243/tcp comment 'QMClient'

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status verbose
```

#### firewalld (CentOS/RHEL)

```bash
# Add ports
sudo firewall-cmd --permanent --add-port=4242/tcp
sudo firewall-cmd --permanent --add-port=4243/tcp

# Add services (if defined)
sudo firewall-cmd --permanent --add-service=scarletdme

# Reload
sudo firewall-cmd --reload

# Verify
sudo firewall-cmd --list-all
```

#### iptables

```bash
# Allow QMServer
sudo iptables -A INPUT -p tcp --dport 4242 -j ACCEPT

# Allow QMClient
sudo iptables -A INPUT -p tcp --dport 4243 -j ACCEPT

# Save rules
sudo iptables-save > /etc/iptables/rules.v4
```

### IP Whitelisting

#### Configuration File

```ini
# /etc/scarlet.conf
ALLOWED_HOSTS=192.168.1.0/24,10.0.0.0/8,172.16.0.100
```

#### Firewall Rules

```bash
# Allow specific IPs only
sudo ufw allow from 192.168.1.0/24 to any port 4243
sudo ufw allow from 10.0.0.50 to any port 4242
```

### Port Security

#### Non-Standard Ports

```ini
# Use non-standard ports
QMSERVER_PORT=14242
QMCLIENT_PORT=14243
```

```bash
# Update firewall
sudo ufw allow 14242/tcp
sudo ufw allow 14243/tcp
```

#### Bind to Specific Interface

```ini
# Bind to internal interface only
BIND_ADDRESS=10.0.0.10

# Localhost only
BIND_ADDRESS=127.0.0.1
```

### SSL/TLS (Future Enhancement)

Currently, ScarletDME does not support native SSL/TLS. Use a reverse proxy:

#### stunnel Configuration

```ini
# /etc/stunnel/scarletdme.conf
[qmclient]
accept = 14243
connect = 4243
cert = /etc/ssl/certs/scarletdme.pem
key = /etc/ssl/private/scarletdme.key
```

#### nginx Reverse Proxy

```nginx
stream {
    upstream scarletdme {
        server 127.0.0.1:4243;
    }
    
    server {
        listen 14243 ssl;
        ssl_certificate /etc/ssl/certs/scarletdme.crt;
        ssl_certificate_key /etc/ssl/private/scarletdme.key;
        proxy_pass scarletdme;
    }
}
```

## Application Security

### Authentication

#### User Authentication

ScarletDME uses Linux PAM authentication:

```bash
# Users must exist in /etc/passwd
# And belong to qmusers group

# Test authentication
qm
# Prompts for password if required
```

#### Disable Password Requirements (Development Only)

```ini
# /etc/scarlet.conf
REQUIRE_PASSWORD=NO
```

**Warning:** Only for isolated development environments!

### Authorization

#### Account-Level Security

Users are restricted to their accounts:

```bash
# User logs into their account
qm MYACCOUNT

# Cannot access other accounts without permission
```

#### Vocabulary Security

Restrict commands in VOC file:

```
# VOC record for restricted command
ID: DANGEROUS-COMMAND
TYPE: V
SECURITY: ADMIN
EXECUTE: ACTUAL-PROGRAM
```

#### File-Level Security

```bash
# Set file to read-only
chmod 444 /usr/qmsys/MYFILE/*

# Restrict access to specific group
chgrp admins /usr/qmsys/SENSITIVE/
chmod 770 /usr/qmsys/SENSITIVE/
```

### Password Security

#### Password Policy

```ini
# /etc/scarlet.conf
PASSWORD_MIN_LENGTH=12
PASSWORD_COMPLEXITY=YES
PASSWORD_EXPIRY=90
PASSWORD_HISTORY=5
```

#### System Password Policy

Use PAM to enforce password policies:

```bash
# /etc/pam.d/common-password
password requisite pam_pwquality.so \
    retry=3 \
    minlen=12 \
    dcredit=-1 \
    ucredit=-1 \
    ocredit=-1 \
    lcredit=-1
```

### Session Security

#### Timeout Configuration

```ini
# /etc/scarlet.conf
SESSION_TIMEOUT=1800  # 30 minutes
IDLE_TIMEOUT=600      # 10 minutes
```

#### Session Logging

```ini
# Log all sessions
SESSION_LOGGING=YES
SESSION_LOG=/var/log/scarletdme/sessions.log
```

## Container Security

### Docker Security

#### Run as Non-Root

```dockerfile
# Dockerfile
USER qmsys:qmusers
```

```bash
# docker run
docker run --user 1000:1000 scarletdme
```

#### Read-Only Root Filesystem

```bash
docker run \
  --read-only \
  --tmpfs /tmp \
  --tmpfs /var/run \
  -v scarletdme-data:/usr/qmsys \
  scarletdme
```

#### Drop Capabilities

```bash
docker run \
  --cap-drop=ALL \
  --cap-add=CHOWN \
  --cap-add=SETUID \
  --cap-add=SETGID \
  scarletdme
```

#### Security Options

```bash
docker run \
  --security-opt=no-new-privileges \
  --security-opt=seccomp=unconfined \
  scarletdme
```

### Kubernetes Security

#### Pod Security Context

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
  seccompProfile:
    type: RuntimeDefault
```

#### Container Security Context

```yaml
securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop:
      - ALL
    add:
      - CHOWN
      - SETUID
      - SETGID
```

#### Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: scarletdme-netpol
spec:
  podSelector:
    matchLabels:
      app: scarletdme
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              role: application
      ports:
        - protocol: TCP
          port: 4243
  egress:
    - to:
        - podSelector:
            matchLabels:
              role: dns
      ports:
        - protocol: UDP
          port: 53
```

#### Secrets Management

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: scarletdme-secret
type: Opaque
stringData:
  admin-password: "SecurePassword123!"
  api-key: "api-key-value"
```

Use in pod:

```yaml
env:
  - name: ADMIN_PASSWORD
    valueFrom:
      secretKeyRef:
        name: scarletdme-secret
        key: admin-password
```

## Audit and Logging

### Enable Audit Logging

```ini
# /etc/scarlet.conf
AUDIT_LOGGING=YES
AUDIT_FILE=/var/log/scarletdme/audit.log
AUDIT_LEVEL=ALL
```

### Audit Events

- User login/logout
- File access
- Record modifications
- Command execution
- Security violations
- Configuration changes

### Log Files

```bash
# System logs
/var/log/scarletdme/system.log

# Audit logs
/var/log/scarletdme/audit.log

# Session logs
/var/log/scarletdme/sessions.log

# Error logs
/var/log/scarletdme/errors.log
```

### Log Rotation

```bash
# /etc/logrotate.d/scarletdme
/var/log/scarletdme/*.log {
    daily
    rotate 30
    compress
    delaycompress
    notifempty
    create 0640 qmsys qmusers
    sharedscripts
    postrotate
        systemctl reload scarletdme > /dev/null 2>&1 || true
    endscript
}
```

### Centralized Logging

#### rsyslog

```bash
# /etc/rsyslog.d/scarletdme.conf
$template ScarletDME,"/var/log/scarletdme/%PROGRAMNAME%.log"
:programname, isequal, "qm" ?ScarletDME
:programname, isequal, "qmlnxd" ?ScarletDME
& stop
```

#### Syslog to Remote Server

```bash
# /etc/rsyslog.d/remote.conf
*.* @@logserver.example.com:514
```

## Backup Security

### Encrypted Backups

```bash
# Backup with encryption
tar czf - /usr/qmsys | \
  gpg --encrypt --recipient admin@example.com > \
  backup-$(date +%Y%m%d).tar.gz.gpg

# Restore
gpg --decrypt backup-20250101.tar.gz.gpg | \
  tar xzf - -C /
```

### Secure Backup Storage

```bash
# Set permissions
chmod 600 /backup/scarletdme/*.tar.gz

# Offsite storage
rsync -avz --delete \
  /backup/scarletdme/ \
  backup@remotehost:/backups/scarletdme/
```

## Vulnerability Management

### Regular Updates

```bash
# Update system packages
sudo apt update && sudo apt upgrade

# Update ScarletDME
cd ScarletDME
git pull
make clean && make
sudo make install
```

### Security Scanning

#### ClamAV

```bash
# Install
sudo apt install clamav

# Scan
clamscan -r /usr/qmsys
```

#### Lynis

```bash
# Install
sudo apt install lynis

# Security audit
sudo lynis audit system
```

### Monitoring for Intrusions

#### fail2ban

```ini
# /etc/fail2ban/jail.d/scarletdme.conf
[scarletdme]
enabled = true
port = 4242,4243
filter = scarletdme
logpath = /var/log/scarletdme/security.log
maxretry = 5
bantime = 3600
```

```ini
# /etc/fail2ban/filter.d/scarletdme.conf
[Definition]
failregex = Failed login attempt from <HOST>
            Authentication failed.*<HOST>
ignoreregex =
```

## Compliance

### GDPR Compliance

- Implement data retention policies
- Enable audit logging
- Provide data export functionality
- Implement data deletion procedures
- Document data processing

### PCI DSS Compliance

- Encrypt sensitive data at rest
- Use SSL/TLS for transmission
- Implement access controls
- Maintain audit logs
- Regular security assessments

### HIPAA Compliance

- Encrypt PHI data
- Access controls and authentication
- Audit logging
- Backup and disaster recovery
- Security incident procedures

## Security Checklist

### Installation

- [ ] Create qmusers group and qmsys user
- [ ] Set correct file permissions
- [ ] Configure firewall
- [ ] Disable unnecessary services
- [ ] Configure secure passwords

### Configuration

- [ ] Review scarlet.conf security settings
- [ ] Enable authentication
- [ ] Configure network restrictions
- [ ] Set resource limits
- [ ] Enable logging and auditing

### Operation

- [ ] Monitor logs regularly
- [ ] Review user access
- [ ] Update system regularly
- [ ] Test backups
- [ ] Perform security audits

### Container Deployment

- [ ] Use official base images
- [ ] Run as non-root user
- [ ] Drop unnecessary capabilities
- [ ] Use read-only root filesystem
- [ ] Implement network policies
- [ ] Scan images for vulnerabilities

## Incident Response

### Security Breach

1. **Isolate**: Disconnect from network
2. **Assess**: Determine scope of breach
3. **Contain**: Stop ongoing attack
4. **Eradicate**: Remove threat
5. **Recover**: Restore from backup
6. **Review**: Analyze and improve

### Contact Information

- Security issues: security@example.com
- GitHub Security: Use private vulnerability reporting
- Community: Discord security channel

## Next Steps

- [Configuration](09-configuration.md) - Configure security settings
- [Monitoring](11-monitoring.md) - Monitor for security events
- [Troubleshooting](14-troubleshooting.md) - Solve security issues

