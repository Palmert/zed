# Architecture Documentation

## System Overview

The Zed AI Pair Programmer is built by adding an "observer mode" directly into Zed's codebase, leveraging its existing LLM infrastructure and editor event system.

## High-Level Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                        ZED PROCESS                              │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    EDITOR CORE                           │  │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐         │  │
│  │  │ Buffer     │  │ Selections │  │ Syntax     │         │  │
│  │  │ Management │  │ & Cursor   │  │ Tree       │         │  │
│  │  └────────────┘  └────────────┘  └────────────┘         │  │
│  └──────────────────────┬───────────────────────────────────┘  │
│                         │ Events                                │
│                         ▼                                       │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                  EVENT DISPATCHER                        │  │
│  │  • EditorEvent::ContentChanged                           │  │
│  │  • EditorEvent::CursorMoved                              │  │
│  │  • EditorEvent::FileOpened                               │  │
│  │  • EditorEvent::DiagnosticsUpdated                       │  │
│  └──────────────┬───────────────┬───────────────┬───────────┘  │
│                 │               │               │               │
│                 ▼               ▼               ▼               │
│  ┌──────────────────┐ ┌─────────────┐ ┌──────────────────┐    │
│  │ Edit Predictions │ │ LSP Compl.  │ │ OBSERVER MODE    │    │
│  │   (existing)     │ │  (existing) │ │    (NEW)         │    │
│  │                  │ │             │ │                  │    │
│  │ • Inline compl.  │ │ • Symbols   │ │ • Context gather │    │
│  │ • Tab to accept  │ │ • Hover     │ │ • LLM analysis   │    │
│  └──────────────────┘ └─────────────┘ │ • Proactive sugg │    │
│                                        └────────┬─────────┘    │
│                                                 │               │
│                                                 ▼               │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              LLM PROVIDER SYSTEM (existing)              │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐  │  │
│  │  │ Ollama   │  │ OpenAI   │  │ Anthropic│  │ Custom  │  │  │
│  │  └──────────┘  └──────────┘  └──────────┘  └─────────┘  │  │
│  └──────────────────────┬───────────────────────────────────┘  │
│                         │                                       │
│                         ▼                                       │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                  OUTPUT SYSTEM                           │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │  │
│  │  │ Notifications│  │ Voice (TTS)  │  │ Status Bar   │   │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘   │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
                                │
                                ▼
                    ┌────────────────────────┐
                    │   EXTERNAL SERVICES    │
                    │  • Ollama (localhost)  │
                    │  • OpenAI API          │
                    │  • Whisper (STT)       │
                    │  • Piper (TTS)         │
                    └────────────────────────┘
```

## Component Details

### 1. Observer Mode Crate

**Location:** `crates/observer_mode/`

**Responsibilities:**
- Monitor editor events
- Gather coding context
- Call LLM for analysis
- Output suggestions

**Key Files:**
```
observer_mode/
├── src/
│   ├── lib.rs          # Public API, module exports
│   ├── observer.rs     # Main Observer struct and logic
│   ├── context.rs      # Context gathering from editor
│   ├── decision.rs     # LLM decision parsing
│   ├── output.rs       # Notification and voice output
│   ├── settings.rs     # Settings schema and loading
│   └── voice.rs        # TTS/STT integration (optional)
```

**Data Flow:**
```
Editor Event → Observer.observe()
             → gather_context()
             → ask_llm()
             → parse_decision()
             → output_suggestion()
```

### 2. Context Gathering

**What we collect:**
```rust
struct ObservationContext {
    // File information
    file_path: Option<String>,
    language: Option<String>,
    
    // Cursor information
    cursor_line: u32,
    cursor_column: u32,
    
    // Code context
    visible_code: String,        // ±10 lines around cursor
    full_file: Option<String>,   // Full file if small
    
    // Diagnostics
    errors: Vec<Diagnostic>,
    warnings: Vec<Diagnostic>,
    
    // Git information
    git_status: GitStatus,
    uncommitted_changes: bool,
    current_branch: String,
    
    // Recent activity
    recent_edits: Vec<Edit>,
    time_since_last_edit: Duration,
}
```

**Context Optimization:**
- Only send visible code (not entire file)
- Limit to ±10 lines around cursor
- Include syntax tree for structure
- Include diagnostics for error awareness

### 3. LLM Integration

**Prompt Structure:**
```
You are an AI pair programmer observing a developer's work.

