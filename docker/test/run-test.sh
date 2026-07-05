#!/bin/bash
# Test the full ScarletDME development workflow:
#   1. rsync a BASIC program into the container via SSH
#   2. Compile and catalogue it using qm from the command line
#
# Usage:
#   ./run-test.sh              # SSH port defaults to 2222
#   ./run-test.sh 2222         # explicit SSH port

set -e

CONTAINER="scarletdme-dev"
SSH_PORT="${1:-2222}"
QM_USER="qmsys"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== ScarletDME rsync + qm workflow test ==="
echo "Container : ${CONTAINER}"
echo "SSH port  : ${SSH_PORT}"
echo ""

# Verify the container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
    echo "Error: container '${CONTAINER}' is not running."
    echo "Start it with:  docker-compose up -d"
    echo "(from the ScarletDME directory)"
    exit 1
fi

# -----------------------------------------------------------------------
# Step 1: rsync HELLO.B into the container via SSH
# -----------------------------------------------------------------------
echo "[1/3] rsyncing HELLO.B into /usr/qmsys/BP/ ..."
rsync -avz \
    --progress \
    -e "ssh -p ${SSH_PORT} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" \
    "${SCRIPT_DIR}/HELLO.B" \
    "${QM_USER}@localhost:/usr/qmsys/BP/HELLO.B"
echo ""

# -----------------------------------------------------------------------
# Step 2: Verify the file landed in the container
# -----------------------------------------------------------------------
echo "[2/3] Verifying file exists in container..."
docker exec "${CONTAINER}" ls -lh /usr/qmsys/BP/HELLO.B
echo ""

# -----------------------------------------------------------------------
# Step 3: Use qm to compile (BASIC) and catalogue the program
#
# Commands piped into qm:
#   BASIC BP HELLO.B          - compile the BASIC source
#   CATALOG BP HELLO.B LOCAL  - catalogue it locally in QMSYS
#   HELLO.B                   - run it to confirm it works
#   QUIT                      - exit qm
# -----------------------------------------------------------------------
echo "[3/3] Compiling and cataloguing via qm..."
echo ""
docker exec -i "${CONTAINER}" \
    su -c "cd /usr/qmsys && /usr/qmsys/bin/qm" qmsys <<'QMEOF'
BASIC BP HELLO.B
CATALOG BP HELLO.B LOCAL
HELLO.B
QUIT
QMEOF

echo ""
echo "=== Test complete ==="
