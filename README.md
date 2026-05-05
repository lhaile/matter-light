# Matter Light

A Matter-compatible Color Temperature Light device built with [ESP-IDF](https://github.com/espressif/esp-idf) and [Espressif's SDK for Matter](https://github.com/espressif/esp-matter).

Based on the `light` example from esp-matter `release/v1.4.2`.

## Prerequisites

- macOS (Apple Silicon) with [Homebrew](https://brew.sh)
- ESP-IDF v5.4.2
- ESP Matter SDK release/v1.4.2

### Install system tools

```sh
brew install cmake ninja dfu-util ccache python3
```

### Install ESP-IDF

```sh
mkdir -p ~/esp && cd ~/esp
git clone -b v5.4.2 --recursive https://github.com/espressif/esp-idf.git
cd esp-idf && ./install.sh esp32c6,esp32h2
```

### Install ESP Matter SDK

```sh
cd ~/esp
git clone --depth 1 -b release/v1.4.2 https://github.com/espressif/esp-matter.git
cd esp-matter
git submodule update --init --depth 1
cd connectedhomeip/connectedhomeip
./scripts/checkout_submodules.py --platform esp32 darwin --shallow
cd ../.. && ./install.sh
```

## Environment Setup

Source both environments in each terminal session:

```sh
. ~/esp/esp-idf/export.sh
. ~/esp/esp-matter/export.sh
export IDF_CCACHE_ENABLE=1
```

Or use the shell alias (if configured):

```sh
get_matter
```

## Build

```sh
idf.py set-target esp32c6
idf.py build
```

Supported targets: `esp32`, `esp32c3`, `esp32c6`, `esp32h2`, `esp32s3`

## Flash & Monitor

```sh
idf.py -p /dev/cu.usbserial-* flash monitor
```

Press `Ctrl+]` to exit the monitor.

## Commissioning

Use `chip-tool` (built during esp-matter installation) to commission the device:

```sh
# Start interactive mode
chip-tool interactive start

# Commission over BLE + Wi-Fi
pairing ble-wifi 0x7283 <ssid> <passphrase> 20202021 3840
```

Default credentials:
- **Setup passcode**: 20202021
- **Discriminator**: 3840
- **Manual pairing code**: 34970112332

## Project Structure

```
main/
├── app_main.cpp        # Application entry point and Matter setup
├── app_driver.cpp      # LED driver and attribute callbacks
├── app_priv.h          # Private declarations
├── Kconfig.projbuild   # Menuconfig options
└── idf_component.yml   # Component dependencies
```

## Toolchain Versions

- ESP-IDF v5.4.2
- ESP Matter SDK release/v1.4.2
- CMake 4.3.2
- ccache 4.13.6
- Python 3.14.4
