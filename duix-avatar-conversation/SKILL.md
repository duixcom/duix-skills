---
name: duix-avatar-conversation
description: >-
  Create a realtime conversational AI digital human via duix-cli: upload portrait
  (format + face check), select TTS voice (with preview), select language,
  optionally set name/greetings/profile, confirm custom-quota deduction, then
  generate and return conversation info + URL. Use when the user asks for
  realtime conversational avatar, custom digital human, talking avatar chat,
  interactive digital human, 实时对话数字人, 定制数字人对话, or mentions
  duix-avatar-conversation / duix-get-avatar-create-result.
version: 1.2.7
author: duix
compatibility: openclaw, cursor, copilot, claude-code, codex, gemini
tags: [duix, avatar, conversation, realtime, digital-human, chat, tts, duix-cli]
---

# Duix Skills - duix-avatar-conversation

Create a realtime conversational digital human with **duix-cli**, then return conversation info and a browser `conversation_url`.

All network requests are handled inside duix-cli. Do **not** call platform APIs directly, and do not add request code in this skill.

## When to Use

Use this skill when the user wants a realtime conversational digital human / custom avatar / talking avatar chat.

## Prerequisites

```bash
npm i duix-cli -g --registry=https://registry.npmjs.org/
```

Required environment variables (avatar commands):

```bash
export DUIX_APP_ID="your-app-id"
export DUIX_APP_KEY="your-app-key"
```

`DUIX_API_KEY` is **not** required for avatar create/check/status.

If credentials are missing, help the user configure them before continuing.

---

## Agent Hard Rules (MUST)

These rules override convenience. Violating them is a skill failure.

1. **Never skip TTS selection.** Providing only an image is not enough to submit.
2. **Never auto-pick a voice.** Do not choose `options[0]`, a “default”, a guessed name, or any value the user did not explicitly select.
3. **Never invent `--ttsName`.** It must come from CLI dropdown `options[].value` (or `label` only if value is absent) after user choice.
4. **Offer TTS preview when available.** If an option has `preview_url` / `url` / `exampleAudioUrl`, show it and invite the user to listen before choosing.
5. **`need_select` is not success.** If create returns `needSelect=true` / `need_select=true`, generation has **not** started. There is usually **no** `task_id`. Stop and wait for the user.
6. **`need_confirm` is not success.** For custom images, create returns `need_confirm=true` until the user replies 是. Do **not** pass `--confirm 是` / `--yes` unless the user explicitly confirmed.
7. **Never auto-confirm quota deduction.**
8. **Do not call `avatar status` until create returns a real `task_id`.**
9. **Do not pass `--ttsName` on the first create call** unless the user already chose a voice earlier in this conversation.
10. Treat `exitCode=0` + `success=true` carefully: also inspect `need_select` / `need_confirm`. Intermediate soft responses must not be treated as “avatar created”.
11. On `skill_code=40301`, tell the user quota is insufficient and guide them to recharge at `https://www.duix.com/pricing` (or `detail.pricing_url` / `detail.solution`).
12. On status `failed`, always relay both the failure reason **and** that custom quota was refunded.

---

## Guided Conversation Flow (Mandatory Order)

Guide the user step by step. Do **not** ask for every field at once.
For optional fields, explicitly tell the user they can skip.

```text
Progress:
- [ ] 1. Upload image → format + face check (CLI imageCheck)
- [ ] 2. Select TTS voice (offer preview)   ← HARD GATE
- [ ] 3. Select language (default English, can skip)
- [ ] 4. Optional persona: name / greetings / profile (each can skip)
- [ ] 5. Confirm custom-quota deduction
- [ ] 6. Confirm submit and start generation
- [ ] 7. Poll result → conversation info + link (or failure + refund)
```

### Step 1: Upload image (required) + validation

Ask the user:

> Please provide a portrait image for the digital human (local file path or a public image URL). Prefer a clear, front-facing face with no obstruction. Aspect ratio must be **16:9** or **9:16**. Supported formats: jpg / jpeg / png.

