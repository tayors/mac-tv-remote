# Mac TV Remote

A native Mac menu-bar remote for Android TV and Google TV. Build it as-is, or use it as a starter for your own remote. The app source is in [`app/`](app).

The remote has a circular directional pad, keyboard navigation, playback and volume controls, app shortcuts, and connection recovery. It runs locally, with no account, cloud service, telemetry, or app installed on the TV.

**Compatibility:** the original remote was tested with a TCL Smart TV Pro. Other models are unverified. Your TV must support authorised network ADB. Samsung Tizen, LG webOS, Roku, and other non-Android platforms need different transports; this release does not support them. Wake from standby depends on the TV and its network settings.

## Build the remote

Requirements:

- A Mac with macOS 13 or newer and Xcode command-line tools (`swiftc`).
- Python 3.9 or newer. The app looks in Apple Silicon Homebrew, Intel Homebrew, then `/usr/bin`.
- [Android SDK Platform Tools](https://developer.android.com/tools/releases/platform-tools), with `adb` installed.
- An Android/Google TV that allows network ADB, on a network reachable from the Mac.

```sh
git clone https://github.com/tayors/mac-tv-remote.git
cd mac-tv-remote
./scripts/test.sh
./scripts/build.sh
open "$HOME/Applications/Mac TV Remote.app"
```

The build creates a locally ad-hoc-signed app, not a notarised downloadable binary. It targets the Mac's current CPU architecture. The macOS 13 deployment target does not establish testing on every macOS release or on Intel hardware.

On first launch, select **Set up TV** or the settings icon. Enter a name and the TV's actual ADB `host:port`. The app has no default endpoint. Enable debugging and accept the Mac's authorisation prompt on the TV. For a pairing-code TV, complete `adb pair PAIRING_HOST:PAIRING_PORT` first, then enter its separate connection endpoint. Follow [Android's ADB instructions](https://developer.android.com/tools/adb) for your device.

Leave Wake MAC and broadcast blank unless you know both values. Without network-wake details, Turn on tries the explicit Android wake key through ADB. A deeply sleeping TV may need its physical remote. If macOS asks, allow this app to access the local network; see [Apple's Local Network guidance](https://developer.apple.com/documentation/technotes/tn3179-understanding-local-network-privacy).

## Personalise it with an agent

Paste this into your coding agent. No skill installation is required:

```text
Use https://github.com/tayors/mac-tv-remote as the starter for my Mac TV remote.
Read its README and start from the working app source, rather than recreating it.

Identify my TV's platform and confirm that it supports network ADB. Help me find
its actual connection address and authorise this Mac, then verify read-only
status before sending controls. Discover the supported app shortcuts and ask
what controls or appearance I want to customise.

Build and test the remote locally. Keep personal network details in local
preferences. Leave TV packages and picture settings alone. Tell me which checks
used my TV and which were offline tests. No agent skills need to be installed.
```

The source and setup steps work independently of any agent. An agent is useful for changing the layout, adding verified app shortcuts, or diagnosing a connection problem.

## Controls and connections

- Arrow keys navigate; Return selects; Space toggles playback; Escape sends Back while the remote has keyboard focus.
- Refresh reads status and shows a timestamp. It never wakes the TV and runs separately from queued control commands.
- Status updates every 15 seconds while the popover is open. ADB subprocesses have five-second timeouts; the app also bounds whole requests.
- **More options → Reconnect to TV** resets that TV's ADB transport. It can restart an idle ADB service when the TV's port is reachable but the service reports “No route to host.” It stops that repair if ADB lists another device.
- The app discovers enabled packages from a catalog of YouTube, Stremio, Netflix, Prime Video, Disney+, and Apple TV. It only shows matching shortcuts. Package presence does not guarantee a launchable TV activity; the launcher checks that when opening an app.

Device name, address, and optional wake details stay in this Mac user's app preferences. The app writes diagnostic failures to the local macOS log. Do not include those logs or your preferences in a public issue without removing private details.

## Customise the starter

Create a separate project from the bundled source:

```sh
python3 scripts/create_remote.py ../my-tv-remote
cd ../my-tv-remote
PYTHONPATH=. python3 -B -m unittest discover -s tests -v
./build.sh
```

The generator refuses existing destinations. It copies the self-contained source from `app/`:

- `Remote.swift`: native interface, preferences, keyboard input, and request queues.
- `tv.py`: bounded ADB commands, status parsing, app catalog, and activity validation.
- `remote_bridge.py`: command-line bridge, optional Wake-on-LAN, and explicit reconnection.
- `build.sh`: app packaging, deployment target, and ad-hoc signing.
- `tests/`: offline transport and device-response fixtures.

Add a streaming app by verifying its Android package ID and TV-launcher activity, then updating the Python catalog and Swift shortcut label/icon. To install multiple customised remotes side by side, change the app output name and bundle identifier in `build.sh`; otherwise they share the default preferences domain.

## Optional maintenance workflow

For repeated customisation or troubleshooting, an [optional agent skill](docs/optional-skill.md) is available. It is not needed to build, set up, or use the remote.

## Development and compatibility reports

```sh
./scripts/test.sh
python3 -B -m unittest discover -s tests -v
./scripts/build.sh "/tmp/Mac TV Remote Test.app"
codesign --verify --strict "/tmp/Mac TV Remote Test.app"
```

CI runs offline tests on Linux and macOS and builds the app on macOS. These checks do not certify hardware compatibility. Useful compatibility reports include TV brand/model, OS version, Mac architecture, and which controls worked. Exclude actual IP/MAC addresses, pairing codes, ADB keys, serial numbers, and unredacted diagnostics.

This repository contains the remote starter and an optional maintenance skill. It excludes the original device-specific calibration experiments, background jobs, package inventories, and captured diagnostics.

## Licence

[MIT](LICENSE). Preserve the licence when distributing a customised starter.
