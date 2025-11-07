# Zed AI Pair Programmer

An AI pair programming assistant built directly into Zed IDE with real-time observation, proactive suggestions, and optional voice interaction.

## Overview

This project adds an "observer mode" to Zed that:
- ✅ Continuously watches your coding activity
- ✅ Analyzes context (code, errors, git status)
- ✅ Makes proactive suggestions via notifications or voice
- ✅ Uses configurable local LLMs (Ollama, OpenAI, etc.)
- ✅ Integrates seamlessly with Zed's existing AI features

## Why Zed?

Zed is the perfect foundation because it already has:
- Built-in LLM provider system (Ollama, OpenAI, Anthropic, custom)
- Edit prediction infrastructure (keystroke tracking, context gathering)
- Configurable per-feature model selection
- Modern Rust codebase with async/await
- Open source (MIT license)

**We're not building a plugin - we're forking Zed and adding observer mode directly.**

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    ZED EDITOR                            │
│                                                          │
│  ┌────────────────────────────────────────────────┐     │
│  │         EDITOR (existing)                      │     │
│  │  • Keystroke events                            │     │
│  │  • Cursor movement                             │     │
│  │  • File changes                                │     │
│  └──────────────┬─────────────────────────────────┘     │
│                 │                                        │
│                 ├──────────────┬──────────────┐         │
│                 ▼              ▼              ▼         │
│  ┌──────────────────┐ ┌──────────┐ ┌──────────────┐    │
│  │ Edit Predictions │ │ LSP      │ │ OBSERVER MODE│    │
│  │   (existing)     │ │(existing)│ │    (NEW)     │    │
│  └──────────────────┘ └──────────┘ └──────┬───────┘    │
│                                            │            │
│                                            ▼            │
│                                 ┌────────────────────┐  │
│                                 │  LLM Provider      │  │
│                                 │  (existing)        │  │
│                                 │  • Ollama          │  │
│                                 │  • OpenAI          │  │
│                                 └────────┬───────────┘  │
│                                          │              │
│                                          ▼              │
│                                 ┌────────────────────┐  │
│                                 │  Output            │  │
│                                 │  • Notifications   │  │
│                                 │  • Voice (TTS)     │  │
│                                 └────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

## Features

### Core Features
- **Real-time observation** - Monitors your coding every N seconds (configurable)
- **Context-aware** - Sees your code, cursor position, errors, git status
- **Proactive suggestions** - Speaks up when it has something valuable to say
- **Configurable LLM** - Use small, fast models (Qwen 2.5 Coder 7B) for observation
- **Non-blocking** - Runs asynchronously, never blocks the editor

### Optional Features
- **Voice output** - Speaks suggestions using TTS (Piper/Coqui)
- **Voice input** - Accept commands via push-to-talk (Whisper STT)
- **Confidence filtering** - Only speaks when confidence > threshold
- **Smart triggers** - Immediate suggestions on errors, less frequent during normal typing

## Configuration

Add to your Zed `settings.json`:

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

## Quick Start

### Prerequisites
- Rust toolchain (1.70+)
- Ollama with Qwen 2.5 Coder model
- macOS, Linux, or Windows

### Installation

1. **Run the setup script**
   ```bash
   ./setup.sh
   ```

2. **Or manually clone the forked Zed repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/zed.git
   cd zed
   ```

2. **Install Ollama and download model**
   ```bash
   # Install Ollama
   curl -fsSL https://ollama.com/install.sh | sh
   
   # Download Qwen model
   ollama pull qwen2.5-coder:7b
   
   # Start Ollama
   ollama serve
   ```

3. **Build Zed with observer mode**
   ```bash
   cargo build --release
   ```

4. **Run Zed**
   ```bash
   ./target/release/zed
   ```

5. **Enable observer mode**
   - Open settings (Cmd+, or Ctrl+,)
   - Add observer_mode configuration (see above)
   - Start coding!

## Implementation Timeline

| Phase | Duration | Deliverable |
|-------|----------|-------------|
| 1. Create observer_mode crate | 2-3 days | Basic structure |
| 2. Hook into editor events | 3-4 days | Events flowing |
| 3. Implement observer logic | 5-7 days | LLM integration |
| 4. Add settings system | 2-3 days | Configurable |
| 5. Integrate with Zed | 3-4 days | Working in Zed |
| 6. Add voice (optional) | 5-7 days | TTS/STT working |
| **Total** | **3-4 weeks** | **Working prototype** |

## Project Structure

```
zed/
├── crates/
│   ├── observer_mode/          # NEW: Observer mode crate
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── lib.rs          # Public API
│   │       ├── observer.rs     # Main observer logic
│   │       ├── context.rs      # Context gathering
│   │       ├── decision.rs     # LLM decision logic
│   │       ├── output.rs       # Notification/voice output
│   │       ├── settings.rs     # Settings definition
│   │       └── voice.rs        # Voice I/O (optional)
│   ├── editor/                 # MODIFIED: Add observer hooks
│   ├── workspace/              # MODIFIED: Start observer timer
│   └── zed/                    # MODIFIED: Initialize observer
└── docs/
    ├── RESEARCH_FINDINGS.md    # Why Zed is perfect
    ├── INTEGRATION_PLAN.md     # Implementation guide
    └── ARCHITECTURE.md         # Technical architecture
