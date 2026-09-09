#!/bin/bash
set -e

echo "==================================="
echo "  ScarletDME Development Container"
echo "==================================="
echo ""

# When a named volume mounts over /usr/qmsys, Docker only copies image data
# into it on first creation.  If the volume was pre-existing (e.g. from a
# previous build) but empty, we need to restore the data files from the
# source tree that was copied in at build time under /usr/src/ScarletDME.
if [ ! -f /usr/qmsys/bin/qm ]; then
    echo "[0/3] Restoring data files into volume..."
    cd /usr/src/ScarletDME
    make install datafiles
    echo "      Data files restored."
    echo ""
fi

# Start SSH daemon so rsync can reach the container
echo "[1/3] Starting SSH daemon..."
/usr/sbin/sshd
echo "      SSH ready on port 22"
echo "      User: qmsys  Password: qmsys"
echo "      rsync example:"
echo "        rsync -avz -e 'ssh -p 2222' ./BP/ qmsys@localhost:/usr/qmsys/BP/"
echo ""

# qm -start requires euid 0 (root) to initialise the system monitor.
# The entrypoint runs as root, so no su wrapper needed here.
echo "[2/3] Starting ScarletDME..."
cd /usr/qmsys
/usr/qmsys/bin/qm -start
echo "      QM system monitor/IPC initialised"
echo ""

# qm -start only brings up QM's internal monitor -- it does not itself
# listen on any port. xinetd is the actual network listener that spawns a
# `qm` process per incoming connection on 4242 (qmserver, telnet-style
# sessions) and 4243 (qmclient, the native QMClient wire protocol).
echo "[3/3] Starting xinetd (qmserver:4242, qmclient:4243)..."
/usr/sbin/xinetd -f /etc/xinetd.conf
echo "      xinetd ready"
echo ""
echo "Connect options:"
echo "  telnet (qmserver):  telnet localhost 4242"
echo "  QMClient (qmclient): port 4243"
echo "  docker exec:        docker exec -it <container> su -c '/usr/qmsys/bin/qm' qmsys"
echo ""
echo "==================================="

# Keep the container alive
exec tail -f /dev/null