Save the value as `coverImageUrl` (local path or `http(s)` URL).
If the user provides Base64, use `--coverImage` instead. Never pass `--coverImage` and `--coverImageUrl` together.

If there is no image yet, **stop here**. Do not move to voice selection.

**What CLI validates (on create, before TTS select):**

1. Local aspect ratio **16:9** or **9:16**
2. Platform **`imageCheck`**: format compliance + face detection

If image validation fails (`skill_code=40002` or imageCheck error):

1. Show the failure reason to the user
2. Ask for a new image
3. Do **not** proceed to TTS / quota / submit
4. Do **not** claim the avatar was created

### Step 2: Select TTS voice (required HARD GATE, with preview)

Call create **once without** `--ttsName` (image is checked first by CLI):

```bash
duix-cli avatar create --coverImageUrl "<image>"
```

#### How to interpret the response

| Signal | Meaning | Required agent action |
| --- | --- | --- |
| Image check failure / `40002` | Portrait invalid | **STOP.** Show reason. Ask for a new image. |
| `data.needSelect=true` **or** `data.skillPayload.need_select=true` | TTS dropdown required; create **not** submitted | **STOP.** Show options (+ preview links). Wait. |
| `data.skillPayload.skill_code=100` and no `task_id` | Intermediate soft state (select / confirm) | Inspect `need_select` / `need_confirm`; do not treat as created |
| `data.taskId` / `data.skillPayload.data.task_id` present | Create actually submitted | Only then proceed to status polling |

When `need_select` is true:

1. Extract `data.options` or `data.skillPayload.data.options`
2. For each option, show `label`/`value`, and if present show **试听** link from `preview_url` / `url` / `exampleAudioUrl`
3. Ask the user to listen (when a link exists) and then pick one
4. Wait for an explicit user reply that maps to one option
5. Only then store `--ttsName <selected option value>`
6. Do **not** proceed to language/persona/quota/submit until this is done

Prompt:

> Please choose one voice from the list below. Where a preview link is shown, you can open it to listen first. Reply with the voice name/number. I cannot choose for you.

**Forbidden in this step:**

- Auto-selecting any option to “save a turn”
- Re-running create with a guessed `--ttsName` before the user answers
- Telling the user “generation started” after a `need_select` response
- Jumping to `avatar status`
- Hiding available preview URLs from the user

### Step 3: Select language (default English, can skip)

Ask proactively **only after TTS is selected**:

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

### Step 5: Confirm custom-quota deduction before submit (required HARD GATE)

Custom-image creation costs **1** custom quota.
After TTS is selected, call create with all fields **except** `--confirm`:

```bash
duix-cli avatar create \
  --coverImageUrl "<image>" \
  --ttsName "<user-selected-voice>" \
  --language "<language, default English>" \
  [--name "<optional>"] \
  [--greetings "<optional>"] \
  [--profile "<optional>"]
```

#### How to interpret the response

| Signal | Meaning | Required agent action |
| --- | --- | --- |
| `data.needConfirm=true` **or** `data.skillPayload.need_confirm=true` | Quota confirm required; create **not** submitted | **STOP.** Show `msg` to the user. Wait for 是/否. |
| `skill_code=40301` / insufficient quota | Cannot continue | Show msg + **recharge link** (`https://www.duix.com/pricing` or `detail.pricing_url`) and stop |
| `task_id` present | Already submitted (should only happen with `--confirm 是`) | Proceed to status |

When `need_confirm` is true:

1. Show CLI `msg` (preferred), e.g.
   `💡 定制次数确认 本次数字人对话生成需消耗 1 次定制次数，当前余额 X 次。确认提交请回复"是"，取消请回复"否"。`
2. Wait for explicit user reply
3. User says 是 / yes / y → continue to Step 6 with `--confirm 是` (or `--yes`)
4. User says 否 / no / n → cancel and end. Optionally call create once with `--confirm 否`
5. **Never auto-confirm** to save a turn

When `40301`:

> 定制次数不足，无法继续创建。请前往 https://www.duix.com/pricing 订阅/充值后再试。

