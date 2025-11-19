# Monitoring

## Overview

This document covers monitoring strategies, tools, and best practices for ScarletDME deployments.

## Health Monitoring

### Daemon Status

#### Check if qmlnxd is Running

```bash
# Process check
ps aux | grep qmlnxd

# Specific process check
pgrep -x qmlnxd

# Detailed information
ps -fp $(pgrep qmlnxd)
```

#### Systemd Status

```bash
# Check service status
sudo systemctl status scarletdme

# Check if enabled
sudo systemctl is-enabled scarletdme

# Check if active
sudo systemctl is-active scarletdme
```

### Port Monitoring

#### Check Listening Ports

```bash
# Using netstat
sudo netstat -tlnp | grep -E '4242|4243'

# Using ss
sudo ss -tlnp | grep -E '4242|4243'

# Using lsof
sudo lsof -i :4242
sudo lsof -i :4243
```

#### Test Port Connectivity

```bash
# Test from localhost
telnet localhost 4242
nc -zv localhost 4243

# Test from remote host
telnet server.example.com 4242
nc -zv server.example.com 4243
```

### Shared Memory Status

#### List Shared Memory Segments

```bash
# List all segments
ipcs -m

# Show details
ipcs -m -i <shmid>

# Show limits
ipcs -l
```

#### Monitor Shared Memory Usage

```bash
# Check usage
ipcs -m | grep qmsys

# Detailed stats
ipcs -m -t -p
```

### Container Health

#### Docker Health Check

```bash
# Check container health
docker inspect --format='{{.State.Health.Status}}' scarletdme

# View health check logs
docker inspect --format='{{range .State.Health.Log}}{{.Output}}{{end}}' scarletdme

# Container stats
docker stats scarletdme
```

#### Kubernetes Health

```bash
# Check pod health
kubectl get pods -l app=scarletdme

# Describe pod
kubectl describe pod <pod-name>

# Check readiness
kubectl get pods -o json | jq '.items[].status.conditions'
```

## Performance Monitoring

### System Resources

#### CPU Usage

```bash
# Overall CPU
top -b -n 1 | grep qm

# Per-process CPU
ps aux | grep qm | awk '{print $3, $11}'

# CPU over time
pidstat -p $(pgrep qmlnxd) 5
```

#### Memory Usage

```bash
# Memory by process
ps aux | grep qm | awk '{print $4, $6, $11}'

# Detailed memory
pmap $(pgrep qmlnxd)

# Memory over time
pidstat -r -p $(pgrep qmlnxd) 5
```

#### Disk I/O

```bash
# I/O statistics
iostat -x 5

# Per-process I/O
pidstat -d -p $(pgrep qmlnxd) 5

# Disk usage
df -h /usr/qmsys
du -sh /usr/qmsys/*
```

### Application Metrics

#### Connected Users

```bash
# List connected users
qm -c "LIST.USERS"

# Count users
qm -c "COUNT.USERS"

# User details
qm -c "WHO"
```

#### Open Files

```bash
# Files opened by qmlnxd
lsof -p $(pgrep qmlnxd) | wc -l

# Detailed file list
lsof -p $(pgrep qmlnxd)

# Files by all qm processes
lsof -c qm
```

#### Lock Status

```bash
# View locks
qm -c "LIST.LOCKS"

# Detailed lock information
qm -c "SHOW.LOCKS"

# Deadlock detection
qm -c "SHOW.DEADLOCKS"
```

### Database Metrics

#### File Statistics

```bash
# File size and statistics
qm -c "FILE.STATS FILENAME"

# File analysis
qm -c "ANALYZE.FILE FILENAME"

# All files statistics
qm -c "LIST.FILES"
```

#### Index Status

```bash
# Check indexes
qm -c "LIST.INDEX FILENAME"

# Index statistics
qm -c "INDEX.STATS FILENAME"

# Verify index integrity
qm -c "VERIFY.INDEX FILENAME"
```

## Log Monitoring

### System Logs

#### systemd Journals

```bash
# View all logs
sudo journalctl -u scarletdme

# Follow logs
sudo journalctl -u scarletdme -f

# Last 50 lines
sudo journalctl -u scarletdme -n 50

# Logs since time
sudo journalctl -u scarletdme --since "1 hour ago"

# Error logs only
sudo journalctl -u scarletdme -p err
```

#### Application Logs

```bash
# View application logs
tail -f /var/log/scarletdme/system.log

# Error logs
tail -f /var/log/scarletdme/errors.log

# Audit logs
tail -f /var/log/scarletdme/audit.log

# Search logs
grep "ERROR" /var/log/scarletdme/system.log
```

### Log Analysis

#### Common Error Patterns

```bash
# Count errors by type
grep "ERROR" /var/log/scarletdme/system.log | \
  cut -d':' -f3 | sort | uniq -c | sort -rn

# Failed login attempts
grep "Failed login" /var/log/scarletdme/security.log

# Connection errors
grep "Connection" /var/log/scarletdme/system.log | grep -i error
```

