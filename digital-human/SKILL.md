---
name: digital-human
description: Generate digital human videos using duix-cli. When user provides a video of a person and an audio file, create a task that makes the person in the video speak the audio content. Trigger on phrases like "digital human", "talking head video", "make this person speak", "lip sync video", "duix".
---

# Digital Human - 数字人视频生成

Generate talking-head videos using duix-cli. Takes a video of a person and an audio file, produces a video where the person appears to speak the audio content.

## Prerequisites

1. Configure npm mirror (China):
```bash
npm config set registry https://registry.npmmirror.com
```

2. Install bun runtime:
```bash
npm install -g bun
```

3. Install duix-cli:
```bash
npm i duix-cli -g
```

4. Configure API Key:
```bash
# 直接传参
./scripts/duix_run.sh --config <your_api_key>

# 或交互式输入
./scripts/duix_run.sh --config
```
配置保存在 `~/.duixrc`，可手动编辑。

优先级: 环境变量 > ~/.duixrc 文件

## Workflow

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
- Status: PENDING → RUNNING → SUCCEEDED/FAILED
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
- API Key auto-loading from ~/.duixrc
- Task creation and polling
- Download on completion
- Debug logging to output_dir

## Direct CLI Usage

```bash
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

## Pitfalls

- Face must be clearly visible in input video
- Task is async: need to poll status then download
- Status command does NOT auto-download (use download command)
- Logs contain full request/response JSON for debugging
