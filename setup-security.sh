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

# Create user using a simple BASIC program passed as input
USER_UPPER=$(echo "$SCARLET_USER" | tr '[:lower:]' '[:upper:]')

/usr/qmsys/bin/qm << EOF
* Create user in \$LOGINS
OPEN '\$LOGINS' TO F ELSE STOP
R = ''
R<1> = OCONV('$SCARLET_PASSWORD','MCP')
R<2> = 'QMSYS'
R<3> = 1
WRITE R TO F,'$USER_UPPER'
CLOSE F
CRT 'User created: $USER_UPPER'
QUIT
EOF

echo "Security setup complete: user $SCARLET_USER created"

