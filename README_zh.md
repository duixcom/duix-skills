# Duix Skills

中文 | [English](README.md)

面向 AI Agent 的 Duix Skill 集合。每个 Skill 提供一个聚焦的数字人工作流，包含独立的安装说明、使用指南和交互脚本。

---

## 🤔 我应该用哪个 Skill？

根据你的需求，快速选择对应的 Skill：

| 你的需求 | 推荐 Skill | 一句话说明 |
| --- | --- | --- |
| 让人物照片开口说话，实时对话交互 | [duix-avatar-conversation](duix-avatar-conversation/README_zh.md) | 上传人像 → 选音色 → 生成对话网页链接，打开即可实时聊天 |
| 让人物视频对口型，生成口播视频 | [duix-avatar-video-generation](duix-avatar-video-generation/README_zh.md) | 上传人物视频 + 音频 → 生成对口型 MP4 视频文件 |

💡 **还不确定？** 如果你要的是“一个能对话的 AI 数字人网页”，选 conversation；如果你要的是“一段人物说话的视频文件”，选 video-generation。

---

## 📊 Skill 对比速查

| 对比项 | duix-avatar-conversation | duix-avatar-video-generation |
| --- | --- | --- |
| 核心能力 | 实时对话数字人 | 口型驱动视频生成 |
| 输入 | 人像照片 + 音色 + 语言 | 人物视频 + 人声音频 |
| 输出 | 浏览器对话链接 (`conversation_url`) | MP4 视频文件路径 |
| 交互方式 | 实时语音/文字对话 | 预生成视频，不可交互 |
| 所需凭证 | `DUIX_APP_ID` + `DUIX_APP_KEY` | `DUIX_API_KEY` |
| 计费方式 | 订阅计划（定制次数，创建 1 次扣 1 次） | 充值积分（按任务视频时长消耗） |
| 制作时长 | 20 分钟–2 小时区间 | 几分钟到二十几分钟 |
| 典型场景 | 智能客服、虚拟教师、品牌大使 | 产品口播、周报视频、外呼 A/B 测试 |
| 硬门槛 | 需用户手动选音色 + 确认扣费 | 素材格式校验 + 积分确认 |

---

## 🚀 快速开始

### 一句话安装（推荐）

将以下提示词直接发送给你的 Agent：

> 请帮我安装 duix-avatar-conversation 和 duix-avatar-video-generation skill：从 https://github.com/duixcom/duix-skills 克隆到 skills 目录，安装 duix-cli，并配置所需的凭证。

### 手动安装

```bash
# 1. 克隆到 Agent 的 skills 目录
cd <your-agent-skills-path>
git clone https://github.com/duixcom/duix-skills.git

# 2. 安装 duix-cli
npm i duix-cli -g --registry=https://registry.npmjs.org/

# 3. 验证安装
duix-cli --version
ls duix-skills/*/README_zh.md
```

> **Agent 集成要求**：将 `duix-skills/` 下的各 Skill 目录放入 Agent 的 skills 目录，确保 Agent 可发现 `*/SKILL.md`。

---

## 📦 前置要求

### 环境要求

| 项目 | 要求 |
| --- | --- |
| Node.js | ≥ 18 |
| duix-cli | 最新版（安装后自动检查更新） |
| 系统 | macOS / Linux / Windows (WSL) |

### 各 Skill 凭证要求

