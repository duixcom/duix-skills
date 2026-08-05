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

1. 上传人像 → CLI 做比例校验 + imageCheck（格式/人脸）  
2. **选择音色（硬门槛；有 `preview_url` 时先试听；禁止自动选）**  
3. 选择语言（默认 English，可跳过）  
4. 可选：名字 / 开场白 / 描述（均可跳过）  
5. 确认扣减定制次数（不足则引导 https://www.duix.com/pricing）  
6. 确认提交 → 开始生成（状态：制作中 / processing）  
7. 成功：返回对话信息 + `conversation_url`；失败：失败原因 + **定制次数已退还**

```bash
# 1) 无音色：先图检，再拿下拉（含试听链接），然后停住
./duix_run.sh run --coverImageUrl ./face.png --language English

# 2) 用户选完音色后：会先 need_confirm，交互确认后再 --yes 提交并轮询
./duix_run.sh run --coverImageUrl ./face.png --ttsName Echo --language English --name Ada
```

Helper 已对齐硬门槛：`need_select` → 停；`need_confirm` → 交互确认后才加 `--yes`。预检 `avatar check` 不会自动给 create 加 `--yes`。

### Agent 禁止事项

- 把 `need_select=true` / `need_confirm=true` 当成创建成功  
- 自动选 `options[0]` 或自行编造 `--ttsName`  
- 隐藏可用的试听链接  
- 在没有真实 `task_id` 之前调用 `avatar status`  
- 次数不足时不告知充值链接；失败时不告知次数已退还  

完整约束见 `SKILL.md` → **Agent Hard Rules (MUST)**。

---

## 使用要求

- 已安装 `duix-cli`（依赖 Bun）
- 已配置 `DUIX_APP_ID` / `DUIX_APP_KEY`
- 人像图片 **或** 已有 conversationId
- 支持 skills 的 Agent 环境

---

## 视频上传常见问题

**Q：上传视频提示“当前输入内容存在安全风险，请修改后重试”**  
A：平台会对上传视频的画面、文本、音频进行合规检测，若视频包含涉政、涉黄、涉恐、涉暴等违规内容，将触发安全风险提示。该报错大多由涉政内容导致，请自查并修改视频违规内容后重新上传即可。

**Q：上传视频提示“请上传尺寸为9:16/16:9的视频”**  
A：
1. 核查视频比例规格：选中视频，鼠标右键点击【属性】-【详细信息】，查看帧宽度、帧高度。平台合规标准比例如下：720P（720×1280）、1080P（1080×1920）、2K（1440×2560）、4K（2160×3840），仅支持 9:16、16:9 两种比例。
2. 排查浏览器问题：若视频比例无误仍提示异常，可能为浏览器兼容问题，建议更换谷歌浏览器后重试上传。

**Q：如何满足平台视频比例要求？**  
A：可使用剪映等专业视频剪辑软件，导入原视频，调整画面比例为平台要求的 9:16 或 16:9，重新导出合规视频即可。

**Q：视频比例正确，更换浏览器后仍无法上传怎么办？**  
A：该情况多为视频编码异常导致。可将视频导入剪映等剪辑软件重新导出，导出时将视频编码选择为 H.264，导出完成后再次尝试上传。

---

## 技术支持

- 联系邮箱：support@duix.com
