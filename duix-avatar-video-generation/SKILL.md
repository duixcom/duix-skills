---
name: duix-avatar-video-generation
description: Generate digital human videos using duix-cli. When user provides a video of a person and an audio file, create a task that makes the person in the video speak the audio content. Trigger on phrases like "digital human", "talking head video", "make this person speak", "lip sync video", "duix".
version: 1.1.5
author: duix
compatibility: openclaw, cursor, copilot, claude-code,codex,hermes
tags: [duix,video, ai, lip-sync, dub, video-generation, avatar, digital-human, ai-video]
---

# Duix Skills - duix-avatar-video-generation

Generate talking-head videos using duix-cli. Takes a video of a person and an audio file, produces a video where the person appears to speak the audio content.

## When to Use  
- User asks to generate a digital human / talking-head video  
- User provides a video of a person and an audio file, wanting the person to speak the audio  
- User mentions phrases like "digital human", "talking head video", "make this person speak", "lip sync video", "duix"  

## Prerequisites

1. Install bun runtime:
```bash
npm install -g bun
```

2. Install duix-cli from the official npm registry:
```bash
npm i duix-cli -g --registry=https://registry.npmjs.org/
```

3. Version check: every skill run checks the local duix-cli version against the official npm registry. If a newer version is available, the user is prompted to update to the latest version:
```bash
duix-cli --version
npm view duix-cli version --registry=https://registry.npmjs.org/
```

4. Configure API Key:
```bash
# Pass the key directly
./scripts/duix_run.sh --config <your_api_key>

# Or enter it interactively
./scripts/duix_run.sh --config
```
The configuration is saved in `~/.duixrc` and can be edited manually.

Priority: environment variable > `~/.duixrc` file

## Workflow

### Step 0: Check Credits and Confirm
```bash
duix-cli compose check -a input.wav
```
- Run this before creating a compose task.
- Read `data.canContinue` from the returned JSON.
- If `data.canContinue` is `false`, stop the task and show:

```text
⚠️ Insufficient Credits
This task is estimated to require XX credits. Current account balance: XX credits.
Please go to the DUIX recharge page (https://www.duix.com/dashboard/duix-cli-skills/pricing), recharge, and try again.
```

- If `data.canContinue` is `true`, ask the user to confirm explicitly:

```text
💡 Credit Confirmation
This talking-head video generation is estimated to consume XX credits. Current balance: XX credits.
To confirm submission, reply "yes". To cancel, reply "no".
```

Continue only when the user replies `yes`; stop when the user replies `no` or any other value.
Use `data.requiredCredits` for the estimated credits and `data.creditsLeft` for the current balance. These two credit prompts are also strict user-facing templates: preserve the exact English text, line breaks, punctuation, and links, and re-render them from the template instead of showing garbled terminal output.

### Step 1: Create Task
```bash
duix-cli compose create --video input.mp4 --audio input.wav --output ./result
```
- Uploads video and audio to cloud
- Returns taskId with PENDING status

### Step 2: Poll Status
```bash
duix-cli compose status <task_id>
```
- Status: PENDING -> RUNNING -> SUCCEEDED/FAILED
- Progress: 0-100%
- Returns outputUrl when SUCCEEDED

### Step 3: Download Result
```bash
duix-cli compose download <task_id>
```
- Downloads video to output directory
- File name: `{remote_id}-{task_id}.mp4`

## Using Script (Recommended)

```bash
./scripts/duix_run.sh <video> <audio> [output_dir]
```

Example:
```bash
./scripts/duix_run.sh person.mp4 voice.wav ./output
```

Script handles:
- Forced duix-cli latest-version check against the official npm registry on every run
- API Key auto-loading from ~/.duixrc
- Credit check with `duix-cli compose check -a <audio>` before task creation
- Explicit user confirmation before credits are consumed
- Task creation and polling
- Download on completion
- Final success/failure messages with task details, output path, and credit status
- Debug logging to output_dir

## Direct CLI Usage

```bash
# Check credits before creating a task
duix-cli compose check -a input.wav

# Create task
duix-cli compose create --video input.mp4 --audio input.wav

# Check status
duix-cli compose status <task_id>

# List all tasks
duix-cli compose status ls

# Download result
duix-cli compose download <task_id>
```

## Parameters

