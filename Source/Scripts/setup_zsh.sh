#!/bin/bash

# ──────────────── Banner ────────────────
BANNER_LINES=(
""
""
"█▀ █▀▀ ▀█▀ ▀█▀ █ █▄░█ █▀▀   █░█ █▀█   ▀█ █▀ █░█"
"▄█ ██▄ ░█░ ░█░ █ █░▀█ █▄█   █▄█ █▀▀   █▄ ▄█ █▀█"
""
""
)

COLORS=(15) # white color
RESET='\033[0m'

for line in "${BANNER_LINES[@]}"; do
    color="\033[38;5;${COLORS[RANDOM % ${#COLORS[@]}]}m"
    echo -e "${color}${line}${RESET}"
done

# ──────────────── Load Colors ────────────────
source "$HOME/Cupcake/Source/Scripts/colors.sh"

ZSHRC="$HOME/.zshrc"

# ──────────────── Ensure .zshrc Exists ────────────────
touch "$ZSHRC"

# ──────────────── Set Zsh as Default ────────────────
ZSH_PATH="$(which zsh)"
CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"

if [[ "$CURRENT_SHELL" != "$ZSH_PATH" ]]; then
    if command -v zsh >/dev/null 2>&1; then
        echo -e "${YELLOW}[INFO]${RESET} Changing default shell to Zsh..."
        if chsh -s "$ZSH_PATH"; then
            NEW_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
            if [[ "$NEW_SHELL" == "$ZSH_PATH" ]]; then
                echo -e "${GREEN}[DONE]${RESET} Default shell changed to Zsh. Please log out and log back in."
            else
                echo -e "${RED}[FAIL]${RESET} chsh ran, but shell didn't change. Try: ${TEXT}chsh -s $ZSH_PATH${RESET}"
            fi
        else
            echo -e "${RED}[FAIL]${RESET} Failed to run chsh. Try: ${TEXT}chsh -s $ZSH_PATH${RESET}"
        fi
    else
        echo -e "${RED}[ERROR]${RESET} Zsh not found. Installing..."
        sudo pacman -S --noconfirm zsh
        if chsh -s "$ZSH_PATH"; then
            NEW_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
            if [[ "$NEW_SHELL" == "$ZSH_PATH" ]]; then
                echo -e "${GREEN}[DONE]${RESET} Installed and set Zsh. Please re-login."
            else
                echo -e "${RED}[FAIL]${RESET} Installed Zsh, but shell change failed. Try: ${TEXT}chsh -s $ZSH_PATH${RESET}"
            fi
        else
            echo -e "${RED}[FAIL]${RESET} Could not set Zsh as default. Try manually: ${TEXT}chsh -s $ZSH_PATH${RESET}"
        fi
    fi
else
    echo -e "${YELLOW}[SKIP]${RESET} Default shell already set to Zsh."
fi

# ──────────────── Install Oh My Zsh ────────────────
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo -e "${YELLOW}[INFO]${RESET} Installing oh-my-zsh..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    echo -e "${GREEN}[DONE]${RESET} oh-my-zsh installed."
else
    echo -e "${YELLOW}[SKIP]${RESET} oh-my-zsh already installed."
fi

# ──────────────── Configure .zshrc ────────────────
SECTIONS_ADDED=false

# ──────────────── Add Aliases ────────────────
if ! grep -q "# ─── Aliases" "$ZSHRC"; then
    {
        echo -e "\n# ─── Aliases ──────────────────────────────────────────────"
        echo "alias inv='nvim \$(fzf -m --preview=\"bat --color=always {}\")'"
    } >> "$ZSHRC"
    SECTIONS_ADDED=true
fi

# ──────────────── Add Zsh Plugins ────────────────
PLUGIN_LINES=(
    "# ─── Zsh Plugins ──────────────────────────────────────────"
    "source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
    "source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    "source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh"
)

for line in "${PLUGIN_LINES[@]}"; do
    if ! grep -Fxq "$line" "$ZSHRC"; then
        echo "$line" >> "$ZSHRC"
        SECTIONS_ADDED=true
    fi
done

# ──────────────── Add FZF & Tool Initializers ────────────────
EVAL_LINES=(
    "# ─── Tool Initializers ─────────────────────────────────────"
    '[ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh'
    '[ -f /usr/share/fzf/completion.zsh ] && source /usr/share/fzf/completion.zsh'
    "fpath+=('/usr/share/zsh/site-functions')"
    "autoload -Uz compinit && compinit"
    'eval "$(atuin init zsh)"'
    'eval "$(starship init zsh)"'
    'export PATH="$HOME/.local/bin:$PATH"'
    '#fastfetch'
    'nitch'
)

for line in "${EVAL_LINES[@]}"; do
    if ! grep -Fxq "$line" "$ZSHRC"; then
        echo "$line" >> "$ZSHRC"
        SECTIONS_ADDED=true
    fi
done

# ──────────────── Zshrc Finalization ────────────────
if [ "$SECTIONS_ADDED" = true ]; then
    echo -e "${GREEN}[DONE]${RESET} Zshrc updated with aliases, plugins, and tools."
else
    echo -e "${YELLOW}[SKIP]${RESET} All sections already present in .zshrc"
fi

# ──────────────── Final Status ────────────────
SETUP_SUCCESS=true

if [[ "$CURRENT_SHELL" != "$ZSH_PATH" ]]; then
    if ! chsh -s "$ZSH_PATH"; then
        SETUP_SUCCESS=false
    fi
fi

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    SETUP_SUCCESS=false
fi

if [ "$SETUP_SUCCESS" = true ]; then
    echo -e "\n${GREEN}[DONE]${RESET} ${TEXT}Zsh fully configured and ready!${RESET}"
else
    echo -e "\n${RED}[WARN]${RESET} ${TEXT}Some parts of Zsh setup may have failed. Please review the above messages.${RESET}"
fi

# ──────────────── Run GRUB Setup ────────────────
bash "$HOME/Cupcake/Source/Scripts/setup_grub.sh"