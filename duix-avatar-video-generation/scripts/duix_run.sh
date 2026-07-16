#!/bin/bash
# Digital Human - Duix Run Script
# Usage: ./duix_run.sh <video_file> <audio_file> <output_dir>
#        ./duix_run.sh --config <api_key>

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Config file
CONFIG_FILE="$HOME/.duixrc"

# Load config
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        export DUIX_API_KEY="$DUIX_API_KEY"
    fi
}

# Save config
save_config() {
    local key="$1"
    echo "DUIX_API_KEY=\"$key\"" > "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
    echo -e "${GREEN}API Key saved to $CONFIG_FILE${NC}"
}

# Config via argument or interactive
set_config() {
    local key="$1"
    
    echo -e "${CYAN}=== Digital Human 配置 ===${NC}"
    echo ""
    
    if [ -n "$key" ]; then
        save_config "$key"
    else
        echo "请输入 DUIX_API_KEY:"
        read -p "> " key
        
        if [ -z "$key" ]; then
            echo -e "${RED}Error: API Key 不能为空${NC}"
            exit 1
        fi
        
        save_config "$key"
    fi
    
    echo ""
}

# Check config or prompt
ensure_api_key() {
    load_config
    
    if [ -z "$DUIX_API_KEY" ]; then
        echo -e "${YELLOW}未检测到 API Key，需要先配置。${NC}"
        echo -e "用法: $0 --config <api_key>"
        echo -e "示例: $0 --config sk-xxxxxxxxxx"
        echo ""
        set_config
    fi
    
    MASKED_KEY="${DUIX_API_KEY:0:6}***${DUIX_API_KEY: -4}"
    echo -e "API Key: ${GREEN}$MASKED_KEY${NC}"
}

usage() {
    echo "Usage:"
    echo "  $0 <video_file> <audio_file> [output_dir]   运行任务"
    echo "  $0 --config <api_key>                       配置 API Key"
    echo ""
    echo "配置文件: $CONFIG_FILE"
    echo ""
    echo "示例:"
    echo "  $0 --config sk-xxxxxxxxxx"
    echo "  $0 person.mp4 voice.wav ./output"
    exit 0
}

# Log function
log() {
    local msg="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $msg" | tee -a "$LOG_FILE"
}

log_json() {
    local label="$1"
    local json="$2"
    echo "" >> "$LOG_FILE"
    echo "=== $label ===" >> "$LOG_FILE"
    echo "$json" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
}

check_duix_cli_update() {
    if ! command -v npm &> /dev/null; then
        return 0
    fi

    local current_version
    local latest_version

    current_version=$(duix-cli --version 2>/dev/null | grep -oE '[0-9]+(\.[0-9]+){1,2}([-+][0-9A-Za-z.-]+)?' | head -1 || true)
    latest_version=$(npm view duix-cli version 2>/dev/null || true)

    if [ -z "$current_version" ] || [ -z "$latest_version" ]; then
        return 0
    fi

    if [ "$current_version" != "$latest_version" ]; then
        echo -e "${YELLOW}duix-cli has a newer version available.${NC}"
        echo -e "Current: ${YELLOW}$current_version${NC}"
        echo -e "Latest:  ${GREEN}$latest_version${NC}"
        echo -e "Update:  npm i duix-cli -g"
        echo ""
    fi
}

# --- Main ---

# Handle --config
if [ "$1" = "--config" ]; then
    set_config "$2"
    exit 0
fi

