#!/usr/bin/env bash
# Digital Human Conversation - Duix Run Script
# Usage:
#   ./duix_run.sh --config
#   ./duix_run.sh check
#   ./duix_run.sh create --coverImageUrl <path|url> [--ttsName ...] [options]
#   ./duix_run.sh create --coverImage <base64> [--ttsName ...] [options]
#   ./duix_run.sh create --conversationId <id> [--ttsName ...] [options]
#   ./duix_run.sh status <task_id> [-c]
#   ./duix_run.sh <coverImageUrl> [language]   # check → create (may need TTS select) → status

set -e

export LANG="${LANG:-C.UTF-8}"
export LC_ALL="${LC_ALL:-C.UTF-8}"
if command -v chcp.com >/dev/null 2>&1; then
  chcp.com 65001 >/dev/null 2>&1 || true
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

CONFIG_FILE="$HOME/.duixrc"
NPM_REGISTRY="https://registry.npmjs.org/"
NPM_INSTALL_CMD="npm i duix-cli -g --registry=$NPM_REGISTRY"

load_config() {
  if [ ! -f "$CONFIG_FILE" ]; then
    return 0
  fi

  while IFS= read -r line || [ -n "$line" ]; do
    line=$(printf '%s' "$line" | tr -d '\r')
    case "$line" in
      ''|\#*) continue ;;
    esac
    case "$line" in
      DUIX_API_KEY=*|DUIX_APP_ID=*|DUIX_APP_KEY=*|DUIX_API_KEY=*)
        key="${line%%=*}"
        value="${line#*=}"
        value="${value%\"}"
        value="${value#\"}"
        value="${value%\'}"
        value="${value#\'}"
        # Legacy alias: DUIX_API_KEY → DUIX_API_KEY
        if [ "$key" = "DUIX_API_KEY" ] && [ -z "${DUIX_API_KEY:-}" ]; then
          export DUIX_API_KEY="$value"
        else
          export "$key=$value"
        fi
        ;;
    esac
  done < "$CONFIG_FILE"
}

save_config() {
  local api_key2="$1"
  local app_id="$2"
  local app_key="$3"

  {
    echo "DUIX_API_KEY=\"$api_key2\""
    echo "DUIX_APP_ID=\"$app_id\""
    echo "DUIX_APP_KEY=\"$app_key\""
  } > "$CONFIG_FILE"
  chmod 600 "$CONFIG_FILE" 2>/dev/null || true
  echo -e "${GREEN}Credentials saved to $CONFIG_FILE${NC}"
}

set_config() {
  echo -e "${CYAN}=== Duix Avatar Conversation Configuration ===${NC}"
  echo "DUIX_APP_ID / DUIX_APP_KEY are required for avatar JWT auth."
  echo "DUIX_API_KEY is optional and not required for avatar commands."
  echo ""

  local app_id app_key api_key2
  read -r -p "DUIX_APP_ID> " app_id
  read -r -p "DUIX_APP_KEY> " app_key
  read -r -p "DUIX_API_KEY (optional)> " api_key2

  if [ -z "$app_id" ] || [ -z "$app_key" ]; then
    echo -e "${RED}Error: DUIX_APP_ID and DUIX_APP_KEY cannot be empty${NC}"
    exit 1
  fi

  save_config "${api_key2:-}" "$app_id" "$app_key"
  export DUIX_APP_ID="$app_id"
  export DUIX_APP_KEY="$app_key"
  if [ -n "$api_key2" ]; then
    export DUIX_API_KEY="$api_key2"
  fi
}

mask_secret() {
  local value="$1"
  if [ -z "$value" ]; then
    printf '%s' "(empty)"
    return
  fi
  if [ "${#value}" -le 8 ]; then
    printf '%s' "***"
    return
  fi
  printf '%s***%s' "${value:0:4}" "${value: -4}"
}

