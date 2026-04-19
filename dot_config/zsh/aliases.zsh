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
alias tmuxpld='tmuxp load default -s "$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")"'
