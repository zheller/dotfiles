# Open chezmoi-managed target files via `chezmoi edit --apply`, otherwise fall
# back to the real editor.
_chezmoi_edit_or_nvim() {
  emulate -L zsh
  setopt local_options no_aliases no_sh_word_split

  local real_editor="${CHEZMOI_WRAPPER_EDITOR:-nvim}"
  local arg abs
  local -a managed_args

  if (( $# == 0 )); then
    command "$real_editor"
    return
  fi

  for arg in "$@"; do
    case "$arg" in
      -*|+*)
        command "$real_editor" "$@"
        return
        ;;
    esac

    abs="$(command python3 - "$arg" <<'PY'
import os, sys
print(os.path.abspath(os.path.expanduser(sys.argv[1])))
PY
)" || {
      command "$real_editor" "$@"
      return
    }

    if [[ -d "$abs" && ! -L "$abs" ]]; then
      command "$real_editor" "$@"
      return
    fi

    if ! command chezmoi source-path -- "$abs" >/dev/null 2>&1; then
      command "$real_editor" "$@"
      return
    fi

    managed_args+=("$abs")
  done

  EDITOR="$real_editor" VISUAL="$real_editor" command chezmoi edit --watch -- "$managed_args[@]"
}

unalias v vi vim 2>/dev/null

v() {
  _chezmoi_edit_or_nvim "$@"
}

vi() {
  _chezmoi_edit_or_nvim "$@"
}

vim() {
  _chezmoi_edit_or_nvim "$@"
}
