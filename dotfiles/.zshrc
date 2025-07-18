## Configure plugin directories
ZSH_DIR="${ZSH:-$HOME/.zsh}"
PURE_DIR="${ZSH_DIR}/pure"
SYNTAX_HIGHLIGHTING_DIR="${ZSH_DIR}/zsh-syntax-highlighting"
COMPLETIONS_DIR="${ZSH_DIR}/zsh-completions"
AUTOSUGGESTIONS_DIR="${ZSH_DIR}/zsh-autosuggestions"

## Clone plugins if not already cloned
if [ ! -d "$PURE_DIR" ]; then
  echo "Cloning pure prompt..."
  git clone --depth=1 https://github.com/sindresorhus/pure.git "$PURE_DIR"
fi
if [ ! -d "$SYNTAX_HIGHLIGHTING_DIR" ]; then
  echo "Cloning zsh-syntax-highlighting..."
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$SYNTAX_HIGHLIGHTING_DIR"
fi
if [ ! -d "$COMPLETIONS_DIR" ]; then
  echo "Cloning zsh-completions..."
  git clone --depth=1 https://github.com/zsh-users/zsh-completions.git "$COMPLETIONS_DIR"
fi
if [ ! -d "$AUTOSUGGESTIONS_DIR" ]; then
  echo "Cloning zsh-autosuggestions..."
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git "$AUTOSUGGESTIONS_DIR"
fi

## Load pure prompt
fpath+="$PURE_DIR"
autoload -U promptinit; promptinit
prompt pure

## Source plugins
source "${SYNTAX_HIGHLIGHTING_DIR}/zsh-syntax-highlighting.zsh"
source "${COMPLETIONS_DIR}/zsh-completions.plugin.zsh"
source "${AUTOSUGGESTIONS_DIR}/zsh-autosuggestions.zsh"

## Load zsh-autosuggestions
autoload -U compinit
compinit

## Load zoxide
eval "$(zoxide init --cmd cd zsh)"

# Configure history
HISTFILE=~/.zsh/history
HISTSIZE=5000
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_dups
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_find_no_dups
setopt hist_ignore_space

# Set command colors 
alias ls='ls --color=auto'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
alias grep='grep --color=auto'
alias diff='diff --color=auto'

# Set kebindings to emacs mode
bindkey -e

# After typing the beginning of a command, the up and down arrow keys will search through the history of commands that match the beginning
bindkey "^[[A" history-search-backward
bindkey "^[[B" history-search-forward

# Function to install packages from rig/packages.txt
ipkgs() {
  local pkgfile="$HOME/rig/packages.txt"
  if [[ -f "$pkgfile" ]]; then
    local pkgs
    pkgs=("${(@f)$(grep -vE '^\s*#|^\s*$' "$pkgfile")}")
    if (( ${#pkgs[@]} )); then
      sudo pacman -S --noconfirm "${pkgs[@]}"
      echo "All packages from rig/packages.txt installed"
    else
      echo "No packages found to install in rig/packages.txt"
    fi
  else
    echo "rig/packages.txt not found."
  fi
}

# Configure aliases
alias clip='xclip -selection clipboard'
