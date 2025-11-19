# API Reference

## Overview

ScarletDME provides the QMClient API for external applications to connect and interact with the database. This document covers the C API and provides examples in multiple languages.

## QMClient C API

### Connection Management

#### QMConnect

Connect to a ScarletDME server.

```c
DLL int QMConnect(
    char* host,      // Hostname or IP address
    int port,        // Port number (typically 4243)
    char* username,  // Username
    char* password,  // Password
    char* account    // Account name
);
```

**Returns:** Session handle (>= 0) on success, negative on error

**Example:**

```c
#include "qmclient.h"

int session = QMConnect("localhost", 4243, "user", "password", "MYACCOUNT");
if (session < 0) {
    fprintf(stderr, "Connection failed: %d\n", session);
    return 1;
}
```

#### QMDisconnect

Disconnect from server.

```c
DLL void QMDisconnect(int session);
```

**Parameters:**
- `session` - Session handle from QMConnect

**Example:**

```c
QMDisconnect(session);
```

#### QMConnected

Check if connected.

```c
DLL int QMConnected(int session);
```

**Returns:** 1 if connected, 0 if not

### Command Execution

#### QMExecute

Execute a command.

```c
DLL char* QMExecute(int session, char* command);
```

**Parameters:**
- `session` - Session handle
- `command` - Command to execute

**Returns:** Command output or NULL on error

**Example:**

```c
char* result = QMExecute(session, "LIST VOC");
if (result) {
    printf("%s\n", result);
    QMFree(result);
}
```

#### QMCall

Call a cataloged subroutine.

```c
DLL char* QMCall(
    int session,
    char* subrname,   // Subroutine name
    int argc,         // Argument count
    char* argv[]      // Argument array
);
```

**Returns:** Result string or NULL

**Example:**

```c
char* args[] = {"ARG1", "ARG2"};
char* result = QMCall(session, "MYSUBR", 2, args);
if (result) {
    printf("Result: %s\n", result);
    QMFree(result);
}
```

### File Operations

#### QMOpen

Open a file.

```c
DLL int QMOpen(int session, char* filename);
```

**Returns:** File handle (>= 0) on success, negative on error

**Example:**

```c
int fh = QMOpen(session, "CUSTOMERS");
if (fh < 0) {
    fprintf(stderr, "Failed to open file\n");
}
```

#### QMClose

Close a file.

```c
DLL void QMClose(int session, int fh);
```

**Example:**

```c
QMClose(session, fh);
```

#### QMRead

Read a record.

```c
DLL char* QMRead(
    int session,
    int fh,        // File handle
    char* id       // Record ID
);
```

**Returns:** Record data or NULL if not found

**Example:**

```c
char* record = QMRead(session, fh, "CUST001");
if (record) {
    printf("Record: %s\n", record);
    QMFree(record);
} else {
    printf("Record not found\n");
}
```

#### QMReadl

Read a record with lock.

```c
DLL char* QMReadl(
    int session,
    int fh,
    char* id,
    int wait       // 1 = wait for lock, 0 = no wait
);
```

**Example:**

```c
char* record = QMReadl(session, fh, "CUST001", 1);
if (record) {
    // Modify record
    QMWrite(session, fh, "CUST001", modified_data);
    QMFree(record);
}
```

#### QMWrite

Write a record.

```c
DLL int QMWrite(
    int session,
    int fh,
    char* id,
    char* data
);
```

**Returns:** 0 on success, negative on error

**Example:**

```c
int status = QMWrite(session, fh, "CUST001", "John Doe\xFEj.doe@example.com");
if (status < 0) {
    fprintf(stderr, "Write failed\n");
}
```

#### QMWriteu

Write and unlock a record.

```c
DLL int QMWriteu(int session, int fh, char* id, char* data);
```

#### QMDelete

Delete a record.

```c
DLL int QMDelete(int session, int fh, char* id);
```

**Example:**

```c
int status = QMDelete(session, fh, "CUST001");
if (status == 0) {
    printf("Record deleted\n");
}
```

#### QMDeleteu

Delete and unlock a record.

```c
DLL int QMDeleteu(int session, int fh, char* id);
```

### Record Locking

