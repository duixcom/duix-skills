---
name: duix-avatar-video-generation
description: Generate digital human videos using duix-cli. When user provides a video of a person and an audio file, create a task that makes the person in the video speak the audio content. Trigger on phrases like "digital human", "talking head video", "make this person speak", "lip sync video", "duix".
version: 1.1.0
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

### Step 0: Check Credits and Confirm
```bash
duix-cli compose check -a input.wav
```
- Run this before creating a compose task.
- Read `data.canContinue` from the returned JSON.
- If `data.canContinue` is `false`, stop the task and show:

```text
⚠️ 积分不足
本次任务预计需要 XX 积分，当前账户余额 XX 积分。
请前往 DUIX充值页面（https://www.duix.com/dashboard/duix-cli-skills/overview） 充值后再试。
```

- If `data.canContinue` is `true`, ask the user to confirm explicitly:

```text
💡 积分确认
本次口播视频生成预计消耗 XX 积分，当前余额 XX 积分。
确认提交请回复"是"，取消请回复"否"。
```

Continue only when the user replies `是`; stop when the user replies `否` or any other value.
Use `data.requiredCredits` for the estimated credits and `data.creditsLeft` for the current balance.

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
- On failure, show the final failure block including refunded credit status, the returned failure reason or `未知原因`, and retry suggestions.

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
      <td>2026-07-20</td>
      <td>v1.1.0</td>
      <td>- 增加合成前积分检查与用户确认；补充成功/失败最终提示信息</td>
    </tr>
    <tr>
      <td>2026-07-16</td>
      <td>v1.0.0</td>
      <td>- 初始版本，支持基础唇形同步</td>
    </tr>
  </tbody>
</table>
