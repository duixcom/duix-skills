---
name: duix-avatar-conversation
description: >-
  Create a realtime conversational AI digital human via duix-cli: upload portrait,
  select TTS voice and language, optionally set name/greetings/profile, confirm
  custom-quota deduction, then generate and return a conversation URL. Use when
  the user asks for realtime conversational avatar, custom digital human, talking
  avatar chat, interactive digital human, 实时对话数字人, 定制数字人对话, or mentions
  duix-avatar-conversation / duix-get-avatar-create-result.
version: 1.2.3
author: duix
compatibility: openclaw, cursor, copilot, claude-code, codex, gemini
tags: [duix, avatar, conversation, realtime, digital-human, chat, tts, duix-cli]
---

# Duix Skills - duix-avatar-conversation

Create a realtime conversational digital human with **duix-cli**, then return a browser `conversation_url`.

All network requests are handled inside duix-cli. Do **not** call platform APIs directly, and do not add request code in this skill.

## When to Use

Use this skill when the user wants a realtime conversational digital human / custom avatar / talking avatar chat.

## Prerequisites

```bash
npm i duix-cli -g --registry=https://registry.npmjs.org/
```

Required environment variables:

```bash
export DUIX_APP_ID="your-app-id"
export DUIX_APP_KEY="your-app-key"
export DUIX_API_KEY="your-skills-api-key"   # needed when uploading a local image to OBS
```

If credentials are missing, help the user configure them before continuing.

---

## Guided Conversation Flow (Mandatory Order)

Guide the user step by step. Do **not** ask for every field at once.  
For optional fields, explicitly tell the user they can skip.

```text
Progress:
- [ ] 1. Upload image
- [ ] 2. Select TTS voice
- [ ] 3. Select language (default English, can skip)
- [ ] 4. Optional persona: name / greetings / profile (each can skip)
- [ ] 5. Confirm custom-quota deduction
- [ ] 6. Confirm submit and start generation
- [ ] 7. Poll result and return conversation link
```

### Step 1: Upload image (required)

Ask the user:

> Please provide a portrait image for the digital human (local file path or a public image URL). Prefer a clear, front-facing face with no obstruction.

Save the value as `coverImageUrl` (local path or `http(s)` URL).  
If the user provides Base64, use `--coverImage` instead. Never pass `--coverImage` and `--coverImageUrl` together.

If there is no image yet, **stop here**. Do not move to voice selection.

### Step 2: Select TTS voice (required)

Call create once without inventing a voice name:

```bash
duix-cli avatar create --coverImageUrl "<image>"
```

The CLI returns a TTS dropdown (`need_select=true` / `select_field=ttsName`).  
Show `data.options` to the user and ask them to pick one.

Prompt:

> Please choose one voice from the list below:

After the user selects, store `--ttsName`.  
**Never invent a TTS name.**

### Step 3: Select language (default English, can skip)

Ask proactively:

> The default speaking language is **English**.  
> To switch, choose one language from the supported list below. To keep the default, reply "skip" or "keep default".

Supported languages (use the exact string as `--language`):

```text
Arabic, Azerbaijani, Belarusian, Bosnian, Bulgarian, Catalan, Chinese,
Croatian, Czech, Danish, Dutch, English, Estonian, Finnish, French,
Galician, German, Greek, Hebrew, Hindi, Hungarian, Indonesian, Italian,
Japanese, Kannada, Kazakh, Korean, Latvian, Lithuanian, Macedonian, Malay,
Nepali, Norwegian, Persian, Polish, Portuguese, Romanian, Russian, Serbian,
Slovak, Slovenian, Spanish, Swedish, Tagalog, Tamil, Thai, Turkish,
Ukrainian, Urdu, Vietnamese
```

- Skip / keep default → `--language English`
- User picks another option → use that exact value from the list (e.g. `Chinese`)
- Do not invent languages outside this list

### Step 4: Optional persona settings (ask proactively; each can skip)

Ask one by one. Every item may be skipped.

**4.1 Name (`name`)**

> Do you want to set a name for the digital human? Reply with the name, or reply "skip".

**4.2 Opening greeting (`greetings`)**

> Do you want to set an opening greeting (the first line spoken when the chat starts)?  
> Reply with the text, or reply "skip".

**4.3 Profile (`profile`)**

> Do you want to add a persona / personality / reply preference?  
> Example: professional support agent, friendly tone, good at product intro.  
> Reply with the description, or reply "skip".

Skipped fields must **not** be passed to the CLI.  
Only include flags for fields the user actually provided.

### Step 5: Confirm custom-quota deduction before submit (required)

Custom-image creation costs **1** custom quota. Check first:

```bash
duix-cli avatar check
```

Rules:

1. `canContinue=false` / `skill_code=40301` → show the payload and **stop**
2. `canContinue=true` → show the confirmation `msg` from CLI (preferred) and wait for explicit approval

If CLI `msg` is missing, use:

> Custom quota confirmation. This digital-human creation will consume 1 custom quota. Current balance: X.  
> Reply "yes" to confirm, or "no" to cancel.

Continue only when the user clearly replies `yes` / `y`.  
`no` or anything else → cancel and end the flow.

