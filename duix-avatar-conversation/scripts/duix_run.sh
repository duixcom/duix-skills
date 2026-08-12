#!/usr/bin/env bash
# Digital Human Conversation - Duix Run Script
# Aligns with SKILL.md hard gates:
#   create → need_select (stop) → create → need_confirm (stop) → create --yes → status
#
# Usage:
#   ./duix_run.sh --config
#   ./duix_run.sh check
#   ./duix_run.sh create [options]
#   ./duix_run.sh run [options]          # end-to-end helper
#   ./duix_run.sh status <task_id> [-c]
#   ./duix_run.sh <coverImageUrl> [language]   # legacy helper shorthand
#
# Options for create/run:
#   --coverImageUrl <path|url>
#   --coverImage <base64>
#   --conversationId <id>
#   --ttsName <name>
#   --language <lang>      default: English
#   --name <name>
#   --greetings <text>
#   --profile <text>
#   --yes / --confirm 是   # only after user confirmed quota (helper will prompt)

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
COVER_IMAGE_URL=""
COVER_IMAGE=""
CONVERSATION_ID=""
TTS_NAME=""
LANGUAGE="English"
NAME=""
GREETINGS=""
PROFILE=""

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
      DUIX_API_KEY=*|DUIX_APP_ID=*|DUIX_APP_KEY=*)
        key="${line%%=*}"
        value="${line#*=}"
        value="${value%\"}"
        value="${value#\"}"
        value="${value%\'}"
        value="${value#\'}"
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
    echo -e "${YELLOW}未检测到创建对话数字人所需的凭证。请先在命令行设置 DUIX_APP_ID 和 DUIX_APP_KEY，然后重新运行。${NC}" >&2
    echo "" >&2
    echo "macOS / Linux:" >&2
    echo 'export DUIX_APP_ID="your-app-id"' >&2
    echo 'export DUIX_APP_KEY="your-app-key"' >&2
    echo "" >&2
    echo "Windows PowerShell（当前窗口）：" >&2
    echo '$env:DUIX_APP_ID="your-app-id"' >&2
    echo '$env:DUIX_APP_KEY="your-app-key"' >&2
    echo "" >&2
    echo "Windows PowerShell（永久设置；请在新窗口中重新打开终端后使用）：" >&2
    echo 'setx DUIX_APP_ID "your-app-id"' >&2
    echo 'setx DUIX_APP_KEY "your-app-key"' >&2
    echo "" >&2
    echo "获取 DUIX_APP_ID 和 DUIX_APP_KEY：http://duix.com/dashboard/avatar-conversation/apikeys" >&2
    exit 1
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
  $0 create [options]
  $0 run [options]                 # end-to-end: preview check → create gates → status
  $0 status <task_id> [-c] [...]
  $0 <coverImageUrl> [language]    # legacy shorthand for: run --coverImageUrl ... --language ...

Options:
  --coverImageUrl <path|url>
  --coverImage <base64>            mutually exclusive with --coverImageUrl
  --conversationId <id>            required when no image is provided
  --ttsName <name>                 required before final submit; never auto-filled
  --language <lang>                default: English
  --name <name>
  --greetings <text>
  --profile <text>

Hard gates (do not bypass):
  1) need_select  → stop, ask user to pick TTS, re-run with --ttsName
  2) need_confirm → stop, ask user 是/否, then re-submit WITH --yes
  Never auto-pass --yes without an interactive user confirmation in this script.

Examples:
  $0 run --coverImageUrl ./face.png --language English
  $0 run --coverImageUrl ./face.png --ttsName Echo --language English --name Ada
  $0 create --coverImageUrl ./face.png --ttsName Echo --language English
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

# Return 0 if any of the given JSON fields equals "true".
json_flag_true() {
  local json="$1"
  shift
  local field value
  for field in "$@"; do
    value=$(json_value "$json" "$field")
    if [ "$value" = "true" ]; then
      return 0
    fi
  done
  return 1
}

ask_yes_no() {
  local prompt="$1"
  local answer
  if [ -n "$prompt" ]; then
    printf '%s\n' "$prompt"
  fi
  read -r answer
  case "$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]')" in
    yes|y|是) return 0 ;;
    *) return 1 ;;
  esac
}

