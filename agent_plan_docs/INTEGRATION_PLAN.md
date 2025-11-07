# Zed Observer Mode - Integration Plan

## Overview

This document outlines how to integrate an AI pair programmer "observer mode" into Zed by leveraging its existing infrastructure.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         ZED EDITOR                           │
│                                                              │
│  ┌────────────────────────────────────────────────────┐     │
│  │              EDITOR (existing)                     │     │
│  │  • Keystroke events                                │     │
│  │  • Cursor movement                                 │     │
│  │  • File changes                                    │     │
│  │  • Syntax tree                                     │     │
│  └──────────────┬─────────────────────────────────────┘     │
│                 │                                            │
│                 ├──────────────┬──────────────┐             │
│                 ▼              ▼              ▼             │
│  ┌──────────────────┐ ┌─────────────┐ ┌──────────────┐     │
│  │ Edit Predictions │ │ LSP Compl.  │ │ OBSERVER MODE│     │
│  │   (existing)     │ │  (existing) │ │    (NEW)     │     │
│  └──────────────────┘ └─────────────┘ └──────┬───────┘     │
│                                               │             │
│                                               ▼             │
│                                    ┌────────────────────┐   │
│                                    │  LLM Provider      │   │
│                                    │  (existing)        │   │
│                                    │  • Ollama          │   │
│                                    │  • OpenAI          │   │
│                                    │  • Custom          │   │
│                                    └────────┬───────────┘   │
│                                             │               │
│                                             ▼               │
│                                    ┌────────────────────┐   │
│                                    │  Output            │   │
│                                    │  • Notifications   │   │
│                                    │  • Voice (TTS)     │   │
│                                    └────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Implementation Phases

### Phase 1: Create Observer Mode Crate

**Location:** `crates/observer_mode/`

**Files to create:**
```
crates/observer_mode/
├── Cargo.toml
├── src/
│   ├── lib.rs              # Public API
│   ├── observer.rs         # Main observer logic
│   ├── context.rs          # Context gathering
│   ├── decision.rs         # LLM decision logic
│   └── output.rs           # Notification/voice output
```

**Dependencies (Cargo.toml):**
```toml
[dependencies]
gpui = { path = "../gpui" }
editor = { path = "../editor" }
language = { path = "../language" }
settings = { path = "../settings" }
client = { path = "../client" }  # For LLM calls
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
anyhow = "1.0"
log = "0.4"
```

### Phase 2: Hook into Editor Events

**File to modify:** `crates/editor/src/editor.rs`

**Add observer event emissions:**

```rust
// In Editor struct
pub struct Editor {
    // ... existing fields ...
    observer_enabled: bool,
    last_observation: Option<Instant>,
}

// In Editor impl
impl Editor {
    // Hook into existing event handlers
    fn handle_input(&mut self, text: &str, cx: &mut ViewContext<Self>) {
        // ... existing code ...
        
        // Notify observer
        if self.observer_enabled {
            cx.emit(EditorEvent::ContentChanged);
        }
    }
    
    fn move_cursor(&mut self, movement: Movement, cx: &mut ViewContext<Self>) {
        // ... existing code ...
        
        // Notify observer
        if self.observer_enabled {
            cx.emit(EditorEvent::CursorMoved);
        }
    }
}
```

### Phase 3: Implement Observer Logic

**File:** `crates/observer_mode/src/observer.rs`

