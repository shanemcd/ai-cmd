# ai-cmd - Generate shell commands from natural language using LLMs
#
# Configuration (set before sourcing or in .zshrc):
#   AI_CMD_OLLAMA_CMD    - Command to run ollama (default: "ollama")
#   AI_CMD_MODEL         - Model to use (default: "qwen2.5:7b")
#   AI_CMD_KEYBINDING    - Keybinding for ai-insert widget (default: "^[a" / Alt+a)
#   AI_CMD_SYSTEM_PROMPT - Custom system prompt (optional)
#
# Examples:
#   export AI_CMD_OLLAMA_CMD="podman exec systemd-ollama ollama"
#   export AI_CMD_OLLAMA_CMD="ollama"
#   export AI_CMD_MODEL="llama3.2:3b"
#   export AI_CMD_KEYBINDING="^[a"   # Alt+a (default)
#   export AI_CMD_KEYBINDING="^xa"   # Ctrl+x, a
#   export AI_CMD_KEYBINDING=""      # Disable keybinding

# Defaults
: ${AI_CMD_OLLAMA_CMD:="ollama"}
: ${AI_CMD_MODEL:="qwen2.5:7b"}
: ${AI_CMD_KEYBINDING:="^[a"}
: ${AI_CMD_SYSTEM_PROMPT:="You are an AI terminal command generator.
Your ONLY output must be valid POSIX shell commands.
No explanations. No commentary. No markdown.
Output only commands that a terminal can execute."}

# Strip ANSI escape codes and carriage returns from output
_ai_cmd_strip_ansi() {
  sed $'s/\x1B\[[0-9;]*[a-zA-Z]//g; s/\x1B\[[?][0-9;]*[a-zA-Z]//g' | tr -d '\r'
}

# Run the LLM and get a command
_ai_cmd_generate() {
  local prompt="$1"
  local full_prompt="SYSTEM: $AI_CMD_SYSTEM_PROMPT

USER: $prompt"

  eval "$AI_CMD_OLLAMA_CMD run $AI_CMD_MODEL \"\$full_prompt\"" 2>/dev/null | _ai_cmd_strip_ansi
}

# Interactive function - call from command line
ai() {
  local prompt

  if [[ -n "$*" ]]; then
    prompt="$*"
  else
    printf "What command do you want? "
    read -r prompt
  fi

  [[ -z "$prompt" ]] && return 1

  _ai_cmd_generate "$prompt"
}

# ZLE widget - use current buffer as prompt
ai-insert() {
  local prompt="$BUFFER"

  if [[ -z "$prompt" ]]; then
    zle -M "Type your prompt first, then press Alt+a"
    return
  fi

  zle -M "Generating command..."

  local output
  output=$(_ai_cmd_generate "$prompt")

  BUFFER="$output"
  CURSOR=${#BUFFER}
  zle -M ""
  zle redisplay
}

zle -N ai-insert

# Bind keybinding if set (empty string disables)
[[ -n "$AI_CMD_KEYBINDING" ]] && bindkey "$AI_CMD_KEYBINDING" ai-insert