ensure_duix_cli() {
  if command -v duix-cli >/dev/null 2>&1; then
    return 0
  fi

  if ! command -v npm >/dev/null 2>&1; then
    echo -e "${RED}未找到 duix-cli，也无法使用 npm 安装它。请先安装 Node.js 和 npm 后重试。${NC}" >&2
    exit 1
  fi

  echo -e "${CYAN}正在从 npm 官方源安装最新版本的 duix-cli...${NC}" >&2
  if ! npm i duix-cli -g --registry="$NPM_REGISTRY" >&2; then
    echo -e "${RED}duix-cli 安装失败。请检查网络连接和 npm 权限后重试。${NC}" >&2
    exit 1
  fi

  if ! command -v duix-cli >/dev/null 2>&1; then
    echo -e "${RED}duix-cli 已安装，但当前终端尚未找到它。请重新打开终端后再试。${NC}" >&2
    exit 1
  fi
}

check_duix_cli_update() {
  local current_version
  local latest_version

  echo -e "${CYAN}正在通过 npm 官方源检查 duix-cli 版本...${NC}" >&2

  if ! command -v npm >/dev/null 2>&1; then
    echo -e "${RED}未找到 npm，无法确认 duix-cli 是否为最新版本。请先安装 npm 后重试。${NC}" >&2
    exit 1
  fi

  current_version=$(duix-cli --version 2>/dev/null | grep -oE '[0-9]+(\.[0-9]+){1,2}([-+][0-9A-Za-z.-]+)?' | head -1 || true)
  latest_version=$(npm view duix-cli version --registry="$NPM_REGISTRY" 2>/dev/null || true)

  if [ -z "$current_version" ] || [ -z "$latest_version" ]; then
    echo -e "${RED}无法完成 duix-cli 版本检查。请检查网络连接后重试。${NC}" >&2
    exit 1
  fi

  if [ "$current_version" != "$latest_version" ]; then
    echo -e "${CYAN}正在升级 duix-cli 到最新版本...${NC}" >&2
    if ! npm i duix-cli -g --registry="$NPM_REGISTRY" >&2; then
      echo -e "${RED}duix-cli 升级失败。请检查网络连接和 npm 权限后重试。${NC}" >&2
      exit 1
    fi

    current_version=$(duix-cli --version 2>/dev/null | grep -oE '[0-9]+(\.[0-9]+){1,2}([-+][0-9A-Za-z.-]+)?' | head -1 || true)
    if [ "$current_version" != "$latest_version" ]; then
      echo -e "${RED}duix-cli 未能升级到最新版本。请重新打开终端后再试。${NC}" >&2
      exit 1
    fi
  else
    echo -e "${GREEN}duix-cli 已是最新版本（$current_version）。${NC}" >&2
  fi
}

# Parse shared create/run options into globals. Consumes "$@".
parse_create_options() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --coverImageUrl)
        COVER_IMAGE_URL="${2:-}"; shift 2 || true ;;
      --coverImage)
        COVER_IMAGE="${2:-}"; shift 2 || true ;;
      --conversationId)
        CONVERSATION_ID="${2:-}"; shift 2 || true ;;
      --ttsName)
        TTS_NAME="${2:-}"; shift 2 || true ;;
      --language)
        LANGUAGE="${2:-English}"; shift 2 || true ;;
      --name)
        NAME="${2:-}"; shift 2 || true ;;
      --greetings)
        GREETINGS="${2:-}"; shift 2 || true ;;
      --profile)
        PROFILE="${2:-}"; shift 2 || true ;;
      --yes|--confirm)
        # Intentionally ignored as inbound auto-flag.
        # Helper will only append --yes after interactive user confirmation.
        if [ "$1" = "--confirm" ]; then
          shift 2 || true
        else
          shift
        fi
        echo -e "${YELLOW}Note: ignoring inbound --yes/--confirm. Helper will ask interactively before final submit.${NC}" >&2
        ;;
      -h|--help)
        usage; exit 0 ;;
      *)
        echo -e "${RED}Unknown option: $1${NC}" >&2
        usage
        exit 1
        ;;
    esac
  done
}

