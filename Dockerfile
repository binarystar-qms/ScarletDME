# Build stage
FROM ubuntu:20.04 as builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    make \
    ncurses-dev \
    libncurses-dev \
    lib32z1 \
    lib32ncurses6 \
    libc6-dev-i386 \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy source code
WORKDIR /src
COPY . .

# Build ScarletDME
RUN make clean && make

# Runtime stage
FROM ubuntu:20.04

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ncurses-bin \
    libncurses6 \
    lib32z1 \
    libc6-i386 \
    libncurses5 \
    libgcc1:i386 \
    telnet \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create qmsys user and qmuser group
RUN groupadd -r qmuser && useradd -r -g qmuser qmsys

# Copy compiled binaries from builder
WORKDIR /usr/qmsys
COPY --from=builder --chown=qmsys:qmuser /src/qmserver ./bin/qmserver
COPY --from=builder --chown=qmsys:qmuser /src/qmclient ./bin/qmclient
COPY --from=builder --chown=qmsys:qmuser /src . .

# Create necessary directories
RUN mkdir -p /usr/qmsys/{lib,tmp,log,accounts} && \
    chown -R qmsys:qmuser /usr/qmsys && \
    chmod 755 /usr/qmsys/bin/*

# Initialize accounts
RUN mkdir -p /usr/qmsys/accounts/ACCOUNTS && \
    chown -R qmsys:qmuser /usr/qmsys/accounts

# Expose port
EXPOSE 4242

# Switch to qmsys user
USER qmsys

# Health check
HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=3 \
    CMD /usr/qmsys/bin/qmclient -h localhost -p 4242 QUIT || exit 1

# Start ScarletDME
ENTRYPOINT ["/usr/qmsys/bin/qmserver"]
CMD ["-p", "4242"]
