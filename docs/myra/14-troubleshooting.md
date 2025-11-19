# Troubleshooting

## Overview

This guide helps diagnose and resolve common issues with ScarletDME installations and operations.

## Quick Diagnostics

### Health Check Script

```bash
#!/bin/bash
# Quick health check

echo "=== ScarletDME Health Check ==="

# Check daemon
if pgrep -x qmlnxd > /dev/null; then
    echo "✓ Daemon running"
else
    echo "✗ Daemon not running"
fi

# Check ports
for port in 4242 4243; do
    if netstat -tln | grep -q ":$port "; then
        echo "✓ Port $port listening"
    else
        echo "✗ Port $port not listening"
    fi
done

# Check shared memory
if ipcs -m | grep -q qmsys; then
    echo "✓ Shared memory exists"
else
    echo "✗ No shared memory"
fi

# Check disk space
DISK=$(df /usr/qmsys | tail -1 | awk '{print $5}' | tr -d '%')
if [ $DISK -lt 90 ]; then
    echo "✓ Disk space OK ($DISK%)"
else
    echo "⚠ Low disk space ($DISK%)"
fi
```

## Installation Issues

### Build Failures

#### Missing Dependencies

**Problem:** gcc: command not found

**Solution:**
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install build-essential

# CentOS/RHEL
sudo yum groupinstall "Development Tools"
```

#### Compilation Errors

**Problem:** Syntax errors during compilation

**Solution:**
```bash
# Check compiler version
gcc --version

# Update compiler
sudo apt-get install gcc-9 g++-9

# Try with specific flags
make CFLAGS="-std=c99 -D_GNU_SOURCE"
```

#### Linker Errors

**Problem:** undefined reference to 'function'

**Solution:**
```bash
# Clean and rebuild
make clean
make

# Check library paths
export LD_LIBRARY_PATH=/usr/qmsys/bin:$LD_LIBRARY_PATH

# Install missing libraries
sudo apt-get install libc6-dev libpthread-stubs0-dev
```

### Installation Failures

#### Permission Denied

**Problem:** Cannot create directories or files

**Solution:**
```bash
# Use sudo
sudo make install

# Check permissions
ls -la /usr/qmsys
sudo chown -R qmsys:qmusers /usr/qmsys
```

#### User/Group Creation Failed

**Problem:** qmusers group already exists

**Solution:**
```bash
# Check existing group
getent group qmusers

# Manual user addition
sudo usermod -aG qmusers $USER

# Verify
groups $USER
```

## Runtime Issues

### Daemon Won't Start

#### Problem: qmlnxd fails to start

**Diagnosis:**
```bash
# Try starting manually
sudo /usr/qmsys/bin/qmlnxd -start

# Check logs
sudo journalctl -u scarletdme -n 50

# Check for errors
dmesg | grep qm
```

**Common Causes:**

1. **Shared memory issues**
```bash
# Check limits
ipcs -l

# Increase limits if needed
sudo sysctl -w kernel.shmmax=68719476736
sudo sysctl -w kernel.shmall=4294967296

# Make permanent
echo "kernel.shmmax=68719476736" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

2. **Already running**
```bash
# Check for existing daemon
ps aux | grep qmlnxd

# Kill if stuck
sudo killall qmlnxd

# Clean shared memory
sudo ipcrm -M $(ipcs -m | grep qmsys | awk '{print $1}')
```

3. **Permission issues**
```bash
# Check file ownership
ls -la /usr/qmsys/bin/qmlnxd

# Fix permissions
sudo chown qmsys:qmusers /usr/qmsys/bin/qmlnxd
sudo chmod 755 /usr/qmsys/bin/qmlnxd
```

### Connection Issues

#### $LOGIN Error

**Problem:** Cannot log in, "$LOGIN" error

**Cause:** User not in qmusers group

**Solution:**
```bash
# Add user to group
sudo usermod -aG qmusers $USER

# Log out and back in
exit
# Then log back in

# Verify
groups $USER | grep qmusers
```

#### Cannot Connect to Port

**Problem:** Connection refused on port 4243

**Diagnosis:**
```bash
# Check if port is listening
sudo netstat -tlnp | grep 4243

# Check firewall
sudo ufw status
sudo iptables -L -n | grep 4243
```

**Solutions:**

1. **Start network services**
```bash
# Systemd socket
sudo systemctl start qmclient.socket
sudo systemctl enable qmclient.socket

# Or xinetd
sudo systemctl restart xinetd
```

