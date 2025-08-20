<#
.SYNOPSIS
    Find and kill processes using specific TCP ports.

.DESCRIPTION
    Port Killer is a PowerShell script that identifies and terminates processes 
    listening on specified TCP ports. It provides options for listing processes
    without killing them and forcibly terminating stubborn processes.

.PARAMETER Port
    One or more port numbers to check and kill processes on.
    Default: 3000

.PARAMETER Force
    Force kill the process.

.PARAMETER ListOnly
    List processes without killing them.

.PARAMETER ShowCommands
    Show detailed information about commands being executed.

.PARAMETER IncludeIPv6
    Include IPv6 connections in search results.

.PARAMETER PortFile
    Path to a file containing port numbers (one per line) to check and kill.

.PARAMETER OutputFormat
    Format for output: 'Text' (default), 'JSON', or 'CSV'.

.EXAMPLE
    .\kill-port.ps1 3000
    Kill processes listening on port 3000

.EXAMPLE
    .\kill-port.ps1 3000,8080,5000
    Kill processes on multiple ports

.EXAMPLE
    .\kill-port.ps1 -Port 3000 -ListOnly
    List processes using port 3000 without killing them

.EXAMPLE
    .\kill-port.ps1 -Port 3000 -Force
    Force kill process on port 3000

.EXAMPLE
    .\kill-port.ps1 -PortFile "ports.txt"
    Kill processes on ports specified in ports.txt

.NOTES
    Author: Harsh Yadav
    Version: 1.1
    Last Updated: 2025-08-14
#>

param(
    [Parameter(Mandatory=$false, Position=0)]
    [int[]]$Port = @(3000),
    
    [Parameter(Mandatory=$false)]
    [switch]$Force,
    
    [Parameter(Mandatory=$false)]
    [switch]$ListOnly,
    
    [Parameter(Mandatory=$false)]
    [switch]$ShowCommands,
    
    [Parameter(Mandatory=$false)]
    [switch]$IncludeIPv6,
    
    [Parameter(Mandatory=$false)]
    [string]$PortFile,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Text", "JSON", "CSV")]
    [string]$OutputFormat = "Text"
)

function Write-FormattedOutput {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ConsoleColor]$ForegroundColor = [ConsoleColor]::White
    )
    
    if ($OutputFormat -eq "Text") {
        Write-Host $Message -ForegroundColor $ForegroundColor
    } else {
        Write-Output $Message
    }
}

function Find-ProcessesByPort {
    param(
        [int]$PortNumber,
        [bool]$IncludeIPv6
    )
    
    try {
        $command = "Get-NetTCPConnection -LocalPort $PortNumber -State Listen -ErrorAction Stop"
        if ($ShowCommands) { 
            Write-FormattedOutput "Running: $command" -ForegroundColor Gray 
        }
        
        $connections = Get-NetTCPConnection -LocalPort $PortNumber -State Listen -ErrorAction Stop
        
        # Filter IPv6 if not included
        if (-not $IncludeIPv6) {
            $connections = $connections | Where-Object { $_.LocalAddress -notlike "*:*" }
        }
        
        return @($connections.OwningProcess)
    } 
    catch [System.InvalidOperationException] {
        Write-FormattedOutput "Network commands unavailable. Ensure you have appropriate permissions." -ForegroundColor Red
        return @()
    } 
    catch [System.Management.Automation.CommandNotFoundException] {
        Write-FormattedOutput "Required cmdlet not found. This script requires Windows 8/Server 2012 or newer." -ForegroundColor Red
        return @()
    } 
    catch {
        Write-Error "Error finding processes: $_"
        return @()
    }
}

function Export-Results {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject[]]$Results
    )
    
    if ($OutputFormat -eq "JSON") {
        $Results | ConvertTo-Json
    } 
    elseif ($OutputFormat -eq "CSV") {
        $Results | ConvertTo-Csv -NoTypeInformation
    }
}

# Results collection for formatted output
$results = @()

# Display script information
Write-FormattedOutput "Port Killer for Windows - Find and terminate processes using specific TCP ports" -ForegroundColor Blue
Write-FormattedOutput "Running on Windows PowerShell $($PSVersionTable.PSVersion)" -ForegroundColor Blue

# Process port file if specified
if ($PortFile -and (Test-Path $PortFile)) {
    try {
        $fileContent = Get-Content $PortFile -ErrorAction Stop
        $portsFromFile = @($fileContent -as [int[]] | Where-Object {$_ -gt 0 -and $_ -lt 65536})
        
        if ($portsFromFile.Count -gt 0) {
            $Port = $portsFromFile
            Write-FormattedOutput "Loaded $($portsFromFile.Count) valid ports from file: $PortFile" -ForegroundColor Cyan
        } else {
            Write-FormattedOutput "No valid ports found in file: $PortFile" -ForegroundColor Yellow
        }
    } catch {
        Write-FormattedOutput "Error reading port file: $_" -ForegroundColor Red
    }
}

