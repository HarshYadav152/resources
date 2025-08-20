# kill-port.sh Documentation

## Overview

kill-port.sh is a versatile command-line utility for Unix-like systems (Linux, macOS) designed to identify and terminate processes running on specific TCP ports. This powerful tool helps system administrators and developers quickly free up ports when applications fail to release them properly.

## Features

- **Automatic Process Detection**: Identifies all processes binding to specified TCP ports
- **Multi-Port Support**: Can process single or multiple ports in one command
- **List-Only Mode**: View processes without terminating them
- **Force Termination**: Option to force kill stubborn processes using SIGKILL
- **IPv6 Support**: Option to include IPv6 connections in detection
- **Multiple Output Formats**: Text (colored), JSON, and CSV output formats
- **Batch Processing**: Ability to read ports from a file
- **Cross-Platform**: Works on both Linux and macOS with automatic OS detection
- **Verbose Mode**: Detailed information about commands being executed

## Requirements

- Bash shell environment
- On Linux: Either `ss` command (from `iproute2` package) or `netstat` command (from `net-tools`)
- On macOS: `lsof` command
- Root/sudo privileges required for killing processes (not needed for list-only mode)
- `ps` command for process details

## Usage

```bash
./kill-port.sh [options] <port(s)>
```

### Command Line Options

| Option | Long Form | Description |
|--------|-----------|-------------|
| `-f` | `--force` | Force kill the process using SIGKILL (signal 9) instead of SIGTERM (signal 15) |
| `-l` | `--list` | List processes without killing them |
| `-v` | `--verbose` | Show detailed information and commands being executed |
| `-h` | `--help` | Show help message |
| `-6` | `--ipv6` | Include IPv6 connections in search results |
| `-j` | `--json` | Output results in JSON format |
| `-c` | `--csv` | Output results in CSV format |
| `-p` | `--port-file` | Read ports from specified file (one port per line) |

### Examples

```bash
# Kill process on port 3000
./kill-port.sh 3000

# Kill processes on multiple ports
./kill-port.sh 3000 8080 5000

# List process using port 3000 without killing it
./kill-port.sh -l 3000

# Force kill process on port 3000 using SIGKILL
./kill-port.sh -f 3000

# Kill processes listed in a file
./kill-port.sh -p ports.txt

# Include IPv6 connections
./kill-port.sh -6 3000

# Output results in JSON format
./kill-port.sh -j 3000

# Verbose mode showing command execution
./kill-port.sh -v 3000
```

## Technical Implementation

### Process Detection Methods

The script automatically detects the operating system and uses the appropriate command:

#### On Linux:
- Primary method: Uses `ss` command (`iproute2` package)
  ```bash
  ss -tuln | grep :PORT
  ```
- Fallback method: Uses `netstat` command (`net-tools` package)
  ```bash
  netstat -tuln | grep :PORT
  ```

#### On macOS:
- Uses `lsof` command to find processes
  ```bash
  lsof -i :PORT -sTCP:LISTEN -t
  ```

### Process Termination Workflow

1. **Detection**: Identifies all processes binding to the specified port(s)
2. **Process Information**: Retrieves process name and details
3. **Termination**:
   - In list-only mode: Displays process information without killing
   - In normal mode: Sends SIGTERM (signal 15) for graceful termination
   - In force mode: Sends SIGKILL (signal 9) for immediate termination
4. **Verification**: Checks if process was successfully terminated
5. **Reporting**: Displays results in the selected output format

### Error Handling

- Validates port numbers (must be between 1-65535)
- Checks for required system commands before execution
- Verifies root/sudo privileges when needed
- Detects and reports when processes cannot be terminated
- Provides appropriate exit codes for scripting integration

## Output Formats

### Text Output (Default)

Human-readable, color-coded output showing:
- Port status (in use, not in use, terminated)
- Process name and PID
- Action taken and result

### JSON Output

```json
[
  {"port":3000,"status":"In use","action":"Kill","process_name":"node","pid":"1234","result":"terminated successfully"},
  {"port":8080,"status":"Not in use","action":"None","process_name":"","pid":"","result":"No action needed"}
]
```

### CSV Output

```
"Port","Status","Action","ProcessName","PID","Result"
"3000","In use","Kill","node","1234","terminated successfully"
"8080","Not in use","None","","","No action needed"
```

## Use Cases

### Development Environment
- Killing stuck development servers
- Freeing ports for testing
- Quickly restarting services on the same port

### System Administration
- Auditing port usage on servers
- Cleaning up orphaned processes
- Preparing ports for new service deployment

### Troubleshooting
- Identifying processes causing "Address already in use" errors
- Finding applications listening on unexpected ports
- Resolving port conflicts between applications

## Advanced Usage

### Running in Automated Scripts

```bash
# Kill process and capture exit code to determine success
./kill-port.sh 3000
if [ $? -eq 0 ]; then
  echo "Port successfully freed"
else
  echo "Failed to free port"
fi

# Use JSON output for parsing in scripts
RESULT=$(./kill-port.sh -j 3000)
echo $RESULT | jq '.[] | select(.port == 3000).status'
```

### Using with Port Ranges

```bash
# Create a file with a range of ports
for port in $(seq 3000 3010); do
  echo $port >> ports.txt
done

# Process all ports in the file
./kill-port.sh -p ports.txt
```

## Troubleshooting

### Common Issues

1. **"Permission denied" errors**
   - Solution: Run with sudo or as root when not using list-only mode
   ```bash
   sudo ./kill-port.sh 3000
   ```

2. **Process not terminating**
   - Solution: Use force mode to send SIGKILL
   ```bash
   ./kill-port.sh -f 3000
   ```

3. **Process detection issues**
   - Solution: Use verbose mode to see commands being executed
   ```bash
   ./kill-port.sh -v 3000
   ```

4. **Missing tools**
   - Solution: Install required packages
   ```bash
   # On Debian/Ubuntu
   sudo apt install net-tools iproute2
   
   # On CentOS/RHEL
   sudo yum install net-tools iproute
   
   # On macOS
   brew install lsof
   ```

## License and Attribution

- **Author**: Harsh Yadav
- **Version**: 1.0
- **Last Updated**: 2025-08-14
- **License**: Open source for personal and commercial use

---

This documentation provides a comprehensive overview of the kill-port.sh utility, its capabilities, and technical implementation. The script is designed to be robust, cross-platform, and flexible for various use cases in development and system administration environments.