2. **Fix firewall**
```bash
# Allow port
sudo ufw allow 4243/tcp

# Or iptables
sudo iptables -A INPUT -p tcp --dport 4243 -j ACCEPT
```

3. **Check configuration**
```bash
# Verify port setting
grep QMCLIENT_PORT /etc/scarlet.conf

# Check bind address
grep BIND_ADDRESS /etc/scarlet.conf
```

### File Access Issues

#### File Not Found

**Problem:** File 'MYFILE' not found

**Diagnosis:**
```bash
# Check if file exists
ls -la /usr/qmsys/MYFILE/

# Check in VOC
qm -c "LIST VOC MYFILE"

# Check file permissions
ls -la /usr/qmsys/
```

**Solutions:**

1. **Create file**
```bash
qm -c "CREATE-FILE MYFILE"
```

2. **Add VOC entry**
```bash
qm
> ED VOC MYFILE
I F
I /usr/qmsys/MYFILE
FI
```

3. **Fix permissions**
```bash
sudo chown qmsys:qmusers /usr/qmsys/MYFILE/
sudo chmod 775 /usr/qmsys/MYFILE/
```

#### Permission Denied

**Problem:** Cannot read/write file

**Solution:**
```bash
# Check permissions
ls -la /usr/qmsys/MYFILE/

# Fix ownership
sudo chown -R qmsys:qmusers /usr/qmsys/MYFILE/

# Fix permissions
sudo chmod 775 /usr/qmsys/MYFILE/
sudo chmod 664 /usr/qmsys/MYFILE/*
```

### Performance Issues

#### Slow Response

**Diagnosis:**
```bash
# Check CPU usage
top -b -n 1 | grep qm

# Check I/O wait
iostat -x 1 5

# Check memory
free -h
```

**Solutions:**

1. **File needs resizing**
```bash
# Analyze file
qm -c "ANALYZE-FILE CUSTOMERS"

# Resize if needed
qm -c "RESIZE CUSTOMERS 101"
```

2. **Rebuild indexes**
```bash
qm -c "BUILD-INDEX CUSTOMERS NAME"
```

3. **Clear old locks**
```bash
qm -c "CLEAR-LOCKS"
```

4. **Increase resources**
```ini
# /etc/scarlet.conf
BUFFERPOOL=64
SHMEM=256
```

#### High Memory Usage

**Diagnosis:**
```bash
# Check memory usage
ps aux | grep qm | awk '{print $4, $11}'

# Check shared memory
ipcs -m
```

**Solutions:**

1. **Restart daemon**
```bash
sudo systemctl restart scarletdme
```

2. **Adjust configuration**
```ini
# /etc/scarlet.conf
CACHE_SIZE=500
BUFFERPOOL=32
```

### Data Corruption

#### File Corruption

**Problem:** File-level corruption errors

**Diagnosis:**
```bash
# Verify file
qmfix -v /usr/qmsys/CUSTOMERS

# Check file statistics
qm -c "FILE-STAT CUSTOMERS"
```

**Solutions:**

1. **Repair file**
```bash
# Stop daemon
sudo systemctl stop scarletdme

# Repair
qmfix /usr/qmsys/CUSTOMERS

# Restart
sudo systemctl start scarletdme
```

2. **Rebuild from backup**
```bash
# Stop daemon
sudo systemctl stop scarletdme

# Restore backup
sudo rm -rf /usr/qmsys/CUSTOMERS
sudo tar xzf backup.tar.gz -C /usr/qmsys

# Fix permissions
sudo chown -R qmsys:qmusers /usr/qmsys/CUSTOMERS

# Restart
sudo systemctl start scarletdme
```

#### Index Corruption

**Problem:** Index errors or inconsistencies

**Solution:**
```bash
# Rebuild index
qm -c "BUILD-INDEX CUSTOMERS NAME"

# Verify
qm -c "LIST-INDEX CUSTOMERS"
```

## Docker Issues

### Container Won't Start

**Diagnosis:**
```bash
# Check logs
docker logs scarletdme

# Check container status
docker inspect scarletdme

# Check for errors
docker events
```

**Solutions:**

1. **Port already in use**
```bash
# Find process using port
sudo lsof -i :4243

# Kill process or use different port
docker run -p 14243:4243 scarletdme
```

2. **Volume permission issues**
```bash
# Check volume
docker volume inspect scarletdme-data

# Fix permissions
docker run --rm -v scarletdme-data:/data alpine \
  chown -R 1000:1000 /data
```

3. **Memory limits**
```bash
# Increase memory
docker run --memory="2g" scarletdme
```