You may still run `duix-cli avatar check` for an early balance preview, but **create’s `need_confirm` is the hard gate**.

### Step 6: Final summary and submit with `--confirm`

Show a short summary, then submit **only after** the user confirmed quota (Step 5):

> Ready to submit. Please confirm:
> - Image: ...
> - Voice: ... (must be the voice you chose)
> - Language: ...
> - Name: ... (or "system default")
> - Greeting: ... (or "system default")
> - Profile: ... (or "system default")
> - Quota: consume 1 custom count (user already replied 是)
>
> Submitting now...

```bash
duix-cli avatar create \
  --coverImageUrl "<image>" \
  --ttsName "<user-selected-voice>" \
  --language "<language, default English>" \
  --confirm 是 \
  [--name "<optional>"] \
  [--greetings "<optional>"] \
  [--profile "<optional>"]
```

Equivalently: `--yes` instead of `--confirm 是`.

On success, read `data.skillPayload.data.task_id` (or `data.taskId`) and tell the user:

> Submitted. Task ID: xxx. The digital human is being generated (`processing`). Please wait...

If create still returns `need_confirm`, confirmation was missing — show the message again and **do not** claim submission succeeded.
If it returns `need_select`, voice was missing/invalid — go back to Step 2.
If it returns `40301`, go to recharge guidance and stop.

### Step 7: Poll result and return conversation info / failure

Avatar generation is **asynchronous and often slow**. After `create` succeeds **with a task_id**, always poll:

```bash
duix-cli avatar status <task_id> -c --retry-interval 2000 --max-retry-times 30
```

#### How to read status (important)

| `task_status` / signal | Meaning | Agent must do |
| --- | --- | --- |
| `processing` / `skill_code=100` | **Normal in-progress state**. The avatar is still being generated. | **Not stuck.** Keep waiting / keep polling. Tell the user generation is in progress. Do **not** cancel, do **not** recreate the task, do **not** report failure. |
| `finished` / `skill_code=200` | Success | Return full conversation deliverable (below) |
| `failed` / `skill_code=500` | Hard failure | Show failure reason **and** that custom quota was **refunded** |
| `skill_code=408` | Polling attempts exhausted, task may still be running on server | Keep `task_id`, tell user it is still generating, and query again later with the same `task_id` |

Note: `skill_code=100` is reused for TTS select / quota confirm / processing. Always check `need_select`, `need_confirm`, and `task_status` / `task_id` before deciding what 100 means.

#### Anti-stuck rules for agents

1. **`processing` is healthy progress, not a hang.** Long waits (several minutes) are expected for avatar generation.
2. Prefer `avatar status <task_id> -c` so duix-cli polls internally. While it runs, treat the command as a long-running job and wait for it to finish.
3. If you query once and get `processing`, **continue polling the same `task_id`**. Do not start a new `avatar create`.
4. Never tell the user "the task is stuck/frozen/dead" only because status is `processing`.
5. User-facing message while processing:

> The digital human is still generating (`processing`). This can take a few minutes. Please wait — I will keep checking the same task ID: `<task_id>`.

6. Only after `408` should you pause automatic polling. Then say generation may still be running server-side, keep the `task_id`, and offer to check again later.
7. Do not treat slow CLI output / repeated `processing` JSON as a tool failure.

#### Success deliverable (required)

Return **all** of the following when available (prefer `data.skillPayload.data`):

- `conversation_url` — primary link; user opens it for realtime chat
- `conversation_id`
- `name` / `cover_image` / `model_scene_id` when present
- `consume_detail` (custom times used / remain) when present
- `tip` (e.g. chatting will continue to consume duration quota)

User-facing success message should include the link and invite the user to open it for realtime interaction.

#### Failure deliverable (required)

When `failed`:

1. Show the failure reason from `msg` / payload
2. Explicitly tell the user: **定制次数已退还** (custom quota was refunded)
3. Do not invent a new create unless the user asks to retry with a new image/voice

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
| `--coverImageUrl` | One of image / conversation modes | Local path or remote URL; local is converted to Base64 by CLI |
| `--coverImage` | Same | Base64; mutually exclusive with `--coverImageUrl` |
| `--ttsName` | Required at **final** submit only | Must be user-selected from dropdown; never auto-filled |
| `--confirm` / `--yes` | Required for custom-image final submit | `--confirm 是` or `--yes` only after user quota confirmation |
| `--language` | Optional | Default `English` |
| `--name` | Optional | Avatar name |
| `--greetings` | Optional | Opening greeting |
| `--profile` | Optional | Persona description |

---

## Error Codes (prefer `data.skillPayload`)

| Code | Meaning |
| --- | --- |
| 100 | Soft intermediate: TTS select / quota confirm / processing — inspect flags |
| 200 | Success |
| 40001 | Missing or conflicting params |
| 40002 | Invalid image / aspect ratio / face check / upload failure |
| 40101 | Auth failure |
| 40301 | Custom quota insufficient — guide recharge at https://www.duix.com/pricing |
| 408 | Polling timeout |
| 500 / 50001 | Upstream failure (on create status fail, also say quota refunded) |

---

## Pitfalls

1. Follow this order only: image (+ check) → **user TTS select (with preview)** → language → optional persona → quota confirm → submit → generate
2. Ask optional fields proactively, and allow "skip"
3. TTS names must come from the CLI dropdown **and the user's explicit choice** — never auto-pick
4. `need_select=true` means stop; it is not “create succeeded”
5. For custom images, create returns `need_confirm=true` until user replies 是; only then re-run with `--confirm 是` / `--yes` — never auto-confirm
6. **`processing` means "still generating", not stuck** — keep polling the same `task_id`; never recreate or declare failure just because status is `processing`
7. On failure, always mention **定制次数已退还**
8. On 40301, always provide the pricing/recharge link
9. Never print full secrets
10. Never reimplement API calls outside duix-cli

## For Automation Authors (`duix_run.sh` / scripts)

Canonical create loop:

```text
create (image only, no --ttsName) → imageCheck → need_select=true → STOP
create (--ttsName, no --yes) → need_confirm=true → STOP, ask user 是/否
create (--ttsName --yes) → task_id → status -c
  → finished: conversation_url + info
  → failed: reason + quota refunded
```

Rules:

1. **`need_select`** means you must already have an **explicit user-chosen** `ttsName` before the next create. Never auto-pick `options[0]`. Show `preview_url` when present.
2. **`need_confirm`** means non-interactive scripts **must not** pre-pass `--yes`. Trigger one create without `--confirm`, show the platform confirm message, then only after the user answers 是 submit again with `--yes`.
3. `avatar check` is an **early preview** only. Passing preview confirmation must never auto-append `--yes` to create.
4. Helper script reference: `scripts/duix_run.sh run --coverImageUrl <path> --ttsName <user-selected> ...`

## Version History

| Updated At | Version | Changes |
| --- | --- | --- |
| 2026-08-05 | v1.2.7 | Align business flow: imageCheck before TTS; TTS preview URLs; recharge + refund + full success deliverable |
| 2026-08-05 | v1.2.6 | Fix `duix_run.sh` helper: handle `need_confirm`, full options, summary, 40301; add automation notes |
| 2026-08-05 | v1.2.5 | Create hard-gates custom quota confirm (`need_confirm` → `--confirm 是` / `--yes`) |
| 2026-08-05 | v1.2.4 | Harden TTS gate: forbid auto-select; clarify `need_select` is not success; avatar no longer needs `DUIX_API_KEY` |
| 2026-08-04 | v1.2.3 | Clarify that status=`processing` is normal progress, not a stuck/hung task |
| 2026-08-04 | v1.2.2 | Expand supported speaking languages to the full platform list |
| 2026-08-04 | v1.2.1 | Rewrite SKILL.md in English while keeping guided flow |
| 2026-08-04 | v1.2.0 | Guided flow: image → TTS → language → optional persona → quota confirm → submit → generate |
| 2026-07-31 | v1.1.0 | Align with duix-cli avatar auth and TTS dropdown |
| 2026-07-27 | v1.0.0 | Initial skill |
