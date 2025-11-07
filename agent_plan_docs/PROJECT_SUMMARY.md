# Project Summary: Zed AI Pair Programmer

## Executive Summary

This project adds an AI-powered "observer mode" to Zed IDE that continuously watches your coding activity and proactively offers suggestions, similar to having an experienced developer pair programming with you in real-time.

## Problem Statement

Current AI coding assistants are **reactive** - they only help when you explicitly ask. This project creates a **proactive** AI pair programmer that:
- Watches what you're doing in real-time
- Understands context (code, errors, git status)
- Speaks up when it has valuable suggestions
- Works like a real pair programmer, not a chatbot

## Why Zed?

After extensive research, Zed IDE emerged as the perfect foundation because it already has:

| Feature | Status | Benefit |
|---------|--------|---------|
| **LLM Provider System** | ✅ Built-in | Supports Ollama, OpenAI, Anthropic, custom |
| **Edit Predictions** | ✅ Built-in | Already tracks keystrokes, gathers context |
| **Configurable Models** | ✅ Built-in | Different models for different features |
| **Open Source** | ✅ MIT License | Can fork and modify freely |
| **Rust Codebase** | ✅ Modern | Fast, safe, async/await |
| **Active Development** | ✅ 69.3k stars | Well-maintained, growing community |

**Bottom line:** Zed gives us 80% of what we need out of the box.

## Approach Comparison

### Option A: IntelliJ Plugin (Initial Approach)
```
❌ Complex: Plugin + External Orchestrator
❌ High Latency: HTTP/WebSocket overhead
❌ Build from Scratch: LLM integration, events, etc.
❌ Two Codebases: Plugin (Kotlin) + Orchestrator (Python)
❌ Limited Access: Plugin API restrictions
```

### Option B: Zed Fork (Chosen Approach)
```
✅ Simple: Single integrated binary
✅ Low Latency: Direct function calls
✅ Reuse Infrastructure: LLM, events already built
✅ One Codebase: All Rust
✅ Full Access: Can modify anything
```

**Decision:** Fork Zed and build observer mode directly into the editor.

## Technical Architecture

### High-Level Design

```
┌─────────────────────────────────────────┐
│           ZED EDITOR                     │
│                                          │
│  Editor Events (keystrokes, cursor)     │
│           ↓                              │
│  Observer Mode (NEW)                     │
│           ↓                              │
│  LLM Provider (existing)                 │
│           ↓                              │
│  Output (notifications or voice)         │
└─────────────────────────────────────────┘
```

### Implementation

**New Component:**
- `crates/observer_mode/` - New Rust crate

**Modified Components:**
- `crates/editor/` - Add observer event hooks
- `crates/workspace/` - Start observer timer
- `crates/zed/` - Initialize observer

**Reused Components:**
- LLM provider system
- Settings system
- UI framework (GPUI)
- Event system

## Features

### Core Features (MVP)
- ✅ Real-time code observation (every N seconds)
- ✅ Context gathering (code, errors, git status)
- ✅ LLM-powered analysis
- ✅ Proactive suggestions via notifications
- ✅ Configurable observation interval
- ✅ Configurable confidence threshold
- ✅ Local LLM support (Ollama)

### Optional Features (Future)
- ⚠️ Voice output (TTS)
- ⚠️ Voice input (STT with push-to-talk)
- ⚠️ Smart triggers (immediate on errors)
- ⚠️ Learning from feedback
- ⚠️ Multi-file context
- ⚠️ Team learning

## Configuration

Simple JSON configuration in Zed's `settings.json`:

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

## Development Timeline

| Phase | Duration | Deliverable |
|-------|----------|-------------|
| **Phase 1: Setup** | 2-3 days | Fork Zed, create observer_mode crate |
| **Phase 2: Events** | 3-4 days | Hook into editor events |
| **Phase 3: Core Logic** | 5-7 days | Context gathering + LLM integration |
| **Phase 4: Settings** | 2-3 days | Configuration system |
| **Phase 5: Integration** | 3-4 days | Working in Zed |
| **Phase 6: Voice** | 5-7 days | TTS/STT (optional) |
| **Total** | **3-4 weeks** | **Working prototype** |

## Success Metrics

### Technical Metrics
- ✅ Observer runs without blocking editor
- ✅ Performance impact < 5% CPU
- ✅ Memory impact < 100MB
- ✅ LLM latency < 2 seconds
- ✅ Suggestions appear within interval

### User Experience Metrics
- ✅ Suggestions are relevant and helpful
- ✅ Not annoying (respects confidence threshold)
- ✅ Easy to configure
- ✅ Easy to disable
- ✅ Clear indication when active

## Use Cases

### 1. Bug Detection
**Scenario:** Developer writes code with a potential bug

