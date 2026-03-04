# ZMK firmware build for Mriya58
# Usage:
#   just init          — first-time setup (pulls ZMK + Zephyr, ~5 min)
#   just build         — build both halves
#   just flash-left    — flash left half (plug in, double-tap reset first)
#   just flash-right   — flash right half

docker_image := "zmkfirmware/zmk-dev-arm:stable"
workdir := justfile_directory() / ".zmk"
config_dir := justfile_directory() / "config"
uid := `id -u`
gid := `id -g`

# Run a command inside the ZMK Docker container
# .zmk/ is the full workspace, config/ is bind-mounted into it
[private]
docker +cmd:
    mkdir -p {{ workdir }}
    docker run --rm \
        --user {{ uid }}:{{ gid }} \
        -v {{ workdir }}:/workspace \
        -v {{ config_dir }}:/workspace/config:ro \
        -w /workspace \
        -e HOME=/tmp \
        -e ZEPHYR_BASE=/workspace/zephyr \
        {{ docker_image }} \
        sh -c "west zephyr-export 2>/dev/null; {{ cmd }}"

# First-time setup: initialize west workspace and fetch ZMK + Zephyr
init:
    just docker "west init -l config/ 2>/dev/null || true && west update && west zephyr-export"

# Update ZMK and Zephyr to latest
update:
    just docker "west update"

# Build both halves
build: build-left build-right
    @echo "Done! Firmware files are in {{ workdir }}/firmware/"
    @ls -lh {{ workdir }}/firmware/*.uf2

# Build left half firmware
build-left:
    just docker "west build -s zmk/app -d build/left -b mriya_left -p -- -DZMK_CONFIG=/workspace/config -DBOARD_ROOT=/workspace/config && mkdir -p firmware && cp build/left/zephyr/zmk.uf2 firmware/mriya_left.uf2"

# Build right half firmware
build-right:
    just docker "west build -s zmk/app -d build/right -b mriya_right -p -- -DZMK_CONFIG=/workspace/config -DBOARD_ROOT=/workspace/config && mkdir -p firmware && cp build/right/zephyr/zmk.uf2 firmware/mriya_right.uf2"

# Build settings reset firmware (for fixing BT pairing issues)
build-reset:
    just docker "west build -s zmk/app -d build/reset -b nice_nano_v2 -p -- -DSHIELD=settings_reset && mkdir -p firmware && cp build/reset/zephyr/zmk.uf2 firmware/settings_reset.uf2"

# Flash left half — double-tap reset on the left half first, then run this
flash-left: build-left
    #!/usr/bin/env bash
    set -euo pipefail
    mountpoint=$(lsblk -o MOUNTPOINT,LABEL -nr | awk '$2 == "Mriya" {print $1; exit}')
    if [ -z "$mountpoint" ]; then
        echo "Error: Mriya drive not found. Double-tap reset on the left half and try again."
        exit 1
    fi
    echo "Flashing left half to $mountpoint ..."
    cp {{ workdir }}/firmware/mriya_left.uf2 "$mountpoint/mriya_left.uf2"
    echo "Done! Left half will reboot automatically."

# Flash right half — double-tap reset on the right half first, then run this
flash-right: build-right
    #!/usr/bin/env bash
    set -euo pipefail
    mountpoint=$(lsblk -o MOUNTPOINT,LABEL -nr | awk '$2 == "Mriya" {print $1; exit}')
    if [ -z "$mountpoint" ]; then
        echo "Error: Mriya drive not found. Double-tap reset on the right half and try again."
        exit 1
    fi
    echo "Flashing right half to $mountpoint ..."
    cp {{ workdir }}/firmware/mriya_right.uf2 "$mountpoint/mriya_right.uf2"
    echo "Done! Right half will reboot automatically."

# Clean build artifacts
clean:
    just docker "rm -rf build firmware"

# Full clean including west workspace (will need `just init` again)
nuke:
    rm -rf {{ workdir }}