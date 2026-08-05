# duix-avatar-conversation skill

语言：中文 | [English](README.md)

用于 AI Agent 的实时对话数字人技能。通过 **duix-cli** 创建数字人，并返回可直接打开的对话网页链接。

---

## 快速开始

### 一句话安装

> 请帮我安装 duix-avatar-conversation skill：从 https://github.com/duixcom/duix-skills-1 克隆到 skills 目录，安装 `duix-cli`，并配置 `DUIX_APP_ID` / `DUIX_APP_KEY`（若需上传本地图片，再配置 `DUIX_API_KEY`）。

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
export DUIX_API_KEY="your-skills-api-key"

# 或
./duix-avatar-conversation/scripts/duix_run.sh --config
```

---

## 包含内容

| 工具 | duix-cli 命令 | 输出 |
| --- | --- | --- |
| `duix-avatar-conversation` | `duix-cli avatar create` | `task_id`（可能先返回音色下拉） |
| `duix-get-avatar-create-result` | `duix-cli avatar status` | `conversation_url` |

**所有数据请求都在 duix-cli 内完成。**

---

## 引导流程（Agent）

1. 上传人像图片  
2. 选择音色（CLI 下拉）  
3. 选择语言（默认 English，可跳过）  
4. 可选：名字 / 开场白 / 描述（均可跳过）  
5. 确认扣减定制次数  
6. 确认提交 → 开始生成  
7. 轮询状态 → 返回 `conversation_url`

```bash
duix-cli avatar create --coverImageUrl ./face.png
# 选择音色后：
duix-cli avatar check
duix-cli avatar create --coverImageUrl ./face.png --ttsName <selected> --language English [--name ...] [--greetings ...] [--profile ...]
duix-cli avatar status <task_id> -c
```

---

## 使用要求

- 已安装 `duix-cli`（依赖 Bun）
- 已配置 `DUIX_APP_ID` / `DUIX_APP_KEY`
- 本地图片上传时需 `DUIX_API_KEY`
- 人像图片 **或** 已有 conversationId
- 支持 skills 的 Agent 环境

---

## 技术支持

- 联系邮箱：support@duix.com