| Skill | 所需凭证 | 获取地址 |
| --- | --- | --- |
| duix-avatar-conversation | `DUIX_APP_ID` + `DUIX_APP_KEY` | [API 密钥管理](https://www.duix.com/dashboard/avatar-conversation/apikeys) |
| duix-avatar-video-generation | `DUIX_API_KEY` | [API Key 管理](https://www.duix.com/dashboard/avatar-video-generation/apikeys) |

💰 **需要充值？**

- conversation 定制次数：[Pricing 页面](https://www.duix.com/avatar-conversation/pricing)
- video-generation 积分：[Pricing 页面](https://www.duix.com/dashboard/avatar-video-generation/pricing)

---

## 📖 各 Skill 详情

### duix-avatar-conversation — 实时对话数字人

上传人像照片，选择音色与语言，生成可在浏览器中实时交互对话的 AI 数字人。

**核心流程：**

人像照片 → 选音色（硬门槛）→ 选语言 → 可选人设 → 确认扣费（硬门槛）→ 生成 → 对话链接

**关键特性：**

- 🎙️ 40+ 种语言支持（默认 English）
- 🎭 可选人设：名字、开场白、性格描述
- 🔒 双硬门槛：必须用户手动选音色 + 必须用户确认扣费
- 🔄 制作失败时定制次数自动退还

[详细文档 →](duix-avatar-conversation/README_zh.md)

### duix-avatar-video-generation — 口型驱动视频生成

输入人物视频和人声音频，生成人物口型与音频完美同步的数字人口播视频。

**核心流程：**

人物视频 + 人声音频 → 素材校验 → 积分确认 → 生成 → MP4 文件

**关键特性：**

- 🎬 支持 720P ~ 4K 视频输入
- 🎵 支持 MP3 / WAV / M4A / AAC / FLAC 音频
- ⚡ 按任务消耗积分，失败有返还机制
- 📐 自动校验视频比例（16:9 或 9:16）和人脸检测

[详细文档 →](duix-avatar-video-generation/README_zh.md)

---

## ✅ 兼容性

本仓库的 Skills 面向支持 `SKILL.md` 的 Agent 环境设计：

| Agent 环境 | 兼容状态 | 备注 |
| --- | --- | --- |
| Codex | ✅ 支持 | — |
| Cursor | ✅ 支持 | — |
| Claude Code | ✅ 支持 | — |
| Copilot | ✅ 支持 | — |
| Gemini | ✅ 支持 | — |
| OpenClaw | ✅ 支持 | — |

具体兼容性及前置条件请以各 Skill 的 README 为准。

---

## ❓ 常见问题

**Q: 两个 Skill 可以同时安装使用吗？**
A: 可以。它们共享同一个 `duix-cli`，但使用不同的凭证和计费体系，互不冲突。

**Q: 安装后 Agent 找不到 Skill？**
A: 确认以下文件存在于 skills 目录：

```text
duix-skills/duix-avatar-conversation/SKILL.md
duix-skills/duix-avatar-conversation/scripts/duix_run.sh
duix-skills/duix-avatar-video-generation/SKILL.md
duix-skills/duix-avatar-video-generation/scripts/duix_run.sh
```

然后让 Agent 重新加载 skills。

**Q: duix-cli 安装失败怎么办？**
A: 确保 Node.js ≥ 18，并尝试使用官方源安装：

```bash
npm i duix-cli -g --registry=https://registry.npmjs.org/
```

**Q: 两个 Skill 的凭证可以共用吗？**
A: 不可以。

- `duix-avatar-conversation` 需要 `DUIX_APP_ID` + `DUIX_APP_KEY`
- `duix-avatar-video-generation` 需要 `DUIX_API_KEY`

请分别前往对应的控制台页面获取。

**Q: 如何查看账户余额？**
A:

- conversation 定制次数：`duix-cli avatar check`
- video-generation 积分：参考各 Skill 文档中的余额查询方式

---

## 📁 仓库结构

```text
duix-skills/
├── README_zh.md          # 本文档（集合总览）
├── LICENSE               # Apache License 2.0
├── duix-avatar-conversation/
│   ├── SKILL.md          # Skill 定义（Agent 读取）
│   ├── README_zh.md      # 中文使用文档
│   ├── README.md         # 英文使用文档
│   └── scripts/
│       └── duix_run.sh   # 辅助执行脚本
└── duix-avatar-video-generation/
    ├── SKILL.md
    ├── README_zh.md
    ├── README.md
    └── scripts/
        └── duix_run.sh
```

---

## 🛠️ 技术支持

- 💬 联系邮箱：support@duix.com
- 🐛 问题反馈：请提供 Skill 名称、`task_id`（如有）、完整的 CLI 输出日志、以及出错时的操作步骤
- 📚 各 Skill 详细文档：点击上方「各 Skill 详情」中的链接

---

## 📄 许可证

本仓库采用 [Apache License 2.0](LICENSE) 许可证。