validate_create_inputs() {
  if [ -n "$COVER_IMAGE" ] && [ -n "$COVER_IMAGE_URL" ]; then
    echo -e "${RED}请只提供一种人像输入方式：图片路径/网址或 Base64 图片。${NC}" >&2
    exit 1
  fi
  if [ -z "$COVER_IMAGE" ] && [ -z "$COVER_IMAGE_URL" ] && [ -z "$CONVERSATION_ID" ]; then
    echo -e "${RED}请提供一张人像图片，或已有的 conversationId。${NC}" >&2
    exit 1
  fi
}

# Build and run: duix-cli avatar create ...
# Pass "1" to append --yes after interactive user confirmation only.
run_create_once() {
  local with_yes="${1:-0}"
  local -a args
  args=(duix-cli avatar create)

  if [ -n "$COVER_IMAGE_URL" ]; then
    args+=(--coverImageUrl "$COVER_IMAGE_URL")
  fi
  if [ -n "$COVER_IMAGE" ]; then
    args+=(--coverImage "$COVER_IMAGE")
  fi
  if [ -n "$CONVERSATION_ID" ]; then
    args+=(--conversationId "$CONVERSATION_ID")
  fi
  if [ -n "$TTS_NAME" ]; then
    args+=(--ttsName "$TTS_NAME")
  fi
  if [ -n "$LANGUAGE" ]; then
    args+=(--language "$LANGUAGE")
  fi
  if [ -n "$NAME" ]; then
    args+=(--name "$NAME")
  fi
  if [ -n "$GREETINGS" ]; then
    args+=(--greetings "$GREETINGS")
  fi
  if [ -n "$PROFILE" ]; then
    args+=(--profile "$PROFILE")
  fi
  if [ "$with_yes" = "1" ]; then
    args+=(--yes)
  fi

  echo -e "${CYAN}$ ${args[*]}${NC}" >&2
  "${args[@]}" 2>&1
}

print_next_command_after_tts_select() {
  echo -e "${YELLOW}HARD STOP: TTS selection required. Create was NOT submitted.${NC}"
  echo -e "${YELLOW}Do not auto-pick a voice. Ask the user to choose, then re-run:${NC}"
  printf '  %s run' "$0"
  if [ -n "$COVER_IMAGE_URL" ]; then
    printf ' --coverImageUrl %q' "$COVER_IMAGE_URL"
  fi
  if [ -n "$COVER_IMAGE" ]; then
    printf ' --coverImage %q' "$COVER_IMAGE"
  fi
  if [ -n "$CONVERSATION_ID" ]; then
    printf ' --conversationId %q' "$CONVERSATION_ID"
  fi
  printf ' --ttsName <user-selected>'
  printf ' --language %q' "$LANGUAGE"
  if [ -n "$NAME" ]; then
    printf ' --name %q' "$NAME"
  fi
  if [ -n "$GREETINGS" ]; then
    printf ' --greetings %q' "$GREETINGS"
  fi
  if [ -n "$PROFILE" ]; then
    printf ' --profile %q' "$PROFILE"
  fi
  printf '\n'
}

print_submit_summary() {
  echo -e "${CYAN}即将提交数字人创建任务：${NC}"
  if [ -n "$COVER_IMAGE_URL" ]; then
    echo "  - 图片: $COVER_IMAGE_URL"
  elif [ -n "$COVER_IMAGE" ]; then
    echo "  - 图片: (Base64 coverImage)"
  else
    echo "  - 图片: (无，使用 conversationId)"
  fi
  echo "  - 声音: ${TTS_NAME:-未选择}"
  echo "  - 语言: ${LANGUAGE:-English}"
  echo "  - 名称: ${NAME:-系统默认}"
  echo "  - 开场白: ${GREETINGS:-系统默认}"
  echo "  - 人设: ${PROFILE:-系统默认}"
  if [ -n "$COVER_IMAGE_URL" ] || [ -n "$COVER_IMAGE" ]; then
    echo "  - 扣费: 1 次定制次数（用户已确认）"
  fi
}