**Observer behavior:**
- Detects division by zero risk
- Suggests adding null check
- Speaks suggestion or shows notification

**Example:**
```python
def calculate_average(numbers):
    return sum(numbers) / len(numbers)  # Bug: division by zero
```

**Suggestion:**
> "Consider adding a check for empty list before division to avoid ZeroDivisionError"

### 2. Code Quality
**Scenario:** Developer uses inefficient pattern

**Observer behavior:**
- Detects inefficient loop
- Suggests list comprehension
- Provides example

**Example:**
```python
result = []
for item in items:
    result.append(item * 2)
```

**Suggestion:**
> "This can be simplified using a list comprehension: `result = [item * 2 for item in items]`"

### 3. Best Practices
**Scenario:** Developer violates language idioms

**Observer behavior:**
- Detects non-idiomatic code
- Suggests idiomatic alternative
- Explains why

**Example:**
```rust
let mut sum = 0;
for i in 0..numbers.len() {
    sum += numbers[i];
}
```

**Suggestion:**
> "Consider using iterator methods: `let sum: i32 = numbers.iter().sum();` - more idiomatic and safer"

## Advantages

### Over Traditional Linters
- **Context-aware:** Understands intent, not just syntax
- **Proactive:** Suggests improvements, not just errors
- **Conversational:** Natural language, not cryptic codes

### Over Chat-Based AI Assistants
- **Automatic:** No need to ask
- **Timely:** Suggests at the right moment
- **Integrated:** Works within your flow

### Over Code Completion
- **Broader scope:** Entire functions, not just next token
- **Explanatory:** Tells you why, not just what
- **Educational:** Helps you learn

## Risks and Mitigations

### Risk 1: Too Many Suggestions (Annoying)
**Mitigation:**
- Confidence threshold (only speak when confident)
- Configurable interval (not too frequent)
- Smart triggers (only on significant events)
- User can disable anytime

### Risk 2: Performance Impact
**Mitigation:**
- Async processing (non-blocking)
- Context limiting (only visible code)
- LLM caching (avoid redundant calls)
- Small, fast models (Qwen 7B)

### Risk 3: Privacy Concerns
**Mitigation:**
- Local-first (Ollama by default)
- No telemetry
- User controls LLM provider
- Clear documentation

### Risk 4: Irrelevant Suggestions
**Mitigation:**
- Tune prompts based on feedback
- Learn from accepted/rejected suggestions
- Allow user to customize prompts
- Continuous improvement

## Cost Analysis

### Development Cost
- **Time:** 3-4 weeks for MVP
- **Resources:** 1 developer
- **Infrastructure:** None (local development)

### Operating Cost
- **Local LLM (Ollama):** Free
- **Cloud LLM (OpenAI):** ~$0.002 per observation
- **Hosting:** None (runs locally)

**Recommendation:** Use local LLM (Ollama) for cost-free operation.

## Deployment Strategy

### Phase 1: Personal Use
- Fork Zed
- Build locally
- Use for personal projects
- Gather feedback

### Phase 2: Early Adopters
- Share with select users
- Collect feedback
- Iterate on features
- Improve prompts

### Phase 3: Public Release
- Create GitHub repository
- Write documentation
- Create demo video
- Share on social media

### Phase 4: Upstream Contribution (Optional)
- Clean up code
- Add tests
- Submit PR to Zed
- Work with maintainers

## Future Roadmap

### Short-term (1-3 months)
- [ ] MVP with notifications
- [ ] Voice support (TTS/STT)
- [ ] Smart triggers
- [ ] Performance optimization

### Medium-term (3-6 months)
- [ ] Learning from feedback
- [ ] Multi-file context
- [ ] Proactive refactoring
- [ ] Custom prompts

### Long-term (6-12 months)
- [ ] Team learning
- [ ] Plugin system
- [ ] Cloud sync (optional)
- [ ] Mobile companion app

## Conclusion

This project transforms Zed IDE into an AI pair programmer by adding a proactive observer mode that watches your coding and offers timely suggestions. By forking Zed and leveraging its existing infrastructure, we can build this in 3-4 weeks with minimal complexity.

**Key Takeaways:**
1. ✅ Zed is the perfect foundation (80% already built)
2. ✅ Simple architecture (single binary, no plugins)
3. ✅ Fast development (3-4 weeks to MVP)
4. ✅ Low cost (free with local LLMs)
5. ✅ High value (proactive AI pair programmer)

**Next Steps:**
1. Fork Zed repository
2. Create observer_mode crate
3. Implement core functionality
4. Test with real coding
5. Iterate and improve

---

**Status:** Research and planning complete. Ready to begin implementation.

**Contact:** Open an issue on GitHub for questions or feedback.

**License:** MIT (same as Zed)
