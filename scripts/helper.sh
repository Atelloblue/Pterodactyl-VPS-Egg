#!/bin/sh

ensure_run_script_exists() {
    for file in common.sh run.sh; do
        src="/$file"
        dst="$HOME/$file"

        if [ ! -f "$dst" ]; then
            cp "$src" "$dst"
            chmod +x "$dst"
        fi
    done
}

parse_ports() {
    config_file="$HOME/vps.config"
    [ ! -f "$config_file" ] && return

    port_args=""

    while IFS='=' read -r key raw_value; do
        # Skip empty lines and comments
        case "$key" in
            ""|"#"*) continue ;;
        esac

        key=$(printf "%s" "$key" | tr -d '[:space:]')
        value=$(printf "%s" "$raw_value" | tr -d '[:space:]')

        [ "$key" = "internalip" ] && continue

        case "$key" in
            port[0-9]*)
                case "$value" in
                    ''|*[!0-9]*)
                        continue
                        ;;
                esac

                if [ "$value" -ge 1 ] && [ "$value" -le 65535 ]; then
                    port_args="$port_args -p $value:$value"
                fi
                ;;
        esac
    done < "$config_file"

    printf "%s" "$port_args"
}

exec_proot() {
    port_args="$(parse_ports)"

    /usr/local/bin/proot \
        --rootfs="$HOME" \
        -0 \
        -w "$HOME" \
        -b /dev \
        -b /sys \
        -b /proc \
        $port_args \
        --kill-on-exit \
        /bin/sh "$HOME/run.sh"
}

ensure_run_script_exists
exec_proot