ensure_credentials() {
  load_config

  if [ -z "${DUIX_APP_ID:-}" ] || [ -z "${DUIX_APP_KEY:-}" ]; then
    echo -e "${YELLOW}Avatar credentials were not detected.${NC}"
    echo -e "Usage: $0 --config"
    set_config
  fi

  echo -e "DUIX_APP_ID: ${GREEN}$(mask_secret "$DUIX_APP_ID")${NC}" >&2
  echo -e "DUIX_APP_KEY: ${GREEN}$(mask_secret "$DUIX_APP_KEY")${NC}" >&2
  if [ -n "${DUIX_API_KEY:-}" ]; then
    echo -e "DUIX_API_KEY: ${GREEN}$(mask_secret "$DUIX_API_KEY")${NC}" >&2
  else
    echo -e "${YELLOW}DUIX_API_KEY: (not set; not required for avatar commands)${NC}" >&2
  fi
}

usage() {
  cat <<EOF
Usage:
  $0 --config
  $0 check
  $0 create --coverImageUrl <path|url> [--ttsName <name>] [options]
  $0 create --coverImage <base64> [--ttsName <name>] [options]
  $0 create --conversationId <id> [--ttsName <name>] [options]
  $0 status <task_id> [-c] [--retry-interval 2000] [--max-retry-times 30]
  $0 <coverImageUrl> [language]

create options:
  --ttsName <name>       User-selected voice from dropdown (required on final submit; never auto-fill)
  --name <name>
  --greetings <text>
  --profile <text>
  --language <lang>      default: English

Notes:
  First create without --ttsName may return need_select=true (exit 2 in helper mode).
  That is NOT success — wait for the user to choose a voice, then create again.

Examples:
  $0 --config
  $0 check
  $0 create --coverImageUrl ./face.png --language English
  $0 create --coverImageUrl ./face.png --ttsName <selected> --language English
  $0 create --conversationId 1983775419508027393 --ttsName <selected>
  $0 status 1983775419508027393 -c
EOF
}

json_value() {
  local json="$1"
  local field="$2"
  local value

  if command -v jq >/dev/null 2>&1; then
    value=$(printf '%s' "$json" \
      | jq -r --arg field "$field" '.. | objects | select(has($field)) | .[$field] | select(. != null) | tostring' 2>/dev/null \
      | head -1)
    if [ -n "$value" ] && [ "$value" != "null" ]; then
      printf '%s\n' "$value"
      return 0
    fi
  fi

  printf '%s\n' "$json" \
    | sed -nE "s/.*\"$field\"[[:space:]]*:[[:space:]]*(\"[^\"]*\"|true|false|null|-?[0-9]+(\.[0-9]+)?).*/\1/p" \
    | head -1 \
    | sed -E "s/^\"//; s/\"$//"
}

check_duix_cli_update() {
  local current_version
  local latest_version

  echo -e "${CYAN}Checking duix-cli version from: $NPM_REGISTRY${NC}" >&2

  if ! command -v npm >/dev/null 2>&1; then
    echo -e "${YELLOW}Warning: npm was not found, skip version check.${NC}" >&2
    return 0
  fi

  current_version=$(duix-cli --version 2>/dev/null | grep -oE '[0-9]+(\.[0-9]+){1,2}([-+][0-9A-Za-z.-]+)?' | head -1 || true)
  latest_version=$(npm view duix-cli version --registry="$NPM_REGISTRY" 2>/dev/null || true)

  if [ -z "$current_version" ] || [ -z "$latest_version" ]; then
    echo -e "${YELLOW}Warning: failed to compare duix-cli versions.${NC}" >&2
    return 0
  fi

  if [ "$current_version" != "$latest_version" ]; then
    echo -e "${YELLOW}duix-cli has a newer version available.${NC}" >&2
    echo -e "Current: ${YELLOW}$current_version${NC}  Latest: ${GREEN}$latest_version${NC}" >&2
    echo -e "Update: $NPM_INSTALL_CMD" >&2
  else
    echo -e "${GREEN}duix-cli is up to date: $current_version${NC}" >&2
  fi
}

