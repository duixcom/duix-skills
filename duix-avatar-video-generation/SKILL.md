---
name: duix-avatar-video-generation
description: Generate digital human videos using duix-cli. When user provides a video of a person and an audio file, create a task that makes the person in the video speak the audio content. Trigger on phrases like "digital human", "talking head video", "make this person speak", "lip sync video", "duix".
version: 1.2.0
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
duix-cli compose check --video input.mp4 --audio input.wav
```
- Run this before creating a compose task. `compose create` must not be called until this pre-check passes.
- Read `data.canContinue` from the returned JSON. Do not use top-level `ok` as the business decision.
- If `data.canContinue` is not exactly `true`, stop the task without creating a compose task and show one of these strict English templates exactly, preserving every line break. If `data.detail` exists, do not print it as a JSON string; parse its fields and place them into the template lines below. For unsupported video format, read `SUPPORTED_VIDEO_FORMATS` from `data.detail.supportedFormats`.

Non-audio-duration rejection template:

```text
⚠️ Unsupported video format
Current video format: VIDEO_FORMAT
Supported video formats: SUPPORTED_VIDEO_FORMATS
For more format requirements, see: https://github.com/duixcom/duix-skills
```

Audio-duration-limit rejection template:

```text
⚠️ Audio duration exceeds plan limit
Current audio duration: AUDIO_DURATION_MINUTES minutes
Your GRADE_NAME plan limit: DURATION_MINUTES minutes
To synthesize longer videos, please upgrade your plan: https://newtest.duix.com/dashboard/duix-cli-skills/pricing
```
- If `data.canContinue` is `true`, ask the user to confirm explicitly:

```text
Credit Confirmation
This talking-head video generation is estimated to consume XX credits. Current balance: XX credits.
To confirm submission, reply "yes". To cancel, reply "no".
```

Continue only when the user replies `yes`; stop when the user replies `no` or any other value.
Use `data.requiredCredits` for the estimated credits and `data.creditsLeft` for the current balance when `data.canContinue === true`. If `data.canContinue !== true`, use the strict rejection template above. Derive `VIDEO_FORMAT` from `data.detail.currentFormat` or the input video extension; derive `SUPPORTED_VIDEO_FORMATS` from `data.detail.supportedFormats` or default to `MP4, MOV, WEBM`; derive `GRADE_NAME` from `data.detail.gradeName`; derive `DURATION_MINUTES` from `data.detail.durationMinutes` or `data.detail.durationLimitSeconds`; derive `AUDIO_DURATION_MINUTES` from `data.detail.audioDurationSeconds` or `data.audioDurationSeconds`. For other compose-check errors, follow the same English line-based style and print each field on its own line: title line prefixed with `⚠️`, then parse and show relevant `data.detail` fields such as `path`, `supportedInput`, `requirement`, `currentFormat`, `supportedFormats`, `sizeBytes`, `sizeGB`, `maxSizeGB`, `message`, `currentResolution`, `currentRatio`, `supportedRatios`, `supportedResolution`, `creditsLeft`, and `requiredCredits`. Never output raw `data.detail` JSON to the user. Do not collapse these templates into a single line; render each template line as a separate output line.

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
- Compose pre-check with `duix-cli compose check --video <video> --audio <audio>` before task creation
- Explicit user confirmation before credits are consumed
- Task creation and polling
- Download on completion
- Final success/failure messages with task details, output path, and credit status
- Debug logging to output_dir

## Direct CLI Usage

```bash
# Check credits before creating a task
duix-cli compose check --video input.mp4 --audio input.wav

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
Only replace the placeholder values such as `TASK_ID`, `VIDEO_PATH`, `AUDIO_PATH`, `OUTPUT_FILE_MARKDOWN_LINK`, `DURATION_SECONDS`, `REQUIRED_CREDITS`, `CREDITS_LEFT`, and `FAILURE_REASON`. Compose pre-check rejection messages must parse `data.detail` into English template fields and must never expose raw JSON strings to the user.

Success template:

```text
Talking-head Video Generated Successfully

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
Talking-head Video Generation Failed

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
Never show garbled text to the user. If script output starts with the Markdown/HTML entity `&#9888;&#65039;`, render it as the warning emoji `⚠️` in the final user-facing message.
If a value cannot be recovered safely, use `Unknown` for that value while preserving the required template format.

## Pitfalls

- Face must be clearly visible in input video
- Task is async: need to poll status then download
- Status command does NOT auto-download (use download command)
- Logs contain full request/response JSON for debugging

## Version History

| Updated At | Version | Changes |
| --- | --- | --- |
| 2026-07-22 | v1.2.0 | - Update compose pre-check to use both video and audio paths; gate task creation only on data.canContinue === true and surface reason/detail on rejection |
| 2026-07-21 | v1.1.5 | - Force duix-cli version checking against the official npm registry on every skill run and prompt users to update when a newer version is available |
| 2026-07-21 | v1.1.4 | - Add example videos |
| 2026-07-21 | v1.1.3 | - Translated SKILL.md and duix_run.sh user-facing Chinese text into English; changed successful output file display to a local absolute-path Markdown link |
| 2026-07-20 | v1.1.2 | - Added mojibake guard rules requiring final prompts to be re-rendered from templates when terminal output is garbled |
| 2026-07-20 | v1.1.1 | - Strengthened final prompt format requirements for completed compose tasks, requiring strict success/failure template output |
| 2026-07-20 | v1.1.0 | - Added pre-compose credit check and user confirmation; added final success/failure prompt information |
| 2026-07-16 | v1.0.0 | - Initial version with basic lip-sync support |