print_image_remediation() {
  local issue="$1"

  echo -e "${YELLOW}无法使用这张人像图片：${issue}${NC}" >&2
  echo "是否要使用大模型将图片处理为符合要求的版本？可处理为 JPG/PNG、10 MB 以内，并裁剪为 16:9 或 9:16；处理前会保留清晰、正脸且无遮挡的人像。回复“是”即可处理，或提供另一张图片。" >&2
}

handle_create_errors() {
  local json="$1"
  local skill_code success ok exit_code message lower_message

  # TTS selection and quota confirmation are expected intermediate responses.
  if json_flag_true "$json" need_select needSelect need_confirm needConfirm; then
    return 0
  fi

  skill_code=$(json_value "$json" "skill_code")
  if [ -z "$skill_code" ]; then
    skill_code=$(json_value "$json" "code")
  fi
  success=$(json_value "$json" "success")
  ok=$(json_value "$json" "ok")
  exit_code=$(json_value "$json" "exitCode")
  message=$(json_value "$json" "reason")
  if [ -z "$message" ]; then
    message=$(json_value "$json" "message")
  fi
  if [ -z "$message" ]; then
    message=$(json_value "$json" "msg")
  fi
  lower_message=$(printf '%s' "$message" | tr '[:upper:]' '[:lower:]')

  if [ "$skill_code" = "40301" ]; then
    echo -e "${RED}定制次数不足，暂时无法创建数字人。${NC}" >&2
    echo "请前往充值或订阅：https://www.duix.com/pricing" >&2
    return 1
  fi

  if [ "$skill_code" = "40002" ] || [[ "$lower_message" == *image* ]] || [[ "$lower_message" == *format* ]] || [[ "$lower_message" == *ratio* ]] || [[ "$lower_message" == *face* ]] || [[ "$lower_message" == *图片* ]] || [[ "$lower_message" == *人脸* ]]; then
    case "$lower_message" in
      *format*|*格式*) print_image_remediation "图片格式不受支持" ;;
      *size*|*large*|*mb*|*大小*) print_image_remediation "图片文件过大" ;;
      *ratio*|*aspect*|*比例*) print_image_remediation "图片比例不是 16:9 或 9:16" ;;
      *face*|*人脸*) print_image_remediation "请使用清晰、正脸且无遮挡的单人照片" ;;
      *) print_image_remediation "图片未通过素材检查" ;;
    esac
    return 1
  fi

  if [ "$skill_code" = "40101" ] || [[ "$lower_message" == *auth* ]] || [[ "$lower_message" == *credential* ]]; then
    echo -e "${RED}无法验证账户凭证。请确认 DUIX_APP_ID 和 DUIX_APP_KEY 设置正确后重试。${NC}" >&2
    return 1
  fi

  if [ "$skill_code" = "500" ] || [ "$skill_code" = "50001" ] || [[ "$lower_message" == *timeout* ]] || [[ "$lower_message" == *network* ]]; then
    echo -e "${RED}服务暂时无法完成本次创建。请稍后重试，并检查网络连接。${NC}" >&2
    return 1
  fi

  if [ "$skill_code" = "100" ] || [ "$skill_code" = "200" ]; then
    return 0
  fi

  if [ "$success" = "false" ] || [ "$ok" = "false" ] || { [ -n "$exit_code" ] && [ "$exit_code" != "0" ]; } || [ -n "$skill_code" ]; then
    echo -e "${RED}暂时无法创建数字人。请检查图片和账户设置后重试。${NC}" >&2
    return 1
  fi

  if [ -n "$json" ] && [[ "$json" != *"{"* ]]; then
    echo -e "${RED}暂时无法创建数字人。请检查网络连接后重试。${NC}" >&2
    return 1
  fi

  return 0
}

