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

1. Upload portrait → CLI aspect check + imageCheck (format/face)  
2. **Select TTS voice (HARD GATE; offer preview_url when present; never auto-pick)**  
3. Choose language (default English, can skip)  
4. Optional: name / greetings / profile (each can skip)  
5. Confirm custom-quota deduction (if insufficient → https://www.duix.com/pricing)  
6. Confirm submit → generate (`processing`)  
7. Success: conversation info + `conversation_url`; failure: reason + **quota refunded**

```bash
# 1) without voice: imageCheck first, then dropdown (with preview links), then stop
./duix_run.sh run --coverImageUrl ./face.png --language English

# 2) after user selects voice: need_confirm → interactive yes → --yes submit → poll
./duix_run.sh run --coverImageUrl ./face.png --ttsName Echo --language English --name Ada
```

Helper now follows hard gates: stop on `need_select`; on `need_confirm`, ask the user, then submit with `--yes` only after explicit confirmation. Preview `avatar check` never auto-appends `--yes`.

### Agent must NOT

- Treat `need_select=true` / `need_confirm=true` as create success  
- Auto-select `options[0]` or invent `--ttsName`  
- Hide available preview links  
- Call `avatar status` before a real `task_id` exists  
- Skip recharge guidance on 40301, or skip refund notice on failure  

See `SKILL.md` → **Agent Hard Rules (MUST)** for full constraints.

---

## Requirements

- `duix-cli` (Bun-based)
- `DUIX_APP_ID` + `DUIX_APP_KEY`
- Portrait image **or** existing conversationId
- Agent environment that supports skills

---

## Video Upload FAQ

**Q: Upload fails with "The current input has a security risk. Please modify and try again."**  
A: The platform checks the video frame, text, and audio for compliance. Content involving politics, pornography, terrorism, or violence will trigger a security-risk error. This message is most often caused by politically sensitive content. Review and remove the violating parts, then upload again.

**Q: Upload fails with "Please upload a video with a 9:16 / 16:9 aspect ratio."**  
A:
1. Check the video dimensions: right-click the file → **Properties** → **Details**, and look at frame width / frame height. Supported compliant sizes include 720P (720×1280), 1080P (1080×1920), 2K (1440×2560), and 4K (2160×3840). Only **9:16** and **16:9** are accepted.
2. Rule out browser issues: if the ratio is already correct but the error persists, try again in Google Chrome (compatibility issues are common).

**Q: How do I meet the platform aspect-ratio requirement?**  
A: Use CapCut (Jianying) or another video editor: import the original clip, set the canvas to **9:16** or **16:9**, then export a compliant video and upload again.

**Q: The aspect ratio is correct and I already switched browsers — upload still fails. What next?**  
A: This is often a codec problem. Re-export the video in CapCut (or similar) with the video codec set to **H.264**, then try uploading the new file.

---

## Technical Support

- support@duix.com
