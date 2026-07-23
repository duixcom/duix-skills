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
            printf '%s\n' "$value"
            return 0
        fi
    fi

    if command -v node >/dev/null 2>&1; then
        value=$(JSON_INPUT="$json" JSON_FIELD="$field" node -e '
const input = process.env.JSON_INPUT || "";
const field = process.env.JSON_FIELD || "";
function find(value) {
  if (value && typeof value === "object") {
    if (Object.prototype.hasOwnProperty.call(value, field) && value[field] !== null && value[field] !== undefined) return value[field];
    for (const key of Object.keys(value)) {
      const found = find(value[key]);
      if (found !== undefined) return found;
    }
  }
  return undefined;
}
try {
  const found = find(JSON.parse(input));
  if (found !== undefined) process.stdout.write(String(found));
} catch (_) {}
' 2>/dev/null || true)
        if [ -n "$value" ]; then
            printf '%s\n' "$value"
            return 0
        fi
    fi

    printf '%s\n' "$json" \
        | sed -nE "s/.*\"$field\"[[:space:]]*:[[:space:]]*(\"[^\"]*\"|true|false|null|-?[0-9]+(\.[0-9]+)?).*/\1/p" \
        | head -1 \
        | sed -E "s/^\"//; s/\"$//"
}
json_object() {
    local json="$1"
    local path="$2"
    local field
    local value

    if command -v jq >/dev/null 2>&1; then
        value=$(printf '%s' "$json" | jq -c "$path // empty" 2>/dev/null || true)
        if [ -n "$value" ] && [ "$value" != "null" ]; then
            printf '%s
' "$value"
            return 0
        fi
    fi

    if command -v node >/dev/null 2>&1; then
        value=$(JSON_INPUT="$json" JSON_PATH="$path" node -e '
const input = process.env.JSON_INPUT || "";
const path = (process.env.JSON_PATH || "").replace(/^\./, "").split(".").filter(Boolean);
try {
  let value = JSON.parse(input);
  for (const key of path) value = value == null ? undefined : value[key];
  if (value !== undefined && value !== null) process.stdout.write(JSON.stringify(value));
} catch (_) {}
' 2>/dev/null || true)
        if [ -n "$value" ] && [ "$value" != "null" ]; then
            printf '%s
' "$value"
            return 0
        fi
    fi

    field="${path##*.}"
    printf '%s' "$json" \
        | tr -d '
' \
        | sed -nE "s/.*\"$field\"[[:space:]]*:[[:space:]]*(\{[^}]*\}).*/\1/p" \
        | head -1
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

    if [ -n "$reason" ]; then
        echo "$reason"
    elif [ -n "$json" ]; then
        printf '%s\n' "$json" | head -1
    else
        echo "Unknown reason"
    fi
}

run_compose_check() {
    local label="$1"
    local check_result
    local failure_reason

    if ! check_result=$(duix-cli compose check --video "$VIDEO" --audio "$AUDIO" 2>&1); then
        failure_reason=$(failure_reason_from_json "$check_result")
        log "ERROR: Failed to run compose pre-check - $failure_reason"
        log_json "$label COMPOSE CHECK ERROR" "$check_result"
        echo -e "${RED}Error: Failed to run compose pre-check${NC}"
        echo "Reason: $failure_reason"
        exit 1
    fi

    log_json "$label COMPOSE CHECK RESPONSE" "$check_result"
    echo "$check_result"
}

format_minutes_from_seconds() {
    local seconds="$1"

    case "$seconds" in
        ''|*[!0-9.]* )
            echo "Unknown"
            return 0
            ;;
    esac

    if command -v awk >/dev/null 2>&1; then
        awk -v seconds="$seconds" 'BEGIN { minutes = seconds / 60; if (minutes == int(minutes)) printf "%d", minutes; else printf "%.2f", minutes }'
    else
        echo "$seconds"
    fi
}

format_supported_formats() {
    local formats="$1"

    if [ -z "$formats" ]; then
        echo "MP4, MOV, WEBM"
        return 0
    fi

    printf '%s' "$formats" \
        | sed -E 's/^\[//; s/\]$//; s/"//g; s/,/, /g; s/[[:space:]]+/ /g; s/^ //; s/ $//'
}

print_if_present() {
    local label="$1"
    local value="$2"

    if [ -n "$value" ]; then
        printf '%s: %s\n' "$label" "$value"
    fi
}

print_warning_title() {
    local title="$1"

    # Use an HTML entity so Markdown renderers show the emoji without UTF-8 mojibake.
    printf '&#9888;&#65039; %s\n' "$title"
}

