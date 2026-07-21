#!/bin/bash
# Digital Human - Duix Run Script
# Usage: ./duix_run.sh <video_file> <audio_file> <output_dir>
#        ./duix_run.sh --config <api_key>

set -e

# Prefer UTF-8 for final messages when the host shell supports it.
export LANG="${LANG:-C.UTF-8}"
export LC_ALL="${LC_ALL:-C.UTF-8}"
export PYTHONIOENCODING="${PYTHONIOENCODING:-UTF-8}"
if command -v chcp.com >/dev/null 2>&1; then
    chcp.com 65001 >/dev/null 2>&1 || true
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Config file
CONFIG_FILE="$HOME/.duixrc"
NPM_REGISTRY="https://registry.npmjs.org/"
NPM_INSTALL_CMD="npm i duix-cli -g --registry=$NPM_REGISTRY"

# Load config
load_config() {
    local key_line

    if [ -f "$CONFIG_FILE" ]; then
        key_line=$(grep -E '^DUIX_API_KEY=' "$CONFIG_FILE" 2>/dev/null | tail -1 || true)
        if [ -n "$key_line" ]; then
            DUIX_API_KEY="${key_line#DUIX_API_KEY=}"
            DUIX_API_KEY=$(printf '%s' "$DUIX_API_KEY" | tr -d '\r')
            DUIX_API_KEY="${DUIX_API_KEY%\"}"
            DUIX_API_KEY="${DUIX_API_KEY#\"}"
            export DUIX_API_KEY
        fi
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
    
    echo -e "${CYAN}=== Digital Human Configuration ===${NC}"
    echo ""
    
    if [ -n "$key" ]; then
        save_config "$key"
    else
        echo "Please enter DUIX_API_KEY:"
        read -p "> " key
        
        if [ -z "$key" ]; then
            echo -e "${RED}Error: API Key cannot be empty${NC}"
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
        echo -e "${YELLOW}API Key was not detected. Please configure it first.${NC}"
        echo -e "Usage: $0 --config <api_key>"
        echo -e "Example: $0 --config <your_api_key>"
        echo ""
        set_config
    fi
    
    MASKED_KEY="${DUIX_API_KEY:0:6}***${DUIX_API_KEY: -4}"
    echo -e "API Key: ${GREEN}$MASKED_KEY${NC}"
}

usage() {
    echo "Usage:"
    echo "  $0 <video_file> <audio_file> [output_dir]   Run task"
    echo "  $0 --config <api_key>                       Configure API Key"
    echo ""
    echo "Config file: $CONFIG_FILE"
    echo ""
    echo "Examples:"
    echo "  $0 --config <your_api_key>"
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

json_value() {
    local json="$1"
    local field="$2"
    local value

    if command -v jq >/dev/null 2>&1; then
        value=$(printf '%s' "$json" \
            | jq -r --arg field "$field" '.. | objects | select(has($field)) | .[$field] | select(. != null) | tostring' 2>/dev/null \
            | head -1)
        if [ -n "$value" ]; then
            printf '%s
' "$value"
            return 0
        fi
    fi

    printf '%s
' "$json" \
        | sed -nE "s/.*\"$field\"[[:space:]]*:[[:space:]]*(\"[^\"]*\"|true|false|null|-?[0-9]+(\.[0-9]+)?).*/\1/p" \
        | head -1 \
        | sed -E "s/^\"//; s/\"$//"
}

failure_reason_from_json() {
    local json="$1"
    local reason

    reason=$(json_value "$json" "failureReason")
    if [ -z "$reason" ]; then
        reason=$(json_value "$json" "statusDesc")
    fi
    if [ -z "$reason" ]; then
        reason=$(json_value "$json" "message")
    fi
    if [ -z "$reason" ]; then
        reason=$(json_value "$json" "msg")
    fi

    echo "${reason:-Unknown reason}"
}

run_credit_check() {
    local label="$1"
    local check_result

    if ! check_result=$(duix-cli compose check -a "$AUDIO"); then
        log "ERROR: Failed to check credits"
        log_json "$label CREDIT CHECK ERROR" "$check_result"
        echo -e "${RED}Error: Failed to check credits${NC}"
        exit 1
    fi

    log_json "$label CREDIT CHECK RESPONSE" "$check_result"
    echo "$check_result"
}

confirm_credits() {
    local check_result="$1"
    local can_continue
    local required_credits
    local credits_left
    local answer

    can_continue=$(json_value "$check_result" "canContinue")
    required_credits=$(json_value "$check_result" "requiredCredits")
    credits_left=$(json_value "$check_result" "creditsLeft")

    if [ "$can_continue" != "true" ]; then
        printf '⚠️ Insufficient Credits
This task is estimated to require %s credits. Current account balance: %s credits.
Please go to the DUIX recharge page (https://www.duix.com/dashboard/duix-cli-skills/overview), recharge, and try again.
' "${required_credits:-Unknown}" "${credits_left:-Unknown}"
        exit 1
    fi

    printf '💡 Credit Confirmation
This talking-head video generation is estimated to consume %s credits. Current balance: %s credits.
To confirm submission, reply "yes". To cancel, reply "no".
' "${required_credits:-Unknown}" "${credits_left:-Unknown}"
    read -r answer

    case "$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]')" in
        yes|y|是) ;;
        *)
            log "User cancelled after credit confirmation"
            echo "The talking-head video generation task has been cancelled."
            exit 0
            ;;
    esac
}

