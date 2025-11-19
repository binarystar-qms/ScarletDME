#!/bin/bash
# Setup security by directly creating user in $LOGINS file

if [ -z "$SCARLET_USER" ] || [ -z "$SCARLET_PASSWORD" ]; then
    echo "No security credentials provided"
    exit 0
fi

# Enable security first
/usr/qmsys/bin/qm << 'EOF'
SECURITY ON
QUIT
EOF

echo "Security enabled"

# Create user using inline BASIC code
# We'll write a temporary program, compile it, run it, then delete it
USER_UPPER=$(echo "$SCARLET_USER" | tr '[:lower:]' '[:upper:]')

cat > /tmp/SETUP.USER.BASIC << BASICEOF
PROGRAM SETUP.USER
OPEN '\$LOGINS' TO F ELSE STOP
R = ''
R<1> = OCONV('$SCARLET_PASSWORD','MCP')
R<2> = 'QMSYS'
R<3> = 1
WRITE R TO F,'$USER_UPPER'
CLOSE F
CRT 'User created: $USER_UPPER'
STOP
BASICEOF

# Copy to BP, compile, and run
cp /tmp/SETUP.USER.BASIC /usr/qmsys/BP/SETUP.USER
chmod 664 /usr/qmsys/BP/SETUP.USER

/usr/qmsys/bin/qm << 'EOF2'
BASIC BP SETUP.USER
RUN BP SETUP.USER
QUIT
EOF2

# Cleanup
rm -f /tmp/SETUP.USER.BASIC
rm -f /usr/qmsys/BP/SETUP.USER
rm -f /usr/qmsys/BP.OUT/SETUP.USER

echo "Security setup complete: user $SCARLET_USER created"