# Preview only: block when quota is already insufficient.
# Do NOT treat this interactive answer as create --yes.
preview_quota_check() {
  local check_json
  local can_continue
  local remain
  local msg

  if [ -z "$COVER_IMAGE_URL" ] && [ -z "$COVER_IMAGE" ]; then
    return 0
  fi

  echo -e "${CYAN}[STEP 0] Preview custom quota (early check only)...${NC}"
  if ! check_json=$(duix-cli avatar check 2>&1); then
    echo -e "${RED}暂时无法查询定制次数，请检查网络连接后重试。${NC}" >&2
    exit 1
  fi

  can_continue=$(json_value "$check_json" "canContinue")
  remain=$(json_value "$check_json" "currentRemain")
  msg=$(json_value "$check_json" "msg")

  if [ "$can_continue" != "true" ]; then
    if ! handle_create_errors "$check_json"; then
      exit 1
    fi
    echo -e "${RED}暂时无法确认定制次数，请稍后重试。${NC}" >&2
    exit 1
  fi

  if [ -n "$msg" ]; then
    printf '%s\n' "$msg"
  else
    printf '预检：本次定制预计消耗 1 次，当前余额 %s 次。\n' "${remain:-未知}"
  fi

  echo -e "${YELLOW}注意：这只是预检。正式提交时 create 仍会返回 need_confirm，必须再次由用户确认后才会加 --yes。${NC}"
  if ! ask_yes_no "预检通过，是否继续进入创建流程？回复 是/否"; then
    echo "数字人创建任务已取消。"
    exit 0
  fi
}

extract_task_id() {
  local json="$1"
  local task_id
  task_id=$(json_value "$json" "task_id")
  if [ -z "$task_id" ]; then
    task_id=$(json_value "$json" "taskId")
  fi
  printf '%s\n' "$task_id"
}

run_avatar_check() {
  local check_json
  local can_continue

  if ! check_json=$(duix-cli avatar check 2>&1); then
    echo -e "${RED}暂时无法查询定制次数，请检查网络连接后重试。${NC}" >&2
    return 1
  fi

  can_continue=$(json_value "$check_json" "canContinue")
  if [ "$can_continue" = "false" ]; then
    if ! handle_create_errors "$check_json"; then
      return 1
    fi
    echo -e "${RED}定制次数不足，暂时无法创建数字人。${NC}" >&2
    echo "请前往充值或订阅：https://www.duix.com/pricing" >&2
    return 1
  fi
  if ! handle_create_errors "$check_json"; then
    return 1
  fi

  echo "$check_json"
}

run_avatar_status() {
  local status_json
  local task_status

  if ! status_json=$(duix-cli avatar status "$@" 2>&1); then
    echo -e "${RED}暂时无法查询生成进度，请检查网络连接后重试。${NC}" >&2
    return 1
  fi

  task_status=$(json_value "$status_json" "task_status")
  if [ "$task_status" = "failed" ]; then
    echo -e "${RED}数字人生成失败，定制次数已退还。请检查素材后重试。${NC}" >&2
    return 1
  fi
  if ! handle_create_errors "$status_json"; then
    return 1
  fi

  echo "$status_json"
}

