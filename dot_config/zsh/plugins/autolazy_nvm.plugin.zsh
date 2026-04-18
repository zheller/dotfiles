# Lazy and autoload nvm
# Nvm takes forever to boot, so dont source it until we see an .nvmrc, auto source it then
#
# Unlike the upstream oh my zsh plugin This plugin avoids `nvm` commands like the plauge becuase
# they can be really really slow, so  it prefers using simple cli functions to
# work out different logic.
#
# Helper function to use in your prompt to display the currently sourced nvm version
nvm_prompt_info() {
    [[ -n ${NVM_BIN} ]] || return
    # Grab the name of the currently source nvm bin as the version
    echo "[nvm: $(basename $(realpath $NVM_BIN/..))] "
}

_nvm_find_up () {
    local path_
    path_="${PWD}"
    while [ "${path_}" != "" ] && [ ! -f "${path_}/${1-}" ]
    do
        path_=${path_%/*}
    done
    echo "${path_}"
}

_nvm_find_nvmrc () {
    local dir
    dir="$(_nvm_find_up '.nvmrc')"
    if [ -e "${dir}/.nvmrc" ]
    then
        echo "${dir}/.nvmrc"
    fi
}
export NVM_DIR="$HOME/.nvm"
nvm() {
    if [[ -d $NVM_DIR ]]; then
        # shellcheck disable=SC1090
        source "${NVM_DIR}/nvm.sh" --no-use
        autoload -U +X bashcompinit && bashcompinit
        # Bypass compinit call in nvm bash completion script. See:
        # https://github.com/nvm-sh/nvm/blob/4436638/bash_completion#L86-L93
        # shellcheck disable=SC1090
        ZSH_VERSION= source "$NVM_DIR/bash_completion"
        nvm "$@"
    else
        echo "nvm is not installed" >&2
        return 1
    fi
}

autoload -U add-zsh-hook
# Avoids using any nvm commands here, which are slow
load-nvmrc() {
    local nvmrc_path
    local nvmrc_version
    nvmrc_path="$(_nvm_find_nvmrc)"

    if [ -n "$nvmrc_path" ]; then
        # If we are switiching to a directory that has an nvm of the same
        # version, exit early to speed up cd
        if (which nvm_version 2>/dev/null &>/dev/null); then
            nvmrc_version="$(cat $nvmrc_path)"
            if [[ "$(nvm version)" = "$(nvm version $nvmrc_version)"  ]]; then
                return
            fi
        fi
        # nvm use returns a non zero code if it isnt installed,
        # so install it in that case
        if ! nvm use --silent 2> /dev/null; then
            nvm install
        fi
    fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc
