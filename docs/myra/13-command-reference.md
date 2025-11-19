# Command Reference

## Overview

This document provides a comprehensive reference for ScarletDME commands available at the QM prompt and via command execution.

## Command Syntax

### General Format

```
COMMAND [parameters] [options]
```

### Options Format

```
(option)           # Boolean option
option value       # Option with value
```

## File Management Commands

### CREATE-FILE

Create a new dynamic file.

**Syntax:**
```
CREATE-FILE filename [type] [modulo] [separation]
```

**Parameters:**
- `filename` - Name of file to create
- `type` - File type (DYNAMIC, DIR, SEQ)
- `modulo` - Modulo (number of groups)
- `separation` - Minimum separation

**Examples:**
```
CREATE-FILE CUSTOMERS
CREATE-FILE ORDERS DYNAMIC 1
CREATE-FILE TEMP DIR
```

### DELETE-FILE

Delete a file.

**Syntax:**
```
DELETE-FILE filename
```

**Example:**
```
DELETE-FILE OLDDATA
```

### CLEAR-FILE

Clear all records from a file.

**Syntax:**
```
CLEAR-FILE filename
```

**Example:**
```
CLEAR-FILE TEMP
```

### COPY-FILE

Copy all records from one file to another.

**Syntax:**
```
COPY-FILE from.file TO to.file [OVERWRITING]
```

**Example:**
```
COPY-FILE CUSTOMERS TO CUSTOMERS.BACKUP
```

### RESIZE

Resize a dynamic file.

**Syntax:**
```
RESIZE filename [new.modulo]
```

**Example:**
```
RESIZE CUSTOMERS 101
```

## Record Management Commands

### COPY

Copy a record.

**Syntax:**
```
COPY FROM filename id1 TO filename id2
```

**Example:**
```
COPY FROM CUSTOMERS CUST001 TO CUSTOMERS CUST999
```

### DELETE

Delete a record.

**Syntax:**
```
DELETE filename id
```

**Example:**
```
DELETE CUSTOMERS CUST001
```

### COUNT

Count records in a file.

**Syntax:**
```
COUNT filename [LIKE pattern]
```

**Examples:**
```
COUNT CUSTOMERS
COUNT CUSTOMERS LIKE "CUST*"
```

## Query and Reporting Commands

### LIST

List records from a file.

**Syntax:**
```
LIST filename [fields] [selection] [sorting] [options]
```

**Examples:**
```
LIST CUSTOMERS
LIST CUSTOMERS NAME PHONE
LIST CUSTOMERS WITH STATE = "CA"
LIST CUSTOMERS BY NAME
LIST CUSTOMERS NAME PHONE BY NAME HDR-SUPP
```

**Selection Criteria:**
```
WITH field = value
WITH field > value
WITH field LIKE "pattern"
WITH field MATCHING "pattern"
```

**Sorting:**
```
BY field           # Ascending
BY-DSND field      # Descending
BY field BY field2 # Multiple sort
```

**Common Options:**
```
HDR-SUPP          # Suppress header
COL-HDR-SUPP      # Suppress column headers
ID-SUPP           # Suppress ID column
LPTR              # Output to printer
NOPAGE            # Suppress pagination
```

### SORT

Sort and list records.

**Syntax:**
```
SORT filename [fields] [BY fields] [selection]
```

**Example:**
```
SORT CUSTOMERS NAME BY STATE BY NAME
```

### SELECT

Create a select list.

**Syntax:**
```
SELECT filename [selection] [TO list.number]
```

**Examples:**
```
SELECT CUSTOMERS
SELECT CUSTOMERS WITH STATE = "CA"
SELECT CUSTOMERS TO 1
```

### SSELECT

Sorted select.

**Syntax:**
```
SSELECT filename [BY fields] [selection]
```

**Example:**
```
SSELECT CUSTOMERS BY NAME
```

### GET-LIST

Retrieve a saved select list.

**Syntax:**
```
GET-LIST listname
```

### SAVE-LIST

Save current select list.

**Syntax:**
```
SAVE-LIST listname
```

### DELETE-LIST

Delete a saved select list.

**Syntax:**
```
DELETE-LIST listname
```

## File Editing Commands

### ED

Edit a record.

**Syntax:**
```
ED filename [id]
```

**Examples:**
```
ED BP MYPROG
ED CUSTOMERS CUST001
```

