# Zed IDE Research Findings for AI Pair Programmer

## Key Discovery: Zed is the Perfect Foundation

After researching Zed's architecture and capabilities, it's clear that **forking Zed is the ideal approach** for building your AI pair programmer.

## Why Zed is Perfect

### 1. **Already Has the Infrastructure We Need**

**Existing AI/LLM Integration:**
- ✅ Built-in LLM provider system (Ollama, OpenAI, Anthropic, custom providers)
- ✅ Edit predictions (inline completions) with configurable models
- ✅ Agent Panel for chat-based AI interaction
- ✅ Inline Assistant for code transformation
- ✅ Model Context Protocol (MCP) support
- ✅ Configurable per-feature LLM selection

**Code Completion Infrastructure:**
- ✅ Real-time keystroke tracking
- ✅ Cursor position monitoring
- ✅ Syntax tree parsing
- ✅ Context gathering
- ✅ Debouncing logic
- ✅ LSP integration

### 2. **Open Source & Rust-Based**

- ✅ MIT licensed - can fork and modify freely
- ✅ Written in Rust - high performance, memory safe
- ✅ Modern async/await architecture
- ✅ Well-structured codebase with clear module separation
- ✅ Active development (69.3k stars, daily commits)

### 3. **Relevant Crates in the Repository**

From browsing the `/crates` directory, key modules include:

**AI-Related:**
- `agent` - AI agent functionality
- `agent_servers` - Agent server integration
- `agent_settings` - Agent configuration
- `agent_ui` - Agent UI components
- `ai_onboarding` - AI onboarding flow
- `acp_thread` - Edit prediction threading
- `acp_tools` - Edit prediction tools
- `anthropic` - Anthropic LLM provider

**Editor-Related:**
- `editor` - Core editor functionality
- `language` - Language support
- `lsp` - Language Server Protocol
- `completion` - Code completion

**Infrastructure:**
- `gpui` - Zed's UI framework
- `settings` - Configuration system
- `workspace` - Workspace management

## What We Can Leverage

### 1. **Configurable LLM System**

Zed already supports:
```json
{
  "language_models": {
    "ollama": {
      "api_url": "http://localhost:11434"
    }
  },
  "edit_prediction_provider": "zed"  // or "copilot", "supermaven"
}
```

**This means:**
- We can configure a small, fast model (Qwen 2.5 Coder 7B) for observations
- We can use a different model for code generation
- All the LLM infrastructure is already built

### 2. **Edit Prediction System**

Zed's edit predictions already:
- Monitor keystrokes in real-time
- Gather context (file, cursor, syntax tree)
- Call LLM for suggestions
- Display inline suggestions
- Handle accept/reject

**We just need to:**
- Add an "observer mode" alongside edit predictions
- Make it proactive (suggest without waiting for completion trigger)
- Add voice output for suggestions

### 3. **Extension Points**

From the codebase structure, we can:
- Add a new crate for `observer_mode`
- Hook into existing editor events
- Reuse LLM provider infrastructure
- Integrate with existing UI components

## Implementation Strategy

### Phase 1: Fork & Understand (Week 1)
1. Fork Zed repository
2. Build and run locally
3. Study `acp_thread` (edit prediction) crate
4. Study `agent` crate
5. Study `editor` crate event system

### Phase 2: Add Observer Mode (Week 2-3)
1. Create new `observer_mode` crate
2. Hook into editor events (keystrokes, cursor movement, file changes)
3. Implement observation loop (every N seconds)
4. Call configured LLM with context
5. Parse LLM response for suggestions
6. Display suggestions (initially via notifications)

### Phase 3: Add Voice (Week 4)
1. Integrate Whisper for STT
2. Integrate Piper/coqui-tts for TTS
3. Add PTT keybinding
4. Speak suggestions instead of showing notifications
5. Accept voice commands

### Phase 4: Refinement (Week 5-6)
1. Tune observation frequency
2. Improve context gathering
3. Add memory/learning
4. Performance optimization
5. UI polish

## Advantages Over IntelliJ Plugin Approach

| Aspect | IntelliJ Plugin | Zed Fork |
|--------|----------------|----------|
| **Architecture** | Plugin + External Orchestrator | Single integrated binary |
| **Performance** | HTTP/WS overhead | Direct function calls |
| **LLM Integration** | Build from scratch | Already built-in |
| **Completion Events** | Need to hook via API | Direct access to events |
| **Voice** | External process | Can integrate directly |
| **Deployment** | Plugin install + orchestrator | Single binary |
| **Maintenance** | Two codebases | One codebase |
| **Latency** | Higher (IPC) | Lower (in-process) |

## Key Files to Examine

Based on crate names, priority files to study:

1. `crates/acp_thread/` - Edit prediction threading
2. `crates/agent/` - AI agent implementation
3. `crates/editor/src/editor.rs` - Editor events
4. `crates/language/` - Language/syntax support
5. `crates/settings/` - Configuration system
6. `crates/gpui/` - UI framework

## Configuration We Can Reuse

Zed already supports:
- Custom LLM providers (Ollama, OpenAI-compatible APIs)
- Per-feature model selection
- API key management
- Local-first operation

## Next Steps

1. **Clone and build Zed locally**
   ```bash
   git clone https://github.com/zed-industries/zed.git
   cd zed
   cargo build --release
   ```

2. **Study the edit prediction system**
   - How does `acp_thread` work?
   - How does it gather context?
   - How does it call LLMs?
   - How does it display suggestions?

3. **Design the observer mode integration**
   - Where to hook in?
   - How to avoid conflicts with edit predictions?
   - How to make it configurable?

4. **Prototype the observer**
   - Simple version: log observations
   - Add LLM call
   - Add notification display
   - Add voice output

## Conclusion

**Zed is the perfect foundation** because:

1. ✅ It already has 80% of what we need
2. ✅ It's open source and forkable
3. ✅ It's written in Rust (fast, safe)
4. ✅ It has configurable LLM support
5. ✅ It has edit prediction infrastructure
6. ✅ It's actively maintained
7. ✅ We can build directly into the editor (no plugin complexity)

**The IntelliJ plugin I built is now obsolete** - Zed gives us a much better starting point.

**Estimated time to working prototype:** 4-6 weeks
**Estimated time to polished product:** 3-4 months

This is significantly faster and cleaner than the IntelliJ approach.
