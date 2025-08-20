# Port Killer - A script to find and kill processes using specific ports
# Usage: ./kill-port.sh [options] <port(s)>
# Options:
#   -f, --force      Force kill the process (SIGKILL instead of SIGTERM)
#   -l, --list       List processes without killing them
#   -v, --verbose    Show detailed information and commands being run
#   -h, --help       Show help message
#   -6, --ipv6       Include IPv6 connections
#   -j, --json       Output results in JSON format
#   -c, --csv        Output results in CSV format
#   -p, --port-file  Read ports from specified file (one port per line)

set -e

# Default values
FORCE=false
LIST_ONLY=false
VERBOSE=false
INCLUDE_IPV6=false
OUTPUT_FORMAT="text"
PORT_FILE=""
PORTS=()

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Functions
show_help() {
    echo -e "${BLUE}Port Killer - Find and terminate processes using specific TCP ports${NC}"
    echo
    echo "Usage: $0 [options] <port(s)>"
    echo
    echo "Options:"
    echo "  -f, --force        Force kill the process (SIGKILL instead of SIGTERM)"
    echo "  -l, --list         List processes without killing them"
    echo "  -v, --verbose      Show detailed information and commands being run"
    echo "  -h, --help         Show this help message"
    echo "  -6, --ipv6         Include IPv6 connections"
    echo "  -j, --json         Output results in JSON format"
    echo "  -c, --csv          Output results in CSV format"
    echo "  -p, --port-file    Read ports from specified file (one port per line)"
    echo
    echo "Examples:"
    echo "  $0 3000                  # Kill process on port 3000"
    echo "  $0 3000 8080 5000        # Kill processes on multiple ports"
    echo "  $0 -l 3000               # List process using port 3000 without killing"
    echo "  $0 -f 3000               # Force kill process on port 3000"
    echo "  $0 -p ports.txt          # Kill processes on ports listed in ports.txt"
    echo "  $0 -6 3000               # Include IPv6 connections for port 3000"
    echo
    exit 0
}

# Check if required tools are available
check_requirements() {
    local missing_tools=()
    
    if [[ "$(uname)" == "Darwin" ]]; then
        if ! command -v lsof &>/dev/null; then
            missing_tools+=("lsof")
        fi
    elif [[ "$(uname)" == "Linux" ]]; then
        if ! command -v ss &>/dev/null && ! command -v netstat &>/dev/null; then
            missing_tools+=("iproute2 (ss command) or net-tools (netstat command)")
        fi
    fi
    
    if ! command -v ps &>/dev/null; then
        missing_tools+=("ps")
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        echo -e "${RED}Error: Required tools not found: ${missing_tools[*]}${NC}"
        echo -e "${YELLOW}Please install the missing packages.${NC}"
        exit 1
    fi
}

# Check if running as root
check_root() {
    if [[ $LIST_ONLY == false && $EUID -ne 0 ]]; then
        echo -e "${RED}This script must be run as root to kill processes.${NC}"
        echo -e "Please run with ${YELLOW}sudo $0 $*${NC}"
        exit 1
    fi
}

# Detect OS
detect_os() {
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "macOS"
    elif [[ "$(uname)" == "Linux" ]]; then
        echo "Linux"
    else
        echo "Unknown"
    fi
}

