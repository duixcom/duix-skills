# duix-avatar-conversation skill

Language: English | [中文](README_zh.md)

A realtime conversational digital-human skill for AI agents: upload a portrait photo, choose a voice and language, and generate a webpage link for realtime interactive AI digital-human chat.

---

## Quick Start

### Option 1: One-Prompt Installation (Recommended)

Send the following prompt directly to your agent. It will complete installation and configuration automatically:

> Please help me install the duix-avatar-conversation skill: clone https://github.com/duixcom/duix-skills into the skills directory, install duix-cli, and configure DUIX_APP_ID and DUIX_APP_KEY. If the environment variables are already set, use them directly; otherwise, prompt me to enter them.

### Option 2: Manual Installation

```bash
# Clone into your agent's skills directory
cd <your-agent-skills-path>
git clone https://github.com/duixcom/duix-skills.git

# Verify the installation
ls duix-skills/duix-avatar-conversation/SKILL.md
duix-skills/duix-avatar-conversation/scripts/duix_run.sh

# Install duix-cli from the official npm registry
npm i duix-cli -g --registry=https://registry.npmjs.org/

# Optional: compare installed version with the official npm package
# Package page: https://www.npmjs.com/package/duix-cli
duix-cli --version
npm view duix-cli version --registry=https://registry.npmjs.org/
```

> **Agent integration requirement**: Place `duix-skills/duix-avatar-conversation` in your agent's skills directory and make sure `duix-avatar-conversation/SKILL.md` is discoverable.

### Configure Credentials

```bash
# macOS / Linux
# Option 1: Environment variables (recommended)
export DUIX_APP_ID="your-app-id"
export DUIX_APP_KEY="your-app-key"

# Option 2: Interactive configuration
./duix-avatar-conversation/scripts/duix_run.sh --config

# Windows PowerShell
# Option 1: Temporary setting
$env:DUIX_APP_ID="your-app-id"
$env:DUIX_APP_KEY="your-app-key"

# Option 2: Persistent setting
setx DUIX_APP_ID "your-app-id"
setx DUIX_APP_KEY "your-app-key"
```

