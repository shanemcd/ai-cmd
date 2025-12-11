# ai-cmd

Zsh plugin to generate shell commands from natural language using local LLMs via ollama.

## Installation

### Oh My Zsh

```bash
git clone https://github.com/shanemcd/ai-cmd.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/ai-cmd
```

Add `ai-cmd` to your plugins in `~/.zshrc`:

```bash
plugins=(... ai-cmd)
```

### Manual

Clone the repo and source the plugin in your `~/.zshrc`:

```bash
git clone https://github.com/shanemcd/ai-cmd.git ~/.zsh/ai-cmd
echo 'source ~/.zsh/ai-cmd/ai-cmd.plugin.zsh' >> ~/.zshrc
```

## Configuration

Set these environment variables **before** the plugin loads (before `source $ZSH/oh-my-zsh.sh`):

```bash
# Command to run ollama (default: "ollama")
export AI_CMD_OLLAMA_CMD="ollama"
export AI_CMD_OLLAMA_CMD="podman exec systemd-ollama ollama"  # containerized
export AI_CMD_OLLAMA_CMD="ssh server ollama"                   # remote

# Model to use (default: "qwen2.5:7b")
export AI_CMD_MODEL="qwen2.5:7b"
export AI_CMD_MODEL="llama3.2:3b"

# Keybinding for ai-insert widget (default: "^[a" / Alt+a)
export AI_CMD_KEYBINDING="^[a"   # Alt+a
export AI_CMD_KEYBINDING="^xa"   # Ctrl+x, a
export AI_CMD_KEYBINDING=""      # Disable keybinding

# Custom system prompt (optional)
export AI_CMD_SYSTEM_PROMPT="Your custom prompt here..."
```

## Usage

### `ai` function

Generate a command from natural language:

```bash
# With arguments
ai list all docker containers sorted by size

# Interactive prompt
ai
# Then type: "find all .py files modified in the last week"
```

The command is printed to stdout, so you can:

```bash
# Just see the suggestion
ai show disk usage by directory

# Execute directly (use with caution!)
$(ai show disk usage by directory)

# Copy to clipboard
ai show disk usage by directory | xclip -selection clipboard
```

### `ai-insert` widget (Alt+a)

1. Type your natural language prompt: `find large files over 100mb`
2. Press `Alt+a` (or your configured keybinding)
3. Your text is replaced with the generated command
4. Edit if needed, then press Enter to execute

## Requirements

- [ollama](https://ollama.ai/) running locally or accessible via your configured command
- A model pulled (e.g., `ollama pull qwen2.5:7b`)

## License

MIT
