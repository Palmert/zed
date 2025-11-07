# Getting Started with Zed AI Pair Programmer

This guide will walk you through setting up and running the Zed AI Pair Programmer.

## Prerequisites

### Required
- **Rust toolchain** (1.70 or later)
  ```bash
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  ```

- **Git**
  ```bash
  # macOS
  brew install git
  
  # Linux
  sudo apt install git  # Debian/Ubuntu
  sudo dnf install git  # Fedora
  ```

- **Ollama** (for local LLM)
  ```bash
  curl -fsSL https://ollama.com/install.sh | sh
  ```

### Optional
- **Whisper** (for voice input)
- **Piper TTS** (for voice output)

## Step 1: Install Ollama and Download Model

### Install Ollama

**macOS/Linux:**
```bash
curl -fsSL https://ollama.com/install.sh | sh
```

**Windows:**
Download from https://ollama.com/download

### Download Qwen 2.5 Coder Model

```bash
# Download the 7B model (recommended for observation)
ollama pull qwen2.5-coder:7b

# Verify it's installed
ollama list
```

### Start Ollama Server

```bash
ollama serve
```

Leave this running in a terminal window.

## Step 2: Fork and Clone Zed

### Fork the Repository

1. Go to https://github.com/zed-industries/zed
2. Click "Fork" button
3. Clone your fork:

```bash
git clone https://github.com/YOUR_USERNAME/zed.git
cd zed
```

## Step 3: Add Observer Mode

### Create the Observer Mode Crate

```bash
mkdir -p crates/observer_mode/src
```

### Create Cargo.toml

Create `crates/observer_mode/Cargo.toml`:

```toml
[package]
name = "observer_mode"
version = "0.1.0"
edition = "2021"

[dependencies]
gpui = { path = "../gpui" }
editor = { path = "../editor" }
language = { path = "../language" }
settings = { path = "../settings" }
client = { path = "../client" }
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
anyhow = "1.0"
log = "0.4"
```

### Create lib.rs

Create `crates/observer_mode/src/lib.rs`:

```rust
pub mod observer;
pub mod settings;

pub use observer::Observer;
pub use settings::ObserverSettings;
```

### Add Implementation Files

Copy the implementation from `INTEGRATION_PLAN.md`:
- `src/observer.rs` - Main observer logic
- `src/context.rs` - Context gathering
- `src/settings.rs` - Settings definition
- `src/output.rs` - Output handling

## Step 4: Build Zed

### Build in Release Mode

```bash
cargo build --release
```

This will take 10-20 minutes on first build.

### Build in Debug Mode (faster, for development)

```bash
cargo build
```

## Step 5: Configure Zed

### Create Settings File

**macOS:**
```bash
mkdir -p ~/.config/zed
touch ~/.config/zed/settings.json
```

**Linux:**
```bash
mkdir -p ~/.config/zed
touch ~/.config/zed/settings.json
```

**Windows:**
```bash
mkdir %APPDATA%\Zed
type nul > %APPDATA%\Zed\settings.json
```

### Add Configuration

Edit `settings.json`:

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

## Step 6: Run Zed

### Run the Built Binary

**macOS/Linux:**
```bash
./target/release/zed
```

**Windows:**
```bash
.\target\release\zed.exe
```

### Or Run in Development Mode

```bash
cargo run
```

## Step 7: Test Observer Mode

### Create a Test File

1. Open Zed
2. Create a new file (`Cmd+N` or `Ctrl+N`)
3. Select a language (e.g., Python, Rust, JavaScript)
4. Start typing code

### Write Code with a Bug

Example Python code:
```python
def calculate_average(numbers):
    total = 0
    for num in numbers:
        total += num
    return total / len(numbers)  # Bug: division by zero if empty list

# Test
result = calculate_average([])  # This will crash!
print(result)
```

### Wait for Observation

After 10 seconds (or your configured interval), you should see:
- A notification with a suggestion
- Or hear a voice suggestion (if voice enabled)

Example suggestion:
> "Consider adding a check for empty list before division to avoid ZeroDivisionError"

## Step 8: Customize Settings

### Adjust Observation Interval

```json
{
  "observer_mode": {
    "interval_seconds": 5  // Check every 5 seconds
  }
}
```

### Change Confidence Threshold

```json
{
  "observer_mode": {
    "min_confidence": 0.8  // Only speak when 80%+ confident
  }
}
```

### Enable Voice Output

```json
{
  "observer_mode": {
    "voice_enabled": true
  }
}
```

### Use Different Model

```json
{
  "observer_mode": {
    "model": "codellama:7b"  // Use CodeLlama instead
  }
}
```

## Troubleshooting

### Ollama Not Found

**Error:** `Failed to connect to Ollama`

**Solution:**
1. Make sure Ollama is running: `ollama serve`
2. Check the API URL in settings: `http://localhost:11434`
3. Test Ollama: `ollama list`

### Model Not Found

**Error:** `Model qwen2.5-coder:7b not found`

**Solution:**
```bash
ollama pull qwen2.5-coder:7b
```

### Build Errors

**Error:** `failed to compile observer_mode`

**Solution:**
1. Make sure all files are created correctly
2. Check Cargo.toml dependencies
3. Run `cargo clean` and rebuild

### No Suggestions Appearing

**Checklist:**
- [ ] Is observer_mode enabled in settings?
- [ ] Is Ollama running?
- [ ] Is the model downloaded?
- [ ] Are you typing code (not just opening files)?
- [ ] Has enough time passed (interval_seconds)?

### Performance Issues

**Problem:** Zed feels slow

**Solutions:**
1. Increase observation interval:
   ```json
   {"observer_mode": {"interval_seconds": 30}}
   ```

2. Use a smaller model:
   ```json
   {"observer_mode": {"model": "qwen2.5-coder:1.5b"}}
   ```

3. Disable observer mode temporarily:
   ```json
   {"observer_mode": {"enabled": false}}
   ```

## Advanced Configuration

### Proactive Triggers

```json
{
  "observer_mode": {
    "enabled": true,
    "interval_seconds": 10,
    "proactive_triggers": {
      "on_error": true,        // Immediate suggestion on errors
      "on_warning": false,     // Don't trigger on warnings
      "on_git_conflict": true  // Immediate suggestion on merge conflicts
    }
  }
}
```

### Context Limits

```json
{
  "observer_mode": {
    "context": {
      "lines_before": 20,  // Include 20 lines before cursor
      "lines_after": 20,   // Include 20 lines after cursor
      "include_imports": true,
      "include_diagnostics": true
    }
  }
}
```

### Multiple Models

```json
{
  "observer_mode": {
    "models": {
      "observer": "qwen2.5-coder:7b",     // Fast model for observation
      "refactor": "qwen2.5-coder:32b",    // Larger model for refactoring
      "explain": "qwen2.5-coder:14b"      // Medium model for explanations
    }
  }
}
```

## Development Workflow

### Making Changes

1. Edit code in `crates/observer_mode/`
2. Rebuild: `cargo build`
3. Run: `cargo run`
4. Test changes

### Running Tests

```bash
# Run all tests
cargo test

# Run observer_mode tests only
cargo test -p observer_mode

# Run specific test
cargo test -p observer_mode test_context_gathering
```

### Debugging

```bash
# Run with debug logging
RUST_LOG=debug cargo run

# Run with observer_mode logging only
RUST_LOG=observer_mode=debug cargo run
```

### Hot Reload

Zed doesn't support hot reload, so you need to:
1. Close Zed
2. Rebuild
3. Restart Zed

## Next Steps

1. **Read the documentation:**
   - [RESEARCH_FINDINGS.md](./RESEARCH_FINDINGS.md) - Why Zed is perfect
   - [INTEGRATION_PLAN.md](./INTEGRATION_PLAN.md) - Implementation details
   - [ARCHITECTURE.md](./ARCHITECTURE.md) - Technical architecture

2. **Customize the observer:**
   - Modify prompts in `observer.rs`
   - Adjust confidence thresholds
   - Add custom triggers

3. **Add voice support:**
   - Follow voice integration guide
   - Configure PTT keybinding
   - Test TTS output

4. **Share feedback:**
   - Open issues on GitHub
   - Contribute improvements
   - Share your experience

## Resources

- **Zed Documentation:** https://zed.dev/docs
- **Ollama Documentation:** https://ollama.com/docs
- **Qwen 2.5 Coder:** https://github.com/QwenLM/Qwen2.5-Coder
- **Rust Book:** https://doc.rust-lang.org/book/

## Getting Help

If you run into issues:

1. Check the troubleshooting section above
2. Search existing GitHub issues
3. Open a new issue with:
   - Your OS and version
   - Zed version/commit
   - Error messages
   - Steps to reproduce

Happy coding with your AI pair programmer! 🚀
