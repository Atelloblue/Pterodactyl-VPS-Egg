#!/bin/sh

# Load shared functions
. /common.sh

ROOTFS_DIR="/home/container"
BASE_URL="https://images.linuxcontainers.org/images"
DISTRO_MAP_URL="https://distromap.istan.to"

export PATH="$PATH:$HOME/.local/usr/bin"

distributions="
1:Debian:debian:false::
2:Ubuntu:ubuntu:false::
3:Void Linux:voidlinux:true::
4:Alpine Linux:alpine:false::
5:CentOS:centos:false::
6:Rocky Linux:rockylinux:false::
7:Fedora:fedora:false::
8:AlmaLinux:almalinux:false::
9:Slackware Linux:slackware:false::
10:Kali Linux:kali:false::
11:openSUSE:opensuse:special::opensuse_handler
12:Gentoo Linux:gentoo:true::
13:Arch Linux:archlinux:false:archlinux:
14:Devuan Linux:devuan:false::
15:Chimera Linux:chimera:custom::chimera_handler
16:Oracle Linux:oracle:false::
17:Amazon Linux:amazonlinux:false::
18:Plamo Linux:plamo:false::
19:Linux Mint:mint:false::
20:Alt Linux:alt:false::
21:Funtoo Linux:funtoo:false::
22:openEuler:openeuler:false::
23:Springdale Linux:springdalelinux:false::
"

num_distros=$(printf "%s" "$distributions" | grep -c '^')

error_exit() {
    log "ERROR" "$1" "$RED"
    exit 1
}

ARCH="$(uname -m)"

check_network() {
    curl -fs --head "$BASE_URL" >/dev/null ||
        error_exit "Unable to reach $BASE_URL"
}

cleanup() {
    log "INFO" "Cleaning up..." "$YELLOW"
    rm -f "$ROOTFS_DIR/rootfs.tar.xz"
    rm -rf /tmp/sbin
}

get_label() {
    distro="$1"
    version="$2"

    resp="$(curl -fs "$DISTRO_MAP_URL/distro/$distro/$version" || echo "")"

    if printf "%s" "$resp" | jq -e '.error' >/dev/null 2>&1; then
        printf "%s" "$version"
    else
        printf "%s" "$resp" | jq -r '.label'
    fi
}

get_distro_data() {
    sel="$1"
    printf "%s" "$distributions" | while IFS= read -r line; do
        [ "${line%%:*}" = "$sel" ] && { printf "%s" "$line"; break; }
    done
}

install_custom() {
    pretty="$1"
    url="$2"

    log "INFO" "Installing $pretty..." "$GREEN"

    mkdir -p "$ROOTFS_DIR"

    file="$ROOTFS_DIR/$(basename "$url")"

    curl -fLs "$url" -o "$file" ||
        error_exit "Failed to download $pretty"

    tar -xf "$file" -C "$ROOTFS_DIR" ||
        error_exit "Failed to extract $pretty"

    mkdir -p "$ROOTFS_DIR/home/container"
    rm -f "$file"
}

opensuse_handler() {
    printf "Select openSUSE version:\n"
    printf "* [1] Leap\n"
    printf "* [2] Tumbleweed\n"
    printf "* [0] Back\n"

    while :; do
        printf "${YELLOW}Enter (0-2): ${NC}\n"
        read -r x
        case "$x" in
            0) exec "$0" ;;
            1)
                log "INFO" "openSUSE Leap" "$GREEN"
                case "$ARCH" in
                    x86_64|aarch64)
                        install_custom "openSUSE Leap" \
                        "https://download.opensuse.org/distribution/openSUSE-current/appliances/opensuse-leap-image.${ARCH}-lxc.tar.xz"
                        ;;
                    *) error_exit "Leap not available on $ARCH" ;;
                esac
                break
                ;;
            2)
                log "INFO" "openSUSE Tumbleweed" "$GREEN"
                [ "$ARCH" = "x86_64" ] ||
                    error_exit "Tumbleweed not available on $ARCH"
                install_custom "openSUSE Tumbleweed" \
                    "https://download.opensuse.org/tumbleweed/appliances/opensuse-tumbleweed-image.x86_64-lxc.tar.xz"
                break
                ;;
            *) log "ERROR" "Invalid selection" "$RED" ;;
        esac
    done
}

chimera_handler() {
    base="https://repo.chimera-linux.org/live/latest/"
    latest="$(curl -fs "$base" | grep -o "chimera-linux-$ARCH-ROOTFS-[0-9]\{8\}-bootstrap.tar.gz" | sort -V | tail -n 1)" ||
        error_exit "Failed to fetch Chimera version"

    [ -z "$latest" ] && error_exit "No Chimera version found"

    install_custom "Chimera Linux" "${base}${latest}"
}

download_and_extract_rootfs() {
    name="$1"
    version="$2"
    custom="$3"

    if [ "$custom" = "true" ]; then
        arch_base="$BASE_URL/$name/current/"
        url="$arch_base/$ARCH_ALT/$version/"
    else
        arch_base="$BASE_URL/$name/$version/"
        url="$arch_base/$ARCH_ALT/default/"
    fi

    curl -fs "$arch_base" | grep -q "$ARCH_ALT" ||
        error_exit "Unsupported architecture: $ARCH_ALT"

    latest="$(curl -fs "$url" | grep -o '[0-9]\{8\}_[0-9]\{2\}:[0-9]\{2\}/' | sort -r | head -n 1)" ||
        error_exit "Unable to determine latest version"

    mkdir -p "$ROOTFS_DIR"

    log "INFO" "Downloading rootfs..." "$GREEN"
    curl -fLs "${url}${latest}rootfs.tar.xz" -o "$ROOTFS_DIR/rootfs.tar.xz" ||
        error_exit "Failed to download rootfs"

    log "INFO" "Extracting rootfs..." "$GREEN"
    tar -xf "$ROOTFS_DIR/rootfs.tar.xz" -C "$ROOTFS_DIR" ||
        error_exit "Failed to extract rootfs"

    rm -f "$ROOTFS_DIR/etc/resolv.conf"
    mkdir -p "$ROOTFS_DIR/home/container"
}

post_install_config() {
    case "$1" in
        archlinux)
            log "INFO" "Arch Linux config..." "$GREEN"
            sed -i '/^#RootDir/s/^#//' "$ROOTFS_DIR/etc/pacman.conf"
            sed -i '/^#DBPath/s/^#//' "$ROOTFS_DIR/etc/pacman.conf"
        ;;
    esac
}

display_menu() {
    print_main_banner
    printf "\n${YELLOW}Select a distro:${NC}\n\n"
    printf "%s" "$distributions" | while IFS=: read -r num name _; do
        printf "* [%s] %s\n" "$num" "$name"
    done
    printf "\n${YELLOW}Enter (1-%s): ${NC}\n" "$num_distros"
}

ARCH_ALT="$(detect_architecture)"
check_network
trap cleanup EXIT

if [ "$num_distros" -eq 1 ]; then
    selection=1
else
    display_menu
    read -r selection
fi

distro_data="$(get_distro_data "$selection")"

[ -z "$distro_data" ] &&
    error_exit "Invalid selection"

IFS=: read -r num display distro_id flag post_config custom_handler <<EOF
$distro_data
EOF

if [ -n "$custom_handler" ]; then
    "$custom_handler"
else
    install "$distro_id" "$display" "$flag"
    [ -n "$post_config" ] && post_install_config "$post_config"
fi

cp /common.sh /run.sh "$ROOTFS_DIR"
chmod +x "$ROOTFS_DIR/common.sh" "$ROOTFS_DIR/run.sh"
