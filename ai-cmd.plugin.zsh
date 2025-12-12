# ai-cmd - Generate shell commands from natural language using LLMs
#
# Configuration (set before sourcing or in .zshrc):
#   AI_CMD_BACKEND         - Backend to use: "ollama" or "claude" (default: "ollama")
#   AI_CMD_OLLAMA_CMD      - Command to run Ollama (default: "ollama")
#   AI_CMD_OLLAMA_MODEL    - Model for Ollama (default: "rnj-1:8b")
#   AI_CMD_CLAUDE_CMD      - Command to run Claude (default: "claude")
#   AI_CMD_CLAUDE_MODEL    - Model for Claude (optional, uses Claude Code default)
#   AI_CMD_KEYBINDING      - Keybinding for ai-insert widget (default: "^[a" / Alt+a)
#   AI_CMD_SYSTEM_PROMPT   - Custom system prompt (optional)
#
# Examples:
#   export AI_CMD_BACKEND="claude"
#   export AI_CMD_CLAUDE_MODEL="sonnet"
#
#   export AI_CMD_BACKEND="ollama"
#   export AI_CMD_OLLAMA_CMD="podman exec systemd-ollama ollama"  # containerized
#   export AI_CMD_OLLAMA_MODEL="llama3.2:3b"
#
#   export AI_CMD_KEYBINDING="^[a"   # Alt+a (default)
#   export AI_CMD_KEYBINDING="^xa"   # Ctrl+x, a
#   export AI_CMD_KEYBINDING=""      # Disable keybinding

# Defaults
: ${AI_CMD_KEYBINDING:="^[a"}
: ${AI_CMD_SYSTEM_PROMPT:="You are an AI terminal command generator.
Output ONLY the raw command. No markdown, no code fences, no backticks, no explanations.
Just the command itself, nothing else."}

# Strip ANSI escape codes, carriage returns, and markdown code fences from output
_ai_cmd_clean_output() {
  sed $'s/\x1B\[[?]*[0-9;]*[a-zA-Z]//g' | tr -d '\r' | sed '/^```/d'
}

# Detect which backend to use
_ai_cmd_detect_backend() {
  if [[ -n "$AI_CMD_BACKEND" ]]; then
    echo "$AI_CMD_BACKEND"
  elif command -v ollama &>/dev/null; then
    echo "ollama"
  else
    echo "none"
  fi
}


# Run the LLM and get a command
_ai_cmd_generate() {
  local prompt="$1"
  local backend=$(_ai_cmd_detect_backend)

  case "$backend" in
    claude)
      local cmd="${AI_CMD_CLAUDE_CMD:-claude}"
      local model_arg=""
      [[ -n "$AI_CMD_CLAUDE_MODEL" ]] && model_arg="--model $AI_CMD_CLAUDE_MODEL"
      eval "$cmd -p $model_arg \"\$AI_CMD_SYSTEM_PROMPT prompt: \$prompt\"" 2>/dev/null | _ai_cmd_clean_output
      ;;
    ollama)
      local cmd="${AI_CMD_OLLAMA_CMD:-ollama}"
      local model="${AI_CMD_OLLAMA_MODEL:-rnj-1:8b}"
      local full_prompt="SYSTEM: $AI_CMD_SYSTEM_PROMPT

USER: $prompt"
      eval "$cmd run $model \"\$full_prompt\"" 2>/dev/null | _ai_cmd_clean_output
      ;;
    *)
      echo "Error: No AI backend available. Install 'ollama' or set AI_CMD_BACKEND." >&2
      return 1
      ;;
  esac
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