```rust
use std::time::{Duration, Instant};
use gpui::*;
use editor::{Editor, EditorEvent};
use language::Buffer;

pub struct Observer {
    enabled: bool,
    interval: Duration,
    last_check: Option<Instant>,
    llm_client: Arc<dyn LanguageModelProvider>,
}

impl Observer {
    pub fn new(cx: &mut AppContext) -> Self {
        let settings = ObserverSettings::get_global(cx);
        
        Self {
            enabled: settings.enabled,
            interval: Duration::from_secs(settings.interval_seconds),
            last_check: None,
            llm_client: get_llm_provider(cx, &settings.model),
        }
    }
    
    pub fn observe(&mut self, editor: &Editor, cx: &mut AppContext) {
        // Check if enough time has passed
        if let Some(last) = self.last_check {
            if last.elapsed() < self.interval {
                return;
            }
        }
        
        // Gather context
        let context = self.gather_context(editor, cx);
        
        // Ask LLM for decision
        let decision = self.ask_llm(context, cx);
        
        // Act on decision
        if decision.should_speak {
            self.output_suggestion(decision.suggestion, cx);
        }
        
        self.last_check = Some(Instant::now());
    }
    
    fn gather_context(&self, editor: &Editor, cx: &AppContext) -> ObservationContext {
        let buffer = editor.buffer().read(cx);
        let cursor = editor.selections.newest_anchor().head();
        let cursor_position = cursor.to_point(&buffer);
        
        // Get surrounding code
        let start_line = cursor_position.row.saturating_sub(10);
        let end_line = (cursor_position.row + 10).min(buffer.max_point().row);
        let visible_code = buffer.text_for_range(
            Point::new(start_line, 0)..Point::new(end_line, 0)
        ).collect::<String>();
        
        // Get file info
        let file_path = buffer.file().map(|f| f.path().to_string_lossy().to_string());
        let language = buffer.language().map(|l| l.name());
        
        // Get git status
        let git_status = editor.project().read(cx).git_status();
        
        // Get diagnostics (errors/warnings)
        let diagnostics = editor.diagnostics(cx);
        
        ObservationContext {
            file_path,
            language,
            cursor_line: cursor_position.row,
            cursor_column: cursor_position.column,
            visible_code,
            diagnostics,
            git_status,
        }
    }
    
    async fn ask_llm(&self, context: ObservationContext, cx: &AsyncAppContext) -> Decision {
        let prompt = format!(
            r#"You are an AI pair programmer observing a developer's work.

Context:
- File: {}
- Language: {}
- Line {}, Column {}
- Recent changes: {}

Code:
```
{}
```

Diagnostics:
{}

Your job:
1. Watch for potential issues (bugs, anti-patterns, inefficiencies)
2. Suggest improvements proactively but not annoyingly
3. Only speak when you have something valuable to say
4. Be concise and actionable

Should you make a suggestion? If yes, what should you say?

Respond in JSON:
{{
  "should_speak": true/false,
  "confidence": 0.0-1.0,
  "suggestion": "your suggestion here",
  "reasoning": "why you're suggesting this"
}}
"#,
            context.file_path.unwrap_or_default(),
            context.language.unwrap_or_default(),
            context.cursor_line,
            context.cursor_column,
            context.git_status,
            context.visible_code,
            context.diagnostics,
        );
        
        // Call LLM
        let response = self.llm_client.complete(prompt, cx).await?;
        
        // Parse response
        serde_json::from_str(&response).unwrap_or(Decision::default())
    }
    
    fn output_suggestion(&self, suggestion: String, cx: &mut AppContext) {
        let settings = ObserverSettings::get_global(cx);
        
        if settings.voice_enabled {
            // Speak the suggestion
            self.speak(suggestion, cx);
        } else {
            // Show notification
            cx.show_notification(Notification {
                title: "AI Observer".to_string(),
                message: suggestion,
                severity: NotificationSeverity::Info,
            });
        }
    }
    
    fn speak(&self, text: String, cx: &mut AppContext) {
        // TODO: Integrate TTS
        // For now, just log
        log::info!("[TTS] {}", text);
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct ObservationContext {
    file_path: Option<String>,
    language: Option<String>,
    cursor_line: u32,
    cursor_column: u32,
    visible_code: String,
    diagnostics: String,
    git_status: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Decision {
    should_speak: bool,
    confidence: f32,
    suggestion: String,
    reasoning: String,
}

impl Default for Decision {
    fn default() -> Self {
        Self {
            should_speak: false,
            confidence: 0.0,
            suggestion: String::new(),
            reasoning: String::new(),
        }
    }
}
```