- `--video <path>`: Input video (person to animate)
- `--audio <path>`: Input audio (speech content)
- `--output <path>`: Output directory (optional)

## Output

- File format: MP4
- File name: `{remote_id}-{task_id}.mp4`
- Logs: `duix_run_<timestamp>.log` in output directory
- On success, show the final task detail block including task ID, success status, video path, audio path, output file, video duration, consumed credits, and remaining credits.
- On success, the output file MUST be shown as a local absolute path. Prefer a Markdown link whose visible label is the local absolute path and whose target opens the video file.
- On failure, show the final failure block including refunded credit status, the returned failure reason or `Unknown reason`, and retry suggestions.

## Final User Message Format Requirements

The final message shown to the user after a compose task finishes is a strict contract.
The agent MUST output one of the following templates exactly, preserving the title text, section order, blank lines, indentation, bullet labels, and recharge link.
Do not summarize, translate, reorder, omit fields, rename fields, or append any extra content after the template.
Only replace the placeholder values such as `TASK_ID`, `VIDEO_PATH`, `AUDIO_PATH`, `OUTPUT_FILE_MARKDOWN_LINK`, `DURATION_SECONDS`, `REQUIRED_CREDITS`, `CREDITS_LEFT`, and `FAILURE_REASON`.

Success template:

```text
✔️ Talking-head Video Generated Successfully

Task Details:
  - Task ID: TASK_ID
  - Status: success (succeeded)
  - Video: VIDEO_PATH
  - Audio: AUDIO_PATH

Output File:
  - OUTPUT_FILE_MARKDOWN_LINK
  - Video Duration: DURATION_SECONDS seconds

Credit Usage:
  - Credits consumed by this video: REQUIRED_CREDITS credits
  - Remaining credits: CREDITS_LEFT credits ([Recharge](https://www.duix.com/dashboard/duix-cli-skills/pricing))
```

Failure template:

```text
❌ Talking-head Video Generation Failed

Credit Status: credits have been refunded

Failure Reason: FAILURE_REASON (for example: video resolution exceeds the limit / audio format is unsupported / network timeout / model exception)

Suggestions:
  - For video issues: check whether the video is front-facing, clear, unobstructed, and within the supported resolution range
  - For audio issues: confirm the audio format is MP3/WAV and can be played normally
  - For network issues: retry later or check the network connection
  - For credit issues: go to the [DUIX recharge page](https://www.duix.com/dashboard/duix-cli-skills/pricing) to recharge

To retry, confirm the source assets and submit again.
```

If the compose task returns a failure reason, use it as `FAILURE_REASON`; otherwise use `Unknown reason`.
If final credit lookup fails after a successful compose task, keep the success template and use `Unknown` for the missing credit or duration fields rather than adding explanatory text after the template.

## Encoding and Mojibake Guard

The final user-facing message MUST be rendered by the agent from the strict templates above, not copied blindly from terminal output if the terminal output is garbled.
If stdout contains broken or unreadable text caused by character encoding issues, treat it as an encoding artifact.
Recover the actual values from the script output, log file, task JSON, paths, and credit check JSON, then re-render the final message in normal English using the required success or failure template.
Never show garbled text to the user.
If a value cannot be recovered safely, use `Unknown` for that value while preserving the required template format.

## Pitfalls

- Face must be clearly visible in input video
- Task is async: need to poll status then download
- Status command does NOT auto-download (use download command)
- Logs contain full request/response JSON for debugging

## Version History

| Updated At | Version | Changes |
| --- | --- | --- |
| 2026-07-21 | v1.1.5 | - Force duix-cli version checking against the official npm registry on every skill run and prompt users to update when a newer version is available |
| 2026-07-21 | v1.1.4 | - Add example videos |
| 2026-07-21 | v1.1.3 | - Translated SKILL.md and duix_run.sh user-facing Chinese text into English; changed successful output file display to a local absolute-path Markdown link |
| 2026-07-20 | v1.1.2 | - Added mojibake guard rules requiring final prompts to be re-rendered from templates when terminal output is garbled |
| 2026-07-20 | v1.1.1 | - Strengthened final prompt format requirements for completed compose tasks, requiring strict success/failure template output |
| 2026-07-20 | v1.1.0 | - Added pre-compose credit check and user confirmation; added final success/failure prompt information |
| 2026-07-16 | v1.0.0 | - Initial version with basic lip-sync support |
