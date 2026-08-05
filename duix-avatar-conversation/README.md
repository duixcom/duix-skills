# duix-avatar-conversation skill

Language: English | [中文](README_zh.md)

A realtime conversational digital-human skill for AI agents. It uses **duix-cli** to create an avatar, then returns a browser conversation link.

---

## Quick Start

### One-Prompt Installation

> Please help me install the duix-avatar-conversation skill: clone https://github.com/duixcom/duix-skills into the skills directory, install `duix-cli`, and configure `DUIX_APP_ID` / `DUIX_APP_KEY`.

### Manual Installation

```bash
cd <your-agent-skills-path>
git clone https://github.com/duixcom/duix-skills.git

npm i duix-cli -g --registry=https://registry.npmjs.org/
duix-cli --version
```

### Credentials

```bash
export DUIX_APP_ID="your-app-id"
export DUIX_APP_KEY="your-app-key"

# or
./duix-avatar-conversation/scripts/duix_run.sh --config
```

Avatar commands do **not** need `DUIX_API_KEY`.

---

## What's Included

| Tool | duix-cli command | Output |
| --- | --- | --- |
| `duix-avatar-conversation` | `duix-cli avatar create` | `task_id` (may first return TTS dropdown) |
| `duix-get-avatar-create-result` | `duix-cli avatar status` | `conversation_url` |

All network requests are implemented inside **duix-cli**.

---

## Guided Flow (Agent)

1. Upload portrait image (16:9 or 9:16)  
2. **Select TTS voice (HARD GATE — wait for user; never auto-pick)**  
3. Choose language (default English, can skip)  
4. Optional: name / greetings / profile (each can skip)  
5. Confirm custom-quota deduction  
6. Confirm submit → generate  
7. Poll status → return `conversation_url`

```bash
duix-cli avatar create --coverImageUrl ./face.png
# if need_select=true: STOP, show options, wait for user choice
duix-cli avatar check
duix-cli avatar create --coverImageUrl ./face.png --ttsName <user-selected> --language English [--name ...] [--greetings ...] [--profile ...]
duix-cli avatar status <task_id> -c
```

### Agent must NOT

- Treat `need_select=true` as create success  
- Auto-select `options[0]` or invent `--ttsName`  
- Call `avatar status` before a real `task_id` exists  

See `SKILL.md` → **Agent Hard Rules (MUST)** for full constraints.

---

## Requirements

- `duix-cli` (Bun-based)
- `DUIX_APP_ID` + `DUIX_APP_KEY`
- Portrait image **or** existing conversationId
- Agent environment that supports skills

---

## Technical Support

- support@duix.com
