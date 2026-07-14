# Digital Human Skill

Language: English | [中文](README_zh.md)

An AI-agent skill for speaking-avatar generation: input person video + audio, output lip-synced talking-head video.

## Install

Place `digital-human` in your agent skills directory so `digital-human/SKILL.md` is discoverable.  
Before first run, only two setup items are required:

1. `duix-cli` installed
2. `DUIX_API_KEY` configured

> This guide intentionally keeps CLI details minimal and focuses on agent usage.

## What's Included

This project ships one core skill:

- `digital-human`: person video + audio -> speaking video

Key files:

- Skill definition: `digital-human/SKILL.md`
- Runtime helper: `digital-human/scripts/duix_run.sh`

## How It Works

```text
User intent               Input assets                  Deliverable
    ↓                         ↓                             ↓
trigger digital-human   video + audio + output      MP4 output + file path
```

Standard agent flow:

1. detect "make this person speak" intent
2. collect `video/audio/output`
3. run the skill and wait for completion
4. return output path with short summary
5. if failed, return actionable retry guidance

## Authentication

Before execution, ensure auth is available:

- `DUIX_API_KEY` is configured

Suggested confirmation message:

> I will use `digital-human` to generate your speaking video.  
> Please confirm video path, audio path, and output directory (optional).

## Things to Try

Prompt examples you can paste directly:

- "Use `digital-human` with `person.mp4` and `voice.wav`, save to `./output`."
- "Make a 30-second product intro where the presenter speaks this audio track."
- "Reuse the same person video and generate 3 outreach variants from 3 audio files."
- "Create a weekly update speaking video and return the final output file path."

Practical scenarios:

- Product intro clips for social channels
- Weekly update video automation
- Outreach A/B variants with different scripts

## Requirements

- source video with clear visible face
- valid audio file for speech
- an agent environment that supports skills (Cursor / Codex / OpenClaw, etc.)

## Security

- this skill processes only provided media files and auth credentials
- avoid exposing full API keys in shared logs
- share redacted error logs when debugging with others
