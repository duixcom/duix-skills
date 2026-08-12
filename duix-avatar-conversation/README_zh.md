# duix-avatar-conversation skill

语言：中文 | [English](README.md)

用于 AI Agent 的实时对话数字人技能：上传人像照片，选择音色与语言，生成可实时交互对话的 AI 数字人网页链接。

---

## 快速开始

### 方式一：一句话安装（推荐）

直接将以下提示词发送给你的 Agent，它会自动完成安装和配置：

> 请帮我安装 duix-avatar-conversation skill：从 https://github.com/duixcom/duix-skills 克隆到 skills 目录，安装 duix-cli，并配置 DUIX_APP_ID 与 DUIX_APP_KEY（如果已设置环境变量则直接使用，否则提示我输入）。

### 方式二：手动安装

```bash
# 克隆到 Agent 的 skills 目录
cd <your-agent-skills-path>
git clone https://github.com/duixcom/duix-skills.git

# 验证安装
ls duix-skills/duix-avatar-conversation/SKILL.md
duix-skills/duix-avatar-conversation/scripts/duix_run.sh

# 从 npm 官方源安装 duix-cli
npm i duix-cli -g --registry=https://registry.npmjs.org/

# 通过 npm 官方源检查版本；版本不一致时升级到最新版
# 包页面：https://www.npmjs.com/package/duix-cli
duix-cli --version
npm view duix-cli version --registry=https://registry.npmjs.org/
npm i duix-cli -g --registry=https://registry.npmjs.org/
duix-cli --version
```

> **Agent 集成要求**：将 `duix-skills/duix-avatar-conversation` 放入 Agent 的 skills 目录并确保可发现 `duix-avatar-conversation/SKILL.md`。

### 配置凭证

```bash
# macOS / Linux
# 方式一：环境变量（推荐）
export DUIX_APP_ID="your-app-id"
export DUIX_APP_KEY="your-app-key"

# 方式二：交互式配置
./duix-avatar-conversation/scripts/duix_run.sh --config

# Windows PowerShell
# 方式一：临时设置
$env:DUIX_APP_ID="your-app-id"
$env:DUIX_APP_KEY="your-app-key"

# 方式二：永久设置
setx DUIX_APP_ID "your-app-id"
setx DUIX_APP_KEY "your-app-key"
```

