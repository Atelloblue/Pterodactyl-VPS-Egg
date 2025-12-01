#!/bin/sh

. /common.sh

HOSTNAME="vps.bluedhost.tech"
HISTORY_FILE="${HOME}/.custom_shell_history"
MAX_HISTORY=1000

if [ ! -e "/.installed" ]; then
    rm -f /rootfs.tar.xz /rootfs.tar.gz
    rm -rf /tmp/sbin

    printf "nameserver 1.1.1.1\nnameserver 1.0.0.1\n" > /etc/resolv.conf

    touch /.installed
fi

# Ensure autorun exists
if [ ! -e "/autorun.sh" ]; then
    touch /autorun.sh
    chmod +x /autorun.sh
fi

printf "\033c"
printf "${GREEN}Starting..${NC}\n"
sleep 1
printf "\033c"

cleanup() {
    log "INFO" "Session ended." "$GREEN"
    exit 0
}

get_formatted_dir() {
    case "$PWD" in
        "$HOME"*)
            printf "~%s" "${PWD#$HOME}"
            ;;
        *)
            printf "%s" "$PWD"
            ;;
    esac
}

save_to_history() {
    cmd="$1"
    [ -z "$cmd" ] && return
    [ "$cmd" = "exit" ] && return

    printf "%s\n" "$cmd" >> "$HISTORY_FILE"

    tail -n "$MAX_HISTORY" "$HISTORY_FILE" > "$HISTORY_FILE.tmp"
    mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
}

reinstall() {
    log "INFO" "Reinstalling OS..." "$YELLOW"
    find / -mindepth 1 -xdev -delete >/dev/null 2>&1
}

install_wget() {
    distro="$(awk -F= '/^ID=/{gsub("\"","");print $2}' /etc/os-release)"

    case "$distro" in
        debian|ubuntu|devuan|linuxmint|kali)
            apt-get update -qq && apt-get install -y -qq wget >/dev/null 2>&1 ;;
        void)
            xbps-install -Sy wget >/dev/null 2>&1 ;;
        centos|fedora|rocky|almalinux|openEuler|amzn|ol)
            yum install -y -q wget >/dev/null 2>&1 ;;
        opensuse* )
            zypper -q install -y wget >/dev/null 2>&1 ;;
        alpine|chimera)
            apk add -q --no-interactive wget >/dev/null 2>&1 ;;
        gentoo)
            emerge -q wget >/dev/null 2>&1 ;;
        arch)
            pacman -Syu --noconfirm --quiet wget >/dev/null 2>&1 ;;
        slackware)
            yes | slackpkg install wget >/dev/null 2>&1 ;;
        *)
            log "ERROR" "Unsupported distribution: $distro" "$RED"
            return 1 ;;
    esac
}

install_ssh() {
    if [ -f "/usr/local/bin/ssh" ]; then
        log "ERROR" "SSH already installed." "$RED"
        return 1
    fi

    if ! command -v wget >/dev/null 2>&1; then
        install_wget
    fi

    arch="$(detect_architecture)"
    url="https://github.com/ysdragon/ssh/releases/latest/download/ssh-$arch"

    wget -q -O /usr/local/bin/ssh "$url" || {
        log "ERROR" "SSH download failed." "$RED"
        return 1
    }

    chmod +x /usr/local/bin/ssh
    log "SUCCESS" "SSH installed." "$GREEN"
}

show_system_status() {
    log "INFO" "System Status:" "$GREEN"
    uptime
    free -h
    df -h
    ps aux --sort=-%mem | head -n 10
}

create_backup() {
    if ! command -v tar >/dev/null; then
        log "ERROR" "tar not installed." "$RED"
        return 1
    fi

    backup="/backup_$(date +%Y%m%d%H%M%S).tar.gz"
    exclude="/tmp/exclude-list.txt"

    cat > "$exclude" <<EOF
./$(basename "$backup")
./proc
./tmp
./dev
./sys
./run
./vps.config
$(basename "$exclude")
EOF

    log "INFO" "Backing up..." "$YELLOW"
    (cd / && tar --numeric-owner -czf "$backup" -X "$exclude" .) >/dev/null 2>&1

    rm -f "$exclude"

    log "SUCCESS" "Backup created: $backup" "$GREEN"
}

restore_backup() {
    file="$1"

    if [ -z "$file" ]; then
        log "INFO" "Usage: restore <backup_file>" "$YELLOW"
        return 1
    fi

    if [ ! -f "/$file" ]; then
        log "ERROR" "Backup not found: $file" "$RED"
        return 1
    fi

    log "INFO" "Restoring..." "$YELLOW"
    tar --numeric-owner -xzf "/$file" -C / --exclude="$file" >/dev/null 2>&1
    log "SUCCESS" "Restored from $file" "$GREEN"
}

execute_command() {
    cmd="$1"
    user="$2"

    save_to_history "$cmd"

    case "$cmd" in
        "" )
            return ;;
        clear|cls)
            printf "\033c" ;;
        exit)
            cleanup ;;
        history)
            [ -f "$HISTORY_FILE" ] && cat "$HISTORY_FILE" ;;
        reinstall)
            reinstall
            exit 2 ;;
        sudo*|su*)
            log "ERROR" "Already root." "$RED" ;;
        install-ssh)
            install_ssh ;;
        status)
            show_system_status ;;
        backup)
            create_backup ;;
        restore)
            log "ERROR" "Usage: restore <backup_file>" "$RED" ;;
        restore\ *)
            restore_backup "${cmd#restore }" ;;
        help)
            print_help_banner ;;
        *)
            eval "$cmd" ;;
    esac
}

print_prompt() {
    printf "\n${GREEN}%s@%s${NC}:${RED}%s${NC}# " \
        "$1" "$HOSTNAME" "$(get_formatted_dir)"
}

run_prompt() {
    user="$1"
    read -r cmd
    execute_command "$cmd" "$user"
}

touch "$HISTORY_FILE"
trap cleanup INT TERM

print_instructions
sh /autorun.sh

printf "${GREEN}root@${HOSTNAME}${NC}:${RED}$(get_formatted_dir)${NC}#\n"

while true; do
    print_prompt "user"
    run_prompt "user"
done
