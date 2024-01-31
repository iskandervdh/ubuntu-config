# ZSH Config
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="agnoster"
HIST_STAMPS="dd/mm/yyyy"

plugins=(
	git
	jsontools
	npm
	zsh-autosuggestions
	zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# Aliases
alias zshconfig="vim ~/.zshrc"
alias ohmyzsh="vim ~/.oh-my-zsh"

alias c="clear"
alias e="exit"

kill_port() { kill $(lsof -t -u:$1); }
alias kill-port="kill_port"
