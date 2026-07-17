# duix-avatar-video-generation skill

语言：中文 | [English](README.md)

用于 AI Agent 的数字人口播技能：输入人物视频和音频，输出口型驱动视频。

---

## 快速开始

### 方式一：一句话安装（推荐）

直接将以下提示词发送给你的 Agent，它会自动完成安装和配置：

> 请帮我安装 duix-avatar-video-generation skill：从 https://github.com/duixcom/duix-skills 克隆到 skills 目录，并配置 DUIX_API_KEY（如果已设置环境变量则直接使用，否则提示我输入）。

### 方式二：手动安装

```bash
# 克隆到 Agent 的 skills 目录
cd <your-agent-skills-path>
git clone https://github.com/duixcom/duix-skills.git

# 验证安装
ls duix-skills/duix-avatar-video-generation/SKILL.md
duix-skills/duix-avatar-video-generation/scripts/duix_run.sh

# 从 npm 官方源安装 duix-cli
npm i duix-cli -g --registry=https://registry.npmjs.org/

# 可选：对比本地版本和官方 npm 包版本
# 包页面：https://www.npmjs.com/package/duix-cli
duix-cli --version
npm view duix-cli version --registry=https://registry.npmjs.org/
```
> **Agent 集成要求**：将 `duix-skills/duix-avatar-video-generation` 放入 Agent 的 skills 目录并确保可发现 `duix-avatar-video-generation/SKILL.md`。

### 配置 API Key

```bash
# macOS / Linux
# 方式一：环境变量（推荐）
export DUIX_API_KEY="your-api-key-here"

# 方式二：写入本地配置文件
echo "DUIX_API_KEY=your-api-key-here" > ~/.duix/config

# Windows PowerShell
# 方式一：临时设置
$env:DUIX_API_KEY="your-api-key-here"

# 方式二 永久设置
setx DUIX_API_KEY "your-api-key-here"

```
> 🔑 **没有 API Key？** 前往 [API Key 管理页面](https://www.duix.com/dashboard/skills/api-key) 获取。   💰 **需要更多积分？** 前往 [Pricing 价格页面](https://www.duix.com/dashboard/skills/pricing) 查看套餐并充值。

---

## 包含内容

本项目主要包含一个核心 skill：

| Skill | 功能 | 输入 | 输出 |
| --- | --- | --- | --- |
| `duix-avatar-video-generation` | 视频人物 + 音频 → 口播视频 | `video` + `audio` + `output` | 生成 MP4 + 返回路径 |

关键文件：

*   **Skill 定义**：`duix-avatar-video-generation/SKILL.md`
    
*   **执行脚本**：`duix-avatar-video-generation/scripts/duix_run.sh`
    

---

## 工作原理

```plaintext
用户意图                                  输入素材                    交付结果
   ↓                                         ↓                           ↓
触发 duix-avatar-video-generation   video + audio + output        生成 MP4 + 返回路径

```

Agent 标准流程：

1.  **识别意图**：识别用户"让人物开口说话"意图
    
2.  **收集输入**：收集 `video`/`audio`/`output` 三类输入
    
3.  **执行生成**：调用 skill 执行并等待完成
    
4.  **返回结果**：返回结果路径与简短说明
    
5.  **失败重试**：失败时给出可执行重试建议
    

---

## 认证方式

Agent 执行前需确认可用认证：

*   `DUIX_API_KEY` 已配置（环境变量或本地配置）
    

推荐确认话术：

> 我将使用 duix-avatar-video-generation 生成口播视频。  请确认视频路径、音频路径，以及输出目录（可选）。

---

## 可直接尝试

### 提示词案例

直接复制给 Agent 即可使用：

* 用 duix-avatar-video-generation 把视频 C:\Users\YourName\Videos\person.mp4 和音频 C:\Users\YourName\Audio\voice.wav 合成口播视频。
    
* 我想做一条产品介绍视频，让 C:\Users\YourName\Videos\spokesperson.mp4 里的人物按 C:\Users\YourName\Audio\intro.mp3 这段音频说话。
    
* 请用 C:\Users\YourName\Videos\avatar.mp4 这个人物视频，分别用 C:\Users\YourName\Audio\script_a.mp3、C:\Users\YourName\Audio\script_b.mp3、C:\Users\YourName\Audio\script_c.mp3 三段音频生成 3 个外呼版本。
    
* 做一条运营周报视频，用 C:\Users\YourName\Videos\reporter.mp4 作为人物，按 C:\Users\YourName\Audio\weekly_report.mp3 说话，语气自然。
    

### 典型业务场景

| 场景 | 输入 | 输出 | 价值 |
| --- | --- | --- | --- |
| **产品介绍口播** | 发言人视频 + 介绍音频 | 社媒发布视频 | 快速生成营销素材 |
| **周报视频化** | 复用同一人物视频 + 周度音频 | 动态周报视频 | 提升信息传达效率 |
| **外呼 A/B 测试** | 固定人物视频 + 多版本话术音频 | 批量外呼视频 | 优化话术转化率 |

---

## 使用要求

*   [ ] 可用的人物视频720p-4k（建议正脸、清晰、无遮挡）
    
*   [ ] 可用的音频文件（可正常播放）
    
*   [ ] 支持 skills 的 Agent 环境（如 Cursor / Codex / OpenClaw 等）
    
*   [ ] 已配置 DUIX_API_KEY （[获取方式](https://www.duix.com/dashboard/skills/api-key)）
    

---

## 安全说明

*   该 skill 仅处理你提供的本地输入素材与认证信息
    
*   **建议不要在公开日志中暴露完整 API Key**
    
*   如需排查，优先分享脱敏后的错误信息
    

---

## 常见问题

**Q: 我需要学命令行吗？**  
A: 不需要。你可以直接通过 Agent 对话完成安装、配置和使用，全程无需手动敲命令。

**Q: 安装后 Agent 找不到 skill？**  
A: 确认 `duix-avatar-video-generation/SKILL.md` 和 `duix-avatar-video-generation/scripts/duix_run.sh` 在 skills 目录下，且 Agent 已重新加载 skills。

**Q: 提示 "DUIX\_API\_KEY not found"？**  
A: 检查环境变量是否生效，或重新配置本地配置文件。  
如果还没有 Key，前往 [API Key 管理页面](https://www.duix.com/dashboard/setting/api-key) 获取。

**Q: 积分消耗如何计算？**  
A: 通过 Skills 发起的调用，将使用所登录账户的积分。具体计费标准请参考 [Pring 价格页面](https://www.duix.com/pricing)。

**Q: 积分不足怎么办？**  
A: 前往 [Pricing 价格页面](https://www.duix.com/pricing) 查看套餐并充值。

**Q: 生成任务很慢怎么办？**  
A: 视频生成本身可能需要较长时间。短视频任务通常也可能等待十几分钟到更久，高峰期会更慢。建议耐心等待，或避开高峰时段重试。

**Q: 失败会扣积分吗？**  
A: 一般生成失败、审核拦截、模型异常等场景可能有返还机制，但不要把"失败一定不消耗"当成固定承诺。  
如果遇到疑似误扣，保留项目链接、节点信息、任务时间和失败原因，再反馈给官方。

---

## 技术支持

*   💬 联系邮箱：support@duix.com