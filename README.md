# duix-avatar-video-generation skill

Language: English | [中文](README_zh.md)

A digital-human speaking-video skill for AI agents: input a person video and an audio file, then output a lip-synced talking-head video.

---

## Quick Start

### Option 1: One-Prompt Installation (Recommended)

Send the following prompt directly to your agent. It will complete installation and configuration automatically:

> Please help me install the duix-avatar-video-generation skill: clone https://github.com/duixcom/duix-skills into the skills directory, and configure DUIX_API_KEY. If the environment variable is already set, use it directly; otherwise, prompt me to enter it.

### Option 2: Manual Installation

```bash
# Clone into your agent's skills directory
cd <your-agent-skills-path>
git clone https://github.com/duixcom/duix-skills.git

# Verify the installation
ls duix-skills/duix-avatar-video-generation/SKILL.md
duix-skills/duix-avatar-video-generation/scripts/duix_run.sh
```

> **Agent integration requirement**: Place `duix-skills/duix-avatar-video-generation` in your agent's skills directory and make sure `duix-avatar-video-generation/SKILL.md` is discoverable.

### Configure the API Key

```bash
# macOS / Linux
# Option 1: Environment variable (recommended)
export DUIX_API_KEY="your-api-key-here"

# Option 2: Write to a local config file
echo "DUIX_API_KEY=your-api-key-here" > ~/.duix/config

# Windows PowerShell
# Option 1: Temporary setting
$env:DUIX_API_KEY="your-api-key-here"

# Option 2: Persistent setting
setx DUIX_API_KEY "your-api-key-here"
```

> **No API key?** Get one from the [API Key management page](https://www.duix.com/dashboard/skills/api-key). **Need more credits?** Visit the [Pricing page](https://www.duix.com/dashboard/skills/pricing) to view plans and recharge.

---

## What's Included

This project mainly includes one core skill:

| Skill | Capability | Input | Output |
| --- | --- | --- | --- |
| `duix-avatar-video-generation` | Person video + audio -> speaking video | `video` + `audio` + `output` | Generated MP4 + returned path |

Key files:

* **Skill definition**: `duix-avatar-video-generation/SKILL.md`
* **Execution script**: `duix-avatar-video-generation/scripts/duix_run.sh`

---

## How It Works

```plaintext
User intent                                Input assets                Deliverable
   |                                             |                          |
trigger duix-avatar-video-generation   video + audio + output      generated MP4 + returned path
```

Standard agent flow:

1. **Detect intent**: Recognize the user's intent to "make a person speak"
2. **Collect inputs**: Collect the three inputs: `video`, `audio`, and `output`
3. **Run generation**: Invoke the skill and wait for completion
4. **Return result**: Return the result path with a short description
5. **Retry on failure**: Provide actionable retry guidance when generation fails

---

## Authentication

Before execution, the agent must confirm that authentication is available:

* `DUIX_API_KEY` is configured, either as an environment variable or in local config

Recommended confirmation message:

> I will use duix-avatar-video-generation to generate a speaking video. Please confirm the video path, audio path, and output directory (optional).

---

## Try It Directly

### Prompt Examples

Copy any of these directly into your agent:

* "Use duix-avatar-video-generation to combine `person.mp4` and `voice.wav` into a speaking video, and output it to `./output`."
* "I want to create a 30-second product introduction video where the person in the video speaks according to this audio."
* "Use the same person video and generate 3 outreach versions with three different audio files."
* "Create an operations weekly-report video with a natural tone, output it locally, and tell me the final file path."

### Typical Business Scenarios

| Scenario | Input | Output | Value |
| --- | --- | --- | --- |
| **Product intro speaking video** | Presenter video + introduction audio | Social-media publishing video | Quickly generate marketing assets |
| **Weekly report video** | Reused person video + weekly audio | Dynamic weekly-report video | Improve information delivery efficiency |
| **Outreach A/B testing** | Fixed person video + multiple script audio versions | Batch outreach videos | Optimize script conversion rate |

---

## Requirements

* [ ] Available person video, 720p-4k, preferably front-facing, clear, and unobstructed
* [ ] Available audio file that can be played normally
* [ ] Agent environment that supports skills, such as Cursor, Codex, or OpenClaw
* [ ] `DUIX_API_KEY` configured ([how to get one](https://www.duix.com/dashboard/skills/api-key))

---

## Security Notes

* This skill only processes the local input assets and authentication information you provide
* **Do not expose the full API key in public logs**
* When troubleshooting, share redacted error information first

---

## FAQ

**Q: Do I need to learn the command line?**  
A: No. You can complete installation, configuration, and usage directly through an agent conversation without manually typing commands.

**Q: The agent cannot find the skill after installation. What should I do?**  
A: Confirm that `duix-avatar-video-generation/SKILL.md` and `duix-avatar-video-generation/scripts/duix_run.sh` are under the skills directory, and that the agent has reloaded skills.

**Q: It says "DUIX_API_KEY not found". What should I do?**  
A: Check whether the environment variable has taken effect, or reconfigure the local config file. If you do not have a key yet, get one from the [API Key management page](https://www.duix.com/dashboard/setting/api-key).

**Q: How are credits calculated?**  
A: Calls initiated through Skills use the credits of the logged-in account. For specific billing standards, see the [Pricing page](https://www.duix.com/pricing).

**Q: What if I do not have enough credits?**  
A: Visit the [Pricing page](https://www.duix.com/pricing) to view plans and recharge.

**Q: What if the generation task is slow?**  
A: Video generation can take a long time. Even short-video tasks may wait for more than ten minutes or longer, and peak periods can be slower. Wait patiently or retry outside peak hours.

**Q: Will failed tasks consume compute credits?**  
A: In general, generation failures, review blocks, model exceptions, and similar cases may have a refund mechanism, but do not treat "failed tasks never consume credits" as a fixed promise. If you suspect an incorrect deduction, keep the project link, node information, task time, and failure reason, then report them to the official support team.

---

## Technical Support

* Contact email: support@duix.com
