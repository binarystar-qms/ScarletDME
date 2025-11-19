# ScarletDME Dockerfile for Kubernetes Deployment
# Multi-stage build for optimized production image using Alpine Linux

# Build stage
FROM alpine:3.19 AS builder

# Install build dependencies
RUN apk add --no-cache \
    gcc \
    g++ \
    make \
    musl-dev \
    linux-headers

# Copy source code
COPY . /usr/src/ScarletDME

# Build ScarletDME (64-bit)
WORKDIR /usr/src/ScarletDME
RUN make clean || true
RUN make

# Production stage
FROM alpine:3.19

LABEL maintainer="ScarletDME Team"
LABEL description="ScarletDME Multi-Value Database Server"
LABEL version="1.0"

# Install runtime dependencies only
RUN apk add --no-cache \
    libstdc++ \
    bash \
    procps \
    shadow \
    busybox-extras

# Create qmusers group and qmsys user
RUN addgroup -S qmusers && \
    adduser -S -G qmusers -h /usr/qmsys -s /bin/bash qmsys && \
    addgroup root qmusers

# Create necessary directories
RUN mkdir -p /usr/qmsys /etc && \
    chown -R qmsys:qmusers /usr/qmsys

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

# Copy Docker entrypoint script and security setup script
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY setup-security.sh /usr/local/bin/setup-security.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/setup-security.sh

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

