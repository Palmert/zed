#!/bin/bash
# Setup script for ZedVoice - Fork and configure Zed IDE

set -e

echo "🚀 ZedVoice Setup - Creating Zed Fork"
echo "======================================"

# Check if Zed already exists
if [ -d "zed" ]; then
    echo "❌ Zed directory already exists. Remove it first: rm -rf zed"
    exit 1
fi

# Clone Zed repository
echo "📦 Cloning Zed IDE repository..."
git clone https://github.com/zed-industries/zed.git
cd zed

# Create observer_mode crate directory
echo "🔧 Creating observer_mode crate..."
mkdir -p crates/observer_mode/src

# Create basic Cargo.toml for observer_mode
cat > crates/observer_mode/Cargo.toml << 'EOF'
[package]
name = "observer_mode"
version = "0.1.0"
edition = "2021"
description = "AI pair programming observer mode for Zed"

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
EOF

# Create basic lib.rs
cat > crates/observer_mode/src/lib.rs << 'EOF'
//! Observer Mode - AI Pair Programming for Zed
//!
//! This crate implements proactive AI suggestions by observing
//! the developer's coding activity in real-time.

pub mod observer;
pub mod context;
pub mod decision;
pub mod output;
pub mod settings;

pub use observer::Observer;
pub use settings::ObserverSettings;
EOF

# Create basic observer.rs stub
cat > crates/observer_mode/src/observer.rs << 'EOF'
//! Main observer logic

use gpui::*;
use std::time::{Duration, Instant};

pub struct Observer {
    enabled: bool,
    last_check: Option<Instant>,
}

impl Observer {
    pub fn new() -> Self {
        Self {
            enabled: false,
            last_check: None,
        }
    }
    
    pub fn observe(&mut self, _cx: &mut AppContext) {
        // TODO: Implement observation logic
        // See INTEGRATION_PLAN.md for details
    }
}
EOF

# Create other stub files
touch crates/observer_mode/src/context.rs
touch crates/observer_mode/src/decision.rs  
touch crates/observer_mode/src/output.rs
touch crates/observer_mode/src/settings.rs

echo "✅ Observer mode crate created"
echo "📝 Next steps:"
echo "   1. Add observer_mode to main Cargo.toml workspace members"
echo "   2. Follow ../INTEGRATION_PLAN.md for implementation details" 
echo "   3. See ../AGENTS.md for coding guidelines"
echo ""
echo "🎯 Ready to start implementing ZedVoice observer mode!"