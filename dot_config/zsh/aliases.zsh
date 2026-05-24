# Shell aliases
alias ll="eza --long --git --group-directories-first -all --header"
alias ipy="ipython"
alias pbjq='pbpaste | jq .'
alias python=python3
alias tf-plan="terraform plan -out tfplan"
alias tf-apply="terraform apply tfplan"
alias cz="chezmoi"
alias cze="chezmoi edit"
alias cza="chezmoi apply"
alias cat='bat --plain --paging=never --color=always'
alias lg=lazygit
tpd() {
  local git_root workspace session_name current_session reload=0

  case "${1:-}" in
    --reload|-r)
      reload=1
      shift
      ;;
    --help|-h)
      echo "usage: tpd [--reload]"
      echo "Loads .tmuxp.yaml/.tmuxp.yml from the git root when present; otherwise loads the default tmuxp workspace."
      echo "Use --reload to kill an existing session before loading the workspace."
      return 0
      ;;
  esac

  if [[ $# -gt 0 ]]; then
    echo "tpd: unexpected argument: $1" >&2
    echo "usage: tpd [--reload]" >&2
    return 2
  fi

  git_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  session_name="$(basename "$git_root")"
  workspace="default"
  if [[ -f "$git_root/.tmuxp.yaml" ]]; then
    workspace="$git_root/.tmuxp.yaml"
  elif [[ -f "$git_root/.tmuxp.yml" ]]; then
    workspace="$git_root/.tmuxp.yml"
  fi

  if tmux has-session -t "=$session_name" 2>/dev/null; then
    if (( reload )); then
      if [[ -n "${TMUX:-}" ]]; then
        current_session="$(tmux display-message -p '#S' 2>/dev/null || true)"
        if [[ "$current_session" == "$session_name" ]]; then
          echo "tpd: cannot reload the current tmux session '$session_name' from inside itself." >&2
          echo "tpd: switch to another session or outside tmux, then run: tpd --reload" >&2
          return 1
        fi
      fi
      tmux kill-session -t "=$session_name"
    else
      echo "tpd: session '$session_name' already exists; attaching without re-reading $workspace." >&2
      echo "tpd: use 'tpd --reload' from another session/shell to recreate it from $workspace." >&2
      if [[ -n "${TMUX:-}" ]]; then
        tmux switch-client -t "=$session_name"
      else
        tmux attach-session -t "=$session_name"
      fi
      return $?
    fi
  fi

  tmuxp load "$workspace" -s "$session_name"
}