Context:
- File: {file_path}
- Language: {language}
- Line {line}, Column {column}
- Recent changes: {git_status}

Code:
```
{visible_code}
```

Diagnostics:
{errors_and_warnings}

Your job:
1. Watch for potential issues
2. Suggest improvements proactively but not annoyingly
3. Only speak when you have something valuable to say
4. Be concise and actionable

Should you make a suggestion?

Respond in JSON:
{
  "should_speak": true/false,
  "confidence": 0.0-1.0,
  "suggestion": "your suggestion here",
  "reasoning": "why you're suggesting this"
}
```

**LLM Response Parsing:**
```rust
#[derive(Deserialize)]
struct Decision {
    should_speak: bool,
    confidence: f32,
    suggestion: String,
    reasoning: String,
}
```

### 4. Event System

**Editor Events We Hook:**
```rust
enum EditorEvent {
    ContentChanged,      // User typed/deleted
    CursorMoved,         // Cursor position changed
    FileOpened,          // New file opened
    FileSaved,           // File saved
    DiagnosticsUpdated,  // Errors/warnings changed
    SelectionChanged,    // Selection changed
}
```

**Observer Event Loop:**
```rust
// In workspace.rs
cx.spawn(|workspace, mut cx| async move {
    loop {
        // Wait for interval
        cx.background_executor()
          .timer(Duration::from_secs(interval))
          .await;
        
        // Get active editor
        workspace.update(&mut cx, |workspace, cx| {
            if let Some(editor) = workspace.active_item_as::<Editor>(cx) {
                // Trigger observation
                let mut observer = cx.global_mut::<Observer>();
                observer.observe(&editor, cx);
            }
        }).ok();
    }
}).detach();
```

### 5. Settings System

**Settings Schema:**
```rust
#[derive(Deserialize, JsonSchema)]
struct ObserverSettings {
    enabled: bool,
    interval_seconds: u64,
    model: String,
    voice_enabled: bool,
    min_confidence: f32,
    
    // Advanced
    proactive_triggers: ProactiveTriggers,
    context_limits: ContextLimits,
}

#[derive(Deserialize, JsonSchema)]
struct ProactiveTriggers {
    on_error: bool,
    on_warning: bool,
    on_git_conflict: bool,
}

#[derive(Deserialize, JsonSchema)]
struct ContextLimits {
    lines_before: u32,
    lines_after: u32,
    include_imports: bool,
    include_diagnostics: bool,
}
```

**Settings Loading:**
```rust
impl Settings for ObserverSettings {
    const KEY: Option<&'static str> = Some("observer_mode");
    
    fn load(
        defaults: &Self,
        user_values: &[&Self],
        cx: &mut AppContext,
    ) -> Result<Self> {
        // Merge defaults with user settings
        // ...
    }
}
```

### 6. Output System

**Notification Output:**
```rust
fn show_notification(&self, suggestion: String, cx: &mut AppContext) {
    cx.show_notification(Notification {
        title: "AI Observer".to_string(),
        message: suggestion,
        severity: NotificationSeverity::Info,
        actions: vec![
            NotificationAction {
                label: "Apply".to_string(),
                action: Box::new(|cx| {
                    // Apply suggestion
                }),
            },
            NotificationAction {
                label: "Dismiss".to_string(),
                action: Box::new(|cx| {
                    // Dismiss
                }),
            },
        ],
    });
}
```

**Voice Output:**
```rust
async fn speak(&self, text: String) {
    // Use Piper TTS or similar
    let audio = self.tts_engine.synthesize(text).await?;
    self.audio_player.play(audio).await?;
}
```

## Performance Considerations

### 1. Async Processing

All LLM calls are async and non-blocking:
```rust
cx.spawn(|_, cx| async move {
    let decision = observer.ask_llm(context, cx).await?;
    // Handle decision
}).detach();
```

### 2. Debouncing

Don't observe on every keystroke:
```rust
if let Some(last) = self.last_observation {
    if last.elapsed() < self.interval {
        return;  // Skip this observation
    }
}
```

### 3. Context Limiting

Only send relevant code:
```rust
// Don't send entire file
let start_line = cursor_line.saturating_sub(10);
let end_line = (cursor_line + 10).min(buffer.max_line());
let visible_code = buffer.text_for_range(start_line..end_line);
```

### 4. LLM Caching

Cache recent contexts to avoid redundant calls:
```rust
struct Observer {
    context_cache: LruCache<ContextHash, Decision>,
}

