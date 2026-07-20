---
name: duix-avatar-video-generation
description: Generate digital human videos using duix-cli. When user provides a video of a person and an audio file, create a task that makes the person in the video speak the audio content. Trigger on phrases like "digital human", "talking head video", "make this person speak", "lip sync video", "duix".
version: 1.1.2
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
Use `data.requiredCredits` for the estimated credits and `data.creditsLeft` for the current balance. These two credit prompts are also strict user-facing templates: preserve the exact Chinese text, line breaks, punctuation, and links, and re-render them from the template instead of showing garbled terminal output.

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


## Final User Message Format Requirements

The final message shown to the user after a compose task finishes is a strict contract.
The agent MUST output one of the following templates exactly, preserving the title text, section order, blank lines, indentation, bullet labels, and recharge link.
Do not summarize, translate, reorder, omit fields, rename fields, or append any extra content after the template.
Only replace the placeholder values such as `TASK_ID`, `VIDEO_PATH`, `AUDIO_PATH`, `OUTPUT_FILE`, `DURATION_SECONDS`, `REQUIRED_CREDITS`, `CREDITS_LEFT`, and `FAILURE_REASON`.

Success template:

```text
✔️ 口播视频生成成功

任务详情：
  - 任务ID：TASK_ID
  - 状态：success（成功）
  - 视频：VIDEO_PATH
  - 音频：AUDIO_PATH

输出文件：
  - OUTPUT_FILE
  - 视频时长：DURATION_SECONDS 秒

积分消耗：
  - 本视频消耗：REQUIRED_CREDITS 积分
  - 剩余积分：CREDITS_LEFT 积分（[去充值](https://duix.com/dashboard/duix-cli-skills/overview)）
```

Failure template:

```text
❌ 口播视频生成失败

积分状态：积分已退还

失败原因：FAILURE_REASON（如：视频分辨率超限 / 音频格式不支持 / 网络超时 / 模型异常等）

建议：
  - 若视频问题：请检查视频是否为正脸、清晰、无遮挡，且分辨率在支持范围内
  - 若音频问题：请确认音频格式为 MP3/WAV，且可正常播放
  - 若网络问题：请稍后重试，或检查网络连接
  - 若积分问题：请前往 [DUIX 充值页面](https://duix.com/dashboard/duix-cli-skills/overview) 充值

如需重试，请确认素材后再次提交。
```

If the compose task returns a failure reason, use it as `FAILURE_REASON`; otherwise use `未知原因`.
If final credit lookup fails after a successful compose task, keep the success template and use `未知` for the missing credit or duration fields rather than adding explanatory text after the template.

## Encoding and Mojibake Guard

The final user-facing message MUST be rendered by the agent from the strict templates above, not copied blindly from terminal output if the terminal output is garbled.
If stdout contains mojibake such as `鉁旓笍`, `鍙ｆ挱`, `绉垎`, `瑙嗛`, or similarly broken Chinese, treat it as an encoding artifact.
Recover the actual values from the script output, log file, task JSON, paths, and credit check JSON, then re-render the final message in normal Chinese using the required success or failure template.
Never show garbled Chinese to the user.
If a value cannot be recovered safely, use `未知` for that value while preserving the required template format.

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
      <td>v1.1.2</td>
      <td>- 增加乱码防护规则，要求发现终端输出乱码时重新按中文模板渲染最终提示</td>
    </tr>
    <tr>
      <td>2026-07-20</td>
      <td>v1.1.1</td>
      <td>- 强化合成任务结束后的最终提示词格式要求，要求严格按成功/失败模板输出</td>
    </tr>
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
