#!/bin/bash
# Low-overhead Docker entrypoint for ScarletDME
# Starts inetd for network services, the daemon, and monitors them

set -e

# Start inetd for network services (QMServer on 4242, QMClient on 4243)
echo "Starting inetd for network services..."
if command -v inetd > /dev/null; then
    inetd /etc/inetd.conf
    sleep 1
    if pgrep -x inetd > /dev/null; then
        echo "inetd started successfully"
    else
        echo "WARNING: inetd failed to start"
    fi
else
    echo "ERROR: inetd not found in system"
    exit 1
fi

echo "Starting ScarletDME..."
/usr/qmsys/bin/qm -start

# Configure security if environment variables are set
if [ -n "$SCARLET_USER" ] && [ -n "$SCARLET_PASSWORD" ]; then
    echo "Configuring security with user: $SCARLET_USER"
    sleep 3  # Wait for ScarletDME to fully initialize
    
    # Run the security setup script
    /usr/local/bin/setup-security.sh
fi

# Wait a moment for the daemon to initialize
sleep 2

# Check if qmlnxd daemon is running
if ! pgrep -x qmlnxd > /dev/null; then
    echo "ERROR: ScarletDME daemon (qmlnxd) failed to start"
    exit 1
fi

# Check if inetd is running
if ! pgrep -x inetd > /dev/null; then
    echo "WARNING: inetd is not running - network services may not be available"
fi

echo "ScarletDME is running. Monitoring daemon..."

# Monitor the qmlnxd daemon process - this is very low overhead
# Just checks every 5 seconds if the daemon is still alive
while pgrep -x qmlnxd > /dev/null; do
    sleep 5
done

echo "ScarletDME daemon has stopped"
exit 0