fn ask_llm(&mut self, context: Context) -> Decision {
    let hash = context.hash();
    if let Some(cached) = self.context_cache.get(&hash) {
        return cached.clone();
    }
    // ... call LLM ...
}
```

## Security Considerations

### 1. Local-First

- Default to local LLMs (Ollama)
- No code sent to cloud unless explicitly configured
- User controls which LLM provider to use

### 2. API Key Management

- Reuse Zed's existing API key storage
- Keys stored in OS keychain
- Never logged or exposed

### 3. Privacy

- No telemetry by default
- User can disable observer mode entirely
- Clear indication when observer is active

## Extensibility

### Adding New Triggers

```rust
enum Trigger {
    Interval(Duration),
    OnError,
    OnWarning,
    OnGitConflict,
    OnFileOpen,
    Custom(Box<dyn Fn(&Editor) -> bool>),
}
```

### Custom Output Handlers

```rust
trait OutputHandler {
    fn handle(&self, suggestion: Suggestion, cx: &mut AppContext);
}

struct NotificationHandler;
struct VoiceHandler;
struct StatusBarHandler;
```

### Plugin System (Future)

```rust
trait ObserverPlugin {
    fn name(&self) -> &str;
    fn on_observation(&self, context: &Context) -> Option<Suggestion>;
}
```

## Testing Strategy

### Unit Tests

```rust
#[cfg(test)]
mod tests {
    #[test]
    fn test_context_gathering() {
        let editor = create_test_editor();
        let context = gather_context(&editor);
        assert_eq!(context.cursor_line, 10);
    }
    
    #[test]
    fn test_decision_parsing() {
        let json = r#"{"should_speak": true, "confidence": 0.9}"#;
        let decision: Decision = serde_json::from_str(json).unwrap();
        assert!(decision.should_speak);
    }
}
```

### Integration Tests

```rust
#[gpui::test]
async fn test_observer_flow(cx: &mut TestAppContext) {
    let workspace = create_test_workspace(cx);
    let editor = workspace.active_editor();
    
    // Type code with bug
    editor.insert("def foo():\n  return 1/0");
    
    // Wait for observation
    cx.executor().advance_clock(Duration::from_secs(10));
    
    // Check for suggestion
    assert!(workspace.has_notification());
}
```

## Deployment

### Building

```bash
# Development build
cargo build

# Release build
cargo build --release

# Platform-specific builds
cargo build --release --target x86_64-apple-darwin
cargo build --release --target x86_64-unknown-linux-gnu
cargo build --release --target x86_64-pc-windows-msvc
```

### Distribution

- Single binary (Zed with observer mode built-in)
- No separate installation required
- Settings configured via `settings.json`

## Monitoring and Debugging

### Logging

```rust
log::info!("Observer triggered");
log::debug!("Context: {:?}", context);
log::warn!("LLM call failed: {}", error);
```

### Metrics

```rust
struct ObserverMetrics {
    observations_count: u64,
    suggestions_made: u64,
    suggestions_accepted: u64,
    avg_llm_latency: Duration,
}
```

### Debug Mode

```bash
RUST_LOG=observer_mode=debug cargo run
```

## Future Architecture Improvements

### 1. Multi-File Context

Extend context to include related files:
```rust
struct EnhancedContext {
    current_file: FileContext,
    related_files: Vec<FileContext>,
    project_structure: ProjectTree,
}
```

### 2. Persistent Memory

Store observations and learnings:
```rust
struct ObserverMemory {
    past_suggestions: Vec<Suggestion>,
    user_preferences: UserPreferences,
    project_patterns: Vec<Pattern>,
}
```

### 3. Collaborative Learning

Share learnings across team:
```rust
struct TeamLearning {
    shared_patterns: Arc<RwLock<Vec<Pattern>>>,
    team_preferences: TeamPreferences,
}
```

## Conclusion

This architecture leverages Zed's existing infrastructure while adding minimal new components. The observer mode integrates cleanly with Zed's event system, LLM providers, and settings, making it a natural extension of the editor rather than a bolted-on plugin.
