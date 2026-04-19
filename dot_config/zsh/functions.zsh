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

