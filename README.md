# Duix Skills

[中文](README_zh.md) | English

A collection of Duix skills for AI agents. Each skill provides a focused digital-human workflow, with its own installation guide, usage docs, and helper scripts.

---

## 🤔 Which Skill Should I Use?

Pick the skill that matches your goal:

| Your need | Recommended skill | One-line summary |
| --- | --- | --- |
| Make a portrait speak and chat in realtime | [duix-avatar-conversation](duix-avatar-conversation/README.md) | Upload a portrait → choose a voice → get a conversation webpage link for live chat |
| Lip-sync a person video into a speaking video | [duix-avatar-video-generation](duix-avatar-video-generation/README.md) | Upload a person video + audio → generate a lip-synced MP4 |

💡 **Still unsure?** If you want “an AI digital-human webpage you can talk to”, choose conversation. If you want “a video file of a person speaking”, choose video-generation.

---

## 📊 Skill Comparison

| Item | duix-avatar-conversation | duix-avatar-video-generation |
| --- | --- | --- |
| Core capability | Realtime conversational digital human | Lip-synced speaking-video generation |
| Input | Portrait photo + voice + language | Person video + speech audio |
| Output | Browser conversation link (`conversation_url`) | Local MP4 file path |
| Interaction | Realtime voice / text chat | Pre-generated video, non-interactive |
| Credentials | `DUIX_APP_ID` + `DUIX_APP_KEY` | `DUIX_API_KEY` |
| Billing | Subscription plan (custom quota; 1 creation = 1 count) | Prepaid credits (consumed by task video duration) |
| Production time | About 20 minutes to 2 hours | A few minutes to around 20+ minutes |
| Typical use cases | Smart support, virtual teacher, brand ambassador | Product intro, weekly report video, outreach A/B tests |
| Hard gates | User must pick TTS voice + confirm charge | Asset validation + credit confirmation |

---

## 🚀 Quick Start

### One-Prompt Installation (Recommended)

Send this prompt directly to your agent:

> Please help me install the duix-avatar-conversation and duix-avatar-video-generation skills: clone https://github.com/duixcom/duix-skills into the skills directory, install duix-cli, and configure the required credentials.

### Manual Installation

```bash
# 1. Clone into your agent's skills directory
cd <your-agent-skills-path>
git clone https://github.com/duixcom/duix-skills.git

# 2. Install duix-cli
npm i duix-cli -g --registry=https://registry.npmjs.org/

# 3. Verify installation
duix-cli --version
ls duix-skills/*/README.md
```

> **Agent integration requirement**: Place each skill directory under `duix-skills/` into your agent's skills directory so the agent can discover `*/SKILL.md`.

---

## 📦 Prerequisites

### Environment

| Item | Requirement |
| --- | --- |
| Node.js | ≥ 18 |
| duix-cli | Latest version (auto-checks for updates after install) |
| OS | macOS / Linux / Windows (WSL) |

### Credentials by Skill

| Skill | Required credentials | Where to get them |
| --- | --- | --- |
| duix-avatar-conversation | `DUIX_APP_ID` + `DUIX_APP_KEY` | [API Key management](https://www.duix.com/dashboard/avatar-conversation/apikeys) |
| duix-avatar-video-generation | `DUIX_API_KEY` | [API Key management](https://www.duix.com/dashboard/avatar-video-generation/apikeys) |

💰 **Need to recharge?**

- conversation custom quota: [Pricing page](https://www.duix.com/avatar-conversation/pricing)
- video-generation credits: [Pricing page](https://www.duix.com/dashboard/avatar-video-generation/pricing)

---

## 📖 Skill Details

### duix-avatar-conversation — Realtime Conversational Digital Human

Upload a portrait photo, choose a voice and language, and generate an AI digital human you can chat with in the browser.

**Core flow:**

Portrait photo → select TTS voice (hard gate) → choose language → optional persona → confirm charge (hard gate) → generate → conversation link

**Key features:**

- 🎙️ 40+ languages (default English)
- 🎭 Optional persona: name, greeting, personality description
- 🔒 Dual hard gates: user must manually pick a voice and confirm billing
- 🔄 Custom quota is refunded automatically if generation fails

[Full docs →](duix-avatar-conversation/README.md)

### duix-avatar-video-generation — Lip-Synced Video Generation

Input a person video and speech audio to generate a talking-head video with synced lip motion.

**Core flow:**

Person video + speech audio → asset validation → credit confirmation → generate → MP4 file

**Key features:**

- 🎬 Supports 720P ~ 4K video input
- 🎵 Supports MP3 / WAV / M4A / AAC / FLAC audio
- ⚡ Credits are consumed per task; failures may be refunded
- 📐 Auto-checks aspect ratio (16:9 or 9:16) and face detection

[Full docs →](duix-avatar-video-generation/README.md)

---

## ✅ Compatibility

Skills in this repository target agent environments that support `SKILL.md`:

| Agent environment | Status | Notes |
| --- | --- | --- |
| Codex | ✅ Supported | — |
| Cursor | ✅ Supported | — |
| Claude Code | ✅ Supported | — |
| Copilot | ✅ Supported | — |
| Gemini | ✅ Supported | — |
| OpenClaw | ✅ Supported | — |

Exact compatibility and prerequisites depend on each skill's README.

---

## ❓ FAQ

**Q: Can I install and use both skills at the same time?**
A: Yes. They share the same `duix-cli`, but use different credentials and billing systems, so they do not conflict.

**Q: The agent cannot find the skills after installation. What should I do?**
A: Confirm these files exist under the skills directory:

```text
duix-skills/duix-avatar-conversation/SKILL.md
duix-skills/duix-avatar-conversation/scripts/duix_run.sh
duix-skills/duix-avatar-video-generation/SKILL.md
duix-skills/duix-avatar-video-generation/scripts/duix_run.sh
```

Then ask the agent to reload skills.

**Q: What if `duix-cli` installation fails?**
A: Make sure Node.js is ≥ 18, then install from the official registry:

```bash
npm i duix-cli -g --registry=https://registry.npmjs.org/
```

**Q: Can the two skills share the same credentials?**
A: No.

- `duix-avatar-conversation` needs `DUIX_APP_ID` + `DUIX_APP_KEY`
- `duix-avatar-video-generation` needs `DUIX_API_KEY`

Get them from the corresponding console pages.

**Q: How do I check account balance?**
A:

- conversation custom quota: `duix-cli avatar check`
- video-generation credits: see the balance-check method in each skill's docs

---

## 📁 Repository Layout

```text
duix-skills/
├── README.md             # This document (collection overview)
├── README_zh.md          # Chinese overview
├── LICENSE               # Apache License 2.0
├── duix-avatar-conversation/
│   ├── SKILL.md          # Skill definition (read by agents)
│   ├── README_zh.md      # Chinese usage docs
│   ├── README.md         # English usage docs
│   └── scripts/
│       └── duix_run.sh   # Helper script
└── duix-avatar-video-generation/
    ├── SKILL.md
    ├── README_zh.md
    ├── README.md
    └── scripts/
        └── duix_run.sh
```

---

## 🛠️ Technical Support

- 💬 Email: support@duix.com
- 🐛 Bug reports: please include the skill name, `task_id` (if any), full CLI output, and the steps that led to the error
- 📚 Skill docs: use the links under “Skill Details” above

---

## 📄 License

This repository is licensed under the [Apache License 2.0](LICENSE).
