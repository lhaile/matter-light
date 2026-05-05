# Matter Light

A Matter-compatible Color Temperature Light device built with [ESP-IDF](https://github.com/espressif/esp-idf) and [Espressif's SDK for Matter](https://github.com/espressif/esp-matter).

Based on the `light` example from esp-matter `release/v1.4.2`.

## Hardware

- **Target**: ESP32-C6 (supports Wi-Fi 6, BLE 5, and IEEE 802.15.4 / Thread)
- **RGB LED (WS2812)**: GPIO 20 (custom device HAL)
- **LED Power Enable**: GPIO 19 (must be driven high to power the RGB LED)
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

### Wi-Fi (default)

```sh
idf.py set-target esp32c6
idf.py build
```

### Thread (Matter over Thread)

The ESP32-C6 supports 802.15.4 for Thread networking. Use the `sdkconfig.defaults.c6_thread` config which enables OpenThread and disables Wi-Fi:

```sh
idf.py -DSDKCONFIG_DEFAULTS="sdkconfig.defaults;sdkconfig.defaults.c6_thread" set-target esp32c6
idf.py build
```

Key differences from the Wi-Fi build:
- OpenThread enabled with SRP and DNS clients
- Wi-Fi station disabled
- Platform mDNS (instead of minimal mDNS)
- LwIP configured for Thread (8 IPv6 addresses, multicast ping)

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

### Default Credentials

- **Setup passcode**: 20202021
- **Discriminator**: 3840
- **Manual pairing code**: 34970112332
- **QR code**: `MT:Y.K9042C00KA0648G00`

### Over BLE + Wi-Fi

```sh
chip-tool pairing ble-wifi 0x7283 "<ssid>" "<password>" 20202021 3840
```

> **macOS note**: BLE commissioning requires the
> [Bluetooth Central Matter Client Developer Mode Profile](https://developer.apple.com/bug-reporting/profiles-and-logs/)
> from Apple.

### Over BLE + Thread

Requires a Thread Border Router on your network (e.g., Apple HomePod Mini, eero, Aqara Hub M100). Provide the Thread operational dataset in hex:

```sh
chip-tool pairing ble-thread 0x7283 <hex-dataset> 20202021 3840
```

Alternatively, commission directly from a Matter controller app (Apple Home, Google Home, Aqara Home) using the manual pairing code or QR code above. The controller will supply the Thread credentials automatically.

### Over IP (if device is already on Wi-Fi)

Connect via device console first:

```
matter esp wifi connect <ssid> <password>
```

Then commission over the network:

```sh
chip-tool pairing onnetwork 0x7283 20202021
```

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

The LED power enable pin (GPIO 19) is configured in `main/app_driver.cpp`.

## Troubleshooting

### Build Errors

**`Please set ESP_MATTER_PATH to the path of esp-matter repo`**

The environment is not sourced. Run `. ~/esp/esp-matter/export.sh` or `get_matter`.

**`No module named 'lark'` or missing Python modules**

```sh
. ~/esp/esp-idf/export.sh
python3 -m pip install -r ~/esp/esp-matter/requirements.txt
```

**`SRC_DIRS entry ... does not exist`**

The custom device HAL path is misconfigured. Ensure `CMakeLists.txt` line 21 points to `${CMAKE_SOURCE_DIR}/device_hal` and the `device_hal/` directory exists with `device.c` and `esp_matter_device.cmake`.

**`This script was called from a virtual environment`**

```sh
pip install -r $IDF_PATH/requirements.txt
```

**Stale build after changing target or GPIO pins**

```sh
idf.py fullclean
idf.py set-target esp32c6
idf.py build
```

### Commissioning Errors

**BLE commissioning fails on macOS**

Install the [Bluetooth Central Matter Client Developer Mode Profile](https://developer.apple.com/bug-reporting/profiles-and-logs/). As a workaround, commission over IP instead:

```
# In device monitor console
matter esp wifi connect <ssid> <password>
```

```sh
# In chip-tool terminal
chip-tool pairing onnetwork 0x7283 20202021
```

**`Discovery timed out` or device not found**

- Ensure the device is powered on and not already commissioned
- Factory reset: `idf.py -p /dev/cu.usbserial-* erase-flash`, then re-flash
- Check that your host and device are on the same network (for IP commissioning)

**`CHIP Error 0x00000032: Timeout`**

The device may have already been commissioned. Reset its state:

```sh
# On the device (via monitor console)
matter device factoryreset
```

```sh
# On the host (clear chip-tool state)
rm -rf /tmp/chip_*
```

**chip-tool not found**

Ensure esp-matter environment is sourced. The binary is at:
`~/esp/esp-matter/connectedhomeip/connectedhomeip/out/host/chip-tool`

### Runtime Errors

**LED not responding after commissioning**

- Verify GPIO pin matches your hardware (`device_hal/device.c`)
- Check the monitor log for WS2812 RMT driver errors
- Ensure the correct endpoint (1) is used in chip-tool commands

**Device crashes with `Chip stack locking error`**

Matter resource access must happen on the Matter thread. If you added custom code, wrap it with the Matter stack lock. See the [esp-matter FAQ](https://docs.espressif.com/projects/esp-matter/en/latest/esp32/faq.html).

## Toolchain Versions

- ESP-IDF v5.4.2
- ESP Matter SDK release/v1.4.2
- CMake 4.3.2
- ccache 4.13.6
- Python 3.14.4