# Find process by port based on OS
find_process_by_port() {
    local port=$1
    local os=$(detect_os)
    local ipv6_flag=$2
    
    if [[ $VERBOSE == true ]]; then
        echo -e "${GRAY}Detecting processes on port $port for $os...${NC}"
    fi
    
    if [[ "$os" == "macOS" ]]; then
        local command="lsof -i :$port -sTCP:LISTEN -t"
        if [[ $ipv6_flag == false ]]; then
            command="lsof -i4TCP:$port -sTCP:LISTEN -t"
        fi
        
        if [[ $VERBOSE == true ]]; then
            echo -e "${GRAY}Running: $command${NC}"
        fi
        eval "$command" 2>/dev/null || true
        
    elif [[ "$os" == "Linux" ]]; then
        if command -v ss &>/dev/null; then
            local command="ss -tuln"
            if [[ $ipv6_flag == false ]]; then
                command="ss -4tuln"
            fi
            command+=" | grep :$port"
            
            if [[ $VERBOSE == true ]]; then
                echo -e "${GRAY}Running: $command${NC}"
            fi
            
            pids=$(eval "$command" | awk '{print $7}' | cut -d',' -f2 | cut -d'=' -f2 2>/dev/null)
            if [[ -z "$pids" ]]; then
                # Try alternative parsing if needed
                pids=$(ss -lptn "sport = :$port" 2>/dev/null | grep LISTEN | awk '{print $6}' | cut -d"," -f2 | cut -d"=" -f2 | cut -d'"' -f1)
            fi
        elif command -v netstat &>/dev/null; then
            if [[ $VERBOSE == true ]]; then
                echo -e "${GRAY}ss command not found, using netstat instead${NC}"
            fi
            local command="netstat -tuln"
            if [[ $ipv6_flag == false ]]; then
                command="netstat -4tuln"
            fi
            command+=" | grep :$port"
            
            if [[ $VERBOSE == true ]]; then
                echo -e "${GRAY}Running: $command${NC}"
            fi
            
            pids=$(eval "$command" | awk '{print $7}' | cut -d'/' -f1 2>/dev/null)
        else
            echo -e "${RED}Neither ss nor netstat found. Please install iproute2 or net-tools.${NC}"
            return 1
        fi
        echo "$pids"
    else
        echo -e "${RED}Unsupported operating system.${NC}"
        return 1
    fi
}

# Get process details
get_process_details() {
    local pid=$1
    ps -p "$pid" -o comm= 2>/dev/null || echo "unknown"
}

# Format output based on selected format
format_output() {
    local port=$1
    local status=$2
    local action=$3
    local process_name=$4
    local pid=$5
    local result=$6
    
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        # Simple JSON format
        echo "{\"port\":$port,\"status\":\"$status\",\"action\":\"$action\",\"process_name\":\"$process_name\",\"pid\":\"$pid\",\"result\":\"$result\"}"
    elif [[ "$OUTPUT_FORMAT" == "csv" ]]; then
        # Simple CSV format
        echo "\"$port\",\"$status\",\"$action\",\"$process_name\",\"$pid\",\"$result\""
    else
        # Use default color output for text
        case "$status" in
            "In use")
                echo -e "${YELLOW}Port $port is used by $process_name (PID: $pid)${NC}"
                ;;
            "Not in use")
                echo -e "${GREEN}Port $port is not in use.${NC}"
                ;;
            "Was in use")
                echo -e "${GREEN}Process $process_name (PID: $pid) on port $port $result.${NC}"
                ;;
            "Error")
                echo -e "${RED}Error with port $port: $result${NC}"
                ;;
        esac
    fi
}

# Kill process
kill_process() {
    local pid=$1
    local port=$2
    local process_name=$3
    
    if [[ $LIST_ONLY == true ]]; then
        format_output "$port" "In use" "List only" "$process_name" "$pid" "Process listed"
        return 0
    fi
    
    echo -e "${MAGENTA}Killing process $process_name (PID: $pid) using port $port...${NC}"
    
    if [[ $FORCE == true ]]; then
        if [[ $VERBOSE == true ]]; then
            echo -e "${GRAY}Running: kill -9 $pid${NC}"
        fi
        kill -9 "$pid" 2>/dev/null
    else
        if [[ $VERBOSE == true ]]; then
            echo -e "${GRAY}Running: kill -15 $pid${NC}"
        fi
        kill -15 "$pid" 2>/dev/null
    fi
    
    # Check if process was killed
    sleep 0.1
    if ! ps -p "$pid" > /dev/null 2>&1; then
        format_output "$port" "Was in use" "$([ $FORCE == true ] && echo "Force kill" || echo "Kill")" "$process_name" "$pid" "terminated successfully"
        return 0
    else
        echo -e "${RED}Failed to kill process $pid. Try with --force option.${NC}"
        format_output "$port" "In use" "$([ $FORCE == true ] && echo "Force kill" || echo "Kill")" "$process_name" "$pid" "failed to terminate"
        return 1
    fi
}

# Process command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -f|--force)
            FORCE=true
            shift
            ;;
        -l|--list)
            LIST_ONLY=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_help
            ;;
        -6|--ipv6)
            INCLUDE_IPV6=true
            shift
            ;;
        -j|--json)
            OUTPUT_FORMAT="json"
            shift
            ;;
        -c|--csv)
            OUTPUT_FORMAT="csv"
            shift
            ;;
        -p|--port-file)
            if [[ -z "$2" || "$2" =~ ^- ]]; then
                echo -e "${RED}Error: Port file path is required after -p/--port-file${NC}"
                exit 1
            fi
            PORT_FILE="$2"
            shift 2
            ;;
        -*)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
        *)
            if [[ $1 =~ ^[0-9]+$ ]]; then
                PORTS+=("$1")
            else
                echo -e "${RED}Invalid port number: $1${NC}"
                exit 1
            fi
            shift
            ;;
    esac