**Editor Commands:**
```
I              # Insert mode
R              # Replace line
D              # Delete line
L              # List
T              # Top
B              # Bottom
FI             # File (save)
EX             # Exit
```

### AE

Alternative editor (full-screen).

**Syntax:**
```
AE filename id
```

## Programming Commands

### BASIC

Compile a BASIC program.

**Syntax:**
```
BASIC filename program [options]
```

**Examples:**
```
BASIC BP MYPROG
BASIC BP MYPROG (L)       # With listing
BASIC BP MYPROG (XL)      # Cross-reference
```

**Options:**
```
(L)           # Listing
(X)           # Cross-reference
(XL)          # Both
(D)           # Debug mode
```

### CATALOG

Catalog a compiled program.

**Syntax:**
```
CATALOG filename program [LOCAL]
```

**Examples:**
```
CATALOG BP MYPROG
CATALOG BP MYPROG LOCAL
```

### RUN

Run a program.

**Syntax:**
```
RUN filename program
```

**Example:**
```
RUN BP MYPROG
```

### EXECUTE

Execute a command or program.

**Syntax:**
```
EXECUTE command
```

**Example:**
```
EXECUTE "LIST CUSTOMERS"
```

### DEBUG

Debug a program.

**Syntax:**
```
DEBUG filename program
```

**Debugger Commands:**
```
S              # Step
C              # Continue
B line         # Set breakpoint
D line         # Delete breakpoint
L              # List
P var          # Print variable
Q              # Quit
```

## Index Commands

### CREATE-INDEX

Create an index on a file.

**Syntax:**
```
CREATE-INDEX filename field.name [options]
```

**Examples:**
```
CREATE-INDEX CUSTOMERS NAME
CREATE-INDEX CUSTOMERS PHONE UNIQUE
```

**Options:**
```
UNIQUE         # Unique index
NULL           # Allow null values
RIGHT          # Right-justified
```

### DELETE-INDEX

Delete an index.

**Syntax:**
```
DELETE-INDEX filename field.name
```

### BUILD-INDEX

Build or rebuild an index.

**Syntax:**
```
BUILD-INDEX filename field.name
```

### LIST-INDEX

List indexes on a file.

**Syntax:**
```
LIST-INDEX filename
```

## Account Management Commands

### CREATE-ACCOUNT

Create a new account.

**Syntax:**
```
CREATE-ACCOUNT accountname path
```

**Example:**
```
CREATE-ACCOUNT MYACCOUNT /usr/qmsys/accounts/myaccount
```

### DELETE-ACCOUNT

Delete an account.

**Syntax:**
```
DELETE-ACCOUNT accountname
```

### LIST-ACCOUNTS

List all accounts.

**Syntax:**
```
LIST-ACCOUNTS
```

### LOGTO

Log into a different account.

**Syntax:**
```
LOGTO accountname
```

**Example:**
```
LOGTO PRODUCTION
```

## System Commands

### WHO

List connected users.

**Syntax:**
```
WHO
```

### LIST-USERS

List all users.

**Syntax:**
```
LIST-USERS
```

### LISTF

List files in account.

**Syntax:**
```
LISTF
```

### FILE-STAT

Display file statistics.

**Syntax:**
```
FILE-STAT filename
```

**Example:**
```
FILE-STAT CUSTOMERS
```

### ANALYZE-FILE

Analyze file structure.

**Syntax:**
```
ANALYZE-FILE filename
```

### SET-FILE

Set file parameters.

**Syntax:**
```
SET-FILE filename parameter value
```

**Examples:**
```
SET-FILE CUSTOMERS SPLIT.LOAD 80
SET-FILE CUSTOMERS BIG.REC.SIZE 4096
```

## Utility Commands

### TERM

Set terminal type.

**Syntax:**
```
TERM termtype
```

**Example:**
```
TERM vt100
```

### TIME

Display current time.

**Syntax:**
```
TIME
```

### DATE

Display current date.

**Syntax:**
```
DATE
```

### SH

Execute shell command.

**Syntax:**
```
SH command
```

**Example:**
```
SH ls -la
```

### !

Alias for SH.

**Syntax:**
```
! command
```

### HELP

Display help information.

**Syntax:**
```
HELP [topic]
```

### ?

Display last error.

**Syntax:**
```
?
```

