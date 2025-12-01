#!/bin/sh

# Give container time to settle
sleep 2

cd /home/container || exit 1

# Expand variables inside the startup string
MODIFIED_STARTUP=$(printf "%s" "$STARTUP" \
    | sed 's/{{/${/g; s/}}/}/g' \
    | eval echo)

# Provide internal Docker IP to processes
export INTERNAL_IP="$(ip route get 1 | awk 'NF {print $NF; exit}')"

# First-time installation
if [ ! -f "$HOME/.installed" ]; then
    /usr/local/bin/proot \
        --rootfs="/" \
        -0 \
        -w "/root" \
        -b /dev \
        -b /sys \
        -b /proc \
        --kill-on-exit \
        /bin/sh "/install.sh" || exit 1
fi

# Run startup helper
sh /helper.sh