### Health Check Failing

**Diagnosis:**
```bash
# Check health
docker inspect --format='{{.State.Health}}' scarletdme

# Manual health check
docker exec scarletdme pgrep -x qmlnxd
```

**Solution:**
```bash
# Restart container
docker restart scarletdme

# Check logs
docker logs scarletdme --tail 100
```

## Kubernetes Issues

### Pod Not Starting

**Diagnosis:**
```bash
# Check pod status
kubectl get pods -l app=scarletdme

# Describe pod
kubectl describe pod <pod-name>

# Check events
kubectl get events --sort-by='.lastTimestamp'
```

**Common Issues:**

1. **Image pull error**
```bash
# Check image
kubectl describe pod <pod-name> | grep -i image

# Update image pull policy
kubectl patch deployment scarletdme \
  -p '{"spec":{"template":{"spec":{"containers":[{"name":"scarletdme","imagePullPolicy":"Always"}]}}}}'
```

2. **Resource constraints**
```bash
# Check resource limits
kubectl describe pod <pod-name> | grep -A 5 Limits

# Increase resources
kubectl edit deployment scarletdme
# Modify resources section
```

3. **Storage issues**
```bash
# Check PVC
kubectl get pvc

# Describe PVC
kubectl describe pvc scarletdme-pvc
```

### Service Not Accessible

**Diagnosis:**
```bash
# Check service
kubectl get svc scarletdme

# Check endpoints
kubectl get endpoints scarletdme

# Test from pod
kubectl run -it --rm debug --image=alpine --restart=Never -- sh
# nc -zv scarletdme 4243
```

**Solutions:**

1. **Fix selector**
```bash
# Check labels match
kubectl get pods --show-labels
kubectl describe svc scarletdme | grep Selector
```

2. **Fix port mapping**
```bash
kubectl edit svc scarletdme
# Verify ports section
```

## Log Analysis

### Finding Errors

```bash
# Recent errors
sudo journalctl -u scarletdme --since "1 hour ago" | grep -i error

# Error count
sudo journalctl -u scarletdme | grep -i error | wc -l

# Unique errors
sudo journalctl -u scarletdme | grep -i error | \
  cut -d':' -f3 | sort | uniq -c | sort -rn
```

### Common Error Messages

#### "Shared memory segment not found"

**Cause:** Daemon not running or crashed

**Solution:**
```bash
sudo systemctl restart scarletdme
```

#### "Lock timeout"

**Cause:** Deadlock or stuck lock

**Solution:**
```bash
qm -c "CLEAR-LOCKS"
```

#### "File is full"

**Cause:** File needs resizing

**Solution:**
```bash
qm -c "RESIZE FILENAME"
```

#### "Permission denied"

**Cause:** Insufficient permissions

**Solution:**
```bash
sudo chown qmsys:qmusers /usr/qmsys/FILENAME
sudo chmod 775 /usr/qmsys/FILENAME
```

## Getting Help

### Information to Collect

When reporting issues, collect:

1. **System information**
```bash
uname -a
cat /etc/os-release
```

2. **ScarletDME version**
```bash
qm -v
```

3. **Error logs**
```bash
sudo journalctl -u scarletdme -n 100 > logs.txt
```

4. **Configuration**
```bash
cat /etc/scarlet.conf
```

5. **Process status**
```bash
ps aux | grep qm
ipcs -m
```

### Community Resources

- **Discord**: [ScarletDME Discord](https://discord.gg/H7MPapC2hK)
- **Google Group**: [ScarletDME Google Group](https://groups.google.com/g/scarletdme/)
- **GitHub Issues**: [Report bugs](https://github.com/geneb/ScarletDME/issues)

### Professional Support

For professional support, contact the ScarletDME team or consult the community resources.

## Preventive Measures

### Regular Maintenance

```bash
# Daily tasks
- Check daemon status
- Review logs for errors
- Monitor disk space

# Weekly tasks
- Analyze file statistics
- Rebuild indexes if needed
- Review lock activity

# Monthly tasks
- Full system backup
- Performance review
- Security audit
```

### Monitoring Setup

```bash
# Set up automated monitoring
# See Monitoring guide for details

# Create alerts for:
- Daemon stopped
- High CPU/memory usage
- Disk space low
- Connection failures
```

## Next Steps

- [Monitoring](11-monitoring.md) - Set up monitoring
- [Configuration](09-configuration.md) - Optimize configuration
- [Security](10-security.md) - Security best practices

