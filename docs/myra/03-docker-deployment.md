# Docker Deployment

## Overview

ScarletDME provides Docker support with multi-stage builds optimized for production deployments. The container images are based on Alpine Linux for minimal size and attack surface.

## Docker Images

### Production Dockerfile

**Location:** `/Dockerfile`

**Build Strategy:**
- Multi-stage build
- Alpine Linux 3.19 base
- Minimal runtime dependencies
- Non-root execution where possible

### Test Dockerfile

**Location:** `/Dockerfile.test`

Used for development and testing purposes.

## Building the Docker Image

### Basic Build

```bash
docker build -t scarletdme:latest .
```

### Build with Custom Tag

```bash
docker build -t scarletdme:2.6-6 .
```

### Build Arguments

The Dockerfile supports various build-time configurations:

```bash
docker build \
  --build-arg ALPINE_VERSION=3.19 \
  -t scarletdme:latest .
```

## Running a Container

### Basic Run

```bash
docker run -d \
  --name scarletdme \
  -p 4242:4242 \
  -p 4243:4243 \
  scarletdme:latest
```

### With Volume Persistence

```bash
docker run -d \
  --name scarletdme \
  -p 4242:4242 \
  -p 4243:4243 \
  -v scarletdme-data:/usr/qmsys \
  scarletdme:latest
```

### With Custom Configuration

```bash
docker run -d \
  --name scarletdme \
  -p 4242:4242 \
  -p 4243:4243 \
  -v /path/to/scarlet.conf:/etc/scarlet.conf:ro \
  -v scarletdme-data:/usr/qmsys \
  scarletdme:latest
```

## Container Structure

### Exposed Ports

| Port | Service | Description |
|------|---------|-------------|
| 4242 | QMServer | Telnet-style connections |
| 4243 | QMClient | API connections |

### Volume Mounts

| Path | Purpose |
|------|---------|
| `/usr/qmsys` | Database files and programs |
| `/etc/scarlet.conf` | Configuration file |

### Environment Variables

The container supports the following environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `QMSYS` | `/usr/qmsys` | System directory |
| `LD_LIBRARY_PATH` | `/usr/qmsys/bin` | Library path |

## Docker Compose

### Basic docker-compose.yml

```yaml
version: '3.8'

services:
  scarletdme:
    build: .
    container_name: scarletdme
    ports:
      - "4242:4242"
      - "4243:4243"
    volumes:
      - scarletdme-data:/usr/qmsys
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "pgrep", "-x", "qmlnxd"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

volumes:
  scarletdme-data:
    driver: local
```

### With Configuration Override

```yaml
version: '3.8'

services:
  scarletdme:
    build: .
    container_name: scarletdme
    ports:
      - "4242:4242"
      - "4243:4243"
    volumes:
      - scarletdme-data:/usr/qmsys
      - ./config/scarlet.conf:/etc/scarlet.conf:ro
    restart: unless-stopped
    environment:
      - TZ=America/New_York
    healthcheck:
      test: ["CMD", "pgrep", "-x", "qmlnxd"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

volumes:
  scarletdme-data:
    driver: local
```

## Entrypoint Script

### docker-entrypoint.sh

The container uses `/usr/local/bin/docker-entrypoint.sh` to:

1. Initialize the system on first run
2. Start the qmlnxd daemon
3. Start inetd for network services
4. Keep the container running
5. Handle graceful shutdown

### Initialization Process

On first run, the entrypoint:
- Sets up security with `setup-security.sh`
- Configures file permissions
- Initializes system files
- Starts services

### Signal Handling

The entrypoint properly handles:
- SIGTERM: Graceful shutdown
- SIGINT: Interrupt and cleanup
- SIGQUIT: Quick termination

## Health Checks

### Container Health Check

```bash
docker inspect --format='{{.State.Health.Status}}' scarletdme
```

### Manual Health Verification

```bash
# Check daemon process
docker exec scarletdme pgrep -x qmlnxd

# Check ports
docker exec scarletdme netstat -ln | grep -E '4242|4243'

# Check shared memory
docker exec scarletdme ipcs -m
```

## Dockerfile Breakdown

### Stage 1: Builder

```dockerfile
FROM alpine:3.19 AS builder

# Install build dependencies
RUN apk add --no-cache \
    gcc \
    g++ \
    make \
    musl-dev \
    linux-headers

# Copy and build source
COPY . /usr/src/ScarletDME
WORKDIR /usr/src/ScarletDME
RUN make clean || true
RUN make
```

