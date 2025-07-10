#!/bin/bash

clear

# ──────────────── Terminal Setup ────────────────
TERM_WIDTH=$(tput cols)
COLORS=(111 141 212 217 216 117 153 150 183 186 189)
RESET='\033[0m'
CHAR_DELAY=0.0000001
LINE_DELAY=0.02

# ──────────────── Main Banner ────────────────
BANNER_LINES=(
    ""
    ""
    ""
    ""
    "      ___           ___           ___         ___           ___           ___           ___     "
    "     /\\__\\         /\\  \\         /\\  \\       /\\__\\         /\\  \\         /|  |         /\\__\\    "
    "    /:/  /         \\:\\  \\       /::\\  \\     /:/  /        /::\\  \\       |:|  |        /:/ _/_   "
    "   /:/  /           \\:\\  \\     /:/\\:\\__\\   /:/  /        /:/\\:\\  \\      |:|  |       /:/ /\\__\\  "
    "  /:/  /  ___   ___  \\:\\  \\   /:/ /:/  /  /:/  /  ___   /:/ /::\\  \\   __|:|  |      /:/ /:/ _/_ "
    " /:/__/  /\\__\\ /\\  \\  \\:\\__\\ /:/_/:/  /  /:/__/  /\\__\\ /:/_/:/\\:\\__\\ /\\ |:|__|____ /:/_/:/ /\\__\\"
    " \\:\\  \\ /:/  / \\:\\  \\ /:/  / \\:\\/:/  /   \\:\\  \\ /:/  / \\:\\/:/  \\/__/ \\:\\/:::::/__/ \\:\\/:/ /:/  /"
    "  \\:\\  /:/  /   \\:\\  /:/  /   \\::/__/     \\:\\  /:/  /   \\::/__/       \\::/~~/~      \\::/_/:/  / "
    "   \\:\\/:/  /     \\:\\/:/  /     \\:\\  \\      \\:\\/:/  /     \\:\\  \\        \\:\\~~\\        \\:\\/:/  /  "
    "    \\::/  /       \\::/  /       \\:\\__\\      \\::/  /       \\:\\__\\        \\:\\__\\        \\::/  /   "
    "     \\/__/         \\/__/         \\/__/       \\/__/         \\/__/         \\/__/         \\/__/    "
)

# ──────────────── Credit Banner ────────────────
CREDIT_LINES=(
    ""
    ""
    "    █░█ █▄█ █▀█ █▀█ █░░ ▄▀█ █▄░█ █▀▄   █▀ █▀▀ ▀█▀ █░█ █▀█   █▄▄ █▄█"
    "    █▀█ ░█░ █▀▀ █▀▄ █▄▄ █▀█ █░▀█ █▄▀   ▄█ ██▄ ░█░ █▄█ █▀▀   █▄█ ░█░"
    ""
    "    █▀▀ █▀▀ █▀█ █▀▄ ░"
    "    █▀░ █▄█ █▄█ █▄▀ ▄"
)

# ──────────────── Cancel Banner ────────────────
CANCEL_BANNER=(
    "░█████╗░░█████╗░███╗░░██╗░█████╗░███████╗██╗░░░░░███████╗██████╗░"
    "██╔══██╗██╔══██╗████╗░██║██╔══██╗██╔════╝██║░░░░░██╔════╝██╔══██╗"
    "██║░░╚═╝███████║██╔██╗██║██║░░╚═╝█████╗░░██║░░░░░█████╗░░██║░░██║"
    "██║░░██╗██╔══██║██║╚████║██║░░██╗██╔══╝░░██║░░░░░██╔══╝░░██║░░██║"
    "╚█████╔╝██║░░██║██║░╚███║╚█████╔╝███████╗███████╗███████╗██████╔╝"
    "░╚════╝░╚═╝░░╚═╝╚═╝░░╚══╝░╚════╝░╚══════╝╚══════╝╚══════╝╚═════╝░"
)

# ──────────────── Print Functions ────────────────
print_line_animated_centered() {
    local line="$1"
    local i=0
    local padding=$(( (TERM_WIDTH - ${#line}) / 2 ))
    printf "%*s" "$padding" ""
    for ((j=0; j<${#line}; j++)); do
        char="${line:$j:1}"
        color_index=$(( (i + j) % ${#COLORS[@]} ))
        color="\033[38;5;${COLORS[$color_index]}m"
        printf "${color}%s${RESET}" "$char"
        sleep $CHAR_DELAY
    done
    echo
}

print_lines_centered() {
    local -n lines=$1
    local use_color=${2:-0}
    for line in "${lines[@]}"; do
        local padding=$(( (TERM_WIDTH - ${#line}) / 2 ))
        if [[ "$use_color" -eq 1 ]]; then
            local color="\033[38;5;${COLORS[RANDOM % ${#COLORS[@]}]}m"
            printf "%*s" "$padding" ""
            echo -e "${color}${line}${RESET}"
        else
            printf "%*s%s\n" "$padding" "" "$line"
        fi
        sleep $LINE_DELAY
    done
}

prompt_centered() {
    local prompt="$1"
    local padding=$(( (TERM_WIDTH - ${#prompt}) / 2 ))
    read -rp "$(printf "%*s" "$padding" "")$prompt" user_input
}

# ──────────────── Main Execution ────────────────
for line in "${BANNER_LINES[@]}"; do
    print_line_animated_centered "$line"
done

print_lines_centered CREDIT_LINES

echo
prompt_centered "➤ Do you want to install/update packages? [Y/N]: "

if [[ "$user_input" =~ ^[Yy]$ ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    bash "$SCRIPT_DIR/Source/Scripts/install_aur.sh"
else
    echo
    print_lines_centered CANCEL_BANNER 1
fi