## Configuration Commands

### SET-DEVICE

Set print device.

**Syntax:**
```
SET-DEVICE device
```

### OPTION

Set runtime option.

**Syntax:**
```
OPTION option [value]
```

**Examples:**
```
OPTION CASE INVERT
OPTION BREAK ON
```

## Lock Management Commands

### LIST-LOCKS

List active locks.

**Syntax:**
```
LIST-LOCKS
```

### CLEAR-LOCKS

Clear locks for a user.

**Syntax:**
```
CLEAR-LOCKS [username]
```

### SET-LOCK

Set file lock.

**Syntax:**
```
SET-LOCK filename
```

## Transaction Commands

### BEGIN-TRANSACTION

Start a transaction.

**Syntax:**
```
BEGIN-TRANSACTION
```

### COMMIT-TRANSACTION

Commit transaction.

**Syntax:**
```
COMMIT-TRANSACTION
```

### ROLLBACK-TRANSACTION

Rollback transaction.

**Syntax:**
```
ROLLBACK-TRANSACTION
```

## Conversion Commands

### ICONV

Input conversion.

**Syntax:**
```
ICONV value format
```

**Example:**
```
ICONV "12/31/2024" D2/
```

### OCONV

Output conversion.

**Syntax:**
```
OCONV value format
```

**Example:**
```
OCONV 19723 D2/
```

**Common Conversions:**
```
D2/            # Date (MM/DD/YYYY)
D4/            # Date (DD/MM/YYYY)
MT             # Time (HH:MM)
MTS            # Time (HH:MM:SS)
MD2            # Decimal (2 places)
ML             # Lowercase
MU             # Uppercase
T              # Text
G1*1           # Group extraction
```

## Output Control Commands

### PRINTER ON

Enable printer output.

**Syntax:**
```
PRINTER ON
```

### PRINTER OFF

Disable printer output.

**Syntax:**
```
PRINTER OFF
```

### PRINTER CLOSE

Close printer.

**Syntax:**
```
PRINTER CLOSE
```

## System Administration Commands

### START-DAEMON

Start qmlnxd daemon.

**Syntax:**
```
qm -start
```

### STOP-DAEMON

Stop qmlnxd daemon.

**Syntax:**
```
qm -stop
```

### REBUILD-FILE

Rebuild a corrupted file.

**Syntax:**
```
qmfix filename
```

### VERIFY-FILE

Verify file integrity.

**Syntax:**
```
qmfix -v filename
```

## Command-Line Options

### QM Command-Line

```bash
# Interactive mode
qm [account]

# Execute command
qm -c "command"

# Start daemon
qm -start

# Stop daemon
qm -stop

# Show version
qm -v

# Help
qm -help
```

## Environment Variables

### QMSYS

System directory.

```bash
export QMSYS=/usr/qmsys
```

### QMTERM

Terminal type override.

```bash
export QMTERM=vt100
```

### QMACCOUNT

Default account.

```bash
export QMACCOUNT=MYACCOUNT
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | File not found |
| 3 | Permission denied |
| 4 | Syntax error |
| 5 | Runtime error |

## Special Characters

| Character | Purpose |
|-----------|---------|
| * | Wildcard in patterns |
| ? | Single character wildcard |
| @ | System variable prefix |
| $ | System file prefix |
| ! | Shell escape |
| > | Output redirect |
| < | Input redirect |
| \| | Pipe |

## System Variables

### @ACCOUNT

Current account name.

### @DATE

Current internal date.

### @TIME

Current internal time.

### @LOGNAME

Current user name.

### @USERNO

Current user number.

### @STATION

Station/terminal ID.

### @WHO

User information.

## Tips and Tricks

### Command History

```
# Previous command
!!

# Command history
HISTORY
```

### Command Aliases

```
# Create alias in VOC
EDIT VOC LL
I V
I LS -LA
FI
```

### Piping Commands

```
LIST CUSTOMERS | SORT
SELECT CUSTOMERS | COUNT
```

### Output Redirection

```
LIST CUSTOMERS > REPORT.TXT
LIST CUSTOMERS >> REPORT.TXT
```

## Next Steps

- [API Reference](12-api-reference.md) - Programming API
- [Development Guide](06-development-guide.md) - BASIC programming
- [Troubleshooting](14-troubleshooting.md) - Command errors

