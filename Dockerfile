# ScarletDME Dockerfile for Kubernetes Deployment
# Multi-stage build for optimized production image using Debian Slim

# Build stage
FROM debian:bookworm-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    make \
    libc6-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy source code
COPY . /usr/src/ScarletDME

# Build ScarletDME (64-bit)
WORKDIR /usr/src/ScarletDME
RUN make clean || true
RUN make

# Production stage
FROM debian:bookworm-slim

LABEL maintainer="ScarletDME Team"
LABEL description="ScarletDME Multi-Value Database Server"
LABEL version="1.0"

# Install runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    libstdc++6 \
    bash \
    procps \
    passwd \
    libpam-modules \
    libpam-runtime \
    openbsd-inetd \
    && rm -rf /var/lib/apt/lists/*

# Create qmusers group and qmsys user
RUN groupadd --system qmusers && \
    useradd --system --gid qmusers --home-dir /usr/qmsys --shell /bin/bash qmsys && \
    usermod -aG qmusers root

# Note: Running without security - no user accounts needed
# Users can connect directly to accounts without authentication

# Create necessary directories
# /run/secrets and /var/run/secrets are needed for Kubernetes service account token mounting
# Ensure /var/run is a symlink to /run (standard on Debian)
RUN mkdir -p /usr/qmsys /etc /run/secrets/kubernetes.io/serviceaccount && \
    chown -R qmsys:qmusers /usr/qmsys && \
    chmod 755 /run /run/secrets /run/secrets/kubernetes.io /run/secrets/kubernetes.io/serviceaccount && \
    rm -rf /var/run && ln -s /run /var/run

# Copy configuration files
COPY scarlet.conf /etc/scarlet.conf
COPY docker-inetd.conf /etc/inetd.conf
RUN chown qmsys:qmusers /etc/scarlet.conf && \
    chmod 644 /etc/scarlet.conf && \
    chmod 644 /etc/inetd.conf

# Copy built binaries from builder stage
COPY --from=builder /usr/src/ScarletDME/bin /tmp/scarlet-bin

# Copy pcode file from source (it's a pre-built static file)
COPY bin/pcode /tmp/pcode-file

# Copy Docker entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Copy source for installation
COPY --from=builder /usr/src/ScarletDME/qmsys /tmp/qmsys
COPY --from=builder /usr/src/ScarletDME/Makefile /tmp/Makefile
COPY --from=builder /usr/src/ScarletDME/terminfo.src /tmp/terminfo.src

# Install ScarletDME
WORKDIR /tmp
RUN mkdir -p /usr/qmsys/bin && \
    cp /tmp/scarlet-bin/* /usr/qmsys/bin/ && \
    cp /tmp/pcode-file /usr/qmsys/bin/pcode && \
    chmod 755 /usr/qmsys/bin/* && \
    chmod 644 /usr/qmsys/bin/pcode && \
    chown -R qmsys:qmusers /usr/qmsys/bin

# Compile terminfo
RUN mkdir -p /usr/qmsys/terminfo && \
    cd /usr/qmsys && \
    /usr/qmsys/bin/qmtic -pterminfo /tmp/terminfo.src

# Copy data files
RUN cp -R /tmp/qmsys/* /usr/qmsys/ && \
    chown -R qmsys:qmusers /usr/qmsys && \
    find /usr/qmsys -type f -exec chmod 664 {} \; && \
    find /usr/qmsys -type d -exec chmod 775 {} \; && \
    chmod 755 /usr/qmsys/bin/*

# Create symbolic link
RUN ln -sf /usr/qmsys/bin/qm /usr/bin/qm

# Clean up
RUN rm -rf /tmp/scarlet-bin /tmp/pcode-file /tmp/qmsys /tmp/Makefile /tmp/terminfo.src

# Expose API ports
# Port 4242: QMServer (telnet connections)
# Port 4243: QMClient (API connections)
EXPOSE 4242 4243

# Set working directory
WORKDIR /usr/qmsys

# Health check - verify qmlnxd daemon is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD pgrep -x qmlnxd > /dev/null || exit 1

# Start ScarletDME using the entrypoint script
# This keeps the container running while monitoring the daemon
USER root
CMD ["/usr/local/bin/docker-entrypoint.sh"]

