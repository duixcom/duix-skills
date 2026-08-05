# duix-avatar-conversation skill

语言：中文 | [English](README.md)

用于 AI Agent 的实时对话数字人技能。通过 **duix-cli** 创建数字人，并返回可直接打开的对话网页链接。

---

## 快速开始

### 一句话安装

> 请帮我安装 duix-avatar-conversation skill：从 https://github.com/duixcom/duix-skills 克隆到 skills 目录，安装 `duix-cli`，并配置 `DUIX_APP_ID` / `DUIX_APP_KEY`。

### 手动安装

```bash
cd <your-agent-skills-path>
git clone https://github.com/duixcom/duix-skills.git

npm i duix-cli -g --registry=https://registry.npmjs.org/
duix-cli --version
```

### 配置凭证

```bash
export DUIX_APP_ID="your-app-id"
export DUIX_APP_KEY="your-app-key"

# 或
./duix-avatar-conversation/scripts/duix_run.sh --config
```

avatar 相关命令**不需要** `DUIX_API_KEY`。

---

## 包含内容

| 工具 | duix-cli 命令 | 输出 |
| --- | --- | --- |
| `duix-avatar-conversation` | `duix-cli avatar create` | `task_id`（可能先返回音色下拉） |
| `duix-get-avatar-create-result` | `duix-cli avatar status` | `conversation_url` |

**所有数据请求都在 duix-cli 内完成。**

---

## 引导流程（Agent）

1. 上传人像图片（比例须为 16:9 或 9:16）  
2. **选择音色（硬门槛：必须等用户选，禁止自动选）**  
3. 选择语言（默认 English，可跳过）  
4. 可选：名字 / 开场白 / 描述（均可跳过）  
5. 确认扣减定制次数  
6. 确认提交 → 开始生成  
7. 轮询状态 → 返回 `conversation_url`

```bash
duix-cli avatar create --coverImageUrl ./face.png
# 若 need_select=true：必须停下，展示选项，等用户选择
duix-cli avatar check
duix-cli avatar create --coverImageUrl ./face.png --ttsName <用户选的音色> --language English [--name ...] [--greetings ...] [--profile ...]
duix-cli avatar status <task_id> -c
```

### Agent 禁止事项

- 把 `need_select=true` 当成创建成功  
- 自动选 `options[0]` 或自行编造 `--ttsName`  
- 在没有真实 `task_id` 之前调用 `avatar status`  

完整约束见 `SKILL.md` → **Agent Hard Rules (MUST)**。

---

## 使用要求

- 已安装 `duix-cli`（依赖 Bun）
- 已配置 `DUIX_APP_ID` / `DUIX_APP_KEY`
- 人像图片 **或** 已有 conversationId
- 支持 skills 的 Agent 环境

---

## 技术支持

- 联系邮箱：support@duix.com