# Full create flow with hard gates. Optionally poll status when POLL_STATUS=1.
run_create_flow() {
  local poll_status="${1:-0}"
  local create_json
  local task_id
  local confirm_msg
  local has_custom_image=0

  validate_create_inputs

  if [ -n "$COVER_IMAGE_URL" ] || [ -n "$COVER_IMAGE" ]; then
    has_custom_image=1
  fi

  # Gate 1: TTS select
  if [ "$has_custom_image" = "1" ] && [ -z "$TTS_NAME" ]; then
    echo -e "${CYAN}[STEP 1] Fetching TTS options (no --ttsName yet)...${NC}"
    create_json=$(run_create_once 0)
    if ! handle_create_errors "$create_json"; then
      exit 1
    fi
    echo "$create_json"

    if json_flag_true "$create_json" need_select needSelect; then
      print_next_command_after_tts_select
      exit 2
    fi

    # Unexpected: custom image without ttsName but no need_select
    task_id=$(extract_task_id "$create_json")
    if [ -n "$task_id" ]; then
      echo -e "${YELLOW}Warning: got task_id without explicit --ttsName. Continuing cautiously.${NC}" >&2
    else
      echo -e "${RED}Expected need_select when --ttsName is missing, but none was returned.${NC}" >&2
      exit 1
    fi
  else
    echo -e "${CYAN}[STEP 1] Creating avatar (without --yes first)...${NC}"
    create_json=$(run_create_once 0)
    if ! handle_create_errors "$create_json"; then
      exit 1
    fi
    echo "$create_json"

    if json_flag_true "$create_json" need_select needSelect; then
      print_next_command_after_tts_select
      exit 2
    fi
  fi

  # Gate 2: quota confirm for custom image
  if [ "$has_custom_image" = "1" ] && json_flag_true "$create_json" need_confirm needConfirm; then
    echo -e "${YELLOW}HARD STOP: Quota confirmation required. Create was NOT submitted.${NC}"
    confirm_msg=$(json_value "$create_json" "msg")
    if [ -z "$confirm_msg" ]; then
      confirm_msg='💡 定制次数确认
本次数字人对话生成需消耗 1 次定制次数。
确认提交请回复"是"，取消请回复"否"。'
    fi

    if ! ask_yes_no "$confirm_msg"; then
      echo "数字人创建任务已取消。"
      # Optional: notify CLI of cancel
      duix-cli avatar create \
        ${COVER_IMAGE_URL:+--coverImageUrl "$COVER_IMAGE_URL"} \
        ${COVER_IMAGE:+--coverImage "$COVER_IMAGE"} \
        ${TTS_NAME:+--ttsName "$TTS_NAME"} \
        ${LANGUAGE:+--language "$LANGUAGE"} \
        --confirm 否 >/dev/null 2>&1 || true
      exit 0
    fi

    print_submit_summary
    echo -e "${CYAN}[STEP 2] User confirmed. Submitting with --yes...${NC}"
    create_json=$(run_create_once 1)
    if ! handle_create_errors "$create_json"; then
      exit 1
    fi
    echo "$create_json"

    if json_flag_true "$create_json" need_confirm needConfirm; then
      echo -e "${RED}仍需要确认定制次数。请重新确认后再试。${NC}" >&2
      exit 1
    fi
    if json_flag_true "$create_json" need_select needSelect; then
      print_next_command_after_tts_select
      exit 2
    fi
  fi

  task_id=$(extract_task_id "$create_json")
  if [ -z "$task_id" ]; then
    echo -e "${RED}暂时无法提交创建任务。请检查图片和账户设置后重试。${NC}" >&2
    if json_flag_true "$create_json" need_select needSelect; then
      print_next_command_after_tts_select
      exit 2
    fi
    if json_flag_true "$create_json" need_confirm needConfirm; then
      echo -e "${YELLOW}仍在等待定制次数确认。请确认后重新提交。${NC}" >&2
      exit 2
    fi
    exit 1
  fi

  echo -e "${GREEN}Task created: $task_id${NC}"
  if [ "$poll_status" = "1" ]; then
    echo -e "${CYAN}[STEP 3] Polling status...${NC}"
    run_avatar_status "$task_id" -c
  else
    echo "Next: $0 status $task_id -c"
  fi
}

############################
# Entrypoint
############################

# Global early flags that may appear before subcommand.
ARGS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --config)
      set_config
      exit 0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done
set -- "${ARGS[@]}"

if [ $# -lt 1 ]; then
  usage
  exit 0
fi

ensure_duix_cli
check_duix_cli_update
ensure_credentials

CMD="$1"
shift || true

case "$CMD" in
  check)
    run_avatar_check
    ;;
  create)
    parse_create_options "$@"
    # create subcommand: same hard gates, but do not auto-poll unless user asks later
    preview_quota_check
    run_create_flow 0
    ;;
  run)
    parse_create_options "$@"
    preview_quota_check
    run_create_flow 1
    ;;
  status|result|get-result)
    run_avatar_status "$@"
    ;;
  --coverImageUrl|--coverImage|--conversationId|--ttsName|--language|--name|--greetings|--profile)
    # Allow: ./duix_run.sh --coverImageUrl ./a.png --ttsName Echo ...
    parse_create_options "$CMD" "$@"
    preview_quota_check
    run_create_flow 1
    ;;
  *)
    # Legacy shorthand: <coverImageUrl> [language]
    COVER_IMAGE_URL="$CMD"
    if [ $# -gt 0 ]; then
      LANGUAGE="$1"
    fi
    preview_quota_check
    run_create_flow 1
    ;;
esac
