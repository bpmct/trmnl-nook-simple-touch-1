# TRMNL client for Nook Simple Touch

A [TRMNL client](https://trmnl.com/developers) for the Nook Simple Touch (BNRV300) and Nook Simple Touch with Glowlight (BNRV350). These devices usually go for around $30 on eBay and have an 800x600 e-ink display.

<table>
<tr>
<td width="33%" align="center"><img src="images/configuration.jpg" alt="Configuration"><br><em>Configuration screen</em></td>
<td width="33%" align="center"><img src="images/display.jpg" alt="Display"><br><em>Fullscreen view</em></td>
<td width="33%" align="center"><img src="images/dialog.jpg" alt="Dialog"><br><em>Menu dialog</em></td>
</tr>
</table>

Questions or feedback? Please [open an issue](https://github.com/bpmct/trmnl-nook-simple-touch/issues/new).

## Table of Contents

- [Prerequisites](#prerequisites)
- [Install](#install)
- [Device Settings](#device-settings)
- [Features](#features)
- [Sleep Button](#sleep-button)
- [Deep Sleep Mode](#deep-sleep-mode)
- [Frames and Cases](#frames-and-cases)
- [Gift Mode](#gift-mode)
- [Roadmap](#roadmap)
- [Other Nook Models](#other-nook-models)
- [Development](#development)
- [Disclaimer](#disclaimer)

## Prerequisites
- Root the device using the [Phoenix Project](https://xdaforums.com/t/nst-g-the-phoenix-project.4673934/). I used "phase 4" (the minimal rooted install for customization). The phases were confusing because you do not need phase 1/2/3 (each is a separate backup).
- Buy a [TRMNL BYOD license](https://shop.usetrmnl.com/collections/frontpage/products/byod) and grab your SSID + API key from Developer Settings after login (or use your own server).

## Install
- Download the APK from [GitHub Releases](https://github.com/bpmct/trmnl-nook-simple-touch/releases).
- Connect the Nook Simple Touch over USB and copy the APK over.
- Open the included `ES File Explorer` app.
- In ES File Explorer: `Favorites -> "/" -> "media" -> "My Files".`
- Tap the APK and install.
- Connect your device to WiFi
- Open the app and configure the device info

## Device Settings

In the TRMNL Device settings, set the device type to "Nook Simple Touch" as the TRMNL team was nice enough to add support for this device!

## Features

- On-device config UI for device ID, API key, and API URL (BYOS)
- Fetches your screen and shows it fullscreen, bypassing the lock screen until you exit
- Respects playlist intervals to advance to the next screen
- TLS v1.2 via BouncyCastle (not included in Android 2.1)
- BYOD support for TRMNL and custom server URLs
- Reports battery voltage and Wi-Fi signal strength
- Deep sleep mode for 30+ day battery life
- Manual sleep button in the tap menu
- Gift Mode for pre-configuring devices as gifts

## Sleep Button

The tap menu (shown when you tap the screen) includes a **Sleep** button alongside Battery, Next, and Settings.

Tapping Sleep immediately puts the device to sleep the same way the physical power button does — the NOOK screensaver is shown and the device can be woken with the home or power button.

### How it works

Forcing the screen off on Android 2.3 (API 10) from a normal (non-system) app is non-trivial:

| Approach | Why it doesn't work |
|---|---|
| `PowerManager.goToSleep()` | Requires `DEVICE_POWER` — a system-only permission, not grantable to third-party apps even on rooted devices |
| `KEYCODE_POWER` via `input keyevent 26` | No-op on NOOK firmware; power key is handled at kernel level |
| `sendevent /dev/input/event1 1 116 1` | Also no-op; kernel intercepts before Android sees it |
| `echo mem > /sys/power/state` via `su` | Raw kernel suspend — bypasses Android power manager entirely, so no screensaver renders and wake behavior is broken |
| `service call power 2 i32 <uptime> i32 0` via `su` | The Superuser dialog causes user activity that resets the power timer; timestamp is stale by the time `su` executes |

**What actually works:** `WRITE_SETTINGS` + screen timeout trick.

`android.permission.WRITE_SETTINGS` is a normal permission any app can hold. The sleep sequence is:

1. Write the TRMNL screensaver image to `/media/screensavers/TRMNL/display.png`
2. Schedule a wake alarm for the next refresh cycle
3. Turn off WiFi (if auto-disable is enabled)
4. Remove `FLAG_KEEP_SCREEN_ON` from the window
5. Set `Settings.System.SCREEN_OFF_TIMEOUT` to **1000 ms** (1 second)
6. The Android power manager fires its natural screen-off path within ~1 second — this goes through the full NOOK EPD screensaver pipeline, same as the physical power button
7. On wake, `onResume` restores `SCREEN_OFF_TIMEOUT` to 120 seconds and re-asserts `FLAG_KEEP_SCREEN_ON`

A `sleepPending` flag blocks `onResume` from re-asserting keep-awake during the brief pause/resume cycle caused by the tap menu dismissing.

## Deep Sleep Mode

Without deep sleep, expect ~60 hours of battery life. With deep sleep and a 30-minute refresh rate, battery lasts 30+ days. The app writes each image to the Nook's screensaver, turns off WiFi, and sets an RTC alarm to wake for the next refresh.

To enable:
1. In the app: Enable "Sleep between updates"
2. In `Nook Settings → Display → Screensaver`: Set to "TRMNL" with 2-minute timeout
3. In `Apps → Nook Touch Mod`: Enable "Hide Screensaver Banner"

## Frames and Cases

The Nook Simple Touch often develops sticky residue on its rubberized surfaces as it ages. [iFixit](https://www.ifixit.com/Device/Barnes_%26_Noble_Nook_Simple_Touch) has great teardown and repair guides if you need to clean or refurbish your device.

<img src="images/frame-comparison.jpg" alt="3D-printed frame (left) vs original case (right)" width="500">

For a custom frame, I recommend this [3D-printed case on Thingiverse](https://www.thingiverse.com/thing:7140441). It requires:
- M3x4 flush screws
- M3x5x4 threaded inserts (soldering iron required to install)
- The original screws and inserts from the Nook Simple Touch

## Gift Mode

Gift Mode displays setup instructions instead of fetching content—perfect for giving a pre-configured device as a gift.

To set up:
1. Buy a [BYOD license](https://shop.usetrmnl.com/products/byod) for the recipient
2. Get the friendly device code from [trmnl.com/claim-a-device](https://trmnl.com/claim-a-device)
3. In the app: Settings → Enable "Gift mode" → "Configure Gift Mode"
4. Enter your name, recipient's name, and the device code

## Roadmap

See [GitHub Issues](https://github.com/bpmct/trmnl-nook-simple-touch/issues) for the roadmap and to submit feature requests.

## Development
See the CI workflow for build details ([`build-apk.yml`](https://github.com/bpmct/trmnl-nook-simple-touch/blob/main/.github/workflows/build-apk.yml)), and the `tools/` adb scripts for build/install workflows. A development guide is coming (https://github.com/bpmct/trmnl-nook-simple-touch/issues/8). In the meantime, the project can be built with surprisingly minimal, self-contained dependencies.

## Other Nook Models

This repository targets legacy Nook devices running Android 2.1 (API 7), which requires different tooling and approaches than modern Android. For newer Nook devices like the Nook Glowlight 4, see [trmnl-nook](https://github.com/usetrmnl/trmnl-nook).

If you have another Nook model from this era that you'd like to test, please [open an issue](https://github.com/bpmct/trmnl-nook-simple-touch/issues/new)!

## Disclaimer
AI was used to help code this repo. I have a software development background, but did not want to relearn old Java and the Android 2.1 ecosystem. Despite best-effort scanning and review, the device and/or this software may contain vulnerabilities. Use at your own risk, and if you want to be safer, run it on a guest network.
