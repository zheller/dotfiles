# Shell helper functions and completion tweaks

check_brew_status() {
  local brew_cmd="${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/bin/brew}"
  brew_cmd="${brew_cmd:-$(command -v brew)}"
  [[ -z $brew_cmd ]] && return 0
  "$brew_cmd" bundle check --file "$HOME/Brewfile" >/dev/null 2>&1 && return
  print "${fg_bold[red]}WARNING: Brew bundle is out of date!\nRun: brew bundle install/clean${reset_color}"
}

tail-json-pretty() {
  stdbuf -o0 jq -C -r -R 'fromjson? | .' | sed 's/\\n/\n/g; s/\\t/\t/g'
}

tail-docker-pretty() {
  docker logs -f "$1" | stdbuf -o0 jq -C -r -R 'fromjson? | .' | sed 's/\\n/\n/g; s/\\t/\t/g'
}

newlines() {
  sed 's/\\n/\n/g; s/\\t/\t/g'
}

# Run a command until it succeeds, but do not restart after intentional stop signals.
failsafe() {
  if (( $# == 0 )); then
    print -u2 "usage: failsafe <command> [args...]"
    print -u2 "optional: FAILSAFE_DELAY=2"
    return 2
  fi

  local delay="${FAILSAFE_DELAY:-2}"
  local exit_code signal_name

  while true; do
    "$@"
    exit_code=$?

    case "$exit_code" in
      0)
        return 0
        ;;
      129|130|131|143)
        case "$exit_code" in
          129) signal_name="SIGHUP" ;;
          130) signal_name="SIGINT" ;;
          131) signal_name="SIGQUIT" ;;
          143) signal_name="SIGTERM" ;;
        esac
        print -u2 "failsafe: command stopped by ${signal_name}; not restarting."
        return "$exit_code"
        ;;
    esac

    print -u2 "failsafe: command exited with status ${exit_code}; restarting in ${delay}s. Press Ctrl-C to stop."
    sleep "$delay" || return 130
  done
}

# Needed by some git completion paths.
__git_files() {
  _wanted files expl 'local files' _files
}

# Make `uv run <file>` use file completion rather than uv subcommand completion.
_uv_run_mod() {
  if [[ "$words[2]" == "run" && "$words[CURRENT]" != -* ]]; then
    _arguments '*:filename:_files'
  else
    _uv "$@"
  fi
}
compdef _uv_run_mod uv

# Resolve env file: repo-local takes precedence over global.
_op_envfile() {
  if [[ -f ./.env.op ]]; then
    echo ./.env.op
  elif [[ -f ./.env.1p ]]; then
    echo ./.env.1p
  elif [[ -f ${XDG_CONFIG_HOME:-$HOME/.config}/op/env ]]; then
    echo "${XDG_CONFIG_HOME:-$HOME/.config}/op/env"
  else
    return 1
  fi
}

# Run a command with secrets injected from env file.
oprun() {
  local envfile
  envfile="$(_op_envfile)" || {
    command "$@"
    return $?
  }
  op run --no-masking --env-file "$envfile" -- "$@"
}

# Run pi's commit skill non-interactively and stream assistant output.
picommit() {
  local prompt="/skill:commit"
  if (( $# > 0 )); then
    prompt+=" ${(j: :)@}"
  fi

  GIT_TERMINAL_PROMPT=0 pi --no-session \
    --provider openai-codex \
    --model gpt-5.4 \
    --thinking off \
    --skill /Users/zheller/src/ai-toolbox/skills/commit \
    --mode json "$prompt" | python3 -c '
import json, sys

for line in sys.stdin:
    try:
        event = json.loads(line)
    except Exception:
        continue

    if event.get("type") == "message_update":
        msg = event.get("message") or {}
        delta = event.get("assistantMessageEvent") or {}
        if msg.get("role") == "assistant" and delta.get("type") == "text_delta":
            sys.stdout.write(delta.get("delta", ""))
            sys.stdout.flush()
    elif event.get("type") == "message_end":
        msg = event.get("message") or {}
        if msg.get("role") == "assistant":
            sys.stdout.write("\n")
            sys.stdout.flush()
'
}

