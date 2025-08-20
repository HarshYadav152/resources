# kill-port.ps1 Documentation

## Overview

kill-port.ps1 is a powerful PowerShell utility designed to identify and terminate processes that are listening on specific TCP ports in Windows environments. This tool helps developers, system administrators, and IT professionals quickly free up ports when applications fail to release them properly during development, testing, or troubleshooting.

## Features

- **Process Detection**: Automatically identifies processes binding to specified TCP ports
- **Multi-Port Support**: Process single or multiple ports in one command
- **List-Only Mode**: View processes without terminating them
- **Force Termination**: Option to force kill stubborn processes
- **IPv6 Support**: Option to include IPv6 connections in detection
- **Multiple Output Formats**: Text (colored), JSON, and CSV output
- **Port File Support**: Read ports from a file for batch processing
- **Detailed Output**: Comprehensive information about processes and actions taken
- **Verbose Mode**: Shows detailed commands being executed behind the scenes

## Requirements

- Windows PowerShell 3.0 or newer
- Windows 8/Server 2012 or newer for `Get-NetTCPConnection` cmdlet
- Administrator privileges required for killing processes (not needed for list-only mode)

## Usage

```powershell
.\kill-port.ps1 [-Port <port1,port2,...>] [-Force] [-ListOnly] [-ShowCommands] [-IncludeIPv6] [-PortFile <file>] [-OutputFormat <Text|JSON|CSV>]
```

### Parameters

| Parameter | Description |
|-----------|-------------|
| `-Port` | One or more port numbers to check and kill processes on. Default: 3000 |
| `-Force` | Force kill the process (more aggressive termination) |
| `-ListOnly` | List processes without killing them |
| `-ShowCommands` | Show detailed information about commands being executed |
| `-IncludeIPv6` | Include IPv6 connections in search results |
| `-PortFile` | Path to a file containing port numbers (one per line) |
| `-OutputFormat` | Format for output: 'Text' (default), 'JSON', or 'CSV' |

### Examples

```powershell
# Kill process on port 3000
.\kill-port.ps1 3000

# Kill processes on multiple ports
.\kill-port.ps1 3000,8080,5000

# List process using port 3000 without killing it
.\kill-port.ps1 -Port 3000 -ListOnly

# Force kill process on port 3000
.\kill-port.ps1 -Port 3000 -Force

# Kill processes listed in a file
.\kill-port.ps1 -PortFile "ports.txt"

# Output results in JSON format
.\kill-port.ps1 -Port 3000 -OutputFormat JSON

# Show commands being executed
.\kill-port.ps1 -Port 3000 -ShowCommands
```

## Technical Implementation

### Process Detection

The script uses the PowerShell `Get-NetTCPConnection` cmdlet to identify processes:

```powershell
Get-NetTCPConnection -LocalPort $PortNumber -State Listen
```

This returns connection information including the owning process ID (PID).

### Process Termination Workflow

1. **Validation**: Checks that port numbers are valid (1-65535)
2. **Privilege Check**: Ensures administrator privileges when not in list-only mode
3. **Detection**: Identifies all processes binding to the specified port(s)
4. **Information Gathering**: Retrieves process name and details using `Get-Process`
5. **Termination**:
   - In list-only mode: Displays process information without killing
   - In normal mode: Uses `Stop-Process` for graceful termination
   - In force mode: Uses `Stop-Process -Force` for more aggressive termination
6. **Verification**: Checks if process was successfully terminated after a brief delay
7. **Reporting**: Displays results in the selected output format

### Error Handling

- Validates port numbers
- Checks for administrator privileges
- Handles cases where processes cannot be found or terminated
- Provides descriptive error messages
- Returns appropriate exit codes for scripting integration

## Output Formats

### Text Output (Default)

Human-readable, color-coded console output showing:
- Port status (in use, not in use)
- Process name and PID
- Action taken and result

### JSON Output

```json
[
  {
    "Port": 3000,
    "Status": "Was in use",
    "Action": "Kill",
    "ProcessName": "node",
    "PID": "1234",
    "Result": "Process terminated"
  },
  {
    "Port": 8080,
    "Status": "Not in use",
    "Action": "None",
    "ProcessName": "",
    "PID": "",
    "Result": "No action needed"
  }
]
```

### CSV Output

```
"Port","Status","Action","ProcessName","PID","Result"
"3000","Was in use","Kill","node","1234","Process terminated"
"8080","Not in use","None","","","No action needed"
```

## Use Cases

### Development Workflows
- Clearing ports between application restarts
- Freeing ports locked by crashed development servers
- Resolving the common "port already in use" error in web development

### System Administration
- Auditing port usage on Windows servers
- Freeing ports during deployment procedures
- Troubleshooting network service issues

### DevOps and Testing
- Ensuring clean environments between test runs
- Automating port cleanup in CI/CD pipelines
- Scripted port management in test suites

## Advanced Usage

### Integration with Task Scheduler

```powershell
# Create a scheduled task to free specific ports at system startup
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Scripts\kill-port.ps1 3000,8080"
$trigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "Free Development Ports" -Description "Free commonly used development ports at startup" -RunLevel Highest
```

### Incorporating into Build Scripts

```powershell
# In a build script, ensure ports are free before starting services
Write-Output "Ensuring required ports are free..."
& .\kill-port.ps1 -Port 3000,8080,5000 -Force
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to free required ports"
    exit $LASTEXITCODE
}
```

## Troubleshooting

### Common Issues

1. **"Access denied" errors**
   - Solution: Run PowerShell as Administrator
   ```powershell
   Start-Process powershell -Verb RunAs -ArgumentList "-File .\kill-port.ps1 3000"
   ```

2. **Process not terminating with standard kill**
   - Solution: Use the -Force parameter
   ```powershell
   .\kill-port.ps1 -Port 3000 -Force
   ```

3. **Get-NetTCPConnection not available**
   - Solution: This cmdlet requires Windows 8/Server 2012 or newer. On older systems, you may need an alternative approach using netstat.

4. **Script execution policy restrictions**
   - Solution: Temporarily bypass the execution policy
   ```powershell
   PowerShell -ExecutionPolicy Bypass -File .\kill-port.ps1 3000
   ```

## License and Attribution

- **Author**: Harsh Yadav
- **Version**: 1.1
- **Last Updated**: 2025-08-14

---

This documentation provides a comprehensive overview of the kill-port.ps1 PowerShell utility, its capabilities, and technical implementation. The script is designed to be robust and flexible for various use cases in Windows development and system administration environments.
