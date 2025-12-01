#!/bin/sh

# Colors
readonly PURPLE='\033[0;35m'
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly NC='\033[0m'

# Logger
log() {
    local level="$1"
    local message="$2"
    local color="${3:-$NC}"
    printf "%b[%s]%b %s\n" "$color" "$level" "$NC" "$message"
}

# Architecture detection
detect_architecture() {
    case "$(uname -m)" in
        x86_64)  printf "amd64\n" ;;
        aarch64) printf "arm64\n" ;;
        riscv64) printf "riscv64\n" ;;
        *)
            log "ERROR" "Unsupported CPU architecture: $(uname -m)" "$RED" >&2
            return 1
        ;;
    esac
}

# Main banner
print_main_banner() {
    printf "\033c"
    cat <<EOF
${CYAN}╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║            ${PURPLE}${BOLD}██╗   ██╗██████╗ ███████╗    ███████╗ ██████╗  ██████╗${CYAN}             ║
║            ${PURPLE}${BOLD}██║   ██║██╔══██╗██╔════╝    ██╔════╝██╔════╝ ██╔════╝${CYAN}             ║
║            ${PURPLE}${BOLD}██║   ██║██████╔╝███████╗    █████╗  ██║  ███╗██║  ███╗${CYAN}            ║
║            ${PURPLE}${BOLD}╚██╗ ██╔╝██╔═══╝ ╚════██║    ██╔══╝  ██║   ██║██║   ██║${CYAN}            ║
║             ${PURPLE}${BOLD}╚████╔╝ ██║     ███████║    ███████╗╚██████╔╝╚██████╔╝${CYAN}            ║
║              ${PURPLE}${BOLD}╚═══╝  ╚═╝     ╚══════╝    ╚══════╝ ╚═════╝  ╚═════╝${CYAN}             ║
║                                                                               ║
║                      ${GREEN}✨  Lightweight • Fast • Reliable ✨${CYAN}                       ║
║                                                                               ║
║                           ${DIM}© 2025 - $(date +%Y) ${PURPLE}@Atelloblue${CYAN}                             ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝${NC}

EOF
}

# Help banner
print_help_banner() {
    cat <<EOF
${BLUE}╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║                           ${WHITE}${BOLD}📋  AVAILABLE COMMANDS 📋${BLUE}                             ║
║                                                                               ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║  ${CYAN}🧹  ${YELLOW}${BOLD}clear, cls${NC}        ${GREEN}▶  ${WHITE}Clear the terminal screen${BLUE}                            ║
║  ${RED}🔌  ${YELLOW}${BOLD}exit${NC}              ${GREEN}▶  ${WHITE}Shutdown the container server${BLUE}                        ║
║  ${PURPLE}📜  ${YELLOW}${BOLD}history${NC}           ${GREEN}▶  ${WHITE}Display command history${BLUE}                              ║
║  ${CYAN}🔄  ${YELLOW}${BOLD}reinstall${NC}         ${GREEN}▶  ${WHITE}Reinstall the operating system${BLUE}                       ║
║  ${GREEN}🔐  ${YELLOW}${BOLD}install-ssh${NC}       ${GREEN}▶  ${WHITE}Install custom SSH server${BLUE}                            ║
║  ${BLUE}📊  ${YELLOW}${BOLD}status${NC}            ${GREEN}▶  ${WHITE}Show detailed system status${BLUE}                          ║
║  ${YELLOW}💾  ${YELLOW}${BOLD}backup${NC}            ${GREEN}▶  ${WHITE}Create a complete system backup${BLUE}                      ║
║  ${PURPLE}📥  ${YELLOW}${BOLD}restore${NC}           ${GREEN}▶  ${WHITE}Restore from a system backup${BLUE}                         ║
║  ${WHITE}❓  ${YELLOW}${BOLD}help${NC}              ${GREEN}▶  ${WHITE}Display this help information${BLUE}                        ║
║                                                                               ║
╠═══════════════════════════════════════════════════════════════════════════════╣
║                                                                               ║
║                     ${DIM}💡 Tip: Type any command to get started!${BLUE}                   ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝${NC}

EOF
}
