# Matter Light

A Matter-compatible Color Temperature Light device built with [ESP-IDF](https://github.com/espressif/esp-idf) and [Espressif's SDK for Matter](https://github.com/espressif/esp-matter).

Based on the `light` example from esp-matter `release/v1.4.2`.

## Hardware

- **Target**: ESP32-C6
- **RGB LED (WS2812)**: GPIO 20 (custom device HAL)
- **Button**: GPIO 9

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

To factory reset:

```sh
idf.py -p /dev/cu.usbserial-* erase-flash
```

## Commissioning

Open a second terminal and activate the environment:

```sh
get_matter
```

### Over BLE + Wi-Fi

```sh
chip-tool pairing ble-wifi 0x7283 "<ssid>" "<password>" 20202021 3840
```

> **macOS note**: BLE commissioning requires the
> [Bluetooth Central Matter Client Developer Mode Profile](https://developer.apple.com/bug-reporting/profiles-and-logs/)
> from Apple.

### Over IP (if device is already on Wi-Fi)

Connect via device console first:

```
matter esp wifi connect <ssid> <password>
```

Then commission over the network:

```sh
chip-tool pairing onnetwork 0x7283 20202021
```

### Default Credentials

- **Setup passcode**: 20202021
- **Discriminator**: 3840
- **Manual pairing code**: 34970112332
- **QR code**: `MT:Y.K9042C00KA0648G00`

## Controlling the Light

```sh
# Turn on
chip-tool onoff on 0x7283 1

# Turn off
chip-tool onoff off 0x7283 1

# Set brightness (0-254)
chip-tool levelcontrol move-to-level 128 0 0 0 0x7283 1

# Set color (hue 0-254, saturation 0-254)
chip-tool colorcontrol move-to-hue-and-saturation 180 200 0 0 0 0x7283 1

# Set color temperature (mireds)
chip-tool colorcontrol move-to-color-temperature 300 0 0 0 0x7283 1
```

## Project Structure

```
├── CMakeLists.txt              # Build config (points esp32c6 to custom device HAL)
├── device_hal/
│   ├── device.c                # Custom GPIO config (LED=GPIO20, Button=GPIO9)
│   └── esp_matter_device.cmake # Device HAL cmake (WS2812 LED, IoT button)
├── main/
│   ├── app_main.cpp            # Application entry point and Matter setup
│   ├── app_driver.cpp          # LED driver and attribute callbacks
│   ├── app_priv.h              # Private declarations
│   ├── Kconfig.projbuild       # Menuconfig options
│   └── idf_component.yml       # Component dependencies
├── partitions.csv              # Partition table
└── sdkconfig.defaults*         # Default configs per target
```

### Customizing GPIO Pins

Edit `device_hal/device.c` to change pin assignments:

```c
#define LED_GPIO_PIN    GPIO_NUM_20   // WS2812 RGB LED
#define BUTTON_GPIO_PIN GPIO_NUM_9    // Boot/toggle button
```

## Toolchain Versions

- ESP-IDF v5.4.2
- ESP Matter SDK release/v1.4.2
- CMake 4.3.2
- ccache 4.13.6
- Python 3.14.4