#### Log Aggregation

```bash
# Daily summary
for log in /var/log/scarletdme/*.log; do
  echo "=== $log ==="
  grep "$(date +%Y-%m-%d)" $log | \
    grep -E "ERROR|WARNING" | wc -l
done
```

## Monitoring Tools

### Prometheus Integration

#### Metrics Exporter

Create a metrics endpoint:

```python
# /usr/local/bin/scarletdme-exporter.py
#!/usr/bin/env python3
from prometheus_client import start_http_server, Gauge
import subprocess
import time

# Define metrics
users_gauge = Gauge('scarletdme_users', 'Number of connected users')
files_gauge = Gauge('scarletdme_open_files', 'Number of open files')
locks_gauge = Gauge('scarletdme_locks', 'Number of active locks')

def collect_metrics():
    # Collect users
    result = subprocess.run(['qm', '-c', 'COUNT.USERS'], 
                          capture_output=True, text=True)
    users_gauge.set(int(result.stdout.strip()))
    
    # Collect files
    result = subprocess.run(['lsof', '-p', str(get_qmlnxd_pid())], 
                          capture_output=True, text=True)
    files_gauge.set(len(result.stdout.splitlines()))
    
    # Add more metrics...

if __name__ == '__main__':
    start_http_server(9090)
    while True:
        collect_metrics()
        time.sleep(15)
```

#### Prometheus Configuration

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'scarletdme'
    static_configs:
      - targets: ['localhost:9090']
```

### Grafana Dashboards

#### Dashboard JSON

```json
{
  "dashboard": {
    "title": "ScarletDME Monitoring",
    "panels": [
      {
        "title": "Connected Users",
        "targets": [
          {
            "expr": "scarletdme_users"
          }
        ]
      },
      {
        "title": "CPU Usage",
        "targets": [
          {
            "expr": "rate(process_cpu_seconds_total{job=\"scarletdme\"}[5m])"
          }
        ]
      }
    ]
  }
}
```

### Nagios/Icinga Checks

#### Check Script

```bash
#!/bin/bash
# /usr/local/bin/check_scarletdme.sh

# Check if daemon is running
if ! pgrep -x qmlnxd > /dev/null; then
    echo "CRITICAL: qmlnxd is not running"
    exit 2
fi

# Check if ports are listening
if ! netstat -tln | grep -q ":4243 "; then
    echo "CRITICAL: QMClient port not listening"
    exit 2
fi

# Check user count
USERS=$(qm -c "COUNT.USERS" 2>/dev/null | tr -d ' ')
if [ $USERS -gt 80 ]; then
    echo "WARNING: High user count: $USERS"
    exit 1
fi

echo "OK: ScarletDME running, $USERS users"
exit 0
```

#### Nagios Configuration

```cfg
# /etc/nagios/conf.d/scarletdme.cfg
define service {
    host_name               scarletdme-server
    service_description     ScarletDME Health
    check_command           check_scarletdme
    check_interval          5
    retry_interval          1
    max_check_attempts      3
}
```

### Zabbix Monitoring

#### Template

```xml
<!-- ScarletDME Zabbix Template -->
<zabbix_export>
  <template>
    <name>ScarletDME</name>
    <items>
      <item>
        <name>Daemon Status</name>
        <key>proc.num[qmlnxd]</key>
        <triggers>
          <trigger>
            <expression>{last()}=0</expression>
            <priority>HIGH</priority>
          </trigger>
        </triggers>
      </item>
    </items>
  </template>
</zabbix_export>
```

## Alerting

### Email Alerts

#### Script

```bash
#!/bin/bash
# /usr/local/bin/scarletdme-alert.sh

ADMIN_EMAIL="admin@example.com"
THRESHOLD_USERS=80

USERS=$(qm -c "COUNT.USERS" 2>/dev/null | tr -d ' ')

if [ $USERS -gt $THRESHOLD_USERS ]; then
    echo "High user count: $USERS" | \
        mail -s "ScarletDME Alert" $ADMIN_EMAIL
fi
```

#### Cron Job

```bash
# /etc/cron.d/scarletdme-monitoring
*/5 * * * * root /usr/local/bin/scarletdme-alert.sh
```

### Slack Notifications

```bash
#!/bin/bash
# Send alert to Slack

WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

curl -X POST -H 'Content-type: application/json' \
    --data "{\"text\":\"ScarletDME Alert: $1\"}" \
    $WEBHOOK_URL
```

### PagerDuty Integration

```python
#!/usr/bin/env python3
import requests

def send_alert(severity, description):
    url = "https://events.pagerduty.com/v2/enqueue"
    headers = {
        "Content-Type": "application/json",
    }
    data = {
        "routing_key": "YOUR_INTEGRATION_KEY",
        "event_action": "trigger",
        "payload": {
            "summary": description,
            "severity": severity,
            "source": "scarletdme",
        }
    }
    requests.post(url, json=data, headers=headers)
