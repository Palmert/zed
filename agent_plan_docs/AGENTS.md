# ZedVoice AI Pair Programmer - Agent Guidelines

## Project Status
**Repository Structure:**
- Root: Documentation and planning files (README.md, ARCHITECTURE.md, etc.)
- `/zed/`: Actual Zed IDE fork from `https://github.com/zed-industries/zed.git`
- **Current Phase:** Ready to implement observer_mode crate

**Zed Codebase Overview:**
- 200+ crates in workspace structure
- Key crates: `editor`, `workspace`, `language_model`, `language_models`, `gpui`, `settings`
- Build system uses custom scripts in `script/` directory

## Build Commands
**Zed Fork Build System:**
- `./script/bootstrap` - Install dependencies and setup environment
- `cargo build --release` - Build the project (release mode)
- `cargo test` - Run all tests
- `./script/clippy` - Run clippy with workspace settings and additional checks
- `cargo test observer_mode::tests::test_context_gathering` - Run specific test
- `RUST_LOG=observer_mode=debug cargo run` - Debug mode with observer logging

**Key Scripts (in `script/` directory):**
- `./script/bootstrap` - Setup development environment
- `./script/clippy` - Lint with strict warnings and additional tools
- `./script/new-crate` - Create new crate following Zed patterns

## Code Style Guidelines
**Rust Standards:**
- Use `cargo fmt` for formatting, `cargo clippy` for linting
- Rust 2021 edition, min version 1.70+
- Async/await for non-blocking operations, use `anyhow` for errors
- Snake_case for functions/variables, PascalCase for types

**Zed Integration Patterns:**
- Use `gpui::*` for UI components and context management (found in `crates/gpui/`)
- Hook into `crates/editor/` - editor events and display system
- Leverage `crates/language_model/` - existing LLM provider infrastructure
- Use `cx.spawn()` for background tasks, `cx.emit()` for events
- Follow workspace patterns in `crates/workspace/` and `crates/collab_ui/`
- Settings system in `crates/settings/` with JSON schema validation

## Architecture
**New crate:** `crates/observer_mode/` with: lib.rs, observer.rs, context.rs, decision.rs, output.rs
**Workspace Integration:** Add to `Cargo.toml` workspace members list (200+ existing crates)
**Modified crates:** 
- `crates/editor/` - add event hooks to existing editor.rs
- `crates/workspace/` - initialize observer in workspace context
- `crates/zed/` - main app initialization
**LLM Integration:** Use existing `crates/language_model/` and `crates/language_models/` system
**Settings:** Extend existing settings system in `crates/settings/` with JSON schema

## Implementation Priority
1. Create observer_mode crate structure and Cargo.toml
2. Hook EditorEvent::ContentChanged and CursorMoved in editor.rs
3. Implement context gathering (cursor, visible code, diagnostics, git status)
4. Add LLM decision logic with structured JSON response parsing
5. Build notification/voice output system using Zed's UI
6. Integrate settings system following Zed patterns

## Testing
- Unit tests for context gathering and JSON parsing
- Integration tests with `#[gpui::test]` for editor interaction
- Mock LLM providers for deterministic testing