> **No APP ID / APP Key?** Get them from the [API Key management page](https://www.duix.com/dashboard/duix-cli-skills/keys).  
> **Need more custom quota?** Visit the [Pricing page](https://www.duix.com/pricing) to view plans and recharge.

Note: avatar commands do **not** need `DUIX_API_KEY`. Only `DUIX_APP_ID` and `DUIX_APP_KEY` are required.

---

## What's Included

This project mainly includes two core skills:

| Skill | Capability | Input | Output |
| --- | --- | --- | --- |
| `duix-avatar-conversation` | Create a digital-human training task | Portrait photo + voice + language + optional name, greeting, profile | `task_id` (or TTS dropdown first) |
| `duix-get-avatar-create-result` | Query training result and return the conversation link | `task_id` | `conversation_url` |

Key files:

* **Skill definition**: `duix-avatar-conversation/SKILL.md`
* **Execution script**: `duix-avatar-conversation/scripts/duix_run.sh`

---

## How It Works

```plaintext
User intent                                Input assets                Deliverable
   |                                             |                          |
trigger duix-avatar-conversation   portrait + voice + language   conversation webpage link
                                        |
                              +---------------------+
                              | 1. Upload portrait  |
                              | 2. Select TTS voice |
                              |    (hard gate)      |
                              | 3. Choose language  |
                              |    (default English)|
                              | 4. Optional name /  |
                              |    greeting / profile|
                              | 5. Confirm quota    |
                              | 6. Submit generation|
                              | 7. Poll -> success  |
                              +---------------------+
```

Standard agent flow:

1. **Detect intent**: Recognize the user's intent to "create a conversational digital human"
2. **Collect inputs**: Collect the portrait photo, voice preference, language, and optional persona fields
3. **Voice selection**: First `create` returns the TTS list; wait for an explicit user choice (hard gate — never auto-pick)
4. **Quota confirmation**: Call `create` again with the selected voice; wait for the user to confirm custom-quota deduction (hard gate — never auto-confirm)
5. **Submit generation**: After confirmation, resubmit with `--confirm 是` and obtain `task_id`
6. **Poll status**: Call `status` until `conversation_url` is returned
7. **Return result**: Return the conversation link with brief usage notes
8. **Handle failure**: Show the failure reason; custom quota is refunded automatically

---

## Authentication

Before execution, the agent must confirm that authentication is available:

* `DUIX_APP_ID` and `DUIX_APP_KEY` are configured (environment variables or local config)

Recommended confirmation message:

> I will use duix-avatar-conversation to create a realtime conversational digital human.  
> Please provide a portrait photo (16:9 or 9:16), and confirm whether you want a specific voice and language.

---

## Try It Directly

### Prompt Examples

Copy any of these directly into your agent. You must provide a portrait photo path; replace the examples with your actual local file paths:

* Use duix-avatar-conversation to read `demo_avatar.png` from `examples/demo_assets` and create a Chinese conversational digital human.
* Use duix-avatar-conversation to turn `C:\Users\YourName\avatar.png` into an English conversational digital human named "Amy", with the greeting "Hello, nice to meet you!".
* I want to create a product-presenter digital human using https://github.com/duixcom/duix-skills/blob/main/duix-avatar-conversation/examples/assets/demo_face.jpg, speaking Chinese, with a professional customer-support persona.
* Please use https://github.com/duixcom/duix-skills/blob/main/duix-avatar-conversation/examples/assets/demo_face.jpg to create a teaching-assistant digital human in Chinese, with the greeting "Hello class, let's learn something new today".
* Create an interview-style conversational digital human using `C:\Users\YourName\avatar.png`, English chat, named "David", with a warm and natural tone.

Tip:  
Replace `C:\Users\YourName\***` in the examples with an actual path on your computer, such as `D:\images\avatar.png`.  
Replace https://github.com/duixcom/duix-skills/blob/main/duix-avatar-conversation/examples/assets/demo_face.jpg with an image URL you can actually access.

### Typical Business Scenarios

| Scenario | Input | Output | Value |
| --- | --- | --- | --- |
| **Smart customer-service avatar** | Support-agent portrait + professional voice | 24/7 chat webpage | Reduce human support cost |
| **Product presenter** | Brand spokesperson photo + friendly voice | Product intro conversation link | Improve user engagement |
| **Virtual teacher** | Teacher portrait + gentle voice | Teaching-assistant chat page | Personalized Q&A |
| **Brand ambassador** | Unified brand portrait + multilingual voices | Multilingual conversational avatar | Reach global audiences |

---

## Requirements

### Input Asset Requirements

| Item | Requirement |
| --- | --- |
| Image format | PNG, JPG, JPEG, WEBP |
| Image size | Up to 10 MB |
| Image aspect ratio | Must be 16:9 or 9:16 |
| Image content | Clear front-facing portrait, unobstructed face, even lighting |
| Face requirement | Exactly one human face; front-facing, clear, and unobstructed |
| Language | Default English; 40+ languages supported (Chinese, Japanese, Korean, etc.) |
| Custom quota | Creating 1 digital human costs 1 custom count; submission fails when balance is insufficient |

### Environment & Config Checklist

* [ ] Input image meets the format, size, ratio, and face requirements above
* [ ] Agent environment that supports skills, such as Cursor, Codex, or OpenClaw
* [ ] `DUIX_APP_ID` and `DUIX_APP_KEY` configured ([how to get them](https://www.duix.com/dashboard/duix-cli-skills/keys))
* [ ] Account has enough custom quota ([view plans](https://www.duix.com/pricing))

---

## Security Notes

* This skill only processes the local input assets and authentication information you provide
* **Do not expose the full `DUIX_APP_ID` / `DUIX_APP_KEY` in public logs**
* When troubleshooting, share redacted error information first (for example, the first few characters of `task_id`)

---

## FAQ

**Q: The agent cannot find the skill after installation. What should I do?**  
A: Confirm that `duix-avatar-conversation/SKILL.md` and `duix-avatar-conversation/scripts/duix_run.sh` are under the skills directory, and that the agent has reloaded skills.

**Q: It says "DUIX_APP_ID / DUIX_APP_KEY not found". What should I do?**  
A: Check whether the environment variables have taken effect, or rerun `./scripts/duix_run.sh --config` for interactive setup. If you do not have credentials yet, get them from the [API Key management page](https://www.duix.com/dashboard/duix-cli-skills/keys).

**Q: Status stays at `processing`. Is it stuck?**  
A: No. `processing` means generation is in progress and usually takes a few minutes. Keep polling the same `task_id`. Do not create a new task, and do not tell the user the task is stuck.

**Q: Do I need to learn the command line?**  
A: No. You can complete installation, configuration, and usage directly through an agent conversation without manually typing commands.

**Q: Can I query the same `task_id` more than once?**  
A: Yes. `task_id` remains valid permanently. You can run `avatar status <task_id>` anytime, even after a previous successful query.

**Q: It says custom quota is insufficient (`skill_code=40301`). What should I do?**  
A: Your custom quota is used up. Subscribe or recharge on the [Pricing page](https://www.duix.com/pricing), then try again.

**Q: If generation fails, is the custom quota refunded?**  
A: Yes. When digital-human creation fails (`skill_code=500`), the consumed custom quota is automatically returned to your balance.

**Q: Can I edit a digital human after it is created?**  
A: After creation succeeds, the agent tools do not support direct parameter edits (for example changing voice or persona). To adjust voice, language, name, greeting, or profile, use the [duix web workbench](https://newtest.duix.com/dashboard/my-avatar). To change them from the agent tools, create a new digital-human task.

---

## Technical Support

* Contact email: support@duix.com
* Bug reports: please provide `task_id`, the full CLI output log, and the steps that led to the error
