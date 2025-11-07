# Zed Voice AI - Agent Guidelines

## Project: AI Pair Programmer with Voice
Building a proactive AI observer that watches coding, makes suggestions via notifications/voice, integrated directly into Zed IDE.

## Build & Test Commands
- `./script/bootstrap` - Setup Zed environment  
- `cargo build --release` - Build Zed with observer_mode
- `cargo test observer_mode` - Test observer crate specifically
- `cargo test observer_mode::tests::test_context_gathering` - Run specific test
- `./script/clippy` - Lint (required for Zed contribution standards)
- `RUST_LOG=observer_mode=debug cargo run` - Debug observer mode

## Code Style (Zed + Observer Mode)
- **GPUI patterns:** Use `Entity<T>`, `App`, `Context<T>` (not `Model<T>`, `AppContext`, `ModelContext<T>`)
- **Async:** Use `cx.spawn(async move |cx| ...)` for non-blocking LLM calls
- **Error handling:** Never `unwrap()` or `let _ =` - use `?` or `.log_err()` for visibility
- **Events:** Hook `EditorEvent::ContentChanged`, `CursorMoved` for observation triggers
- **Settings:** Extend Zed's JSON schema system in `crates/settings/`
- **Voice:** Integrate TTS/STT without blocking editor UI thread

## Observer Mode Architecture
- **New crate:** `crates/observer_mode/` (context gathering, LLM calls, voice output)
- **Modified:** `crates/editor/` (event hooks), `crates/workspace/` (timer), `crates/zed/` (init)
- **Reuse:** LLM provider system, settings system, GPUI UI framework
- **Flow:** Editor events → Context gathering → LLM analysis → Voice/notification output

## Key Implementation Notes
- Observer runs every N seconds (configurable), non-blocking
- Context includes visible code, cursor position, diagnostics, git status
- LLM responds with JSON: `{should_speak: bool, confidence: 0-1, suggestion: string}`
- Voice output via TTS (Piper/Coqui), voice input via STT (Whisper) with push-to-talk