#### QMRecordlock

Lock a record.

```c
DLL int QMRecordlock(
    int session,
    int fh,
    char* id,
    int wait       // 1 = wait, 0 = no wait
);
```

**Returns:** 0 on success, negative on error

#### QMRelease

Release a record lock.

```c
DLL int QMRelease(int session, int fh, char* id);
```

### Select Operations

#### QMSelect

Create a select list.

```c
DLL int QMSelect(int session, int fh, int listno);
```

**Parameters:**
- `listno` - Select list number (0-10)

**Returns:** Number of records selected

**Example:**

```c
int count = QMSelect(session, fh, 0);
printf("Selected %d records\n", count);
```

#### QMSelectIndex

Select using an index.

```c
DLL int QMSelectIndex(
    int session,
    int fh,
    char* indexname,
    char* indexvalue,
    int listno
);
```

#### QMReadNext

Read next ID from select list.

```c
DLL char* QMReadNext(int session, int listno);
```

**Returns:** Next record ID or NULL if end of list

**Example:**

```c
char* id;
while ((id = QMReadNext(session, 0)) != NULL) {
    char* record = QMRead(session, fh, id);
    // Process record
    QMFree(record);
    QMFree(id);
}
```

#### QMClearSelect

Clear a select list.

```c
DLL void QMClearSelect(int session, int listno);
```

### Data Manipulation

#### QMExtract

Extract a field from a record.

```c
DLL char* QMExtract(
    char* src,       // Source string
    int field,       // Field number
    int value,       // Value number (0 = all)
    int subvalue     // Subvalue number (0 = all)
);
```

**Example:**

```c
// Extract field 2
char* field2 = QMExtract(record, 2, 0, 0);
QMFree(field2);
```

#### QMReplace

Replace a field in a record.

```c
DLL char* QMReplace(
    char* src,
    int field,
    int value,
    int subvalue,
    char* new_data
);
```

#### QMIns

Insert a field into a record.

```c
DLL char* QMIns(
    char* src,
    int field,
    int value,
    int subvalue,
    char* new_data
);
```

#### QMDel

Delete a field from a record.

```c
DLL char* QMDel(
    char* src,
    int field,
    int value,
    int subvalue
);
```

### String Functions

#### QMChange

Change all occurrences of a substring.

```c
DLL char* QMChange(
    char* src,
    char* old_str,
    char* new_str,
    int occurrences,  // 0 = all
    int start         // Starting occurrence
);
```

#### QMDcount

Count delimiters.

```c
DLL int QMDcount(char* src, char* delimiter);
```

**Example:**

```c
// Count fields
int fields = QMDcount(record, "\xFE") + 1;
```

#### QMField

Extract field using delimiter.

```c
DLL char* QMField(
    char* src,
    char* delimiter,
    int occurrence,
    int count         // Number of fields to extract
);
```

### Error Handling

#### QMError

Get last error message.

```c
DLL char* QMError(int session);
```

**Example:**

```c
if (result < 0) {
    char* error = QMError(session);
    fprintf(stderr, "Error: %s\n", error);
    QMFree(error);
}
```

#### QMStatus

Get status code.

```c
DLL int QMStatus(int session);
```

### Memory Management

#### QMFree

Free memory allocated by API.

```c
DLL void QMFree(void* ptr);
```

**Important:** Always free strings returned by API functions.

## Multivalue Delimiters

| Delimiter | Hex | Decimal | Purpose |
|-----------|-----|---------|---------|
| Field Mark (FM) | 0xFE | 254 | Separate fields |
| Value Mark (VM) | 0xFD | 253 | Separate values |
| Subvalue Mark (SM) | 0xFC | 252 | Separate subvalues |

## Language Bindings

### Python

```python
import ctypes

# Load library
qmclient = ctypes.CDLL('/usr/qmsys/bin/libqmcli.so')

# Define return types
qmclient.QMConnect.restype = ctypes.c_int
qmclient.QMRead.restype = ctypes.c_char_p

# Connect
session = qmclient.QMConnect(
    b"localhost", 4243, b"user", b"password", b"ACCOUNT"
)

# Open file
fh = qmclient.QMOpen(session, b"CUSTOMERS")

# Read record
record = qmclient.QMRead(session, fh, b"CUST001")
print(record.decode('utf-8'))

# Close and disconnect
qmclient.QMClose(session, fh)
qmclient.QMDisconnect(session)
```