confirm_quota() {
  local check_json="$1"
  local can_continue
  local remain
  local msg
  local answer

  can_continue=$(json_value "$check_json" "canContinue")
  remain=$(json_value "$check_json" "currentRemain")
  msg=$(json_value "$check_json" "msg")

  if [ "$can_continue" != "true" ]; then
    echo "$check_json"
    exit 1
  fi

  if [ -n "$msg" ]; then
    printf '%s\n' "$msg"
  else
    printf '定制次数确认. 本次数字人对话生成需消耗 1 次定制次数，当前余额 %s 次。确认提交请回复'\''是'\''，取消请回复'\''否'\''。\n' "${remain:-未知}"
  fi

  read -r answer
  case "$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]')" in
    yes|y|是) ;;
    *)
      echo "数字人创建任务已取消。"
      exit 0
      ;;
  esac
}

if [ "$1" = "--config" ]; then
  set_config
  exit 0
fi

if [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ $# -lt 1 ]; then
  usage
  exit 0
fi

if ! command -v duix-cli >/dev/null 2>&1; then
  echo -e "${RED}Error: duix-cli not found. Install: $NPM_INSTALL_CMD${NC}"
  exit 1
fi

check_duix_cli_update
ensure_credentials

CMD="$1"
shift || true

case "$CMD" in
  check)
    exec duix-cli avatar check
    ;;
  create)
    exec duix-cli avatar create "$@"
    ;;
  status|result|get-result)
    exec duix-cli avatar status "$@"
    ;;
  *)
    # End-to-end helper: <coverImageUrl> [language]
    IMAGE_URL="$CMD"
    LANGUAGE="${1:-English}"

    echo -e "${CYAN}[STEP 0] Checking custom quota...${NC}"
    CHECK_JSON=$(duix-cli avatar check)
    echo "$CHECK_JSON"
    confirm_quota "$CHECK_JSON"

    echo -e "${CYAN}[STEP 1] Creating avatar task (TTS select may be required)...${NC}"
    CREATE_JSON=$(duix-cli avatar create --coverImageUrl "$IMAGE_URL" --language "$LANGUAGE")
    echo "$CREATE_JSON"

    NEED_SELECT=$(json_value "$CREATE_JSON" "need_select")
    if [ "$NEED_SELECT" = "true" ] || [ "$NEED_SELECT" = "needSelect" ]; then
      NEED_SELECT=$(json_value "$CREATE_JSON" "needSelect")
    fi
    if [ "$(json_value "$CREATE_JSON" "needSelect")" = "true" ] || [ "$(json_value "$CREATE_JSON" "need_select")" = "true" ]; then
      echo -e "${YELLOW}HARD STOP: TTS selection required. Create was NOT submitted.${NC}"
      echo -e "${YELLOW}Do not auto-pick a voice. Show options to the user, then re-run with their choice:${NC}"
      echo "  $0 create --coverImageUrl \"$IMAGE_URL\" --ttsName <user-selected> --language \"$LANGUAGE\""
      echo "Then:"
      echo "  $0 status <task_id> -c"
      exit 2
    fi

    TASK_ID=$(json_value "$CREATE_JSON" "task_id")
    if [ -z "$TASK_ID" ]; then
      TASK_ID=$(json_value "$CREATE_JSON" "taskId")
    fi

    if [ -z "$TASK_ID" ]; then
      echo -e "${RED}Failed to extract task_id (maybe TTS selection is still required).${NC}"
      exit 1
    fi

    echo -e "${GREEN}Task created: $TASK_ID${NC}"
    echo -e "${CYAN}[STEP 2] Polling status...${NC}"
    exec duix-cli avatar status "$TASK_ID" -c
    ;;
esac