**Purpose:** Compile ScarletDME from source with all necessary build tools.

### Stage 2: Production

```dockerfile
FROM alpine:3.19

# Install runtime dependencies only
RUN apk add --no-cache \
    libstdc++ \
    bash \
    procps \
    shadow \
    busybox-extras

# Create users and groups
RUN addgroup -S qmusers && \
    adduser -S -G qmusers -h /usr/qmsys -s /bin/bash qmsys && \
    addgroup root qmusers

# Copy binaries from builder
COPY --from=builder /usr/src/ScarletDME/bin /tmp/scarlet-bin

# Install and configure
# ... (see Dockerfile for full details)
```

**Purpose:** Create minimal production image with only runtime dependencies.

## Networking

### Bridge Network (Default)

```bash
docker run -d \
  --name scarletdme \
  -p 4242:4242 \
  -p 4243:4243 \
  scarletdme:latest
```

### Custom Network

```bash
# Create network
docker network create scarletdme-net

# Run container
docker run -d \
  --name scarletdme \
  --network scarletdme-net \
  -p 4242:4242 \
  -p 4243:4243 \
  scarletdme:latest
```

### Connect Multiple Containers

```bash
# Run ScarletDME
docker run -d \
  --name scarletdme \
  --network scarletdme-net \
  scarletdme:latest

# Run application container
docker run -d \
  --name myapp \
  --network scarletdme-net \
  -e SCARLET_HOST=scarletdme \
  -e SCARLET_PORT=4243 \
  myapp:latest
```

## Data Persistence

### Named Volumes (Recommended)

```bash
# Create volume
docker volume create scarletdme-data

# Use volume
docker run -d \
  --name scarletdme \
  -v scarletdme-data:/usr/qmsys \
  scarletdme:latest
```

### Bind Mounts

```bash
# Create host directory
mkdir -p /var/scarletdme/data

# Use bind mount
docker run -d \
  --name scarletdme \
  -v /var/scarletdme/data:/usr/qmsys \
  scarletdme:latest
```

### Backup and Restore

```bash
# Backup volume
docker run --rm \
  -v scarletdme-data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/scarletdme-backup.tar.gz /data

# Restore volume
docker run --rm \
  -v scarletdme-data:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/scarletdme-backup.tar.gz -C /
```

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker logs scarletdme

# Check for errors
docker logs scarletdme 2>&1 | grep -i error

# Inspect container
docker inspect scarletdme
```

### Permission Issues

```bash
# Check file ownership
docker exec scarletdme ls -la /usr/qmsys

# Reset permissions
docker exec -u root scarletdme chown -R qmsys:qmusers /usr/qmsys
```

### Daemon Not Running

```bash
# Check process
docker exec scarletdme ps aux | grep qmlnxd

# Manually start daemon (debugging)
docker exec -u root scarletdme /usr/qmsys/bin/qmlnxd -start
```

### Network Issues

```bash
# Check port binding
docker port scarletdme

# Test connectivity
telnet localhost 4242
```

## Production Considerations

### Resource Limits

```bash
docker run -d \
  --name scarletdme \
  --memory="2g" \
  --memory-swap="2g" \
  --cpus="2.0" \
  scarletdme:latest
```

### Logging

```bash
# JSON file logging
docker run -d \
  --name scarletdme \
  --log-driver json-file \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  scarletdme:latest

# Syslog logging
docker run -d \
  --name scarletdme \
  --log-driver syslog \
  --log-opt syslog-address=udp://logserver:514 \
  scarletdme:latest
```

### Security

```bash
# Read-only root filesystem (where possible)
docker run -d \
  --name scarletdme \
  --read-only \
  --tmpfs /tmp \
  -v scarletdme-data:/usr/qmsys \
  scarletdme:latest

# Drop capabilities
docker run -d \
  --name scarletdme \
  --cap-drop=ALL \
  --cap-add=CHOWN \
  --cap-add=SETGID \
  --cap-add=SETUID \
  scarletdme:latest
```

## Next Steps

- [Kubernetes Deployment](04-kubernetes-deployment.md) - Deploy to Kubernetes
- [Configuration](09-configuration.md) - Configure ScarletDME
- [Monitoring](11-monitoring.md) - Monitor container health