done

# Check requirements
check_requirements

# Process port file if specified
if [[ -n "$PORT_FILE" ]]; then
    if [[ ! -f "$PORT_FILE" ]]; then
        echo -e "${RED}Error: Port file not found: $PORT_FILE${NC}"
        exit 1
    fi
    
    while read -r port; do
        if [[ "$port" =~ ^[0-9]+$ ]]; then
            PORTS+=("$port")
        fi
    done < "$PORT_FILE"
    
    if [[ $VERBOSE == true ]]; then
        echo -e "${GRAY}Loaded ${#PORTS[@]} ports from file: $PORT_FILE${NC}"
    fi
fi

# Check if ports were specified
if [[ ${#PORTS[@]} -eq 0 ]]; then
    echo -e "${RED}No valid ports specified!${NC}"
    echo "Use --help for usage information"
    exit 1
fi

# Check for root permissions if needed
check_root "$@"

# Output header for CSV format
if [[ "$OUTPUT_FORMAT" == "csv" ]]; then
    echo "\"Port\",\"Status\",\"Action\",\"ProcessName\",\"PID\",\"Result\""
elif [[ "$OUTPUT_FORMAT" == "json" ]]; then
    echo "["
fi

# Display OS information
OS=$(detect_os)
if [[ "$OUTPUT_FORMAT" == "text" ]]; then
    echo -e "${BLUE}Operating System: $OS${NC}"
fi

# Process each port
port_count=0
for PORT in "${PORTS[@]}"; do
    port_count=$((port_count + 1))
    
    # Validate port number
    if [[ "$PORT" -lt 1 || "$PORT" -gt 65535 ]]; then
        if [[ "$OUTPUT_FORMAT" == "text" ]]; then
            echo -e "${RED}Invalid port number: $PORT (must be between 1-65535)${NC}"
        elif [[ "$OUTPUT_FORMAT" == "json" ]]; then
            [[ $port_count -gt 1 ]] && echo ","
            echo "{\"port\":$PORT,\"status\":\"Error\",\"action\":\"None\",\"process_name\":\"\",\"pid\":\"\",\"result\":\"Invalid port number\"}"
        elif [[ "$OUTPUT_FORMAT" == "csv" ]]; then
            echo "\"$PORT\",\"Error\",\"None\",\"\",\"\",\"Invalid port number\""
        fi
        continue
    fi
    
    if [[ "$OUTPUT_FORMAT" == "text" ]]; then
        echo -e "${CYAN}Checking port $PORT...${NC}"
    fi
    
    # Find PIDs using this port
    PIDS=$(find_process_by_port "$PORT" "$INCLUDE_IPV6")
    
    if [[ -z "$PIDS" ]]; then
        format_output "$PORT" "Not in use" "None" "" "" "No action needed"
        continue
    fi
    
    # Process each PID
    for PID in $PIDS; do
        if [[ -z "$PID" || ! "$PID" =~ ^[0-9]+$ ]]; then
            continue  # Skip invalid PIDs
        fi
        
        PROCESS_NAME=$(get_process_details "$PID")
        
        if [[ -n "$PROCESS_NAME" && "$PROCESS_NAME" != "unknown" ]]; then
            kill_process "$PID" "$PORT" "$PROCESS_NAME"
        else
            if [[ "$OUTPUT_FORMAT" == "text" ]]; then
                echo -e "${RED}Process with PID $PID not found.${NC}"
            elif [[ "$OUTPUT_FORMAT" == "json" ]]; then
                [[ $port_count -gt 1 ]] && echo ","
                echo "{\"port\":$PORT,\"status\":\"Error\",\"action\":\"None\",\"process_name\":\"Unknown\",\"pid\":\"$PID\",\"result\":\"Process not found\"}"
            elif [[ "$OUTPUT_FORMAT" == "csv" ]]; then
                echo "\"$PORT\",\"Error\",\"None\",\"Unknown\",\"$PID\",\"Process not found\""
            fi
        fi
    done
done

# Close JSON array if applicable
if [[ "$OUTPUT_FORMAT" == "json" ]]; then
    echo "]"
fi

exit 0