### Phase 4: Add Settings

**File:** `crates/observer_mode/src/settings.rs`

```rust
use serde::{Deserialize, Serialize};
use settings::Settings;

#[derive(Clone, Debug, Serialize, Deserialize, JsonSchema)]
pub struct ObserverSettings {
    /// Enable observer mode
    pub enabled: bool,
    
    /// Observation interval in seconds
    pub interval_seconds: u64,
    
    /// LLM model to use for observations
    pub model: String,
    
    /// Enable voice output
    pub voice_enabled: bool,
    
    /// Minimum confidence to speak (0.0-1.0)
    pub min_confidence: f32,
}

impl Default for ObserverSettings {
    fn default() -> Self {
        Self {
            enabled: false,
            interval_seconds: 10,
            model: "qwen2.5-coder:7b".to_string(),
            voice_enabled: false,
            min_confidence: 0.7,
        }
    }
}

impl Settings for ObserverSettings {
    const KEY: Option<&'static str> = Some("observer_mode");
    
    type FileContent = Self;
    
    fn load(
        defaults: &Self::FileContent,
        user_values: &[&Self::FileContent],
        _: &mut AppContext,
    ) -> Result<Self> {
        Ok(Self {
            enabled: user_values.last().map(|v| v.enabled).unwrap_or(defaults.enabled),
            interval_seconds: user_values.last().map(|v| v.interval_seconds).unwrap_or(defaults.interval_seconds),
            model: user_values.last().map(|v| v.model.clone()).unwrap_or(defaults.model.clone()),
            voice_enabled: user_values.last().map(|v| v.voice_enabled).unwrap_or(defaults.voice_enabled),
            min_confidence: user_values.last().map(|v| v.min_confidence).unwrap_or(defaults.min_confidence),
        })
    }
}
```

**User configuration (settings.json):**
```json
{
  "observer_mode": {
    "enabled": true,
    "interval_seconds": 10,
    "model": "qwen2.5-coder:7b",
    "voice_enabled": false,
    "min_confidence": 0.7
  },
  "language_models": {
    "ollama": {
      "api_url": "http://localhost:11434"
    }
  }
}
```

### Phase 5: Integrate with Main App

**File to modify:** `crates/zed/src/main.rs`

```rust
use observer_mode::Observer;

fn main() {
    // ... existing initialization ...
    
    // Initialize observer
    let observer = Observer::new(&mut cx);
    cx.set_global(observer);
    
    // ... rest of main ...
}
```

**File to modify:** `crates/workspace/src/workspace.rs`

```rust
impl Workspace {
    fn new(...) -> Self {
        // ... existing code ...
        
        // Start observer timer
        if ObserverSettings::get_global(cx).enabled {
            cx.spawn(|workspace, mut cx| async move {
                loop {
                    cx.background_executor().timer(Duration::from_secs(1)).await;
                    
                    workspace.update(&mut cx, |workspace, cx| {
                        if let Some(editor) = workspace.active_item_as::<Editor>(cx) {
                            let mut observer = cx.global_mut::<Observer>();
                            observer.observe(&editor, cx);
                        }
                    }).ok();
                }
            }).detach();
        }
        
        // ... rest of new ...
    }
}
```

### Phase 6: Add Voice Support (Optional)

**Dependencies to add:**
```toml
[dependencies]
# For TTS
coqui-tts = "0.1"  # or piper-tts
# For STT
whisper-rs = "0.1"
```

**File:** `crates/observer_mode/src/voice.rs`

```rust
use std::sync::Arc;

pub struct VoiceInterface {
    tts_engine: Arc<dyn TextToSpeech>,
    stt_engine: Arc<dyn SpeechToText>,
}

impl VoiceInterface {
    pub fn new() -> Self {
        Self {
            tts_engine: Arc::new(PiperTTS::new()),
            stt_engine: Arc::new(WhisperSTT::new()),
        }
    }
    
    pub async fn speak(&self, text: &str) {
        self.tts_engine.speak(text).await;
    }
    
    pub async fn listen(&self) -> String {
        self.stt_engine.transcribe().await
    }
}

trait TextToSpeech: Send + Sync {
    async fn speak(&self, text: &str);
}

trait SpeechToText: Send + Sync {
    async fn transcribe(&self) -> String;
}
```

