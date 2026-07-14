# Digital Human Skill

用于 AI Agent 的数字人口播技能：输入人物视频和音频，输出口型驱动视频。

## 安装

将 `digital-human` 放入 Agent 的 skills 目录并确保可发现 `digital-human/SKILL.md`。  
首次使用前只需完成两件事：

1. 安装 `duix-cli`
2. 配置 `DUIX_API_KEY`

> 本文不展开 CLI 安装细节，重点是 Agent 调用方式。

## 包含内容

本项目主要包含一个核心 skill：

- `digital-human`：视频人物 + 音频 -> 口播视频

关键文件：

- Skill 定义：`digital-human/SKILL.md`
- 执行脚本：`digital-human/scripts/duix_run.sh`

## 工作原理

```text
用户意图                输入素材                    交付结果
   ↓                       ↓                           ↓
触发 digital-human   video + audio + output    生成 MP4 + 返回路径
```

Agent 标准流程：

1. 识别用户“让人物开口说话”意图
2. 收集 `video/audio/output` 三类输入
3. 调用 skill 执行并等待完成
4. 返回结果路径与简短说明
5. 失败时给出可执行重试建议

## 认证方式

Agent 执行前需确认可用认证：

- `DUIX_API_KEY` 已配置（环境变量或本地配置）

推荐确认话术：

> 我将使用 `digital-human` 生成口播视频。  
> 请确认视频路径、音频路径，以及输出目录（可选）。

## 可直接尝试

可直接复制给 Agent 的提示词案例：

- “用 `digital-human` 把 `person.mp4` 和 `voice.wav` 合成口播视频，输出到 `./output`。”
- “我想做一条 30 秒产品介绍视频，让视频里的人按这段音频说话。”
- “请用同一个人物视频，分别用三段不同音频生成 3 个外呼版本。”
- “做一条运营周报视频，语气自然，输出到本地并告诉我最终文件路径。”

典型业务案例：

- 产品介绍口播：发言人视频 + 介绍音频 -> 社媒发布视频
- 周报视频化：复用同一人物视频，按周替换音频
- 外呼 A/B：固定人物视频，批量替换话术音频

## 使用要求

- 可用的人物视频（建议正脸、清晰、无遮挡）
- 可用音频文件（可正常播放）
- 支持 skills 的 Agent 环境（如 Cursor / Codex / OpenClaw 等）

## 安全说明

- 该 skill 仅处理你提供的本地输入素材与认证信息
- 建议不要在公开日志中暴露完整 API Key
- 如需排查，优先分享脱敏后的错误信息