# Handle -h/--help or no args
if [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ $# -lt 2 ]; then
    usage
fi

VIDEO="$1"
AUDIO="$2"
OUTPUT_DIR="${3:-.}"
POLL_INTERVAL="${4:-10}"

# Validate inputs
if [ ! -f "$VIDEO" ]; then
    echo -e "${RED}Error: Video file '$VIDEO' not found${NC}"
    exit 1
fi

if [ ! -f "$AUDIO" ]; then
    echo -e "${RED}Error: Audio file '$AUDIO' not found${NC}"
    exit 1
fi

if ! command -v duix-cli &> /dev/null; then
    echo -e "${RED}Error: duix-cli not found. Install: npm i duix-cli -g${NC}"
    exit 1
fi

check_duix_cli_update

# Ensure API key is configured
ensure_api_key

mkdir -p "$OUTPUT_DIR"

# Setup log file
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$OUTPUT_DIR/duix_run_${TIMESTAMP}.log"

# Start logging
log "=== Digital Human Run Started ==="
log "Video: $VIDEO"
log "Audio: $AUDIO"
log "Output Dir: $OUTPUT_DIR"
log "Config: $CONFIG_FILE"
log "Log File: $LOG_FILE"

echo ""
echo -e "${CYAN}Log file: $LOG_FILE${NC}"
echo ""

# Step 1: Create task
log "[STEP 1] Creating task..."

CREATE_RESULT=$(duix-cli compose create --video "$VIDEO" --audio "$AUDIO" --output "$OUTPUT_DIR")

log_json "CREATE REQUEST" "duix-cli compose create --video \"$VIDEO\" --audio \"$AUDIO\" --output \"$OUTPUT_DIR\""
log_json "CREATE RESPONSE" "$CREATE_RESULT"

echo "$CREATE_RESULT" | head -30

# Extract task_id from JSON
TASK_ID=$(echo "$CREATE_RESULT" | grep -oP '"taskId"\s*:\s*"\K[^"]+')

if [ -z "$TASK_ID" ]; then
    log "ERROR: Failed to extract task_id"
    echo -e "${RED}Error: Failed to extract task_id${NC}"
    exit 1
fi

log "Task ID: $TASK_ID"
echo ""
echo -e "${GREEN}Task created: $TASK_ID${NC}"

# Step 2: Poll status
log "[STEP 2] Polling task status..."
echo -e "${YELLOW}Waiting for task to complete...${NC}"

POLL_COUNT=0

while true; do
    POLL_COUNT=$((POLL_COUNT + 1))
    
    log "Poll #$POLL_COUNT: Querying status..."
    STATUS_JSON=$(duix-cli compose status "$TASK_ID")
    
    # Extract status from JSON
    STATUS=$(echo "$STATUS_JSON" | grep -oP '"status"\s*:\s*"\K[^"]+')
    PROGRESS=$(echo "$STATUS_JSON" | grep -oP '"progress"\s*:\s*\K[0-9]+')
    STATUS_DESC=$(echo "$STATUS_JSON" | grep -oP '"statusDesc"\s*:\s*"\K[^"]+')
    
    log "Status: $STATUS ($STATUS_DESC) | Progress: ${PROGRESS}%"
    log_json "STATUS RESPONSE #$POLL_COUNT" "$STATUS_JSON"
    
    echo "Status: $STATUS ($STATUS_DESC) | Progress: ${PROGRESS}%"
    
    # Check completed
    if [ "$STATUS" = "SUCCEEDED" ]; then
        log "[STEP 3] Task completed! Starting download..."
        
        OUTPUT_URL=$(echo "$STATUS_JSON" | grep -oP '"outputUrl"\s*:\s*"\K[^"]+')
        log "Output URL: $OUTPUT_URL"
        
        echo ""
        echo -e "${GREEN}Task completed!${NC}"
        echo -e "${YELLOW}Downloading...${NC}"
        
        # Step 3: Download
        DOWNLOAD_RESULT=$(duix-cli compose download "$TASK_ID")
        
        log_json "DOWNLOAD RESPONSE" "$DOWNLOAD_RESULT"
        
        # Extract downloaded file path
        OUTPUT_FILE=$(echo "$DOWNLOAD_RESULT" | grep -oP '"downloadedFilePath"\s*:\s*"\K[^"]+')
        
        if [ -n "$OUTPUT_FILE" ] && [ -f "$OUTPUT_FILE" ]; then
            FILE_SIZE=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')
            log "Downloaded: $OUTPUT_FILE ($FILE_SIZE)"
            
            echo ""
            echo -e "${GREEN}Download complete!${NC}"
            echo -e "${GREEN}Output: $OUTPUT_FILE${NC}"
            ls -lh "$OUTPUT_FILE"
        else
            log "WARNING: Download may have failed"
            echo -e "${YELLOW}Download response:${NC}"
            echo "$DOWNLOAD_RESULT"
        fi
        
        log "=== Digital Human Run Completed ==="
        echo ""
        echo -e "${GREEN}Log: $LOG_FILE${NC}"
        break
    fi
    
    # Check failed
    if [ "$STATUS" = "FAILED" ]; then
        FAILURE_REASON=$(echo "$STATUS_JSON" | grep -oP '"failureReason"\s*:\s*"\K[^"]+')
        log "ERROR: Task failed - $FAILURE_REASON"
        log_json "ERROR RESPONSE" "$STATUS_JSON"
        log "=== Digital Human Run Failed ==="
        
        echo ""
        echo -e "${RED}Error: Task failed${NC}"
        echo -e "${RED}Reason: $FAILURE_REASON${NC}"
        echo ""
        echo -e "${RED}Log: $LOG_FILE${NC}"
        exit 1
    fi
    
    sleep "$POLL_INTERVAL"
done