absolute_path() {
    local input="$1"

    if [ -z "$input" ]; then
        return 1
    fi

    if command -v cygpath >/dev/null 2>&1; then
        cygpath -wa "$input" 2>/dev/null && return 0
    fi

    if command -v realpath >/dev/null 2>&1; then
        realpath "$input" 2>/dev/null && return 0
    fi

    case "$input" in
        /*) printf '%s
' "$input" ;;
        *) printf '%s/%s
' "$(pwd)" "$input" ;;
    esac
}

file_uri() {
    local input="$1"
    local uri_path
    local abs

    if [ -z "$input" ]; then
        return 1
    fi

    if command -v cygpath >/dev/null 2>&1; then
        uri_path=$(cygpath -am "$input" 2>/dev/null || true)
        if [ -n "$uri_path" ]; then
            printf 'file:///%s
' "$uri_path"
            return 0
        fi
    fi

    abs=$(absolute_path "$input" 2>/dev/null || true)
    if [ -n "$abs" ]; then
        printf 'file://%s
' "$abs"
    fi
}

markdown_file_link() {
    local input="$1"
    local abs
    local uri

    abs=$(absolute_path "$input" 2>/dev/null || true)
    uri=$(file_uri "$input" 2>/dev/null || true)

    if [ -n "$abs" ] && [ -n "$uri" ]; then
        printf '[%s](<%s>)
' "$abs" "$uri"
    elif [ -n "$abs" ]; then
        printf '%s
' "$abs"
    else
        printf 'Unknown
'
    fi
}

print_success_result() {
    local output_file="$1"
    local credit_result
    local credits_left
    local required_credits
    local video_duration
    local output_link

    if credit_result=$(duix-cli compose check -a "$AUDIO"); then
        log_json "FINAL CREDIT CHECK RESPONSE" "$credit_result"
        credits_left=$(json_value "$credit_result" "creditsLeft")
        required_credits=$(json_value "$credit_result" "requiredCredits")
        video_duration=$(json_value "$credit_result" "audioDurationSeconds")
    else
        log "WARNING: Failed to check final credits"
        log_json "FINAL CREDIT CHECK ERROR" "$credit_result"
    fi

    output_link=$(markdown_file_link "$output_file")

    echo ""
    echo "✔️ Talking-head Video Generated Successfully"
    echo ""
    echo "Task Details:"
    echo "  - Task ID: $TASK_ID"
    echo "  - Status: success (succeeded)"
    echo "  - Video: $VIDEO"
    echo "  - Audio: $AUDIO"
    echo ""
    echo "Output File:"
    echo "  - $output_link"
    echo "  - Video Duration: ${video_duration:-Unknown} seconds"
    echo ""
    echo "Credit Usage:"
    echo "  - Credits consumed by this video: ${required_credits:-Unknown} credits"
    echo "  - Remaining credits: ${credits_left:-Unknown} credits ([Recharge](https://duix.com/dashboard/duix-cli-skills/overview))"
}

print_failure_result() {
    local reason="${1:-Unknown reason}"

    if [ -z "$reason" ]; then
        reason="Unknown reason"
    fi

    echo ""
    echo "❌ Talking-head Video Generation Failed"
    echo ""
    echo "Credit Status: credits have been refunded"
    echo ""
    echo "Failure Reason: $reason (for example: video resolution exceeds the limit / audio format is unsupported / network timeout / model exception)"
    echo ""
    echo "Suggestions:"
    echo "  - For video issues: check whether the video is front-facing, clear, unobstructed, and within the supported resolution range"
    echo "  - For audio issues: confirm the audio format is MP3/WAV and can be played normally"
    echo "  - For network issues: retry later or check the network connection"
    echo "  - For credit issues: go to the [DUIX recharge page](https://duix.com/dashboard/duix-cli-skills/overview) to recharge"
    echo ""
    echo "To retry, confirm the source assets and submit again."
}
check_duix_cli_update() {
    if ! command -v npm &> /dev/null; then
        return 0
    fi

    local current_version
    local latest_version

    current_version=$(duix-cli --version 2>/dev/null | grep -oE '[0-9]+(\.[0-9]+){1,2}([-+][0-9A-Za-z.-]+)?' | head -1 || true)
    latest_version=$(npm view duix-cli version --registry="$NPM_REGISTRY" 2>/dev/null || true)

    if [ -z "$current_version" ] || [ -z "$latest_version" ]; then
        return 0
    fi

    if [ "$current_version" != "$latest_version" ]; then
        echo -e "${YELLOW}duix-cli has a newer version available.${NC}"
        echo -e "Current: ${YELLOW}$current_version${NC}"
        echo -e "Latest:  ${GREEN}$latest_version${NC}"
        echo -e "Update:  $NPM_INSTALL_CMD"
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
MAX_POLLS="${MAX_POLLS:-0}"
case "$POLL_INTERVAL" in ""|*[!0-9]*) POLL_INTERVAL=10 ;; esac
case "$MAX_POLLS" in ""|*[!0-9]*) MAX_POLLS=0 ;; esac

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
    echo -e "${RED}Error: duix-cli not found. Install: $NPM_INSTALL_CMD${NC}"
    exit 1
fi

check_duix_cli_update

# Ensure API key is configured
ensure_api_key

if ! mkdir -p "$OUTPUT_DIR"; then
    echo -e "${RED}Error: Failed to create output directory: $OUTPUT_DIR${NC}"
    exit 1
fi

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

# Credit check and user confirmation
log "[STEP 0] Checking credits..."
CREDIT_CHECK_RESULT=$(run_credit_check "INITIAL")
confirm_credits "$CREDIT_CHECK_RESULT"

# Step 1: Create task
log "[STEP 1] Creating task..."

if ! CREATE_RESULT=$(duix-cli compose create --video "$VIDEO" --audio "$AUDIO" --output "$OUTPUT_DIR"); then
    log "ERROR: Failed to create task"
    log_json "CREATE ERROR" "$CREATE_RESULT"
    print_failure_result "$(failure_reason_from_json "$CREATE_RESULT")"
    exit 1
fi

log_json "CREATE REQUEST" "duix-cli compose create --video \"$VIDEO\" --audio \"$AUDIO\" --output \"$OUTPUT_DIR\""
log_json "CREATE RESPONSE" "$CREATE_RESULT"

echo "$CREATE_RESULT" | head -30

# Extract task_id from JSON
TASK_ID=$(json_value "$CREATE_RESULT" "taskId")

if [ -z "$TASK_ID" ]; then
    log "ERROR: Failed to extract task_id"
    print_failure_result "$(failure_reason_from_json "$CREATE_RESULT")"
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
    if [ "$MAX_POLLS" -gt 0 ] && [ "$POLL_COUNT" -gt "$MAX_POLLS" ]; then
        log "ERROR: Polling exceeded MAX_POLLS=$MAX_POLLS"
        echo ""
        echo -e "${RED}Log: $LOG_FILE${NC}"
        print_failure_result "Polling timed out before the task completed"
        exit 1
    fi
    
    log "Poll #$POLL_COUNT: Querying status..."
    if ! STATUS_JSON=$(duix-cli compose status "$TASK_ID" 2>&1); then
        log "ERROR: Failed to query task status"
        log_json "STATUS ERROR #$POLL_COUNT" "$STATUS_JSON"
        echo ""
        echo -e "${RED}Log: $LOG_FILE${NC}"
        print_failure_result "Failed to query task status"
        exit 1
    fi
    
    # Extract status from JSON
    STATUS=$(json_value "$STATUS_JSON" "status")
    PROGRESS=$(json_value "$STATUS_JSON" "progress")
    STATUS_DESC=$(json_value "$STATUS_JSON" "statusDesc")

    if [ -z "$STATUS" ]; then
        log "ERROR: Failed to parse task status"
        log_json "STATUS PARSE ERROR #$POLL_COUNT" "$STATUS_JSON"
        echo ""
        echo -e "${RED}Log: $LOG_FILE${NC}"
        print_failure_result "Failed to parse task status"
        exit 1
    fi
    
    log "Status: $STATUS ($STATUS_DESC) | Progress: ${PROGRESS}%"
    log_json "STATUS RESPONSE #$POLL_COUNT" "$STATUS_JSON"
    
    echo "Status: $STATUS ($STATUS_DESC) | Progress: ${PROGRESS}%"
    
    # Check completed
    if [ "$STATUS" = "SUCCEEDED" ]; then
        log "[STEP 3] Task completed! Starting download..."
        
        OUTPUT_URL=$(json_value "$STATUS_JSON" "outputUrl")
        log "Output URL: $OUTPUT_URL"
        
        echo ""
        echo -e "${GREEN}Task completed!${NC}"
        echo -e "${YELLOW}Downloading...${NC}"
        
        # Step 3: Download
        if ! DOWNLOAD_RESULT=$(duix-cli compose download "$TASK_ID" 2>&1); then
            log "ERROR: Failed to download result"
            log_json "DOWNLOAD ERROR" "$DOWNLOAD_RESULT"
            echo ""
            echo -e "${RED}Log: $LOG_FILE${NC}"
            print_failure_result "Failed to download result"
            exit 1
        fi
        
        log_json "DOWNLOAD RESPONSE" "$DOWNLOAD_RESULT"
        
        # Extract downloaded file path
        OUTPUT_FILE=$(json_value "$DOWNLOAD_RESULT" "downloadedFilePath")
        
        if [ -n "$OUTPUT_FILE" ] && [ -f "$OUTPUT_FILE" ]; then
            FILE_SIZE=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')
            log "Downloaded: $OUTPUT_FILE ($FILE_SIZE)"
            
            echo ""
            echo -e "${GREEN}Download complete!${NC}"
            echo -e "${GREEN}Output: $OUTPUT_FILE${NC}"
            ls -lh "$OUTPUT_FILE"
        else
            log "ERROR: Download response did not contain a local output file"
            echo -e "${YELLOW}Download response:${NC}"
            echo "$DOWNLOAD_RESULT"
            echo ""
            echo -e "${RED}Log: $LOG_FILE${NC}"
            print_failure_result "Downloaded output file was not found locally"
            exit 1
        fi
        
        echo ""
        echo -e "${GREEN}Log: $LOG_FILE${NC}"
        log "=== Digital Human Run Completed ==="
        print_success_result "$OUTPUT_FILE"
        break
    fi
    
    # Check failed
    if [ "$STATUS" = "FAILED" ]; then
        FAILURE_REASON=$(failure_reason_from_json "$STATUS_JSON")
        log "ERROR: Task failed - $FAILURE_REASON"
        log_json "ERROR RESPONSE" "$STATUS_JSON"
        log "=== Digital Human Run Failed ==="
        
        echo ""
        echo -e "${RED}Log: $LOG_FILE${NC}"
        print_failure_result "$FAILURE_REASON"
        exit 1
    fi
    
    sleep "$POLL_INTERVAL"
done
