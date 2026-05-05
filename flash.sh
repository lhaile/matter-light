#!/usr/bin/env bash
set -euo pipefail

# Matter Light — clean build and flash
# Usage:
#   ./flash.sh              # Build Wi-Fi (default), flash, and monitor
#   ./flash.sh thread       # Build Thread, erase flash, flash, and monitor
#   ./flash.sh wifi         # Build Wi-Fi, flash, and monitor
#   ./flash.sh --erase      # Build Wi-Fi, erase flash first, then flash and monitor
#   ./flash.sh thread --erase  # (erase is implicit for thread builds)

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
IDF_PATH="${IDF_PATH:-$HOME/esp/esp-idf}"
ESP_MATTER_PATH="${ESP_MATTER_PATH:-$HOME/esp/esp-matter}"
TARGET="esp32c6"

# Parse arguments
TRANSPORT="wifi"
ERASE=false
MONITOR=true

for arg in "$@"; do
    case "$arg" in
        thread)  TRANSPORT="thread" ;;
        wifi)    TRANSPORT="wifi" ;;
        --erase) ERASE=true ;;
        --no-monitor) MONITOR=false ;;
        -h|--help)
            echo "Usage: $0 [wifi|thread] [--erase] [--no-monitor]"
            echo ""
            echo "  wifi      Build with Wi-Fi transport (default)"
            echo "  thread    Build with Thread transport (implies --erase)"
            echo "  --erase   Erase entire flash before programming (clears NVS/commissioning data)"
            echo "  --no-monitor  Flash without opening the serial monitor"
            exit 0
            ;;
        *)
            echo "Unknown argument: $arg"
            echo "Run '$0 --help' for usage."
            exit 1
            ;;
    esac
done

# Thread builds always need a full erase to clear any Wi-Fi commissioning state
if [ "$TRANSPORT" = "thread" ]; then
    ERASE=true
fi

# Source environments
echo "==> Sourcing ESP-IDF and ESP-Matter environments..."
# shellcheck source=/dev/null
. "$IDF_PATH/export.sh" > /dev/null 2>&1
# shellcheck source=/dev/null
. "$ESP_MATTER_PATH/export.sh" > /dev/null 2>&1
export ESP_MATTER_PATH
export IDF_CCACHE_ENABLE=1

# Clean build
echo "==> Cleaning previous build..."
rm -rf "$PROJECT_DIR/build" "$PROJECT_DIR/sdkconfig"

# Configure
echo "==> Configuring for $TARGET ($TRANSPORT)..."
if [ "$TRANSPORT" = "thread" ]; then
    idf.py -C "$PROJECT_DIR" \
        -DSDKCONFIG_DEFAULTS="sdkconfig.defaults;sdkconfig.defaults.c6_thread" \
        set-target "$TARGET"
else
    idf.py -C "$PROJECT_DIR" set-target "$TARGET"
fi

# Verify key config
if [ "$TRANSPORT" = "thread" ]; then
    if ! grep -q "^CONFIG_OPENTHREAD_ENABLED=y" "$PROJECT_DIR/sdkconfig"; then
        echo "ERROR: OpenThread not enabled in sdkconfig. Thread build failed." >&2
        exit 1
    fi
    echo "    ✓ OpenThread enabled, Wi-Fi station disabled"
else
    if ! grep -q "^CONFIG_ENABLE_WIFI_STATION=y" "$PROJECT_DIR/sdkconfig"; then
        echo "WARNING: Wi-Fi station not enabled in sdkconfig." >&2
    fi
    echo "    ✓ Wi-Fi station enabled"
fi

# Build
echo "==> Building..."
idf.py -C "$PROJECT_DIR" build

# Flash
if [ "$ERASE" = true ]; then
    echo "==> Erasing flash and programming..."
    idf.py -C "$PROJECT_DIR" erase-flash flash
else
    echo "==> Programming..."
    idf.py -C "$PROJECT_DIR" flash
fi

echo ""
echo "==> Done! Flashed $TRANSPORT firmware to $TARGET."
echo "    Pairing code: 34970112332"
echo "    QR code:      MT:Y.K9042C00KA0648G00"

# Monitor
if [ "$MONITOR" = true ]; then
    echo "==> Opening monitor (Ctrl+] to exit)..."
    idf.py -C "$PROJECT_DIR" monitor
fi
