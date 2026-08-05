# duix-avatar-conversation skill

Language: English | [中文](README_zh.md)

A realtime conversational digital-human skill for AI agents. It uses **duix-cli** to create an avatar, then returns a browser conversation link.

---

## Quick Start

### One-Prompt Installation

> Please help me install the duix-avatar-conversation skill: clone https://github.com/duixcom/duix-skills into the skills directory, install `duix-cli`, and configure `DUIX_APP_ID` / `DUIX_APP_KEY` (plus `DUIX_API_KEY` if local image upload is needed).

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
export DUIX_API_KEY="your-skills-api-key"   # needed for local --coverImageUrl upload

# or
./duix-avatar-conversation/scripts/duix_run.sh --config
```

---

## What's Included

| Tool | duix-cli command | Output |
| --- | --- | --- |
| `duix-avatar-conversation` | `duix-cli avatar create` | `task_id` (may first return TTS dropdown) |
| `duix-get-avatar-create-result` | `duix-cli avatar status` | `conversation_url` |

All network requests are implemented inside **duix-cli**.

---

## Guided Flow (Agent)

1. Upload portrait image  
2. Select TTS voice (from CLI dropdown)  
3. Choose language (default English, can skip)  
4. Optional: name / greetings / profile (each can skip)  
5. Confirm custom-quota deduction  
6. Confirm submit → generate  
7. Poll status → return `conversation_url`

```bash
duix-cli avatar create --coverImageUrl ./face.png
# select TTS, then:
duix-cli avatar check
duix-cli avatar create --coverImageUrl ./face.png --ttsName <selected> --language English [--name ...] [--greetings ...] [--profile ...]
duix-cli avatar status <task_id> -c
```

---

## Requirements

- `duix-cli` (Bun-based)
- `DUIX_APP_ID` + `DUIX_APP_KEY`
- `DUIX_API_KEY` when uploading local images
- Portrait image **or** existing conversationId
- Agent environment that supports skills

---

## Technical Support

- support@duix.com