# Ensure running as admin if not in ListOnly mode
if (-not $ListOnly -and -not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Write-FormattedOutput "Administrator privileges required to kill processes." -ForegroundColor Yellow
    Write-FormattedOutput "Please run the script as Administrator." -ForegroundColor Red
    exit 1
}

foreach ($PortNumber in $Port) {
    Write-FormattedOutput "Checking port $PortNumber..." -ForegroundColor Cyan
    
    # Validate port number
    if ($PortNumber -lt 1 -or $PortNumber -gt 65535) {
        Write-FormattedOutput "Invalid port number: $PortNumber (must be between 1-65535)" -ForegroundColor Red
        continue
    }
    
    # Find the PID(s) listening on the port
    $pids = Find-ProcessesByPort -PortNumber $PortNumber -IncludeIPv6 $IncludeIPv6
    
    if ($pids.Count -eq 0) {
        Write-FormattedOutput "Port $PortNumber is not in use." -ForegroundColor Yellow
        
        $results += [PSCustomObject]@{
            Port = $PortNumber
            Status = "Not in use"
            Action = "None"
            ProcessName = ""
            PID = ""
            Result = "No action needed"
        }
        
        continue
    }
    
    foreach ($pid in $pids) {
        # Get process info
        $proc = Get-Process -Id $pid -ErrorAction SilentlyContinue
        
        if ($proc) {
            if ($ListOnly) {
                Write-FormattedOutput "Port $PortNumber is used by $($proc.ProcessName) (PID: $pid)" -ForegroundColor Green
                
                $results += [PSCustomObject]@{
                    Port = $PortNumber
                    Status = "In use"
                    Action = "List only"
                    ProcessName = $proc.ProcessName
                    PID = $pid
                    Result = "Process listed"
                }
            } else {
                Write-FormattedOutput "Killing process $($proc.ProcessName) (PID: $pid) using port $PortNumber..." -ForegroundColor Magenta
                
                try {
                    $command = if ($Force) { "Stop-Process -Id $pid -Force" } else { "Stop-Process -Id $pid" }
                    if ($ShowCommands) { 
                        Write-FormattedOutput "Running: $command" -ForegroundColor Gray 
                    }
                    
                    if ($Force) {
                        Stop-Process -Id $pid -Force -ErrorAction Stop
                    } else {
                        Stop-Process -Id $pid -ErrorAction Stop
                    }
                    
                    # Verify process was terminated
                    Start-Sleep -Milliseconds 100
                    $processStillExists = Get-Process -Id $pid -ErrorAction SilentlyContinue
                    
                    if ($processStillExists) {
                        Write-FormattedOutput "Warning: Process may still be running. Try -Force option." -ForegroundColor Yellow
                        $results += [PSCustomObject]@{
                            Port = $PortNumber
                            Status = "In use"
                            Action = if ($Force) { "Force kill" } else { "Kill" }
                            ProcessName = $proc.ProcessName
                            PID = $pid
                            Result = "Process may still be running"
                        }
                    } else {
                        Write-FormattedOutput "Process $($proc.ProcessName) (PID: $pid) terminated successfully." -ForegroundColor Green
                        $results += [PSCustomObject]@{
                            Port = $PortNumber
                            Status = "Was in use"
                            Action = if ($Force) { "Force kill" } else { "Kill" }
                            ProcessName = $proc.ProcessName
                            PID = $pid
                            Result = "Process terminated"
                        }
                    }
                    
                } catch {
                    Write-FormattedOutput "Failed to kill process: $_" -ForegroundColor Red
                    $results += [PSCustomObject]@{
                        Port = $PortNumber
                        Status = "In use"
                        Action = if ($Force) { "Force kill" } else { "Kill" }
                        ProcessName = $proc.ProcessName
                        PID = $pid
                        Result = "Failed: $($_.Exception.Message)"
                    }
                }
            }
        } else {
            Write-FormattedOutput "Process with PID $pid not found." -ForegroundColor Red
            $results += [PSCustomObject]@{
                Port = $PortNumber
                Status = "Unknown"
                Action = "None"
                ProcessName = "Unknown"
                PID = $pid
                Result = "Process not found"
            }
        }
    }
}

# Output results in the requested format
if ($OutputFormat -ne "Text") {
    Export-Results -Results $results
}