print_compose_check_rejection() {
    local check_result="$1"
    local reason
    local path
    local supported_input
    local requirement
    local grade_name
    local duration_minutes
    local duration_limit_seconds
    local audio_duration_seconds
    local audio_duration_minutes
    local video_format
    local video_format_from_detail
    local supported_formats
    local supported_formats_from_detail
    local size_bytes
    local size_gb
    local max_size_gb
    local message
    local current_resolution
    local current_ratio
    local supported_ratios
    local supported_resolution
    local credits_left
    local required_credits
    local title
    local check_text
    local check_text_lower

    reason=$(json_value "$check_result" "reason")
    path=$(json_value "$check_result" "path")
    supported_input=$(json_value "$check_result" "supportedInput")
    requirement=$(json_value "$check_result" "requirement")
    grade_name=$(json_value "$check_result" "gradeName")
    duration_minutes=$(json_value "$check_result" "durationMinutes")
    duration_limit_seconds=$(json_value "$check_result" "durationLimitSeconds")
    audio_duration_minutes=$(json_value "$check_result" "audioDurationMinutes")
    audio_duration_seconds=$(json_value "$check_result" "audioDurationSeconds")
    if [ -z "$audio_duration_minutes" ]; then
        audio_duration_minutes=$(format_minutes_from_seconds "$audio_duration_seconds")
    fi
    if [ -z "$duration_minutes" ]; then
        duration_minutes=$(format_minutes_from_seconds "$duration_limit_seconds")
    fi

    video_format_from_detail=$(json_value "$check_result" "currentFormat")
    if [ -z "$video_format_from_detail" ]; then
        video_format_from_detail=$(json_value "$check_result" "currentVideoFormat")
    fi
    if [ -z "$video_format_from_detail" ]; then
        video_format_from_detail=$(json_value "$check_result" "videoFormat")
    fi
    if [ -z "$video_format_from_detail" ]; then
        video_format_from_detail=$(json_value "$check_result" "format")
    fi
    video_format="$video_format_from_detail"
    if [ -z "$video_format" ]; then
        video_format="${VIDEO##*.}"
        if [ "$video_format" = "$VIDEO" ] || [ -z "$video_format" ]; then
            video_format="Unknown"
        fi
    fi
    video_format=$(printf '%s' "$video_format" | tr '[:lower:]' '[:upper:]')

    supported_formats_from_detail=$(json_value "$check_result" "supportedVideoFormats")
    if [ -z "$supported_formats_from_detail" ]; then
        supported_formats_from_detail=$(json_value "$check_result" "supportedFormats")
    fi
    supported_formats=$(format_supported_formats "$supported_formats_from_detail")
    size_bytes=$(json_value "$check_result" "sizeBytes")
    size_gb=$(json_value "$check_result" "sizeGB")
    max_size_gb=$(json_value "$check_result" "maxSizeGB")
    message=$(json_value "$check_result" "message")
    current_resolution=$(json_value "$check_result" "currentResolution")
    current_ratio=$(json_value "$check_result" "currentRatio")
    supported_ratios=$(json_value "$check_result" "supportedRatios")
    supported_resolution=$(json_value "$check_result" "supportedResolution")
    credits_left=$(json_value "$check_result" "creditsLeft")
    required_credits=$(json_value "$check_result" "requiredCredits")

    check_text="$reason $check_result"
    check_text_lower=$(printf '%s' "$check_text" | tr '[:upper:]' '[:lower:]')

    case "$check_text_lower" in
        *audio*duration*|*audio_duration*|*audiodurationseconds*|*audiodurationminutes*|*durationlimitseconds*)
            print_warning_title 'Audio duration exceeds plan limit'
            printf 'Current audio duration: %s minutes\n' "${audio_duration_minutes:-Unknown}"
            printf 'Your %s plan limit: %s minutes\n' "${grade_name:-Unknown}" "${duration_minutes:-Unknown}"
            printf '%s\n' 'To synthesize longer videos, please upgrade your plan: https://newtest.duix.com/dashboard/duix-cli-skills/pricing'
            ;;
        *unsupported*format*|*supportedformats*|*currentformat*)
            print_warning_title 'Unsupported video format'
            printf 'Current video format: %s\n' "$video_format"
            printf 'Supported video formats: %s\n' "$supported_formats"
            printf '%s\n' 'For more format requirements, see: https://github.com/duixcom/duix-skills'
            ;;
        *)
            title="${reason:-Compose check failed}"
            case "$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]')" in
                *input*) title="Unsupported input" ;;
                *size*) title="File size exceeds limit" ;;
                *resolution*) title="Unsupported video resolution" ;;
                *ratio*) title="Unsupported video aspect ratio" ;;
                *credit*) title="Insufficient credits" ;;
                *ffprobe*|*parse*) title="Media parsing failed" ;;
            esac

            print_warning_title "$title"
            print_if_present "Path" "$path"
            print_if_present "Supported input" "$supported_input"
            print_if_present "Requirement" "$requirement"
            print_if_present "Current format" "$video_format_from_detail"
            if [ -n "$supported_formats_from_detail" ]; then
                print_if_present "Supported formats" "$supported_formats"
            fi
            if [ -n "$size_gb" ]; then
                print_if_present "Current size" "$size_gb GB"
            fi
            print_if_present "Current size bytes" "$size_bytes"
            if [ -n "$max_size_gb" ]; then
                print_if_present "Max size" "$max_size_gb GB"
            fi
            print_if_present "Message" "$message"
            print_if_present "Current resolution" "$current_resolution"
            print_if_present "Current ratio" "$current_ratio"
            print_if_present "Supported ratios" "$supported_ratios"
            print_if_present "Supported resolution" "$supported_resolution"
            print_if_present "Credits left" "$credits_left"
            print_if_present "Required credits" "$required_credits"
            ;;
    esac
}
confirm_compose_check() {
    local check_result="$1"
    local can_continue
    local required_credits
    local credits_left
    local answer

    can_continue=$(json_value "$check_result" "canContinue")
    required_credits=$(json_value "$check_result" "requiredCredits")
    credits_left=$(json_value "$check_result" "creditsLeft")

    if [ "$can_continue" != "true" ]; then
        print_compose_check_rejection "$check_result"
        exit 1
    fi

    printf 'Credit Confirmation
This talking-head video generation is estimated to consume %s credits. Current balance: %s credits.
To confirm submission, reply "yes". To cancel, reply "no".
' "${required_credits:-Unknown}" "${credits_left:-Unknown}"
    read -r answer

    case "$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]')" in
        yes|y) ;;
        *)
            log "User cancelled after compose pre-check confirmation"
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

    if credit_result=$(duix-cli compose check --video "$VIDEO" --audio "$AUDIO"); then
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
    echo "Talking-head Video Generated Successfully"
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
    echo "  - Remaining credits: ${credits_left:-Unknown} credits ([Recharge](https://www.duix.com/dashboard/duix-cli-skills/pricing))"
}

