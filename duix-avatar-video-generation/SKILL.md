---
name: duix-avatar-video-generation
description: Generate digital human videos using duix-cli. When user provides a video of a person and an audio file, create a task that makes the person in the video speak the audio content. Trigger on phrases like "digital human", "talking head video", "make this person speak", "lip sync video", "duix".
version: 1.0.0
author: duix
compatibility: openclaw, cursor, copilot, claude-code,codex,hermes
tags: [video, ai, lip-sync, dub, video generation,avatar,digital human,ai-video]
---

# duix-avatar-video-generation - 数字人视频生成

Generate talking-head videos using duix-cli. Takes a video of a person and an audio file, produces a video where the person appears to speak the audio content.

## Prerequisites

1. Install bun runtime:
```bash
npm install -g bun
```

2. Install duix-cli from the official npm registry:
```bash
npm i duix-cli -g --registry=https://registry.npmjs.org/
```

3. Optional: verify the installed version against the official npm registry:
```bash
duix-cli --version
npm view duix-cli version --registry=https://registry.npmjs.org/
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

## 版本记录

<table border="0">
  <thead>
    <tr>
      <th>更新时间</th>
      <th>版本号</th>
      <th>更新内容</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>2026-07-16</td>
      <td>v1.0.0</td>
      <td>- 初始版本，支持基础唇形同步</td>
    </tr>
  </tbody>
</table>
