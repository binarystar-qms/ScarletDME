PROGRAM REGISTER.USER
* Register a user in $LOGINS (password is handled by Linux PAM)
* Takes username as argument
* Field 1: Last account name
* Field 6: Administrator flag (1=admin, 0=user)
OPEN '$LOGINS' TO F ELSE STOP 201
R = ''
R<1> = 'QMSYS'
R<6> = 1
WRITE R TO F,@SENTENCE<2>
CLOSE F
STOP

