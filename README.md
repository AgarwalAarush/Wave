# Wave

Wave is a lightweight macOS menu bar assistant that opens a floating prompt panel, captures your screen context (optional), and streams responses from OpenAI in real time.

## Features

- Global quick-toggle panel (`Shift + Delete`)
- Streaming responses from OpenAI Chat Completions
- Optional automatic full-screen screenshot context
- Model switcher (`Cmd + Shift + M`) with keyboard navigation
- API key stored securely in macOS Keychain
- Menu bar app with Settings UI

## Tech Stack

- SwiftUI + AppKit (`NSPanel`) for the floating UI
- `ScreenCaptureKit` for screenshot capture
- `URLSession.bytes` for streaming SSE response chunks
- Carbon hotkey API for global keyboard shortcut

## Requirements

- macOS 26.2+
- Xcode (with Swift 5 toolchain)
- An OpenAI API key

## Quick Start

1. Open `Wave.xcodeproj` in Xcode.
2. Select the `Wave` scheme.
3. Run the app.
4. Open **Settings** (`Cmd + ,`) and save your OpenAI API key.
5. If screenshot context is enabled, grant **Screen Recording** permission when prompted.

## Usage

- `Shift + Delete`: Toggle Wave panel
- `Enter`: Submit prompt
- `Esc`: Hide panel
- `Cmd + N`: Start a new chat
- `Cmd + Shift + M`: Open model picker
- `Up/Down + Enter`: Select a model

## Configuration

- API key is stored in Keychain under service `agarwalaarush.Wave`.
- User defaults used:
  - `gpt_model` (selected model identifier)
  - `screenshot_enabled` (bool, defaults to `true`)

Current model options in code:

- `gpt-5-nano-2025-08-07`
- `gpt-5-mini-2025-08-07` (default)
- `gpt-5.2-2025-12-11`
- `gpt-5.1-codex`

## Project Structure

- `Wave/WaveApp.swift`: App entry point and Settings scene
- `Wave/AppDelegate.swift`: Panel lifecycle + menu bar integration
- `Wave/WavePanel.swift`: Floating, top-pinned panel behavior
- `Wave/ContentView.swift`: Prompt UI, model picker, response rendering
- `Wave/ChatViewModel.swift`: State management + orchestration
- `Wave/GPTService.swift`: OpenAI request building + stream parsing
- `Wave/ScreenCaptureService.swift`: Full-screen screenshot capture
- `Wave/SettingsView.swift`: API key, model, context, and shortcuts settings

## Build from CLI

```bash
xcodebuild -project Wave.xcodeproj -scheme Wave -configuration Debug -derivedDataPath ./.derivedData build
```

## Notes

- This repo currently has no test target.
- OpenAI model IDs and availability may change over time.