## Configuration Examples

### Minimal (Text-only)
```json
{
  "observer_mode": {
    "enabled": true,
    "interval_seconds": 10,
    "model": "qwen2.5-coder:7b"
  }
}
```

### With Voice
```json
{
  "observer_mode": {
    "enabled": true,
    "interval_seconds": 10,
    "model": "qwen2.5-coder:7b",
    "voice_enabled": true,
    "min_confidence": 0.8
  }
}
```

### Advanced
```json
{
  "observer_mode": {
    "enabled": true,
    "interval_seconds": 5,
    "model": "qwen2.5-coder:7b",
    "voice_enabled": true,
    "min_confidence": 0.75,
    "proactive_triggers": {
      "on_error": true,
      "on_warning": false,
      "on_git_conflict": true
    }
  }
}
```

## Testing Plan

### Unit Tests
```rust
#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_context_gathering() {
        // Test that context is properly gathered
    }
    
    #[test]
    fn test_llm_decision_parsing() {
        // Test JSON parsing of LLM responses
    }
    
    #[test]
    fn test_interval_timing() {
        // Test that observations respect interval
    }
}
```

### Integration Tests
1. Start Zed with observer enabled
2. Type code with a bug
3. Wait for observation interval
4. Verify suggestion appears
5. Accept/dismiss suggestion

## Performance Considerations

### Optimization Strategies

1. **Debouncing**
   - Don't observe on every keystroke
   - Wait for pause in typing (e.g., 2 seconds)
   
2. **Context Limiting**
   - Only send visible code (±10 lines)
   - Don't send entire file
   
3. **LLM Caching**
   - Cache recent contexts
   - Don't re-analyze unchanged code
   
4. **Async Processing**
   - LLM calls happen in background
   - Don't block editor
   
5. **Smart Triggering**
   - Trigger immediately on errors
   - Trigger less frequently on normal typing

## Deployment

### Building
```bash
cd zed
cargo build --release
```

### Running
```bash
./target/release/zed
```

### Distribution
- Package as standalone binary
- Include in Zed fork
- Optionally: Submit as PR to upstream Zed (if they want it)

## Timeline

| Phase | Duration | Deliverable |
|-------|----------|-------------|
| 1. Create crate | 2 days | Basic structure |
| 2. Hook events | 3 days | Events flowing |
| 3. Observer logic | 5 days | LLM integration working |
| 4. Settings | 2 days | Configurable |
| 5. Integration | 3 days | Runs in Zed |
| 6. Voice (optional) | 5 days | TTS/STT working |
| **Total** | **3-4 weeks** | **Working prototype** |

## Success Criteria

- ✅ Observer runs without blocking editor
- ✅ Suggestions appear at configured interval
- ✅ LLM receives proper context
- ✅ Suggestions are relevant and helpful
- ✅ Performance impact < 5% CPU
- ✅ Memory impact < 100MB
- ✅ User can configure all settings
- ✅ Voice output works (if enabled)

## Future Enhancements

1. **Learning from feedback**
   - Track accepted/rejected suggestions
   - Adjust confidence thresholds
   
2. **Multi-file context**
   - Include related files
   - Project-wide analysis
   
3. **Proactive refactoring**
   - Suggest larger refactorings
   - Generate diffs
   
4. **Team learning**
   - Share patterns across team
   - Learn from code reviews

## Conclusion

This integration plan leverages Zed's existing infrastructure to add observer mode with minimal changes to core code. The modular design allows for incremental development and testing.

**Key advantages:**
- Reuses Zed's LLM provider system
- Minimal changes to existing code
- Clean separation of concerns
- Easy to configure and extend
- Performance-conscious design