```

## Documentation

- **[Research Findings](./RESEARCH_FINDINGS.md)** - Why Zed is the perfect foundation
- **[Integration Plan](./INTEGRATION_PLAN.md)** - Detailed implementation guide
- **[Architecture](./ARCHITECTURE.md)** - Technical architecture and design decisions
- **[Getting Started](./GETTING_STARTED.md)** - Step-by-step setup guide

## Advantages Over Plugin Approach

| Aspect | IntelliJ Plugin | Zed Fork |
|--------|----------------|----------|
| **Architecture** | Plugin + External Orchestrator | Single integrated binary |
| **Performance** | HTTP/WebSocket overhead | Direct function calls |
| **LLM Integration** | Build from scratch | Already built-in |
| **Latency** | High (IPC) | Low (in-process) |
| **Deployment** | Plugin + orchestrator | Single binary |
| **Maintenance** | Two codebases | One codebase |
| **Complexity** | High | Low |

## Contributing

This is a fork of Zed with observer mode additions. To contribute:

1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

Same as Zed: MIT License

## Credits

- **Zed IDE** - https://github.com/zed-industries/zed
- **Ollama** - https://ollama.com
- **Qwen 2.5 Coder** - https://github.com/QwenLM/Qwen2.5-Coder

## Support

For issues or questions:
- Open an issue on GitHub
- Join the discussion in Zed Discord

## Roadmap

### Phase 1: Core Functionality (Weeks 1-3)
- [x] Research and planning
- [ ] Create observer_mode crate
- [ ] Hook into editor events
- [ ] Implement LLM integration
- [ ] Add settings system
- [ ] Basic notifications

### Phase 2: Voice Integration (Week 4)
- [ ] Integrate Whisper STT
- [ ] Integrate Piper/Coqui TTS
- [ ] Add PTT keybinding
- [ ] Voice command processing

### Phase 3: Refinement (Weeks 5-6)
- [ ] Tune observation frequency
- [ ] Improve context gathering
- [ ] Performance optimization
- [ ] UI polish
- [ ] Documentation

### Phase 4: Advanced Features (Future)
- [ ] Learning from feedback
- [ ] Multi-file context
- [ ] Proactive refactoring
- [ ] Team learning

## FAQ

**Q: Why fork Zed instead of building a plugin?**  
A: Zed's extension API is limited. Forking gives us full access to editor internals, LLM infrastructure, and allows deep integration.

**Q: Will this work with other editors?**  
A: This is Zed-specific. For other editors, you'd need different approaches (VS Code extension, IntelliJ plugin, etc.)

**Q: What models can I use?**  
A: Any model supported by Zed's LLM provider system: Ollama (local), OpenAI, Anthropic, or custom OpenAI-compatible APIs.

**Q: How much does it cost?**  
A: Free if using local models (Ollama). Paid if using cloud APIs (OpenAI, Anthropic).

**Q: Does it send my code to the cloud?**  
A: Only if you configure a cloud LLM provider. With Ollama, everything stays local.

**Q: How do I disable it?**  
A: Set `"observer_mode": { "enabled": false }` in settings.

## Status

🚧 **In Development** - Currently in research and planning phase. Implementation starting soon.

---

**Built with ❤️ for developers who want an AI pair programmer that actually watches and helps in real-time.**