> 🔑 **没有 APP ID / APP Key？** 前往 [API 密钥管理页面](https://www.duix.com/dashboard/avatar-conversation/apikeys) 获取。
> 💰 **需要更多定制次数？** 前往 [Pricing 价格页面](https://www.duix.com/dashboard/avatar-conversation/pricing) 查看套餐并充值。

注意：avatar 相关命令**不需要** `DUIX_API_KEY`，仅需 `DUIX_APP_ID` 和 `DUIX_APP_KEY`。

如果任一凭证未设置，请先将上方命令复制到命令行执行，再重新运行 Skill。不要在对话或公开日志中发送凭证。

---

## 包含内容

本项目主要包含两个核心 skill：

| Skill | 功能 | 输入 | 输出 |
| --- | --- | --- | --- |
| `duix-avatar-conversation` | 创建数字人训练任务 | 人像照片 + 音色 + 语言 + 可选名字、开场白、人设 | `task_id`（或先返回音色下拉） |
| `duix-get-avatar-create-result` | 查询训练结果并返回对话链接 | `task_id` | `conversation_url` |

关键文件：

* **Skill 定义**：`duix-avatar-conversation/SKILL.md`
* **执行脚本**：`duix-avatar-conversation/scripts/duix_run.sh`

---

## 工作原理

```plaintext
用户意图                                  输入素材                    交付结果
   ↓                                         ↓                           ↓
触发 duix-avatar-conversation      人像照片 + 音色 + 语言        对话网页链接
                                        ↓
                              ┌─────────────────────┐
                              │  1. 上传人像照片      │
                              │  2. 选择音色（硬门槛） │
                              │  3. 选择语言          │
                              │     （默认 English）  │
                              │  4. 可选名字/开场白/人设 │
                              │  5. 确认定制次数扣减  │
                              │  6. 提交生成任务      │
                              │  7. 轮询状态 → 成功   │
                              └─────────────────────┘
```

Agent 标准流程：

1. **识别意图**：识别用户“创建一个能对话的数字人”意图
2. **收集输入**：收集人像照片、音色偏好、语言、可选人设信息
3. **音色选择**：首次 create 获取音色列表，等用户明确选择（硬门槛，禁止自动选）
4. **配额确认**：携带音色再次 create，等待用户确认扣减定制次数（硬门槛，禁止自动确认）
5. **提交生成**：用户确认后，携带 `--confirm 是` 最终提交，获取 `task_id`
6. **轮询状态**：调用 status 轮询，直到返回 `conversation_url`
7. **返回结果**：返回对话链接与使用说明
8. **失败处理**：失败时展示原因，定制次数自动退还

---

## 认证方式

Agent 执行前需确认可用认证：

* `DUIX_APP_ID` 与 `DUIX_APP_KEY` 已配置（环境变量或本地配置）

推荐确认话术：

> 我将使用 duix-avatar-conversation 创建实时对话数字人。
> 请提供一张人像照片（16:9 或 9:16），并确认是否要选择特定音色和语言。

---

## 可直接尝试

### 提示词案例

直接复制给 Agent 即可使用，必须提供人像照片路径（请替换为你本地的实际文件路径）：

* 用 duix-avatar-conversation 读取 examples/demo_assets 下的 demo_avatar.png 人像照片，创建一个中文对话数字人。
* 用 duix-avatar-conversation 把照片 C:\Users\YourName\avatar.png 生成一个英文对话数字人，名字叫 “Amy”，开场白是 “Hello, nice to meet you!”。
* 我想创建一个产品讲解员数字人，用 https://github.com/duixcom/duix-skills/blob/main/duix-avatar-conversation/examples/assets/demo_face.jpg 这张照片，说中文，人设是专业客服风格。
* 请用 https://github.com/duixcom/duix-skills/blob/main/duix-avatar-conversation/examples/assets/demo_face.jpg 这张照片生成一个教学助手数字人，语言选中文，开场白为 “同学们好，今天我们来学习新知识”。
* 做一个人物采访风格的对话数字人，用 C:\Users\YourName\avatar.png 作为形象，英文对话，名字叫 “David”，语气要亲切自然。

💡 提示：
将示例中的 `C:\Users\YourName\***` 替换为你电脑上的实际路径，例如 `D:\images\avatar.png`。
将示例中的 https://github.com/duixcom/duix-skills/blob/main/duix-avatar-conversation/examples/assets/demo_face.jpg 替换为你实际可访问的图片 URL。

### 典型业务场景

| 场景 | 输入 | 输出 | 价值 |
| --- | --- | --- | --- |
| **智能客服数字人** | 客服形象照片 + 专业音色 | 7×24 在线对话网页 | 降低人工客服成本 |
| **产品讲解员** | 品牌代言人照片 + 亲和音色 | 产品介绍对话链接 | 提升用户互动体验 |
| **虚拟教师** | 教师形象照片 + 温和音色 | 教学助手对话网页 | 实现个性化答疑 |
| **品牌大使** | 统一形象照片 + 多语言音色 | 多语言对话数字人 | 覆盖全球用户群体 |

---

## 使用要求

### 输入素材要求

| 项目 | 要求 |
| --- | --- |
| 图片格式 | PNG、JPG、JPEG、WEBP |
| 图片大小 | 不超过 10MB |
| 图片比例 | 必须为 16:9 或 9:16 |
| 图片内容 | 清晰正面人像，面部无遮挡，光线均匀 |
| 人脸要求 | 必须包含且仅包含 1 张人脸，正脸、清晰、无遮挡 |
| 语言 | 默认 English，支持 40+ 种语言（Chinese、Japanese、Korean 等） |
| 定制次数 | 创建 1 个数字人消耗 1 次定制次数；余额不足时无法提交 |

如果图片未通过格式、大小、比例或人脸校验，Agent 会用通俗语言说明问题，并询问是否使用大模型将图片转换、缩放或裁剪为符合要求的人像。只有在你明确同意后才会处理图片。

### 环境与配置检查清单

* [ ] 输入图片满足上方格式、大小、比例和人脸要求
* [ ] 支持 skills 的 Agent 环境（如 Cursor / Codex / OpenClaw 等）
* [ ] 已配置 `DUIX_APP_ID` 与 `DUIX_APP_KEY`（[获取方式](https://www.duix.com/dashboard/avatar-conversation/apikeys)）
* [ ] 账户拥有足够的定制次数（[查看套餐](https://www.duix.com/dashboard/avatar-conversation/pricing)）

---

## 安全说明

* 该 skill 仅处理你提供的本地输入素材与认证信息
* **建议不要在公开日志中暴露完整的 `DUIX_APP_ID` / `DUIX_APP_KEY`**
* 如需排查，优先分享脱敏后的错误信息（如 `task_id` 前几位）

---

## 常见问题

**Q: 安装后 Agent 找不到 skill？**
A: 确认 `duix-avatar-conversation/SKILL.md` 和 `duix-avatar-conversation/scripts/duix_run.sh` 在 skills 目录下，且 Agent 已重新加载 skills。

**Q: 提示 “DUIX_APP_ID / DUIX_APP_KEY not found”？**
A: 请将“配置凭证”中的环境变量命令复制到命令行执行后，再重新运行 Skill。如果还没有凭证，前往 [API 密钥管理页面](https://duix.com/dashboard/avatar-conversation/apikeys) 获取。

**Q: 图片不符合要求怎么办？**
A: 你可以换一张人像，或明确让 Agent 使用大模型将图片转换、缩放或裁剪为支持的 JPG/PNG 格式，且大小不超过 10 MB、比例为 16:9 或 9:16。

**Q: 状态一直是 processing，是不是卡住了？**
A: 不是卡住。`processing` 是正常的制作中状态，数字人生成通常需要几分钟时间。请继续轮询同一个 `task_id`，不要重新创建新任务，也不要告诉用户“任务卡死了”。

**Q: 我需要学命令行吗？**
A: 不需要。你可以直接通过 Agent 对话完成安装、配置和使用，全程无需手动敲命令。

**Q: 一个 task_id 可以多次查询吗？**
A: 可以。`task_id` 是永久有效的，你可以随时用 `avatar status <task_id>` 查询结果，即使之前已经查询过。

**Q: 提示 “定制次数不足”怎么办？**
A: 你的账号定制次数已用完，需要订阅套餐。前往 [Pricing 价格页面](https://www.duix.com/dashboard/avatar-conversation/pricing) 充值后再次尝试即可。

**Q: 制作失败了，定制次数会退还吗？**
A: 会退还。若数字人制作失败（skill_code=500），消耗的定制次数会自动退回你的账户余额。

**Q: 可以修改已创建的数字人吗？**
A: 数字人创建成功后，在 Agent 工具中不支持直接修改参数（如更换音色、修改人设）。如需调整声音、语言、名字、开场白、人设，可以前往 [duix 网页工作台](https://www.duix.com/dashboard/my-avatar) 进行修改；若想在 Agent 工具中修改，需要重新创建一个新的数字人任务。

---

## 技术支持

* 💬 联系邮箱：support@duix.com
* 🐛 问题反馈：请提供 `task_id`、完整的 CLI 输出日志、以及出错时的操作步骤