### Step 6: Final confirm and start generation

Do one last confirmation:

> Ready to submit. Please confirm:  
> - Image: ...  
> - Voice: ...  
> - Language: ...  
> - Name: ... (or "system default")  
> - Greeting: ... (or "system default")  
> - Profile: ... (or "system default")  
>  
> Reply "confirm" to submit, or "cancel" to abort.

After confirmation, submit immediately:

```bash
duix-cli avatar create \
  --coverImageUrl "<image>" \
  --ttsName "<selected-voice>" \
  --language "<language, default English>" \
  [--name "<optional>"] \
  [--greetings "<optional>"] \
  [--profile "<optional>"]
```

On success, read `data.skillPayload.data.task_id` (or `data.taskId`) and tell the user:

> Submitted. Task ID: xxx. Generation has started. Please wait...

### Step 7: Poll result and return the link

Avatar generation is **asynchronous and often slow**. After `create` succeeds, always poll:

```bash
duix-cli avatar status <task_id> -c --retry-interval 2000 --max-retry-times 30
```

#### How to read status (important)

| `task_status` / signal | Meaning | Agent must do |
| --- | --- | --- |
| `processing` / `skill_code=100` | **Normal in-progress state**. The avatar is still being generated. | **Not stuck.** Keep waiting / keep polling. Tell the user generation is in progress. Do **not** cancel, do **not** recreate the task, do **not** report failure. |
| `finished` / `skill_code=200` | Success | Return `conversation_url` |
| `failed` / `skill_code=500` | Hard failure | Show failure reason |
| `skill_code=408` | Polling attempts exhausted, task may still be running on server | Keep `task_id`, tell user it is still generating, and query again later with the same `task_id` |

#### Anti-stuck rules for agents

1. **`processing` is healthy progress, not a hang.** Long waits (several minutes) are expected for avatar generation.
2. Prefer `avatar status <task_id> -c` so duix-cli polls internally. While it runs, treat the command as a long-running job and wait for it to finish.
3. If you query once and get `processing`, **continue polling the same `task_id`**. Do not start a new `avatar create`.
4. Never tell the user "the task is stuck/frozen/dead" only because status is `processing`.
5. User-facing message while processing:

> The digital human is still generating (`processing`). This can take a few minutes. Please wait — I will keep checking the same task ID: `<task_id>`.

6. Only after `408` should you pause automatic polling. Then say generation may still be running server-side, keep the `task_id`, and offer to check again later.
7. Do not treat slow CLI output / repeated `processing` JSON as a tool failure.

On outcomes:

- Success: return `conversation_url` as the main deliverable, plus the tip
- `408`: keep `task_id` and ask the user whether to query again later
- Failure: show the failure reason (never expose full secrets)

---

## Command Cheat Sheet

| Purpose | Command |
| --- | --- |
| Check custom quota | `duix-cli avatar check` |
| Fetch voices / create | `duix-cli avatar create ...` |
| Query result | `duix-cli avatar status <task_id> -c` |

Common flags:

| Flag | Required? | Notes |
| --- | --- | --- |
| `--coverImageUrl` | One of image / conversation modes | Local path or remote URL (recommended) |
| `--coverImage` | Same | Base64; mutually exclusive with `--coverImageUrl` |
| `--ttsName` | Required at final submit | Must come from dropdown selection |
| `--language` | Optional | Default `English` |
| `--name` | Optional | Avatar name |
| `--greetings` | Optional | Opening greeting |
| `--profile` | Optional | Persona description |

---

## Error Codes (prefer `data.skillPayload`)

| Code | Meaning |
| --- | --- |
| 100 | Processing / needs confirmation / needs TTS select |
| 200 | Success |
| 40001 | Missing or conflicting params |
| 40002 | Invalid image / upload failure |
| 40101 | Auth failure |
| 40301 | Custom quota insufficient |
| 408 | Polling timeout |
| 500 / 50001 | Upstream failure |

---

## Pitfalls

1. Follow this order only: image → voice → language → optional persona → quota confirm → submit confirm → generate  
2. Ask optional fields proactively, and allow "skip"  
3. TTS names must come from the CLI dropdown  
4. For custom images, always run `avatar check` and get explicit quota confirmation before create  
5. **`processing` means "still generating", not stuck** — keep polling the same `task_id`; never recreate or declare failure just because status is `processing`  
6. Never print full secrets  
7. Never reimplement API calls outside duix-cli

## Version History

| Updated At | Version | Changes |
| --- | --- | --- |
| 2026-08-04 | v1.2.3 | Clarify that status=`processing` is normal progress, not a stuck/hung task |
| 2026-08-04 | v1.2.2 | Expand supported speaking languages to the full platform list |
| 2026-08-04 | v1.2.1 | Rewrite SKILL.md in English while keeping guided flow |
| 2026-08-04 | v1.2.0 | Guided flow: image → TTS → language → optional persona → quota confirm → submit → generate |
| 2026-07-31 | v1.1.0 | Align with duix-cli avatar auth and TTS dropdown |
| 2026-07-27 | v1.0.0 | Initial skill |