```

## Performance Baselines

### Establish Baselines

```bash
# CPU baseline
sar -u 1 3600 > cpu_baseline.txt

# Memory baseline
sar -r 1 3600 > mem_baseline.txt

# I/O baseline
sar -d 1 3600 > io_baseline.txt

# Network baseline
sar -n DEV 1 3600 > net_baseline.txt
```

### Compare to Baseline

```bash
# Current vs baseline
diff <(sar -u 1 10) <(head -n 20 cpu_baseline.txt)
```

## Capacity Planning

### Resource Trends

#### Track Growth

```bash
# Database size over time
du -sb /usr/qmsys >> /var/log/scarletdme/size_history.log

# User count over time
qm -c "COUNT.USERS" >> /var/log/scarletdme/users_history.log

# Analyze trend
awk '{sum+=$1} END {print sum/NR}' /var/log/scarletdme/users_history.log
```

#### Predict Capacity Needs

```bash
# Growth rate calculation
# Current size: 50GB
# Size 6 months ago: 30GB
# Growth: 20GB in 6 months
# Monthly growth: 3.33GB
# Months until 100GB: (100-50)/3.33 = ~15 months
```

### Resource Recommendations

| Users | CPU Cores | RAM (GB) | Disk (GB) |
|-------|-----------|----------|-----------|
| 1-10  | 1         | 2        | 20        |
| 10-25 | 2         | 4        | 50        |
| 25-50 | 2         | 8        | 100       |
| 50-100| 4         | 16       | 250       |
| 100+  | 8+        | 32+      | 500+      |

## Automated Monitoring Scripts

### Comprehensive Monitoring

```bash
#!/bin/bash
# /usr/local/bin/monitor-scarletdme.sh

LOG="/var/log/scarletdme/monitor.log"

echo "=== $(date) ===" >> $LOG

# Check daemon
if pgrep -x qmlnxd > /dev/null; then
    echo "Daemon: OK" >> $LOG
else
    echo "Daemon: FAILED" >> $LOG
    systemctl restart scarletdme
fi

# Check ports
for port in 4242 4243; do
    if netstat -tln | grep -q ":$port "; then
        echo "Port $port: OK" >> $LOG
    else
        echo "Port $port: FAILED" >> $LOG
    fi
done

# Check resources
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')
MEM=$(free | grep Mem | awk '{print ($3/$2) * 100.0}')
DISK=$(df /usr/qmsys | tail -1 | awk '{print $5}')

echo "CPU: $CPU%, MEM: $MEM%, DISK: $DISK" >> $LOG

# Check users
USERS=$(qm -c "COUNT.USERS" 2>/dev/null | tr -d ' ')
echo "Users: $USERS" >> $LOG
```

### Schedule Monitoring

```bash
# /etc/cron.d/scarletdme-monitor
*/5 * * * * root /usr/local/bin/monitor-scarletdme.sh
```

## Troubleshooting Monitoring Issues

### Metrics Not Updating

```bash
# Check exporter is running
ps aux | grep exporter

# Check exporter logs
journalctl -u scarletdme-exporter -n 50

# Test endpoint
curl http://localhost:9090/metrics
```

### High Resource Usage

```bash
# Identify resource hog
top -b -n 1 | head -20

# Check for runaway processes
ps aux | grep qm | awk '$3>50 {print}'

# Check for memory leaks
valgrind --leak-check=full /usr/qmsys/bin/qm -c "TEST"
```

### Missing Logs

```bash
# Check log directory permissions
ls -la /var/log/scarletdme/

# Check disk space
df -h /var/log

# Check syslog configuration
grep scarletdme /etc/rsyslog.conf /etc/rsyslog.d/*
```

## Best Practices

### Monitoring Strategy

1. **Monitor at all layers**: OS, network, application, database
2. **Set meaningful thresholds**: Based on baselines
3. **Alert on trends**: Not just absolute values
4. **Keep historical data**: For capacity planning
5. **Test alerting**: Regularly verify alerts work

### Dashboard Design

1. **Overview dashboard**: High-level system health
2. **Detailed dashboards**: Per-component metrics
3. **Use color coding**: Green/yellow/red status
4. **Show trends**: Include time-series graphs
5. **Include context**: Show baselines and thresholds

### Alert Fatigue Prevention

1. **Tune thresholds**: Reduce false positives
2. **Use severity levels**: Critical vs warning
3. **Implement alert suppression**: During maintenance
4. **Group related alerts**: Avoid duplicate notifications
5. **Review and adjust**: Regularly update alerting rules

## Next Steps

- [Configuration](09-configuration.md) - Configure monitoring settings
- [Troubleshooting](14-troubleshooting.md) - Diagnose issues
- [Security](10-security.md) - Security monitoring