### Java

```java
import com.sun.jna.*;

public interface QMClient extends Library {
    QMClient INSTANCE = Native.load("qmcli", QMClient.class);
    
    int QMConnect(String host, int port, String user, 
                  String password, String account);
    void QMDisconnect(int session);
    int QMOpen(int session, String filename);
    String QMRead(int session, int fh, String id);
    int QMWrite(int session, int fh, String id, String data);
    void QMClose(int session, int fh);
    void QMFree(Pointer ptr);
}

// Usage
public class Example {
    public static void main(String[] args) {
        QMClient qm = QMClient.INSTANCE;
        
        int session = qm.QMConnect("localhost", 4243, 
                                   "user", "password", "ACCOUNT");
        int fh = qm.QMOpen(session, "CUSTOMERS");
        String record = qm.QMRead(session, fh, "CUST001");
        System.out.println(record);
        
        qm.QMClose(session, fh);
        qm.QMDisconnect(session);
    }
}
```

### PHP

```php
<?php
$qm = new QMClient("localhost", 4243, "user", "password", "ACCOUNT");

if ($qm->connect()) {
    $fh = $qm->open("CUSTOMERS");
    
    $record = $qm->read($fh, "CUST001");
    echo "Record: $record\n";
    
    $fields = explode("\xFE", $record);
    echo "Name: " . $fields[0] . "\n";
    echo "Email: " . $fields[1] . "\n";
    
    $qm->close($fh);
    $qm->disconnect();
}
?>
```

### Node.js

```javascript
const ffi = require('ffi-napi');
const ref = require('ref-napi');

const qmclient = ffi.Library('/usr/qmsys/bin/libqmcli.so', {
    'QMConnect': ['int', ['string', 'int', 'string', 'string', 'string']],
    'QMDisconnect': ['void', ['int']],
    'QMOpen': ['int', ['int', 'string']],
    'QMRead': ['string', ['int', 'int', 'string']],
    'QMWrite': ['int', ['int', 'int', 'string', 'string']],
    'QMClose': ['void', ['int', 'int']]
});

// Connect
const session = qmclient.QMConnect('localhost', 4243, 
                                   'user', 'password', 'ACCOUNT');

// Open and read
const fh = qmclient.QMOpen(session, 'CUSTOMERS');
const record = qmclient.QMRead(session, fh, 'CUST001');
console.log(record);

// Close
qmclient.QMClose(session, fh);
qmclient.QMDisconnect(session);
```

## Error Codes

| Code | Description |
|------|-------------|
| 0 | Success |
| -1 | Connection failed |
| -2 | Authentication failed |
| -3 | File not found |
| -4 | Record not found |
| -5 | Lock timeout |
| -6 | Invalid session |
| -7 | Invalid file handle |
| -8 | Permission denied |
| -9 | Disk full |
| -10 | Network error |

## Best Practices

### Connection Management

1. **Reuse connections**: Don't connect/disconnect frequently
2. **Connection pooling**: Use pools for multi-threaded apps
3. **Handle failures**: Always check return values
4. **Clean disconnect**: Always disconnect on exit

### Error Handling

1. **Check return values**: All functions can fail
2. **Get error messages**: Use QMError() for details
3. **Implement retry logic**: For transient errors
4. **Log errors**: For debugging and monitoring

### Performance

1. **Batch operations**: Group reads/writes when possible
2. **Use select lists**: More efficient than individual reads
3. **Lock minimally**: Release locks quickly
4. **Close files**: Don't keep unnecessary files open

### Security

1. **Secure credentials**: Never hardcode passwords
2. **Use SSL/TLS**: When available (via proxy)
3. **Validate input**: Prevent injection attacks
4. **Limit permissions**: Use least-privilege accounts

## Next Steps

- [Command Reference](13-command-reference.md) - QM commands
- [Development Guide](06-development-guide.md) - Develop with ScarletDME
- [Troubleshooting](14-troubleshooting.md) - API troubleshooting