print_failure_result() {
    local reason="${1:-Unknown reason}"

    if [ -z "$reason" ]; then
        reason="Unknown reason"
    fi

    echo ""
    echo "Talking-head Video Generation Failed"
    echo ""
    echo "Credit Status: credits have been refunded"
    echo ""
    echo "Failure Reason: $reason (for example: video resolution exceeds the limit / audio format is unsupported / network timeout / model exception)"
    echo ""
    echo "Suggestions:"
    echo "  - For video issues: check whether the video is front-facing, clear, unobstructed, and within the supported resolution range"
    echo "  - For audio issues: confirm the audio format is MP3/WAV and can be played normally"
    echo "  - For network issues: retry later or check the network connection"
    echo "  - For credit issues: go to the [DUIX recharge page](https://www.duix.com/dashboard/duix-cli-skills/pricing) to recharge"
    echo ""
    echo "To retry, confirm the source assets and submit again."
}
check_duix_cli_update() {
    local current_version
    local latest_version

    echo -e "${CYAN}Checking duix-cli version from the official npm registry: $NPM_REGISTRY${NC}"

    if ! command -v npm &> /dev/null; then
        echo -e "${YELLOW}Warning: npm was not found, so the duix-cli latest-version check could not be completed.${NC}"
        echo -e "Install npm and run: $NPM_INSTALL_CMD"
        echo ""
        return 0
    fi

    current_version=$(duix-cli --version 2>/dev/null | grep -oE '[0-9]+(\.[0-9]+){1,2}([-+][0-9A-Za-z.-]+)?' | head -1 || true)
    latest_version=$(npm view duix-cli version --registry="$NPM_REGISTRY" 2>/dev/null || true)

    if [ -z "$current_version" ]; then
        echo -e "${YELLOW}Warning: failed to read the local duix-cli version.${NC}"
        echo -e "Reinstall or update with: $NPM_INSTALL_CMD"
        echo ""
        return 0
    fi

    if [ -z "$latest_version" ]; then
        echo -e "${YELLOW}Warning: failed to query the latest duix-cli version from $NPM_REGISTRY.${NC}"
        echo -e "You can manually check with: npm view duix-cli version --registry=$NPM_REGISTRY"
        echo ""
        return 0
    fi

    if [ "$current_version" != "$latest_version" ]; then
        echo -e "${YELLOW}duix-cli has a newer version available. Please update to the latest version.${NC}"
        echo -e "Current: ${YELLOW}$current_version${NC}"
        echo -e "Latest:  ${GREEN}$latest_version${NC}"
        echo -e "Update:  $NPM_INSTALL_CMD"
        echo ""
    else
        echo -e "${GREEN}duix-cli is up to date: $current_version${NC}"
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
log "[STEP 0] Running compose pre-check..."
CREDIT_CHECK_RESULT=$(run_compose_check "INITIAL")
confirm_compose_check "$CREDIT_CHECK_RESULT"

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
